//
//  SHBoardPostViewController.m
//  Nightboard
//
//  Created by Ali.cpp on 3/17/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import "SHBoardPostViewController.h"

#import "NSString+Utils.h"

#import "AFHTTPRequestOperationManager.h"
#import "AppDelegate.h"
#import "SHBoardViewController.h"
#import "SHSearchViewController.h"

@implementation SHBoardPostViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        isPostOwner = NO;
        inEditingMode = NO;
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor whiteColor];
    
    lowerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44)];
    
    mainScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - 44)];
    mainScrollView.opaque = YES;
    mainScrollView.delegate = self;
    
    composer = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 100) textContainer:nil];
    composer.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
    composer.textColor = [UIColor blackColor];
    composer.font = [UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE];
    composer.keyboardType = UIKeyboardTypeTwitter;
    composer.delegate = self;
    composer.hidden = YES;
    
    editButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"GENERIC_EDIT", nil) style:UIBarButtonItemStylePlain target:self action:@selector(enterEditingMode)];
    
    deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(confirmDelete)];
    shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showSharingOptions)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    lowerToolbar.items = @[deleteButton, flexibleItem, shareButton];
    
    postLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(40, 40, appDelegate.screenBounds.size.width - 80, 0)];
    postLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE];
    postLabel.linkAttributes = @{(id)kCTFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:MAIN_FONT_SIZE]};
    postLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
    postLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    postLabel.numberOfLines = 0;
    postLabel.delegate = self;
    
    timestampLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    timestampLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:MIN_MAIN_FONT_SIZE];
    timestampLabel.textColor = [UIColor grayColor];
    timestampLabel.opaque = YES;
    
    viewsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    viewsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:MIN_MAIN_FONT_SIZE];
    viewsLabel.textColor = [UIColor grayColor];
    viewsLabel.opaque = YES;
    
    if ( !(IS_IOS7) )
    {
        lowerToolbar.frame =CGRectMake(0, appDelegate.screenBounds.size.height - 108, appDelegate.screenBounds.size.width, 44);
    }
    
    [mainScrollView addSubview:postLabel];
    [mainScrollView addSubview:timestampLabel];
    [mainScrollView addSubview:viewsLabel];
    [mainScrollView addSubview:composer];
    [contentView addSubview:mainScrollView];
    [contentView addSubview:lowerToolbar];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ( _boardName )
    {
        [self setTitle:_boardName];
    }
    else
    {
        [self setTitle:NSLocalizedString(@"BOARD_POST_TITLE", nil)];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDictionary *info = [notification userInfo];
    keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    composer.frame = CGRectMake(composer.frame.origin.x, composer.frame.origin.y, composer.frame.size.width, appDelegate.screenBounds.size.height - keyboardSize.height);
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    composer.frame = CGRectMake(composer.frame.origin.x, composer.frame.origin.y, composer.frame.size.width, appDelegate.screenBounds.size.height - 64);
}

- (void)setPost:(NSMutableDictionary *)post
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    postData = post;
    _postID = [post objectForKey:@"post_id"];
    BOOL viewed = [[post objectForKey:@"viewed"] boolValue];
    int ownerID = [[post objectForKey:@"owner_id"] intValue];
    
    if ( ownerID != [[appDelegate.currentUser objectForKey:@"user_id"] intValue] )
    {
        isPostOwner = NO;
    }
    else
    {
        isPostOwner = YES;
    }
    
    if ( !isPostOwner && !viewed )
    {
        [self recordView];
    }
    
    [self redrawView];
}

