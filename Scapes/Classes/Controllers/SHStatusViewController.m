//
//  SHStatusViewController.m
//  Nightboard
//
//  Created by MachOSX on 9/15/13.
//
//

#import "SHStatusViewController.h"

#import <MediaPlayer/MediaPlayer.h>

#import "AFHTTPRequestOperationManager.h"
#import "SHChatBubble.h"

@implementation SHStatusViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        statusListEntries = [[NSMutableArray alloc] init];
        
        FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT * FROM sh_thread WHERE thread_id == :last_status_id"
                                        withParameterDictionary:@{@"last_status_id": [appDelegate.currentUser objectForKey:@"last_status_id"]}];
        
        while ( [s1 next] )
        {
            status = [s1 stringForColumn:@"message"];
            statusType = [s1 stringForColumn:@"thread_type"];
        }
        
        [s1 close];
        
        s1 = [appDelegate.modelManager executeQuery:@"SELECT COUNT(status_id) FROM sh_status_template"
                           withParameterDictionary:nil];
        
        int statusTemplateCount = 0;
        
        while ( [s1 next] )
        {
            statusTemplateCount = [s1 intForColumnIndex:0];
        }
        
        [s1 close];
        
        if ( statusTemplateCount > 0 )
        {
            s1 = [appDelegate.modelManager executeQuery:@"SELECT * FROM sh_status_template "
                                                        @"ORDER BY sh_status_template.status_index ASC"
                               withParameterDictionary:nil];
            
            while ( [s1 next] )
            {
                NSString *statusTemplate = [s1 stringForColumn:@"status"];
                
                [statusListEntries addObject:statusTemplate];
            }
            
            [s1 close];
        }
        
        [appDelegate.modelManager.results close];
        [appDelegate.modelManager.DB close];
        
        if ( statusTemplateCount == 0 )
        {
            [statusListEntries addObject:@"🔵 available."];
            [statusListEntries addObject:@"🔴 busy."];
            [statusListEntries addObject:@"💬 can't talk right now."];
            [statusListEntries addObject:@"🔋 battery low."];
            [statusListEntries addObject:@"🎮 gaming."];
            [statusListEntries addObject:@"📚 at school."];
            [statusListEntries addObject:@"🎥 at the movies."];
            [statusListEntries addObject:@"📑 at work."];
            [statusListEntries addObject:@"💪 at the gym."];
            [statusListEntries addObject:@"⛔️ in a meeting."];
            [statusListEntries addObject:@"😴 sleeping."];
            
            for ( int i = 0; i < statusListEntries.count; i++ )
            {
                NSString *statusTemplate = [statusListEntries objectAtIndex:i];
                
                NSDictionary *argsDict_statusTemplate = [NSDictionary dictionaryWithObjectsAndKeys:statusTemplate, @"status",
                                                         [NSNumber numberWithInt:i], @"status_index", nil];
                
                [appDelegate.modelManager executeUpdate:@"INSERT INTO sh_status_template "
                                                        @"(status, status_index) "
                                                        @"VALUES (:status, :status_index)"
                                       withParameterDictionary:argsDict_statusTemplate];
            }
        }
        
        [statusListEntries addObject:@"🎧 current iPod song."];
        [statusListEntries addObject:@"📍 current location."];
        
        keyboardIsShown = NO;
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor whiteColor];
    
    cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"GENERIC_CANCEL", nil) style:UIBarButtonItemStylePlain target:self action:@selector(dismissView)];
    
    doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"GENERIC_DONE", nil) style:UIBarButtonItemStyleDone target:self action:@selector(postStatus)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    statusList = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - 100)];
    statusList.backgroundView = nil;
    statusList.backgroundColor = [UIColor clearColor];
    statusList.separatorStyle = UITableViewCellSeparatorStyleNone;
    statusList.scrollsToTop = YES;
    statusList.tag = 1;
    statusList.delegate = self;
    statusList.dataSource = self;
    
    lowerWell = [[UIView alloc] initWithFrame:CGRectMake(0, statusList.frame.size.height, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - statusList.frame.size.height)];
    lowerWell.opaque = YES;
    
    lowerWellSeparator = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 0.5)];
    lowerWellSeparator.image = [[UIImage imageNamed:@"separator_gray"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    lowerWellSeparator.opaque = YES;
    
    lowerWellIcon = [[UIImageView alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width - 33, lowerWell.frame.size.height / 2 - 11, 23, 23)];
    lowerWellIcon.image = [[UIImage imageNamed:@"compose_blue"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    lowerWellIcon.opaque = YES;
    
    currentStatusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [currentStatusButton addTarget:self action:@selector(editCurrentStatus) forControlEvents:UIControlEventTouchUpInside];
    currentStatusButton.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - statusList.frame.size.height);
    currentStatusButton.showsTouchWhenHighlighted = YES;
    
    SHChatBubble *userBubble = [[SHChatBubble alloc] initWithFrame:CGRectMake(20, currentStatusButton.frame.size.height / 2 - 18, 36, 36) withMiniModeEnabled:YES];
    userBubble.enabled = NO;
    
    UIImage *currentDP = [UIImage imageWithData:[appDelegate.currentUser objectForKey:@"dp"]];
    [userBubble setImage:currentDP];
    
    currentLocationLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    currentLocationLabel.backgroundColor = [UIColor clearColor];
    currentLocationLabel.textColor = [UIColor colorWithRed:144/255.0 green:143/255.0 blue:149/255.0 alpha:0.7];
    currentLocationLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:25];
    currentLocationLabel.lineBreakMode = NSLineBreakByWordWrapping;
    currentLocationLabel.numberOfLines = 0;
    currentLocationLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    currentLocationLabel.opaque = YES;
    currentLocationLabel.hidden = YES;
    
    currentStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(66, 10, 216, currentStatusButton.frame.size.height - 20)];
    currentStatusLabel.backgroundColor = [UIColor clearColor];
    currentStatusLabel.textColor = [UIColor colorWithRed:144/255.0 green:143/255.0 blue:149/255.0 alpha:0.7];
    currentStatusLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
    currentStatusLabel.numberOfLines = 0;
    currentStatusLabel.opaque = YES;
    currentStatusLabel.text = status;
    
    status = nil; // IMPORTANT!
    
    characterCounter = [[UILabel alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width - 85, 10, 65, 27)];
    characterCounter.backgroundColor = [UIColor clearColor];
    characterCounter.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
    characterCounter.textAlignment = NSTextAlignmentRight;
    characterCounter.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:25];
    characterCounter.opaque = YES;
    characterCounter.hidden = YES;
    
    statusTemplateHelpLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, appDelegate.screenBounds.size.height / 2 - 10, 280, 20)];
    statusTemplateHelpLabel.backgroundColor = [UIColor clearColor];
    statusTemplateHelpLabel.textColor = [UIColor whiteColor];
    statusTemplateHelpLabel.textAlignment = NSTextAlignmentCenter;
    statusTemplateHelpLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:MAIN_FONT_SIZE];
    statusTemplateHelpLabel.opaque = YES;
    statusTemplateHelpLabel.alpha = 0.0;
    statusTemplateHelpLabel.text = NSLocalizedString(@"HELP_ADD_TEMPLATE", nil);
    statusTemplateHelpLabel.hidden = YES;
    
    statusEditor = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, currentStatusButton.frame.size.height)];
    statusEditor.delegate = self;
    statusEditor.backgroundColor = [UIColor clearColor];
    statusEditor.textColor = [UIColor blackColor];
    statusEditor.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:25];
    statusEditor.returnKeyType = UIReturnKeyDone;
    statusEditor.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    statusEditor.scrollsToTop = NO;
    statusEditor.hidden = YES;
    
    lowerWellShadowCopy = [[UIView alloc] initWithFrame:lowerWell.frame];
    lowerWellShadowCopy.alpha = 0.0;
    lowerWellShadowCopy.hidden = YES;
    
    statusListOverlay = [[UIView alloc] initWithFrame:statusList.frame];
    statusListOverlay.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.0];
    statusListOverlay.hidden = YES;
    
    statusLabelShadow = [[UILabel alloc] initWithFrame:currentStatusLabel.frame];
    statusLabelShadow.backgroundColor = currentStatusLabel.backgroundColor;
    statusLabelShadow.textColor = currentStatusLabel.textColor;
    statusLabelShadow.font = currentStatusLabel.font;
    statusLabelShadow.numberOfLines = currentStatusLabel.numberOfLines;
    statusLabelShadow.opaque = YES;
    
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        statusList.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - 164);
        statusList.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        statusList.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        
        lowerWell.frame = CGRectMake(0, statusList.frame.size.height, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - statusList.frame.size.height);
        
        statusEditor.frame = CGRectMake(20, 0, 280, currentStatusButton.frame.size.height);
        statusEditor.contentInset = UIEdgeInsetsMake(20, 0, 20, 0);
        statusEditor.showsVerticalScrollIndicator = NO; // Because we're offseting the frame rather the content, hide the scroller 'cuz it looks bad.
        
        statusTemplateHelpLabel.frame = CGRectMake(20, appDelegate.screenBounds.size.height / 2 - 100, 280, MAIN_FONT_SIZE * 5 + 20);
    }
    else
    {
        statusEditor.textContainerInset = UIEdgeInsetsMake(20, 20, 20, 20);
    }
    
    UILongPressGestureRecognizer *gesture_longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapAndHoldStatusButton:)];
    [currentStatusButton addGestureRecognizer:gesture_longPress];
    
    [currentStatusButton addSubview:currentStatusLabel];
    [currentStatusButton addSubview:userBubble];
    [lowerWell addSubview:lowerWellIcon];
    [lowerWell addSubview:currentStatusButton];
    [lowerWell addSubview:currentLocationLabel];
    [lowerWell addSubview:statusEditor];
    [lowerWell addSubview:characterCounter];
    [lowerWell addSubview:lowerWellSeparator];
    [lowerWellShadowCopy addSubview:statusLabelShadow];
    [contentView addSubview:statusList];
    [contentView addSubview:statusListOverlay];
    [contentView addSubview:statusTemplateHelpLabel];
    [contentView addSubview:lowerWell];
    [contentView addSubview:lowerWellShadowCopy];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    [self setTitle:NSLocalizedString(@"STATUS_TITLE", nil)];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionNavigationBar];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (void)dismissView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( keyboardIsShown )
    {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            lowerWellIcon.alpha = 1.0;
        } completion:^(BOOL finished){
            
        }];
        
        statusEditor.hidden = YES;
        currentStatusButton.hidden = NO;
        
        if ( currentVenue ) // When canceling adding a personal message to a checkin.
        {
            self.navigationItem.leftBarButtonItem = nil;
            self.navigationItem.rightBarButtonItem = doneButton;
            currentLocationLabel.hidden = YES;
            
            [self showLowerWell];
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                statusList.alpha = 0.0;
            } completion:^(BOOL finished){
                currentVenue = nil;
                
                [statusList reloadData];
                [statusList scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    statusList.alpha = 1.0;
                } completion:^(BOOL finished){
                    
                }];
            }];
        }
        
        [statusEditor resignFirstResponder];
        status = nil; // Clear this out AFTER resigning first responder.
        doneButton.enabled = YES;
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:^{
            [appDelegate.mainMenu showMainWindowSide];
        }];
    }
}