- (void)redrawView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    postColor = [[postData objectForKey:@"color"] intValue];
    int viewCount = [[postData objectForKey:@"view_count"] intValue];
    
    self.view.backgroundColor = [appDelegate colorForCode:postColor];
    composer.backgroundColor = [appDelegate colorForCode:postColor];
    
    // Display the timestamp.
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    
    NSDate *timestampDate = [dateFormatter dateFromString:[postData objectForKey:@"timestamp"]];
    
    // Pretty format the view count.
    NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSString *viewCountFormatted = [numberFormatter stringFromNumber:[NSNumber numberWithInt:viewCount]];
    
    postLabel.text = [postData objectForKey:@"text"];
    timestampLabel.text = [[NSString stringWithFormat:@"%@.", [appDelegate relativeTimefromDate:timestampDate shortened:NO condensed:NO]] uppercaseString];
    viewsLabel.text = [[NSString stringWithFormat:@"%@ view%@.", viewCountFormatted, (viewCount != 1 ? @"s" : @"")] uppercaseString];
    
    // Create links out of the hashtags.
    NSRegularExpression *hashtagRegex = [NSRegularExpression regularExpressionWithPattern:@"(?<=\\s|^)#(\\w*[A-Za-z_]+\\w*)" options:0 error:NULL];
    NSArray *allTags = [hashtagRegex matchesInString:postLabel.text options:0 range:NSMakeRange(0, [[postData objectForKey:@"text"] length])];
    
    for ( NSTextCheckingResult *match in allTags )
    {
        int captureIndex;
        
        for ( captureIndex = 1; captureIndex < match.numberOfRanges; captureIndex++ )
        {
            [postLabel addLinkToURL:[NSURL URLWithString:[postLabel.text substringWithRange:[match rangeAtIndex:captureIndex]]]
                          withRange:[match rangeAtIndex:1]];
        }
    }
    
    if ( isPostOwner )
    {
        self.navigationItem.rightBarButtonItem = editButton;
        
        deleteButton.enabled = YES;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = nil;
        
        deleteButton.enabled = NO;
    }
    
    // Setting frames.
    CGSize textSize = [postLabel.text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE]
                                 constrainedToSize:CGSizeMake(postLabel.frame.size.width, CGFLOAT_MAX)
                                     lineBreakMode:NSLineBreakByWordWrapping];
    CGSize timestampSize = [timestampLabel.text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:MIN_MAIN_FONT_SIZE]
                                           constrainedToSize:CGSizeMake(200, CGFLOAT_MAX)
                                               lineBreakMode:NSLineBreakByWordWrapping];
    CGSize viewsSize = [viewsLabel.text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:MIN_MAIN_FONT_SIZE]
                                   constrainedToSize:CGSizeMake(250, CGFLOAT_MAX)
                                       lineBreakMode:NSLineBreakByWordWrapping];
    
    postLabel.frame = CGRectMake(postLabel.frame.origin.x, postLabel.frame.origin.y, postLabel.frame.size.width, textSize.height + 40);
    timestampLabel.frame = CGRectMake(40, postLabel.frame.origin.y + postLabel.frame.size.height, timestampSize.width, timestampSize.height);
    viewsLabel.frame = CGRectMake(appDelegate.screenBounds.size.width - viewsSize.width - 40, postLabel.frame.origin.y + postLabel.frame.size.height, viewsSize.width, viewsSize.height);
    
    if ( !(IS_IOS7) )
    {
        mainScrollView.contentSize = CGSizeMake(mainScrollView.frame.size.width, MAX(appDelegate.screenBounds.size.height - 43, postLabel.frame.size.height + viewsSize.height + 80));
    }
    else
    {
        mainScrollView.contentSize = CGSizeMake(mainScrollView.frame.size.width, MAX(appDelegate.screenBounds.size.height - 107, postLabel.frame.size.height + viewsSize.height + 80));
    }
}

- (void)showSharingOptions
{
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[[postData objectForKey:@"text"]] applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}

- (void)enterEditingMode
{
    inEditingMode = YES;
    editButton.action = @selector(saveEdits);
    editButton.title = NSLocalizedString(@"GENERIC_DONE", nil);
    editButton.style = UIBarButtonItemStyleDone;
    
    composer.text = postLabel.text;
    composer.hidden = NO;
    [composer becomeFirstResponder];
}

- (void)exitEditingMode
{
    composer.hidden = YES;
    
    [postData setObject:composer.text forKey:@"text"];
    postLabel.text = composer.text;
    
    inEditingMode = NO;
    editButton.action = @selector(enterEditingMode);
    editButton.title = NSLocalizedString(@"GENERIC_EDIT", nil);
    editButton.style = UIBarButtonItemStylePlain;
    
    [self redrawView];
}

- (void)decideOnEnablingDoneButton
{
    NSString *post = composer.text;
    
    post = [post stringByTrimmingLeadingWhitespace];
    
    if ( post.length > 0 )
    {
        editButton.enabled = YES;
    }
    else
    {
        editButton.enabled = NO;
    }
}

- (void)saveEdits
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSString *post = composer.text;
    
    if ( post.length > MAX_POST_LENGTH )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"BOARD_POST_COMPOSER_LENGTH_ERROR_TITLE", nil)
                                                        message:NSLocalizedString(@"BOARD_POST_COMPOSER_LENGTH_ERROR", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"GENERIC_BACK", nil)
                                              otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    
    [appDelegate.strobeLight activateStrobeLight];
    [composer resignFirstResponder];
    editButton.enabled = NO;
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[_postID,
                                                                                    post]
                                                                          forKeys:@[@"post_id",
                                                                                    @"text"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/editboardpost", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        if ( responseData )
        {
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            if ( errorCode == 0 )
            {
                NSArray *viewControllers = self.navigationController.viewControllers;
                id sender = [viewControllers objectAtIndex:0];
                
                if ( [sender isKindOfClass:[SHBoardViewController class]] )
                {
                    SHBoardViewController *senderView = (SHBoardViewController *)sender;
                    
                    [senderView loadBoardBatch:0];
                }
                else
                {
                    SHSearchViewController *senderView = (SHSearchViewController *)sender;
                    
                    [senderView searchForQuery:senderView.currentQuery];
                }
                
                editButton.enabled = YES;
                [appDelegate.strobeLight affirmativeStrobeLight];
                [self exitEditingMode];
            }
            else
            {
                [appDelegate.strobeLight negativeStrobeLight];
                [composer becomeFirstResponder];
                editButton.enabled = YES;
            }
        }
        else
        {
            [appDelegate.strobeLight negativeStrobeLight];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [appDelegate.strobeLight negativeStrobeLight];
        [composer becomeFirstResponder];
        editButton.enabled = YES;
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)deletePost
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight activateStrobeLight];
    deleteButton.enabled = NO;
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[_postID]
                                                                          forKeys:@[@"post_id"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/deleteboardpost", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        if ( responseData )
        {
            NSArray *viewControllers = self.navigationController.viewControllers;
            id sender = [viewControllers objectAtIndex:0];
            
            if ( [sender isKindOfClass:[SHBoardViewController class]] )
            {
                SHBoardViewController *senderView = (SHBoardViewController *)sender;
                
                [senderView loadBoardBatch:0];
            }
            else
            {
                SHSearchViewController *senderView = (SHSearchViewController *)sender;
                
                [senderView searchForQuery:senderView.currentQuery];
            }
            
            [appDelegate.strobeLight deactivateStrobeLight];
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            [appDelegate.strobeLight negativeStrobeLight];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [appDelegate.strobeLight negativeStrobeLight];
        deleteButton.enabled = YES;
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)confirmDelete
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"BOARD_POST_DELETE_CONFIRMATION", nil)
                                              delegate:self
                                     cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                destructiveButtonTitle:NSLocalizedString(@"GENERIC_DELETE", nil)
                                     otherButtonTitles:nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.tag = 2;
    [actionSheet showFromRect:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44) inView:self.view animated:YES];
}

- (void)recordView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[_postID]
                                                                          forKeys:@[@"post_id"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/recordboardpostview", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        if ( responseData )
        {
            NSArray *viewControllers = self.navigationController.viewControllers;
            id sender = [viewControllers objectAtIndex:0];
            
            if ( [sender isKindOfClass:[SHBoardViewController class]] )
            {
                SHBoardViewController *senderView = (SHBoardViewController *)sender;
                
                [senderView markPostAsViewed:_postID];
            }
            else
            {
                SHSearchViewController *senderView = (SHSearchViewController *)sender;
                
                [senderView markPostAsViewed:_postID];
            }
        }
        
        //NSLog(@"Response: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

#pragma mark -
#pragma mark TTTAttributedLabelDelegate methods

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if ( (url && url.scheme && url.host) || [url.absoluteString hasPrefix:@"mailto:"] )
    {
        [[UIApplication sharedApplication] openURL:url];
    }
    else
    {
        NSArray *viewControllers = self.navigationController.viewControllers;
        id sender = [viewControllers objectAtIndex:0];
        
        [self.navigationController popViewControllerAnimated:YES];
        
        if ( [sender isKindOfClass:[SHBoardViewController class]] )
        {
            SHBoardViewController *senderView = (SHBoardViewController *)sender;
            
            // We need a slight delay here till the view pop animation completes.
            long double delayInSeconds = 0.2;
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [senderView presentSearchWithQuery:url.absoluteString];
            });
        }
        else
        {
            SHSearchViewController *senderView = (SHSearchViewController *)sender;
            
            [senderView searchForQuery:url.absoluteString];
        }
    }
}

- (void)attributedLabel:(TTTAttributedLabel *)label didLongPressLinkWithURL:(NSURL *)url atPoint:(CGPoint)point
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    activeLink = url.absoluteString;
    UIActionSheet *actionSheet;
    
    if ( (url && url.scheme && url.host) || [url.absoluteString hasPrefix:@"mailto:"] )
    {
        actionSheet = [[UIActionSheet alloc] initWithTitle:activeLink
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:@"Copy", nil];
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        actionSheet.tag = 0;
    }
    else
    {
        
        
        actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"#%@", activeLink]
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:@"Add to Favorites", nil];
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        actionSheet.tag = 1;
    }
    
    [actionSheet showFromRect:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44) inView:self.view animated:YES];
}

#pragma mark -
#pragma mark UITextViewDelegate methods

- (void)textViewDidChange:(UITextView *)textView
{
    [self decideOnEnablingDoneButton];
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( actionSheet.tag == 0 ) // Link options.
    {
        if ( buttonIndex == 0 )      // Copy
        {
            [[UIPasteboard generalPasteboard] setString:activeLink];
        }
    }
    else if ( actionSheet.tag == 1 ) // Hashtag options.
    {
        if ( buttonIndex == 0 )      // Add to Faves
        {
            /*SHHashtagListViewController *hashtagListView = [[SHHashtagListViewController alloc] init];
            [hashtagListView addItemInBackground:activeLink];*/
        }
    }
    else if ( actionSheet.tag == 2 ) // Delete post.
    {
        if ( buttonIndex == 0 )      // Add to Faves
        {
            [self deletePost];
        }
    }
    
    activeLink = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