- (void)hideLowerWell
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        statusList.frame = CGRectMake(statusList.frame.origin.x, 0, statusList.frame.size.width, statusList.frame.size.height + (screenBounds.size.height - lowerWell.frame.origin.y));
        lowerWell.frame = CGRectMake(lowerWell.frame.origin.x, screenBounds.size.height, lowerWell.frame.size.width, lowerWell.frame.size.height);
    } completion:^(BOOL finished){
        
    }];
}

- (void)showLowerWell
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
        {
            statusList.frame = CGRectMake(statusList.frame.origin.x, 0, statusList.frame.size.width, screenBounds.size.height - 164);
        }
        else
        {
            statusList.frame = CGRectMake(statusList.frame.origin.x, 0, statusList.frame.size.width, screenBounds.size.height - 100);
        }
        
        lowerWell.frame = CGRectMake(lowerWell.frame.origin.x, statusList.frame.size.height, lowerWell.frame.size.width, lowerWell.frame.size.height);
    } completion:^(BOOL finished){
        
    }];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    NSDictionary *info = [notification userInfo];
    keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    keyboardAnimationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    keyboardAnimationCurve = (UIViewAnimationCurve)[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    UIViewAnimationOptions animationOption = keyboardAnimationCurve << 16;
    [UIView animateWithDuration:keyboardAnimationDuration delay:0 options:animationOption animations:^{
        if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
        {
            lowerWell.frame = CGRectMake(0, 0, lowerWell.frame.size.width, screenBounds.size.height - keyboardSize.height);
            statusEditor.frame = CGRectMake(statusEditor.frame.origin.x, statusEditor.frame.origin.y, statusEditor.frame.size.width, screenBounds.size.height - lowerWell.frame.origin.y - keyboardSize.height - 64);
        }
        else
        {
            lowerWell.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height + 44, lowerWell.frame.size.width, screenBounds.size.height - keyboardSize.height - ([UIApplication sharedApplication].statusBarFrame.size.height + 44));
            statusEditor.frame = CGRectMake(statusEditor.frame.origin.x, statusEditor.frame.origin.y, statusEditor.frame.size.width, screenBounds.size.height - lowerWell.frame.origin.y - keyboardSize.height);
        }
        
        statusList.frame = CGRectMake(-statusList.frame.size.height, statusList.frame.origin.y, statusList.frame.size.width, statusList.frame.size.height);
        
        characterCounter.frame = CGRectMake(characterCounter.frame.origin.x, statusEditor.frame.size.height - characterCounter.frame.size.height - 20, characterCounter.frame.size.width, characterCounter.frame.size.height);
        lowerWellSeparator.alpha = 0.0;
    } completion:^(BOOL finished){
        
    }];
    
    keyboardIsShown = YES;
    
    NSString *editorText = statusEditor.text;
    editorText = [editorText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ( editorText.length >= MAX_STATUS_UPDATE_LENGTH - 20 ) {
        characterCounter.hidden = NO;
        
        if ( editorText.length > MAX_STATUS_UPDATE_LENGTH )
        {
            characterCounter.textColor = [UIColor redColor];
        }
        else
        {
            characterCounter.textColor = [UIColor colorWithWhite:1.0 alpha:0.7];
        }
    }
    else
    {
        characterCounter.hidden = YES;
    }
    
    characterCounter.text = [NSString stringWithFormat:@"%d", MAX_STATUS_UPDATE_LENGTH - (int)editorText.length];
}

// Called when the UIKeyboardWillHideNotification is sent.
- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    self.navigationItem.leftBarButtonItem = nil;
    
    NSDictionary *info = [notification userInfo];
    keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    keyboardAnimationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    keyboardAnimationCurve = (UIViewAnimationCurve)[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    UIViewAnimationOptions animationOption = keyboardAnimationCurve << 16;
    [UIView animateWithDuration:keyboardAnimationDuration delay:0 options:animationOption animations:^{
        statusList.frame = CGRectMake(0, statusList.frame.origin.y, statusList.frame.size.width, statusList.frame.size.height);
        statusEditor.frame = CGRectMake(statusEditor.frame.origin.x, statusEditor.frame.origin.y, statusEditor.frame.size.width, currentStatusButton.frame.size.height);
        lowerWell.frame = CGRectMake(0, screenBounds.size.height - (screenBounds.size.height - statusList.frame.size.height), lowerWell.frame.size.width, screenBounds.size.height - statusList.frame.size.height);
        lowerWellSeparator.alpha = 1.0;
    } completion:^(BOOL finished){
        
    }];
    
    keyboardIsShown = NO;
    characterCounter.hidden = YES;
    
    NSString *editorText = statusEditor.text;
    editorText = [editorText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    status = editorText;
}

- (void)editCurrentStatus
{
    //statusEditor.text = currentStatusLabel.text;
    statusEditor.hidden = NO;
    currentStatusButton.hidden = YES;
    statusType = @"2";
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        lowerWellIcon.alpha = 0.0;
    } completion:^(BOOL finished){
        
    }];
    
    if ( statusEditor.text.length > 0 )
    {
        doneButton.enabled = YES;
    }
    else
    {
        doneButton.enabled = NO;
    }
    
    [statusEditor becomeFirstResponder];
}

- (void)setStatus:(NSMutableDictionary *)statusData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSString *statusID = [statusData objectForKey:@"thread_id"];
    
    if ( [[statusData objectForKey:@"media_extra"] isKindOfClass:NSDictionary.class] )
    {
        NSData *mediaExtraData = [NSJSONSerialization dataWithJSONObject:[statusData objectForKey:@"media_extra"] options:NSJSONWritingPrettyPrinted error:nil];
        [statusData setObject:mediaExtraData forKey:@"media_extra"];
    }
    
    [appDelegate.modelManager executeUpdate:@"INSERT INTO sh_thread "
                                            @"(thread_id, thread_type, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                                            @"VALUES (:thread_id, :thread_type, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent,  :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                    withParameterDictionary:statusData];
    
    [appDelegate.modelManager executeUpdate:@"UPDATE sh_cloud SET last_status_id = :thread_id WHERE sh_user_id = :current_user_id"
                    withParameterDictionary:@{@"thread_id": statusID,
                                              @"current_user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
    
    [appDelegate.modelManager executeUpdate:@"UPDATE sh_current_user SET last_status_id = :thread_id"
                    withParameterDictionary:@{@"thread_id": statusID}];
    
    [appDelegate.currentUser setObject:statusID forKey:@"last_status_id"];
}

- (void)addToTemplates
{
    
}

- (void)postStatus
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    // The done button also acts as an exit from table editing.
    if ( statusList.editing )
    {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = doneButton;
        
        [self showLowerWell];
        [statusList setEditing:NO animated:YES];
        [statusList reloadData];
    }
    else if ( status || keyboardIsShown )
    {
        [appDelegate.strobeLight activateStrobeLight];
        
        doneButton.enabled = NO;
        cancelButton.enabled = NO;
        statusEditor.editable = NO;
        [statusEditor resignFirstResponder];
        
        status = [status stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ( currentVenue && status.length == 0 )
        {
            status = [NSString stringWithFormat:@"📍 at %@.", [currentVenue objectForKey:@"name"]];
        }
        else if ( currentVenue )
        {
            status = [NSString stringWithFormat:@"📍 %@ - at %@.", status, [currentVenue objectForKey:@"name"]];
        }
        
        // Now, make sure the new status is not identical to the old one (client side).
        if ( !currentVenue && [currentStatusLabel.text isEqualToString:status] )
        {
            [self dismissView];
            
            return;
        }
        
        // Show the HUD.
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        
        HUD.customView = [[UIImageView alloc] init];
        HUD.mode = MBProgressHUDModeIndeterminate;
        HUD.dimBackground = YES;
        HUD.delegate = self;
        [HUD show:YES];
        
        NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[status,
                                                                                        statusType]
                                                                              forKeys:@[@"status",
                                                                                        @"status_type"]];
        
        NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
        
        NSDictionary *parameters = @{@"request": jsonString,
                                     @"scope": appDelegate.SHTokenID};
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/updatestatus", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSString *response = operation.responseString;
            
            if ( [response hasPrefix:@"while(1);"] )
            {
                response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
            }
            
            response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
            NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
            
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            if ( errorCode == 0 )
            {
                NSMutableDictionary *statusData = [[responseData objectForKey:@"response"] mutableCopy];
                [statusData setObject:@"1" forKey:@"entry_type"];
                [statusData setObject:@"-1" forKey:@"media_local_path"];
                [statusData setObject:@"-1" forKey:@"media_data"];
                
                [appDelegate.messageManager dispatchStatus:statusData];
                [self setStatus:statusData];
                [appDelegate.mainMenu refreshMiniFeed]; // Refresh the feed.
                
                if ( appDelegate.activeWindow == SHAppWindowTypeMessages )
                {
                    [appDelegate.mainMenu.messagesView receivedStatusUpdate:statusData fresh:YES];
                }
                
                currentVenue = nil; // If this was a checkin, nil this ivar or the view won't dismiss.
                [self dismissView];
                
                [HUD hide:YES];
                [appDelegate.strobeLight deactivateStrobeLight];
            }
            else if ( errorCode == 500 ) // Dupe.
            {
                [HUD hide:YES];
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"ALERT_DUPLICATE_STATUS", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil) otherButtonTitles:nil];
                
                [alert show];
                [appDelegate.strobeLight negativeStrobeLight];
            }
            
            statusEditor.editable = YES;
            status = nil;
            
            NSLog(@"Response: %@", responseData);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self showNetworkError];
            
            NSLog(@"Error: %@", operation.responseString);
        }];
    }
    else
    {
        [self dismissView];
    }
}

- (void)showLocationPicker
{
    SHLocationPicker *locationPicker = [[SHLocationPicker alloc] init];
    locationPicker.requiresSpecificVenue = YES;
    locationPicker.delegate = self;
    
    SHOrientationNavigationController *navigationController = [[SHOrientationNavigationController alloc] initWithRootViewController:locationPicker];
    navigationController.autoRotates = NO;
    
    [self presentViewController:navigationController animated:YES completion:nil];
    
    locationPicker = nil;
    navigationController = nil;
}

#pragma mark -
#pragma mark Gestures

- (void)userDidTapAndHoldRow:(UILongPressGestureRecognizer *)longPress
{
    if ( longPress.state == UIGestureRecognizerStateBegan )
    {
        // Enter editing mode.
        if ( !statusList.editing )
        {
            self.navigationItem.leftBarButtonItem = doneButton;
            self.navigationItem.rightBarButtonItem = nil;
            doneButton.enabled = YES;
            
            [self hideLowerWell];
            [statusList setEditing:YES animated:YES];
        }
    }
}

- (void)userDidTapAndHoldStatusButton:(UILongPressGestureRecognizer *)longPress
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    panCoordinate = [longPress locationInView:self.view];
    
    if ( longPress.state == UIGestureRecognizerStateBegan )
    {
        statusTemplateHelpLabel.hidden = NO;
        lowerWellShadowCopy.hidden = NO;
        statusListOverlay.hidden = NO;
        statusLabelShadow.text = currentStatusLabel.text;
        
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            lowerWellShadowCopy.alpha = 0.5;
            currentStatusLabel.transform = CGAffineTransformMakeScale(0.7, 0.7);
        } completion:^(BOOL finished){
            
        }];
    }
    else if ( longPress.state == UIGestureRecognizerStateChanged )
    {
        lowerWellShadowCopy.frame = CGRectMake(lowerWellShadowCopy.frame.origin.x, panCoordinate.y - 40, lowerWellShadowCopy.frame.size.width, lowerWellShadowCopy.frame.size.height);
        
        if ( panCoordinate.y - 40 >= screenBounds.size.height - 64 - lowerWell.frame.size.height && lowerWell.alpha != 1.0 ) // Indicate to the user that this cancels the action.
        {
            [self showLowerWell];
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                statusListOverlay.frame = statusList.frame;
                statusListOverlay.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.0];
                currentStatusLabel.transform = CGAffineTransformIdentity;
                statusTemplateHelpLabel.alpha = 0.0;
                lowerWell.alpha = 1.0;
                lowerWellShadowCopy.alpha = 0.5;
            } completion:^(BOOL finished){
                statusTemplateHelpLabel.hidden = YES;
            }];
        } else if ( panCoordinate.y - 40 < screenBounds.size.height - 64 - lowerWell.frame.size.height && lowerWell.alpha != 0.4 )
        {
            statusTemplateHelpLabel.hidden = NO;
            
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                lowerWell.frame = CGRectMake(lowerWell.frame.origin.x, screenBounds.size.height - (lowerWell.frame.size.height / 2), lowerWell.frame.size.width, lowerWell.frame.size.height);
                statusList.frame = CGRectMake(statusList.frame.origin.x, 0, statusList.frame.size.width, statusList.frame.size.height + (screenBounds.size.height - lowerWell.frame.origin.y));
                statusListOverlay.frame = statusList.frame;
                statusListOverlay.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];
                lowerWellShadowCopy.transform = CGAffineTransformMakeScale(1.4, 1.4);
                statusTemplateHelpLabel.alpha = 1.0;
                lowerWell.alpha = 0.4;
                lowerWellShadowCopy.alpha = 0.8;
            } completion:^(BOOL finished){
                
            }];
        }
    }
    else if ( longPress.state == UIGestureRecognizerStateEnded )
    {
        [self showLowerWell];
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            statusListOverlay.frame = statusList.frame;
            statusListOverlay.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.0];
            statusTemplateHelpLabel.alpha = 0.0;
            currentStatusLabel.transform = CGAffineTransformIdentity;
            lowerWell.alpha = 1.0;
            lowerWellShadowCopy.alpha = 0.0;
        } completion:^(BOOL finished){
            lowerWellShadowCopy.frame = lowerWell.frame;
            statusTemplateHelpLabel.hidden = YES;
            lowerWellShadowCopy.hidden = YES;
            statusListOverlay.hidden = YES;
        }];
        
        if ( panCoordinate.y - 40 < screenBounds.size.height - 64 - lowerWell.frame.size.height && panCoordinate.y - 40 > 64 )
        {
            for ( int i = 0; i < statusListEntries.count; i++ ) // Check if the new template already exists.
            {
                NSString *targetStatus = [statusListEntries objectAtIndex:i];
                
                if ( [targetStatus isEqualToString:currentStatusLabel.text] )
                {
                    [statusList scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                    
                    return;
                }
            }
            
            // Template is new. Add it.
            [statusList beginUpdates];
            
            [statusListEntries insertObject:currentStatusLabel.text atIndex:0];
            [statusList insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            
            [statusList endUpdates];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
                [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    [db executeUpdate:@"DELETE FROM sh_status_template "
                            withParameterDictionary:nil];
                    
                    for ( int i = 0; i < statusListEntries.count - 2; i++ ) // Don't include the last 2 entries!
                    {
                        NSString *statusTemplate = [statusListEntries objectAtIndex:i];
                        
                        NSDictionary *argsDict_statusTemplate = [NSDictionary dictionaryWithObjectsAndKeys:statusTemplate, @"status",
                                                                 [NSNumber numberWithInt:i], @"status_index", nil];
                        
                        [db executeUpdate:@"INSERT INTO sh_status_template "
                                            @"(status, status_index) "
                                            @"VALUES (:status, :status_index)"
                                withParameterDictionary:argsDict_statusTemplate];
                    }
                }];
            });
        }
    }
}

- (void)showNetworkError
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight negativeStrobeLight];
    [HUD hide:YES];
    
    // We need a slight delay here.
    long double delayInSeconds = 0.45;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        
        HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cross_white"]];
        
        // Set custom view mode.
        HUD.mode = MBProgressHUDModeCustomView;
        HUD.dimBackground = YES;
        HUD.delegate = self;
        HUD.labelText = NSLocalizedString(@"GENERIC_HUD_NETWORK_ERROR", nil);
        
        [HUD show:YES];
        [HUD hide:YES afterDelay:3];
    });
}

#pragma mark -
#pragma mark UITableViewDataSource methods.

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return statusListEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"ListCell";
    listCell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    UILabel *statusLabel;
    UIImageView *separatorLine;
    
    if ( listCell == nil )
    {
        listCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        listCell.backgroundColor = [UIColor clearColor];
        listCell.frame = CGRectZero;
        listCell.contentView.opaque = YES;
        
        if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
        {
            listCell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        
        statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 260, 28)];
        statusLabel.backgroundColor = [UIColor clearColor];
        statusLabel.textColor = [UIColor blackColor];
        statusLabel.textAlignment = NSTextAlignmentLeft;
        statusLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:25];
        statusLabel.numberOfLines = 1;
        statusLabel.opaque = YES;
        statusLabel.tag = 7;
        
        separatorLine = [[UIImageView alloc] initWithFrame:CGRectMake(20, 0, tableView.frame.size.width - 20, 0.5)];
        separatorLine.image = [[UIImage imageNamed:@"separator_gray"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
        separatorLine.opaque = YES;
        separatorLine.tag = 8;
        separatorLine.hidden = YES;
        
        UILongPressGestureRecognizer *gesture_longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapAndHoldRow:)];
        [listCell addGestureRecognizer:gesture_longPress];
        
        [listCell addSubview:statusLabel]; // Don't add it to the content view, so it doesn't shift when entering table editing mode.
        [listCell addSubview:separatorLine];
    }
    
    statusLabel = (UILabel *)[listCell viewWithTag:7];
    statusLabel.text = [statusListEntries objectAtIndex:indexPath.row];
    
    separatorLine = (UIImageView *)[listCell viewWithTag:8];
    
    if ( indexPath.row == statusListEntries.count - 2 )
    {
        separatorLine.hidden = NO;
    }
    else
    {
        separatorLine.hidden = YES;
    }
    
    listCell.editing = NO; // This fixes a random iOS 8 bug.
    
    return listCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 68;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.row == statusListEntries.count - 1 ) // Current location.
    {
        statusType = @"3";
        
        [self showLocationPicker];
    }
    else if ( indexPath.row == statusListEntries.count - 2 ) // Current song.
    {
        MPMediaItem *song = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem];
        
        if ( song )
        {
            NSString *title   = [song valueForProperty:MPMediaItemPropertyTitle];
            NSString *artist  = [song valueForProperty:MPMediaItemPropertyArtist];
            
            if ( artist )
            {
                status = [NSString stringWithFormat:@"🎧 listening to \"%@\" by %@.", title, artist];
            }
            else
            {
                status = [NSString stringWithFormat:@"🎧 listening to \"%@\".", title];
            }
            
            statusType = @"4";
            
            [self postStatus];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"ALERT_NO_SONG", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil) otherButtonTitles:nil];
            [alert show];
        }
    }
    else // Custom text.
    {
        status = [statusListEntries objectAtIndex:indexPath.row];
        statusType = @"2";
        
        [self postStatus];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( tableView.editing && indexPath.row < statusListEntries.count - 2 )
    {
        return YES;
    }
    
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (proposedDestinationIndexPath.row >= statusListEntries.count - 2) // The last 2 rows are fixed at the bottom.
    {
        return [NSIndexPath indexPathForRow:statusListEntries.count - 3 inSection:0];
    }
    
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( statusList.editing && sourceIndexPath.row < statusListEntries.count - 2 )
    {
        NSString *status_oldPosition = [statusListEntries objectAtIndex:sourceIndexPath.row];
        
        [statusListEntries removeObjectAtIndex:sourceIndexPath.row];
        [statusListEntries insertObject:status_oldPosition atIndex:destinationIndexPath.row];
        
        // Ended up re-insterting all the entries to get their indexes right. :/
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
            [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                [db executeUpdate:@"DELETE FROM sh_status_template "
                    withParameterDictionary:nil];
                
                for ( int i = 0; i < statusListEntries.count - 2; i++ ) // Don't include the last 2 entries!
                {
                    NSString *statusTemplate = [statusListEntries objectAtIndex:i];
                    
                    NSDictionary *argsDict_statusTemplate = [NSDictionary dictionaryWithObjectsAndKeys:statusTemplate, @"status",
                                                             [NSNumber numberWithInt:i], @"status_index", nil];
                    
                    [db executeUpdate:@"INSERT INTO sh_status_template "
                                        @"(status, status_index) "
                                        @"VALUES (:status, :status_index)"
                        withParameterDictionary:argsDict_statusTemplate];
                }
            }];
        });
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( tableView.editing || indexPath.row >= statusListEntries.count - 2 )
    {
        return UITableViewCellEditingStyleNone;
    }
    
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( editingStyle == UITableViewCellEditingStyleDelete )
    {
        // Remove the row here.
        [statusListEntries removeObjectAtIndex:indexPath.row];
        
        // Animate the deletion.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [appDelegate.modelManager executeUpdate:@"DELETE FROM sh_status_template "
         @"WHERE status_index = :status_index"
                        withParameterDictionary:@{@"status_index": [NSNumber numberWithLong:indexPath.row]}];
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    NSString *editorText = statusEditor.text;
    editorText = [editorText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    CGSize statusEditorTextSize = [editorText sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:25] constrainedToSize:CGSizeMake(280, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    CGSize currentLocationTextSize = [currentLocationLabel.text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:25] constrainedToSize:CGSizeMake(280, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    
    currentLocationLabel.firstLineIndent = statusEditorTextSize.width + 15;
    currentLocationLabel.text = currentLocationLabel.text; // Set the text again after setting the indent! Weird behavior of TTTAttributedLabel...
    
    if ( !(IS_IOS7) )
    {
        currentLocationLabel.frame = CGRectMake(20, 30 + fabs(MAX(29.5, statusEditorTextSize.height) - 29.5), 280, currentLocationTextSize.height + currentLocationLabel.firstLineIndent);
    }
    else
    {
        currentLocationLabel.frame = CGRectMake(20, 20 + fabs(MAX(29.5, statusEditorTextSize.height) - 29.5), 280, currentLocationTextSize.height + currentLocationLabel.firstLineIndent);
    }
    
    if ( editorText.length > 0 )
    {
        doneButton.enabled = YES;
    }
    else
    {
        doneButton.enabled = NO;
    }
    
    if ( editorText.length >= MAX_STATUS_UPDATE_LENGTH - 20 )
    {
        characterCounter.hidden = NO;
        
        if ( editorText.length > MAX_STATUS_UPDATE_LENGTH )
        {
            characterCounter.textColor = [UIColor redColor];
        }
        else
        {
            characterCounter.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
        }
    }
    else
    {
        characterCounter.hidden = YES;
    }
    
    characterCounter.text = [NSString stringWithFormat:@"%d", MAX_STATUS_UPDATE_LENGTH - (int)editorText.length];
}

#pragma mark -
#pragma mark UITextViewDelegate methods

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ( [text isEqualToString:@"\n"] )
    {
        NSString *editorText = statusEditor.text;
        editorText = [editorText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        status = editorText;
        [self postStatus];
        return NO;
    }
    
    return YES;
}

#pragma mark -
#pragma mark SHLocationPickerDelegate methods

- (void)locationPickerDidCancel
{
    /*
     *  Since we don't remove the keyboard notification,
     *  the search box keyboard in the picker might
     *  fuck with the keyboard notifications in this view.
     */
    keyboardIsShown = NO;
    status = nil;
}

- (void)locationPickerDidPickVenue:(NSDictionary *)venue
{
    currentVenue = venue;
    
    currentLocationLabel.text = [NSString stringWithFormat:@"- at %@", [venue objectForKey:@"name"]];
    status = [NSString stringWithFormat:@"at %@", [venue objectForKey:@"name"]];
    
    CGSize statusEditorTextSize = [statusEditor.text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:25] constrainedToSize:CGSizeMake(280, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    CGSize currentLocationTextSize = [currentLocationLabel.text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:25] constrainedToSize:CGSizeMake(280, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    
    self.navigationItem.rightBarButtonItem = doneButton;
    statusEditor.hidden = NO;
    currentStatusButton.hidden = YES;
    
    currentLocationLabel.firstLineIndent = statusEditorTextSize.width + 15;
    currentLocationLabel.text = [NSString stringWithFormat:@"- at %@", [venue objectForKey:@"name"]]; // Set the text again after setting the indent! Weird behavior of TTTAttributedLabel...
    currentLocationLabel.hidden = NO;
    
    if ( !(IS_IOS7) )
    {
        currentLocationLabel.frame = CGRectMake(20, 30, 280, currentLocationTextSize.height + currentLocationLabel.firstLineIndent);
    }
    else
    {
        currentLocationLabel.frame = CGRectMake(20, 20, 280, currentLocationTextSize.height + currentLocationLabel.firstLineIndent);
    }
    
    [statusEditor becomeFirstResponder];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods.

- (void)hudWasHidden:(MBProgressHUD *)hud
{
	// Remove HUD from screen when the HUD was hidden.
	[HUD removeFromSuperview];
	HUD = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
