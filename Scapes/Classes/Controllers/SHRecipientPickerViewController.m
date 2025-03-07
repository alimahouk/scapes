//
//  SHRecipientPickerViewController.m
//  Nightboard
//
//  Created by MachOSX on 11/18/13.
//
//

#import "SHRecipientPickerViewController.h"

@implementation SHRecipientPickerViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        wallpaperIsAnimating = NO;
        wallpaperShouldAnimate = YES;
        wallpaperIsAnimatingRight = NO;
        wallpaperDidChange_dawn = NO;
        wallpaperDidChange_day = NO;
        wallpaperDidChange_dusk = NO;
        wallpaperDidChange_night = NO;
        isShowingSearchInterface = NO;
        
        // The defaults.
        _mode = SHRecipientPickerModeRecipients;
        _showsBackButton = YES;
    }
    
    return self;
}

- (id)initInMode:(SHRecipientPickerMode)mode
{
    self = [super init];
    
    if ( self )
    {
        wallpaperShouldAnimate = YES;
        wallpaperIsAnimatingRight = NO;
        wallpaperDidChange_dawn = NO;
        wallpaperDidChange_day = NO;
        wallpaperDidChange_dusk = NO;
        wallpaperDidChange_night = NO;
        isShowingSearchInterface = NO;
        
        _mode = mode;
        _showsBackButton = YES;
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor blackColor];
    contentView.clipsToBounds = YES;
    
    _wallpaper = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 750, 568)];
    _wallpaper.backgroundColor = [UIColor blackColor];
    _wallpaper.opaque = YES;
    
    dismissViewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [dismissViewButton addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchUpInside];
    
    if ( _showsBackButton )
    {
        [dismissViewButton setImage:[UIImage imageNamed:@"back_white"] forState:UIControlStateNormal];
        dismissViewButton.frame = CGRectMake(10, 10, 32, 32);
    }
    else
    {
        [dismissViewButton setBackgroundImage:[[UIImage imageNamed:@"button_rect_bg_white"] stretchableImageWithLeftCapWidth:16 topCapHeight:16] forState:UIControlStateNormal];
        [dismissViewButton setTitle:NSLocalizedString(@"GENERIC_CANCEL", nil) forState:UIControlStateNormal];
        [dismissViewButton setTitleColor:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0] forState:UIControlStateNormal];
        dismissViewButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13];
        dismissViewButton.frame = CGRectMake(10, 10, 70, 33);
    }
    
    _searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_searchButton setBackgroundImage:[[UIImage imageNamed:@"button_round_white_transparent"] stretchableImageWithLeftCapWidth:17 topCapHeight:17] forState:UIControlStateNormal];
    [_searchButton addTarget:self action:@selector(showSearchInterface) forControlEvents:UIControlEventTouchUpInside];
    _searchButton.frame = CGRectMake(contentView.frame.size.width - 43, 10, 33, 33);
    _searchButton.adjustsImageWhenDisabled = NO;
    _searchButton.showsTouchWhenHighlighted = YES;
    
    _cloudCenterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cloudCenterButton setBackgroundImage:[[UIImage imageNamed:@"button_round_white_transparent"] stretchableImageWithLeftCapWidth:17 topCapHeight:17] forState:UIControlStateNormal];
    [_cloudCenterButton addTarget:self action:@selector(jumpTocontactCloudCenter) forControlEvents:UIControlEventTouchUpInside];
    _cloudCenterButton.frame = CGRectMake(-33, appDelegate.screenBounds.size.height - 43, 33, 33);
    _cloudCenterButton.showsTouchWhenHighlighted = YES;
    _cloudCenterButton.alpha = 0.0;
    _cloudCenterButton.hidden = YES;
    
    searchCancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [searchCancelButton setBackgroundImage:[[UIImage imageNamed:@"button_rect_bg_white"] stretchableImageWithLeftCapWidth:18 topCapHeight:18] forState:UIControlStateNormal];
    [searchCancelButton setTitle:NSLocalizedString(@"GENERIC_CANCEL", nil) forState:UIControlStateNormal];
    [searchCancelButton setTitleColor:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0] forState:UIControlStateNormal];
    [searchCancelButton addTarget:self action:@selector(dismissSearchInterface) forControlEvents:UIControlEventTouchUpInside];
    searchCancelButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13];
    searchCancelButton.frame = CGRectMake(250, 10, 70, 33);
    searchCancelButton.alpha = 0.0;
    searchCancelButton.hidden = YES;
    
    usernamePanel = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    usernamePanel.opaque = YES;
    usernamePanel.hidden = YES;
    
    UIImageView *searchIcon = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 16, 16)];
    searchIcon.image = [UIImage imageNamed:@"search_white"];
    
    UIImageView *contactCloudCenterIcon = [[UIImageView alloc] initWithFrame:CGRectMake(8.5, 8.5, 16, 16)];
    contactCloudCenterIcon.image = [UIImage imageNamed:@"center_white"];
    
    UIImageView *livingRoomIcon = [[UIImageView alloc] initWithFrame:CGRectMake(9, 9, 16, 16)];
    livingRoomIcon.image = [UIImage imageNamed:@"living_room_white"];
    
    UIImageView *settingsIcon = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 51, 16)];
    settingsIcon.image = [UIImage imageNamed:@"settings_1"];
    
    usernameFieldBG = [[UIImageView alloc] initWithFrame:CGRectMake(20, 190, 280, 33)];
    usernameFieldBG.image = [[UIImage imageNamed:@"button_round_white_transparent"] stretchableImageWithLeftCapWidth:17 topCapHeight:17];
    usernameFieldBG.userInteractionEnabled = YES;
    
    searchBox = [[UITextField alloc] initWithFrame:CGRectMake(30, 5, 188, 24)];
    searchBox.textColor  = [UIColor whiteColor];
    searchBox.clearButtonMode = UITextFieldViewModeWhileEditing;
    searchBox.returnKeyType = UIReturnKeyGo;
    searchBox.enablesReturnKeyAutomatically = YES;
    searchBox.alpha = 0.0;
    searchBox.hidden = YES;
    searchBox.tag = 0;
    searchBox.delegate = self;
    
    usernameField = [[UITextField alloc] initWithFrame:CGRectMake(27, 5, usernameFieldBG.frame.size.width - 27, 24)];
    usernameField.textColor  = [UIColor whiteColor];
    usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    usernameField.returnKeyType = UIReturnKeyDone;
    usernameField.enablesReturnKeyAutomatically = YES;
    usernameField.tag = 1;
    usernameField.delegate = self;
    
    _contactCloud = [[SHContactCloud alloc] initWithFrame:appDelegate.screenBounds];
    _contactCloud.delegate = self;
    _contactCloud.scrollsToTop = NO;
    _contactCloud.scrollEnabled = NO;
    _contactCloud.cloudDelegate = self;
    _contactCloud.insertBadgeCounts = NO;
    _contactCloud.tag = 0;
    
    contactCloudInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, _contactCloud.frame.size.height / 2 - 25, 280, 55)];
    contactCloudInfoLabel.backgroundColor = [UIColor clearColor];
    contactCloudInfoLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
    contactCloudInfoLabel.textColor = [UIColor whiteColor];
    contactCloudInfoLabel.textAlignment = NSTextAlignmentCenter;
    contactCloudInfoLabel.text = NSLocalizedString(@"CHAT_CLOUD_LOADING", nil);
    contactCloudInfoLabel.numberOfLines = 0;
    contactCloudInfoLabel.clipsToBounds = NO;
    contactCloudInfoLabel.layer.masksToBounds = NO;
    contactCloudInfoLabel.layer.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
    contactCloudInfoLabel.layer.shadowRadius = 4.0f;
    contactCloudInfoLabel.layer.shadowOpacity = 0.9;
    contactCloudInfoLabel.layer.shadowOffset = CGSizeZero;
    contactCloudInfoLabel.opaque = YES;
    
    atSignLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 15, 24)];
    atSignLabel.backgroundColor = [UIColor clearColor];
    atSignLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:MAIN_FONT_SIZE];
    atSignLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    atSignLabel.text = @"@";
    
    DPPreview = [[SHChatBubble alloc] initWithFrame:CGRectMake(120, 80, CHAT_CLOUD_BUBBLE_SIZE, CHAT_CLOUD_BUBBLE_SIZE) withMiniModeEnabled:NO];
    [DPPreview setImage:[UIImage imageNamed:@"user_placeholder"]];
    DPPreview.enabled = NO;
    
    UIColor *outerColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    UIColor *innerColor = [UIColor colorWithWhite:1.0 alpha:0.0];
    
    // Adding transparency to the top & bottom of the Chat Cloud.
    maskLayer_contactCloud = [CAGradientLayer layer];
    maskLayer_contactCloud.colors = [NSArray arrayWithObjects:(__bridge id)innerColor.CGColor, (__bridge id)outerColor.CGColor, (__bridge id)outerColor.CGColor, (__bridge id)innerColor.CGColor, nil];
    maskLayer_contactCloud.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0],
                                     [NSNumber numberWithFloat:0.2],
                                     [NSNumber numberWithFloat:0.8],
                                     [NSNumber numberWithFloat:1.0], nil];
    
    maskLayer_contactCloud.bounds = CGRectMake(0, 0, _contactCloud.frame.size.width, _contactCloud.frame.size.height);
    maskLayer_contactCloud.position = CGPointMake(_contactCloud.contentOffset.x, _contactCloud.contentOffset.y);
    maskLayer_contactCloud.anchorPoint = CGPointZero;
    _contactCloud.layer.mask = maskLayer_contactCloud;
    
    [usernameFieldBG addSubview:atSignLabel];
    [usernameFieldBG addSubview:usernameField];
    [usernamePanel addSubview:DPPreview];
    [usernamePanel addSubview:usernameFieldBG];
    [_searchButton addSubview:searchIcon];
    [_cloudCenterButton addSubview:contactCloudCenterIcon];
    [_searchButton addSubview:searchBox];
    [contentView addSubview:_wallpaper];
    [contentView addSubview:usernamePanel];
    [contentView addSubview:_contactCloud];
    [contentView addSubview:contactCloudInfoLabel];
    [contentView addSubview:dismissViewButton];
    [contentView addSubview:_searchButton];
    [contentView addSubview:_cloudCenterButton];
    [contentView addSubview:searchCancelButton];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( _mode == SHRecipientPickerModeAddByUsername )
    {
        _contactCloud.hidden = YES;
        _searchButton.hidden = YES;
        contactCloudInfoLabel.hidden = YES;
        usernamePanel.hidden = NO;
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_contactCloud beginUpdates];
            
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
            [queue inDatabase:^(FMDatabase *db) {
                if ( _mode == SHRecipientPickerModeRecipients )
                {
                    _contactCloud.makeRoomForBubbles = NO;
                }
                else
                {
                    FMResultSet *s1;
                    
                    if ( _mode == SHRecipientPickerModeHidden )
                    {
                        s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id <> :current_user_id AND temp = 0 AND hidden = 1"
                                    withParameterDictionary:@{@"current_user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
                    }
                    else if ( _mode == SHRecipientPickerModeBlocked )
                    {
                        s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id <> :current_user_id AND temp = 0 AND hidden = 0 AND blocked = 1"
                                    withParameterDictionary:@{@"current_user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
                    }
                    
                    _contactCloud.makeRoomForBubbles = YES;
                    
                    // Read & store each contact's data.
                    while ( [s1 next] )
                    {
                        NSString *lastViewTimestamp = [s1 stringForColumn:@"last_view_timestamp"];
                        NSString *lastMessageTimestamp = [s1 stringForColumn:@"last_message_timestamp"];
                        NSData *DP = [s1 dataForColumn:@"dp"];
                        
                        if ( !lastViewTimestamp )
                        {
                            lastViewTimestamp = @"";
                        }
                        
                        if ( !lastMessageTimestamp )
                        {
                            lastMessageTimestamp = @"";
                        }
                        
                        if ( !DP )
                        {
                            DP = UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0);
                        }
                        
                        NSMutableDictionary *contactData = [[NSMutableDictionary alloc] initWithObjects:@[[s1 stringForColumn:@"sh_user_id"],
                                                                                                          [s1 stringForColumn:@"temp"],
                                                                                                          [s1 stringForColumn:@"name_first"],
                                                                                                          [s1 stringForColumn:@"name_last"],
                                                                                                          [s1 stringForColumn:@"alias"],
                                                                                                          [s1 stringForColumn:@"user_handle"],
                                                                                                          [s1 stringForColumn:@"blocked"],
                                                                                                          [s1 stringForColumn:@"dp_hash"],
                                                                                                          DP,
                                                                                                          [s1 dataForColumn:@"alias_dp"],
                                                                                                          [s1 stringForColumn:@"email_address"],
                                                                                                          [s1 stringForColumn:@"gender"],
                                                                                                          [s1 stringForColumn:@"birthday"],
                                                                                                          [s1 stringForColumn:@"location_country"],
                                                                                                          [s1 stringForColumn:@"location_state"],
                                                                                                          [s1 stringForColumn:@"location_city"],
                                                                                                          [s1 stringForColumn:@"website"],
                                                                                                          [s1 stringForColumn:@"bio"],
                                                                                                          [s1 stringForColumn:@"join_date"],
                                                                                                          [s1 stringForColumn:@"last_status_id"],
                                                                                                          [s1 stringForColumn:@"total_messages_sent"],
                                                                                                          [s1 stringForColumn:@"total_messages_received"],
                                                                                                          [s1 stringForColumn:@"unread_thread_count"],
                                                                                                          [s1 stringForColumn:@"view_count"],
                                                                                                          lastViewTimestamp,
                                                                                                          lastMessageTimestamp,
                                                                                                          [s1 stringForColumn:@"coordinate_x"],
                                                                                                          [s1 stringForColumn:@"coordinate_y"],
                                                                                                          [s1 stringForColumn:@"rank_score"]]
                                                                                                forKeys:@[@"user_id",
                                                                                                          @"temp",
                                                                                                          @"name_first",
                                                                                                          @"name_last",
                                                                                                          @"alias",
                                                                                                          @"user_handle",
                                                                                                          @"blocked",
                                                                                                          @"dp_hash",
                                                                                                          @"dp",
                                                                                                          @"alias_dp",
                                                                                                          @"email_address",
                                                                                                          @"gender",
                                                                                                          @"birthday",
                                                                                                          @"location_country",
                                                                                                          @"location_state",
                                                                                                          @"location_city",
                                                                                                          @"website",
                                                                                                          @"bio",
                                                                                                          @"join_date",
                                                                                                          @"last_status_id",
                                                                                                          @"total_messages_sent",
                                                                                                          @"total_messages_received",
                                                                                                          @"unread_thread_count",
                                                                                                          @"view_count",
                                                                                                          @"last_view_timestamp",
                                                                                                          @"last_message_timestamp",
                                                                                                          @"coordinate_x",
                                                                                                          @"coordinate_y",
                                                                                                          @"rank_score"]];
                        
                        if ( contactData.count > 0 )
                        {
                            NSString *userID = [contactData objectForKey:@"user_id"];
                            
                            FMResultSet *s2 = [db executeQuery:@"SELECT * FROM sh_user_online_status WHERE user_id = :user_id"
                                       withParameterDictionary:@{@"user_id": userID}];
                            
                            while ( [s2 next] )
                            {
                                NSString *presenceTargetID = [s2 stringForColumn:@"target_id"];
                                NSString *presence = [s2 stringForColumn:@"status"];
                                NSString *audience = [s2 stringForColumn:@"audience"];
                                NSString *presenceTimestamp = [s2 stringForColumn:@"timestamp"];
                                
                                if ( !presence )
                                {
                                    presence = @"";
                                }
                                
                                if ( !presenceTargetID )
                                {
                                    presenceTargetID = @"";
                                }
                                
                                if ( !audience )
                                {
                                    audience = @"";
                                }
                                
                                if ( !presenceTimestamp )
                                {
                                    presenceTimestamp = @"";
                                }
                                
                                [contactData setObject:presence forKey:@"presence"];
                                [contactData setObject:presenceTargetID forKey:@"presence_target"];
                                [contactData setObject:audience forKey:@"audience"];
                                [contactData setObject:presenceTimestamp forKey:@"presence_timestamp"];
                            }
                            
                            [s2 close];
                            
                            s2 = [db executeQuery:@"SELECT * FROM sh_phone_numbers WHERE sh_user_id = :user_id"
                                       withParameterDictionary:@{@"user_id": userID}];
                            
                            while ( [s2 next] )
                            {
                                [contactData setObject:[s2 stringForColumn:@"country_calling_code"] forKey:@"country_calling_code"];
                                [contactData setObject:[s2 stringForColumn:@"prefix"] forKey:@"prefix"];
                                [contactData setObject:[s2 stringForColumn:@"phone_number"] forKey:@"phone_number"];
                            }
                            
                            [s2 close];
                            
                            s2 = [db executeQuery:@"SELECT * FROM sh_thread WHERE thread_id = :last_status_id"
                                        withParameterDictionary:@{@"last_status_id": userID}];
                            
                            while ( [s2 next] )
                            {
                                NSString *entryType = @"1";
                                NSString *threadID = @"";
                                NSString *threadType = @"";
                                NSString *rootItemID = @"";
                                NSString *childCount = @"";
                                NSString *ownerID = @"";
                                NSString *ownerType = @"";
                                NSString *groupID = @"";
                                NSString *unreadMessageCount = @"";
                                NSString *privacy = @"";
                                NSString *status_sent = @"";
                                NSString *status_delivered = @"";
                                NSString *status_read = @"";
                                NSString *timestamp_sent = @"";
                                NSString *timestamp_delivered = @"";
                                NSString *timestamp_read = @"";
                                NSString *message = @"";
                                NSString *longitude = @"";
                                NSString *latitude = @"";
                                NSString *mediaType = @"";
                                NSString *mediaFileSize = @"";
                                NSString *mediaLocalPath = @"";
                                NSString *mediaHash = @"";
                                id mediaData = @"";
                                id mediaExtra = @"";
                                
                                if ( status_sent.intValue == SHThreadStatusSending )
                                {
                                    status_sent = [NSString stringWithFormat:@"%d", SHThreadStatusSendingFailed];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"thread_id"]] )
                                {
                                    threadID = [s2 stringForColumn:@"thread_id"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"thread_type"]] )
                                {
                                    threadType = [s2 stringForColumn:@"thread_type"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"root_item_id"]] )
                                {
                                    rootItemID = [s2 stringForColumn:@"root_item_id"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"child_count"]] )
                                {
                                    childCount = [s2 stringForColumn:@"child_count"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"owner_id"]] )
                                {
                                    ownerID = [s2 stringForColumn:@"owner_id"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"owner_type"]] )
                                {
                                    ownerType = [s2 stringForColumn:@"owner_type"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"group_id"]] )
                                {
                                    groupID = [s2 stringForColumn:@"group_id"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"unread_message_count"]] )
                                {
                                    unreadMessageCount = [s2 stringForColumn:@"unread_message_count"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"privacy"]] )
                                {
                                    privacy = [s2 stringForColumn:@"privacy"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"status_sent"]] )
                                {
                                    status_sent = [s2 stringForColumn:@"status_sent"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"status_delivered"]] )
                                {
                                    status_delivered = [s2 stringForColumn:@"status_delivered"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"status_read"]] )
                                {
                                    status_read = [s2 stringForColumn:@"status_read"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"timestamp_sent"]] )
                                {
                                    timestamp_sent = [s2 stringForColumn:@"timestamp_sent"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"timestamp_delivered"]] )
                                {
                                    timestamp_delivered = [s2 stringForColumn:@"timestamp_delivered"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"timestamp_read"]] )
                                {
                                    timestamp_read = [s2 stringForColumn:@"timestamp_read"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"message"]] )
                                {
                                    message = [s2 stringForColumn:@"message"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"location_longitude"]] )
                                {
                                    longitude = [s2 stringForColumn:@"location_longitude"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"location_latitude"]] )
                                {
                                    latitude = [s2 stringForColumn:@"location_latitude"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"media_type"]] )
                                {
                                    mediaType = [s2 stringForColumn:@"media_type"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"media_file_size"]] )
                                {
                                    mediaFileSize = [s2 stringForColumn:@"media_file_size"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"media_local_path"]] )
                                {
                                    mediaLocalPath = [s2 stringForColumn:@"media_local_path"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 stringForColumn:@"media_hash"]] )
                                {
                                    mediaHash = [s2 stringForColumn:@"media_hash"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 dataForColumn:@"media_data"]] )
                                {
                                    mediaData = [s2 dataForColumn:@"media_data"];
                                }
                                
                                if ( ![[NSNull null] isEqual:[s2 dataForColumn:@"media_extra"]] )
                                {
                                    mediaExtra = [s1 dataForColumn:@"media_extra"];
                                    
                                    NSDictionary *attachmentData = (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:mediaExtra];
                                    mediaExtra = attachmentData;
                                }
                                
                                [contactData setObject:entryType forKey:@"entry_type"];
                                [contactData setObject:threadID forKey:@"thread_id"];
                                [contactData setObject:threadType forKey:@"thread_type"];
                                [contactData setObject:rootItemID forKey:@"root_item_id"];
                                [contactData setObject:childCount forKey:@"child_count"];
                                [contactData setObject:ownerID forKey:@"owner_id"];
                                [contactData setObject:ownerType forKey:@"owner_type"];
                                [contactData setObject:groupID forKey:@"group_id"];
                                [contactData setObject:unreadMessageCount forKey:@"unread_message_count"];
                                [contactData setObject:privacy forKey:@"privacy"];
                                [contactData setObject:status_sent forKey:@"status_sent"];
                                [contactData setObject:status_delivered forKey:@"status_delivered"];
                                [contactData setObject:status_read forKey:@"status_read"];
                                [contactData setObject:timestamp_sent forKey:@"timestamp_sent"];
                                [contactData setObject:timestamp_delivered forKey:@"timestamp_delivered"];
                                [contactData setObject:timestamp_read forKey:@"timestamp_read"];
                                [contactData setObject:message forKey:@"message"];
                                [contactData setObject:longitude forKey:@"location_longitude"];
                                [contactData setObject:latitude forKey:@"location_latitude"];
                                [contactData setObject:mediaType forKey:@"media_type"];
                                [contactData setObject:mediaFileSize forKey:@"media_file_size"];
                                [contactData setObject:mediaLocalPath forKey:@"media_local_path"];
                                [contactData setObject:mediaHash forKey:@"media_hash"];
                                [contactData setObject:mediaData forKey:@"media_data"];
                                [contactData setObject:mediaExtra forKey:@"media_extra"];
                            }
                            
                            [s2 close];
                        }
                        
                        UIImage *currentDP = [UIImage imageWithData:[contactData objectForKey:@"alias_dp"]];
                        
                        if ( !currentDP )
                        {
                            currentDP = [UIImage imageWithData:[contactData objectForKey:@"dp"]];
                            
                            if ( !currentDP )
                            {
                                currentDP = [UIImage imageNamed:@"user_placeholder"];
                            }
                        }
                        
                        // Give it a slight delay here to achieve a nice animation effect.
                        long double delayInSeconds = 1.0;
                        
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            SHChatBubble *bubble = [[SHChatBubble alloc] initWithFrame:CGRectMake(0, 0, CHAT_CLOUD_BUBBLE_SIZE, CHAT_CLOUD_BUBBLE_SIZE) andImage:currentDP withMiniModeEnabled:NO];
                            [bubble setMetadata:contactData];
                            [bubble setBlocked:[[contactData objectForKey:@"blocked"] boolValue]];
                            
                            CGFloat centerOffset_x = (appDelegate.mainMenu.contactCloud.contentSize.width / 2);
                            CGFloat centerOffset_y = (appDelegate.mainMenu.contactCloud.contentSize.height / 2);
                            
                            NSInteger pos_x = arc4random_uniform(20) + centerOffset_x;
                            NSInteger pos_y = arc4random_uniform(20) + centerOffset_y;
                            
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                [_contactCloud insertBubble:bubble atPoint:CGPointMake(pos_x, pos_y) animated:YES];
                            });
                        });
                    }
                    
                    [s1 close]; // Very important that you close this!
                    
                    _contactCloud.makeRoomForBubbles = YES;
                    
                    long double delayInSeconds = 1.2; // Slightly longer than the delay to insert the first bubble.
                    
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        if ( _contactCloud.cloudBubbles.count == 0 )
                        {
                            _contactCloud.scrollEnabled = NO;
                            _searchButton.hidden = YES;
                            
                            contactCloudInfoLabel.hidden = NO;
                            contactCloudInfoLabel.text = NSLocalizedString(@"CHAT_CLOUD_EMPTY", nil);
                        }
                        else
                        {
                            if ( _contactCloud.cloudBubbles.count > 5 )
                            {
                                _searchButton.hidden = NO;
                            }
                            
                            _contactCloud.scrollEnabled = YES;
                            contactCloudInfoLabel.hidden = YES;
                        }
                        
                        [_contactCloud endUpdates];
                        
                        [self setMaxMinZoomScalesForcontactCloudBounds];
                        
                        // Center the cloud's offset.
                        CGFloat centerOffset_x = (appDelegate.mainMenu.contactCloud.contentSize.width / 2) - (appDelegate.mainMenu.contactCloud.bounds.size.width / 2);
                        CGFloat centerOffset_y = (appDelegate.mainMenu.contactCloud.contentSize.height / 2) - (appDelegate.mainMenu.contactCloud.bounds.size.height / 2);
                        [_contactCloud setContentOffset:CGPointMake(centerOffset_x, centerOffset_y) animated:YES];
                    });
                }
            }];
        });
    }
    
    [self checkTimeOfDay];
    [self startWallpaperAnimation];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        timer_timeOfDayCheck = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(checkTimeOfDay) userInfo:nil repeats:YES]; // Run this every 1 minute.
    });
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionFullScreen];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    if ( _mode == SHRecipientPickerModeAddByUsername )
    {
        [usernameField becomeFirstResponder];
    }
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionNavigationBar];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    
    appDelegate.contactManager.delegate = appDelegate.mainMenu;
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    [super viewDidDisappear:animated];
}

- (void)dismissView
{
    [self stopWallpaperAnimation];
    [timer_timeOfDayCheck invalidate];
    timer_timeOfDayCheck = nil;
    
    if ( _showsBackButton )
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark Live Wallpaper

- (void)startWallpaperAnimation
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    // Keep the animation slow & mellow.
    [UIView animateWithDuration:0.05 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        if ( wallpaperIsAnimatingRight )
        {
            if ( _wallpaper.frame.origin.x < 0 )
            {
                _wallpaper.frame = CGRectMake(_wallpaper.frame.origin.x + 1, _wallpaper.frame.origin.y, _wallpaper.frame.size.width, _wallpaper.frame.size.height);
            }
            else
            {
                wallpaperIsAnimatingRight = NO; // Go left now.
            }
        }
        else // Animating left.
        {
            if ( _wallpaper.frame.origin.x > appDelegate.screenBounds.size.width - _wallpaper.frame.size.width )
            {
                _wallpaper.frame = CGRectMake(_wallpaper.frame.origin.x - 1, _wallpaper.frame.origin.y, _wallpaper.frame.size.width, _wallpaper.frame.size.height);
            }
            else
            {
                wallpaperIsAnimatingRight = YES; // Go right now.
            }
        }
    } completion:^(BOOL finished){
        if ( wallpaperShouldAnimate )
        {
            wallpaperIsAnimating = YES;
            
            [self startWallpaperAnimation];
        }
    }];
}

// Call this function only after pausing wallpaper animation, not to start it.
- (void)resumeWallpaperAnimation
{
    if ( !wallpaperIsAnimating )
    {
        wallpaperShouldAnimate = YES;
        wallpaperIsAnimating = YES;
        
        [self startWallpaperAnimation];
    }
}

- (void)stopWallpaperAnimation
{
    wallpaperShouldAnimate = NO;
    wallpaperIsAnimating = NO;
}

#pragma mark -
#pragma mark Check the time of the day to set the wallpaper accordingly.

- (void)checkTimeOfDay
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDate *now = [NSDate date];
    NSDateComponents *components = [appDelegate.calendar components:NSHourCalendarUnit fromDate:now];
    
    if ( components.hour >= 6 && components.hour < 8 && !wallpaperDidChange_dawn )        // Dawn.
    {
        wallpaperImageName = @"wallpaper_dawn_1";
        wallpaperDidChange_dawn = YES;
        wallpaperDidChange_night = NO;
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                _wallpaper.alpha = 0.0;
            } completion:^(BOOL finished){
                _wallpaper.image = [UIImage imageNamed:wallpaperImageName];
                
                [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    _wallpaper.alpha = 1.0;
                } completion:^(BOOL finished){
                    
                }];
            }];
        });
    }
    else if ( components.hour >= 8 && components.hour <= 16 && !wallpaperDidChange_day )  // Day.
    {
        wallpaperImageName = @"wallpaper_day_1";
        wallpaperDidChange_dawn = NO;
        wallpaperDidChange_day = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                _wallpaper.alpha = 0.0;
            } completion:^(BOOL finished){
                _wallpaper.image = [UIImage imageNamed:wallpaperImageName];
                
                [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    _wallpaper.alpha = 1.0;
                } completion:^(BOOL finished){
                    
                }];
            }];
        });
    }
    else if ( components.hour >= 17 && components.hour <= 19 && !wallpaperDidChange_dusk ) // Dusk.
    {
        wallpaperImageName = @"wallpaper_dusk_1";
        wallpaperDidChange_day = NO;
        wallpaperDidChange_dusk = YES;
        // Each one resets the one before it.
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                _wallpaper.alpha = 0.0;
            } completion:^(BOOL finished){
                _wallpaper.image = [UIImage imageNamed:wallpaperImageName];
                
                [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    _wallpaper.alpha = 1.0;
                } completion:^(BOOL finished){
                    
                }];
            }];
        });
    }
    else if ( (components.hour >= 20 || components.hour <= 5) && !wallpaperDidChange_night ) // Night.
    {
        // Since we use different images here, the selection is random.
        NSInteger randomChoice = arc4random_uniform(3);
        
        switch ( randomChoice )
        {
            case 0:
                wallpaperImageName = @"wallpaper_night_1";
                break;
                
            case 1:
                wallpaperImageName = @"wallpaper_night_2";
                break;
                
            case 2:
                wallpaperImageName = @"wallpaper_night_3";
                break;
                
            default:
                break;
        }
        
        wallpaperDidChange_dusk = NO;
        wallpaperDidChange_night = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                _wallpaper.alpha = 0.0;
            } completion:^(BOOL finished){
                _wallpaper.image = [UIImage imageNamed:wallpaperImageName];
                
                [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    _wallpaper.alpha = 1.0;
                } completion:^(BOOL finished){
                    
                }];
            }];
        });
    }
}

#pragma mark -
#pragma mark Chat Cloud Search & Navigation

- (void)showSearchInterface
{
    if ( !isShowingSearchInterface )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        searchBox.hidden = NO;
        searchCancelButton.hidden = NO;
        
        [searchBox becomeFirstResponder];
        [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionFullScreen];
        [_contactCloud jumpToCenter];
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            searchCancelButton.alpha = 1.0;
            searchBox.alpha = 1.0;
            _mainWindowContainer.alpha = 0.0;
            dismissViewButton.alpha = 0.0;
            
            if ( _isFullscreen )
            {
                _searchButton.frame = CGRectMake(_searchButton.frame.origin.x - 220 / 2, 10, 220, _searchButton.frame.size.height);
                searchCancelButton.frame = CGRectMake(_searchButton.frame.origin.x + _searchButton.frame.size.width + 10, 10, searchCancelButton.frame.size.width, searchCancelButton.frame.size.height);
            }
            else
            {
                _searchButton.frame = CGRectMake(10, 10, appDelegate.screenBounds.size.width - searchCancelButton.frame.size.width - 20, _searchButton.frame.size.height);
                searchCancelButton.frame = CGRectMake(appDelegate.screenBounds.size.width - searchCancelButton.frame.size.width - _searchButton.frame.origin.x + 5, 10, searchCancelButton.frame.size.width, searchCancelButton.frame.size.height);
            }
        } completion:^(BOOL finished){
            _mainWindowContainer.hidden = YES;
            dismissViewButton.hidden = YES;
            
            isShowingSearchInterface = YES;
        }];
    }
}

- (void)dismissSearchInterface
{
    if ( isShowingSearchInterface )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        [searchBox resignFirstResponder];
        
        dismissViewButton.hidden = NO;
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            _contactCloud.headerLabel.frame = CGRectMake(_contactCloud.headerLabel.frame.origin.x, _contactCloud.headerLabel.frame.origin.y, _contactCloud.headerLabel.frame.size.width - 40, _contactCloud.headerLabel.frame.size.height);
            searchCancelButton.alpha = 0.0;
            searchBox.alpha = 0.0;
            dismissViewButton.alpha = 1.0;
            _contactCloud.cloudContainer.alpha = 1.0;
            _contactCloud.cloudSearchResultsContainer.alpha = 0.0;
            _searchButton.frame = CGRectMake(appDelegate.screenBounds.size.width - 43, 10, 33, _searchButton.frame.size.height);
            searchCancelButton.frame = CGRectMake(250, 10, searchCancelButton.frame.size.width, searchCancelButton.frame.size.height);
            maskLayer_contactCloud.bounds = CGRectMake(0, 0, _contactCloud.frame.size.width, _contactCloud.frame.size.height);
        } completion:^(BOOL finished){
            _contactCloud.isInSearchMode = NO;
            isShowingSearchInterface = NO;
            searchBox.hidden = YES;
            searchCancelButton.hidden = YES;
            _contactCloud.cloudContainer.hidden = NO;
            [_contactCloud setZoomScale:1.0 animated:YES];
            [_contactCloud jumpToCenter];
            
            searchBox.text = @"";
            [_contactCloud.searchResultsBubbles removeAllObjects];
        }];
    }
}

- (void)showcontactCloudCenterJumpButton
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        _cloudCenterButton.hidden = NO;
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            _cloudCenterButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
        } completion:^(BOOL finished){
            
        }];
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            _cloudCenterButton.frame = CGRectMake(10, _cloudCenterButton.frame.origin.y, _cloudCenterButton.frame.size.width, _cloudCenterButton.frame.size.height);
            _cloudCenterButton.alpha = 1.0;
        } completion:^(BOOL finished){
            
        }];
    });
}

- (void)dismisscontactCloudCenterJumpButton
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        _cloudCenterButton.alpha = 0.99;
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            _cloudCenterButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(0));
        } completion:^(BOOL finished){
            
        }];
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            _cloudCenterButton.frame = CGRectMake(-33, _cloudCenterButton.frame.origin.y, _cloudCenterButton.frame.size.width, _cloudCenterButton.frame.size.height);
            _cloudCenterButton.alpha = 0.0;
        } completion:^(BOOL finished){
            _cloudCenterButton.hidden = YES;
        }];
    });
}

- (void)searchcontactCloudForQuery:(NSString *)query
{
    [_contactCloud.searchResultsBubbles removeAllObjects];
    _contactCloud.isInSearchMode = YES;
    
    [[_contactCloud.cloudSearchResultsContainer subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if ( _contactCloud.cloudContainer.alpha == 1.0 )
    {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            _contactCloud.cloudContainer.alpha = 0.0;
            _contactCloud.cloudSearchResultsContainer.alpha = 1.0;
        } completion:^(BOOL finished){
            _contactCloud.cloudContainer.hidden = YES;
        }];
    }
    
    if ( _contactCloud.zoomScale != 1.0 )
    {
        [_contactCloud setZoomScale:1.0 animated:YES];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( SHChatBubble *bubble in _contactCloud.cloudBubbles )
        {
            /*  Special case:
             When the user types only one character, we only search for
             users whose names/usernames begin with that character, not just any
             users whose names contain that character.
             */
            
            __block NSString *name = [[NSString stringWithFormat:@"%@ %@", [bubble.metadata objectForKey:@"name_first"], [bubble.metadata objectForKey:@"name_last"]] stringByRemovingEmoji];
            __block NSString *userHandle = [[bubble.metadata objectForKey:@"user_handle"] stringByRemovingEmoji];
            __block NSString *alias = [[bubble.metadata objectForKey:@"alias"] stringByRemovingEmoji];
            __block BOOL userHandleExists = YES;
            __block BOOL aliasExists = YES;
            
            if ( userHandle.length == 0 )
            {
                userHandleExists = NO;
                userHandle = @" "; // Keep this 1 blank character to avoid an exception when matching 1st characters.
            }
            
            if ( alias.length == 0 )
            {
                aliasExists = NO;
                alias = @" ";
            }
            
            if ( query.length == 1 )
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    name = [name stringByReplacingOccurrencesOfString:@"☺" withString:@""];
                    name = [name stringByReplacingOccurrencesOfString:@"☹" withString:@""];
                    name = [name stringByReplacingOccurrencesOfString:@"❤" withString:@""];
                    name = [name stringByReplacingOccurrencesOfString:@"❤️" withString:@""];
                    name = [name stringByReplacingOccurrencesOfString:@"★" withString:@""];
                    name = [name stringByReplacingOccurrencesOfString:@"☆" withString:@""];
                    name = [name stringByReplacingOccurrencesOfString:@"☀" withString:@""];
                    name = [name stringByReplacingOccurrencesOfString:@"☁" withString:@""];
                    name = [name stringByReplacingOccurrencesOfString:@"☂" withString:@""];
                    name = [name stringByReplacingOccurrencesOfString:@"☃" withString:@""];
                    name = [name stringByReplacingOccurrencesOfString:@"☎" withString:@""];
                    name = [name stringByReplacingOccurrencesOfString:@"☏" withString:@""];
                    name = [name stringByReplacingOccurrencesOfString:@"☢" withString:@""];
                    name = [name stringByReplacingOccurrencesOfString:@"☣" withString:@""];
                    name = [name stringByReplacingOccurrencesOfString:@"☯" withString:@""];
                    name = [name stringByTrimmingLeadingWhitespace];
                    
                    userHandle = [userHandle stringByReplacingOccurrencesOfString:@"☺" withString:@""];
                    userHandle = [userHandle stringByReplacingOccurrencesOfString:@"☹" withString:@""];
                    userHandle = [userHandle stringByReplacingOccurrencesOfString:@"❤" withString:@""];
                    userHandle = [userHandle stringByReplacingOccurrencesOfString:@"❤️" withString:@""];
                    userHandle = [userHandle stringByReplacingOccurrencesOfString:@"★" withString:@""];
                    userHandle = [userHandle stringByReplacingOccurrencesOfString:@"☆" withString:@""];
                    userHandle = [userHandle stringByReplacingOccurrencesOfString:@"☀" withString:@""];
                    userHandle = [userHandle stringByReplacingOccurrencesOfString:@"☁" withString:@""];
                    userHandle = [userHandle stringByReplacingOccurrencesOfString:@"☂" withString:@""];
                    userHandle = [userHandle stringByReplacingOccurrencesOfString:@"☃" withString:@""];
                    userHandle = [userHandle stringByReplacingOccurrencesOfString:@"☎" withString:@""];
                    userHandle = [userHandle stringByReplacingOccurrencesOfString:@"☏" withString:@""];
                    userHandle = [userHandle stringByReplacingOccurrencesOfString:@"☢" withString:@""];
                    userHandle = [userHandle stringByReplacingOccurrencesOfString:@"☣" withString:@""];
                    userHandle = [userHandle stringByReplacingOccurrencesOfString:@"☯" withString:@""];
                    
                    alias = [alias stringByReplacingOccurrencesOfString:@"☺" withString:@""];
                    alias = [alias stringByReplacingOccurrencesOfString:@"☹" withString:@""];
                    alias = [alias stringByReplacingOccurrencesOfString:@"❤" withString:@""];
                    alias = [alias stringByReplacingOccurrencesOfString:@"★" withString:@""];
                    alias = [alias stringByReplacingOccurrencesOfString:@"☆" withString:@""];
                    alias = [alias stringByReplacingOccurrencesOfString:@"☀" withString:@""];
                    alias = [alias stringByReplacingOccurrencesOfString:@"☁" withString:@""];
                    alias = [alias stringByReplacingOccurrencesOfString:@"☂" withString:@""];
                    alias = [alias stringByReplacingOccurrencesOfString:@"☃" withString:@""];
                    alias = [alias stringByReplacingOccurrencesOfString:@"☎" withString:@""];
                    alias = [alias stringByReplacingOccurrencesOfString:@"☏" withString:@""];
                    alias = [alias stringByReplacingOccurrencesOfString:@"☢" withString:@""];
                    alias = [alias stringByReplacingOccurrencesOfString:@"☣" withString:@""];
                    alias = [alias stringByReplacingOccurrencesOfString:@"☯" withString:@""];
                    
                    if ( userHandleExists )
                    {
                        userHandle = [userHandle stringByTrimmingLeadingWhitespace];
                    }
                    
                    if ( aliasExists )
                    {
                        alias = [alias stringByTrimmingLeadingWhitespace];
                    }
                    
                    if ( [name characterAtIndex:0] == [query characterAtIndex:0] ||
                        [userHandle characterAtIndex:0] == [query characterAtIndex:0] ||
                        [alias characterAtIndex:0] == [query characterAtIndex:0] )
                    {
                        UIImage *currentDP = [UIImage imageWithData:[bubble.metadata objectForKey:@"alias_dp"]];
                        
                        if ( !currentDP )
                        {
                            currentDP = [UIImage imageWithData:[bubble.metadata objectForKey:@"dp"]];
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            // Put together a new copy of a matching bubble.
                            SHChatBubble *searchResultBubble = [[SHChatBubble alloc] initWithFrame:CGRectMake(0, 0, CHAT_CLOUD_BUBBLE_SIZE, CHAT_CLOUD_BUBBLE_SIZE) andImage:currentDP withMiniModeEnabled:NO];
                            [searchResultBubble setBubbleMetadata:bubble.metadata];
                            
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                [_contactCloud insertBubble:searchResultBubble atPoint:CGPointMake(0, 0) animated:YES];
                            });
                        });
                    }
                });
            }
            else
            {
                if ( [name rangeOfString:query].location != NSNotFound ||
                    [userHandle rangeOfString:query].location != NSNotFound ||
                    [alias rangeOfString:query].location != NSNotFound )
                {
                    // Put together a new copy of a matching bubble.
                    UIImage *currentDP = [UIImage imageWithData:[bubble.metadata objectForKey:@"alias_dp"]];
                    
                    if ( !currentDP )
                    {
                        currentDP = [UIImage imageWithData:[bubble.metadata objectForKey:@"dp"]];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        SHChatBubble *searchResultBubble = [[SHChatBubble alloc] initWithFrame:CGRectMake(0, 0, CHAT_CLOUD_BUBBLE_SIZE, CHAT_CLOUD_BUBBLE_SIZE) andImage:currentDP withMiniModeEnabled:NO];
                        [searchResultBubble setBubbleMetadata:bubble.metadata];
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [_contactCloud insertBubble:searchResultBubble atPoint:CGPointMake(0, 0) animated:YES];
                        });
                    });
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [_contactCloud endUpdates];
        });
    });
}

- (void)jumpTocontactCloudCenter
{
    [_contactCloud jumpToCenter];
}

- (void)confirmContactAddition
{
    
}

- (void)setMaxMinZoomScalesForcontactCloudBounds
{
    // Reset.
    _contactCloud.maximumZoomScale = 1;
    _contactCloud.minimumZoomScale = 1;
    _contactCloud.zoomScale = 1;
    
    // Reset position.
    _contactCloud.cloudContainer.frame = CGRectMake(0, 0, _contactCloud.cloudContainer.frame.size.width, _contactCloud.cloudContainer.frame.size.height);
    _contactCloud.cloudSearchResultsContainer.frame = CGRectMake(0, 0, _contactCloud.cloudContainer.frame.size.width, _contactCloud.cloudContainer.frame.size.height);
    
    // Sizes.
    CGSize boundsSize = _contactCloud.bounds.size;
    CGSize cloudSize = _contactCloud.cloudContainer.frame.size;
    
    // Calculate Min.
    CGFloat xScale = boundsSize.width / cloudSize.width;    // The scale needed to perfectly fit the cloud width-wise.
    CGFloat yScale = boundsSize.height / cloudSize.height;  // The scale needed to perfectly fit the cloud height-wise.
    CGFloat minScale = MIN(xScale, yScale);                 // Use minimum of these to allow the cloud to become fully visible.
    
    // Calculate Max.
    CGFloat maxScale = 3;
    
    // Image is smaller than screen so no zooming!
    if ( xScale >= 1 && yScale >= 1 )
    {
        minScale = 1.0;
    }
    
    // Set min/max zoom
    _contactCloud.maximumZoomScale = maxScale;
    _contactCloud.minimumZoomScale = minScale;
    
    // If we're zooming to fill then centralise.
    if ( _contactCloud.zoomScale != minScale )
    {
        // Centralize.
        _contactCloud.contentOffset = CGPointMake((cloudSize.width * _contactCloud.zoomScale - boundsSize.width) / 2.0,
                                                  (cloudSize.height * _contactCloud.zoomScale - boundsSize.height) / 2.0);
    }
    
    // Layout.
    // Center the cloud as it becomes smaller than the size of the screen.
    CGRect frameToCenter = _contactCloud.cloudContainer.frame;
    
    // Horizontally.
    if ( frameToCenter.size.width < boundsSize.width )
    {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    }
    else
    {
        frameToCenter.origin.x = 0;
    }
    
    // Vertically.
    if ( frameToCenter.size.height < boundsSize.height )
    {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    }
    else
    {
        frameToCenter.origin.y = 0;
    }
    
    // Center.
    if ( !CGRectEqualToRect(_contactCloud.cloudContainer.frame, frameToCenter) )
    {
        _contactCloud.cloudContainer.frame = frameToCenter;
        _contactCloud.cloudSearchResultsContainer.frame = frameToCenter;
    }
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods.
    
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ( scrollView.tag == 0 ) // Chat Cloud
    {
        CGFloat centerOffset_x = (_contactCloud.contentSize.width / 2) - (_contactCloud.bounds.size.width / 2);
        CGFloat centerOffset_y = (_contactCloud.contentSize.height / 2) - (_contactCloud.bounds.size.height / 2);
        
        // Hide the Center Jump button if we're inside the center.
        if ( !(_contactCloud.contentOffset.x > centerOffset_x + 200 || _contactCloud.contentOffset.x < centerOffset_x - 200 ||
               _contactCloud.contentOffset.y > centerOffset_y + 200 || _contactCloud.contentOffset.y < centerOffset_y - 200) )
        {
            if ( _cloudCenterButton.alpha >= 1.0 )
            {
                [self dismisscontactCloudCenterJumpButton];
            }
        }
    }
}
    
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    if ( scrollView.tag == 0 ) // Chat Cloud
    {
        CGFloat centerOffset_x = (_contactCloud.contentSize.width / 2) - (_contactCloud.bounds.size.width / 2);
        CGFloat centerOffset_y = (_contactCloud.contentSize.height / 2) - (_contactCloud.bounds.size.height / 2);
        
        maskLayer_contactCloud.position = CGPointMake(_contactCloud.contentOffset.x, _contactCloud.contentOffset.y);
        _contactCloud.headerLabel.frame = CGRectMake(20 + _contactCloud.contentOffset.x, _contactCloud.headerLabel.frame.origin.y, _contactCloud.headerLabel.frame.size.width, _contactCloud.headerLabel.frame.size.height);
        
        // Show the Center Jump button only if we're straggling outside the center.
        if ( _contactCloud.contentOffset.x > centerOffset_x + 200 || _contactCloud.contentOffset.x < centerOffset_x - 200 ||
            _contactCloud.contentOffset.y > centerOffset_y + 200 || _contactCloud.contentOffset.y < centerOffset_y - 200 )
        {
            if ( _cloudCenterButton.hidden )
            {
                [self showcontactCloudCenterJumpButton];
            }
        }
        else
        {
            if ( _cloudCenterButton.alpha >= 1.0 )
            {
                [self dismisscontactCloudCenterJumpButton];
            }
        }
    }
    
    [CATransaction commit];
}
    
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    if ( scrollView.tag == 0 ) // Chat Cloud
    {
        if ( searchBox.text.length > 0 )
        {
            return _contactCloud.cloudSearchResultsContainer;
        }
        else
        {
            return _contactCloud.cloudContainer;
        }
    }
    else
    {
        return nil;
    }
}
    
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    if ( scrollView.tag == 0 ) // Chat Cloud
    {
        // Remove the mask while zooming to avoid a flickering bug.
        _contactCloud.layer.mask = nil;
    }
    
    [CATransaction commit];
}
    
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    if ( scrollView.tag == 0 ) // Chat Cloud
    {
        scrollView.contentSize = CGSizeMake(MAX(scrollView.contentSize.width, scrollView.frame.size.width + 1), MAX(scrollView.contentSize.height, scrollView.frame.size.height + 1));
        _contactCloud.layer.mask = maskLayer_contactCloud; // Restore the mask.
    }
}

#pragma mark -
#pragma mark SHContactManagerDelegate methods.

- (void)contactManagerDidAddNewContact:(NSMutableDictionary *)userData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight affirmativeStrobeLight];
    appDelegate.contactManager.delegate = appDelegate.mainMenu; // Hand control back to the Home Menu.
    
    dismissViewButton.enabled = YES;
    
    if ( _mode == SHRecipientPickerModeAddByUsername )
    {
        FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :user_id"
                                         withParameterDictionary:@{@"user_id": [userData objectForKey:@"user_id"]}];
        
        while ( [s1 next] )
        {
            NSData *DP = [s1 dataForColumn:@"dp"];
            NSData *alias_DP = [s1 dataForColumn:@"alias_dp"];
            
            UIImage *currentDP = [UIImage imageWithData:alias_DP];
            
            if ( !currentDP )
            {
                currentDP = [UIImage imageWithData:DP];
                
                if ( !currentDP )
                {
                    currentDP = [UIImage imageNamed:@"user_placeholder"];
                }
            }
            
            [DPPreview setImage:currentDP];
        }
        
        [s1 close];
        [appDelegate.modelManager.results close];
        [appDelegate.modelManager.DB close];
        
        // We need a slight delay here.
        long double delayInSeconds = 1.5;
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
    else
    {
        [_contactCloud removeBubble:activeBubble permanently:YES animated:YES];
        activeBubble = nil;
    }
    
    [appDelegate.currentUser setObject:@"" forKey:@"last_magic_run"]; // Clear this out to force a fresh run.
    [appDelegate.contactManager.freshContacts addObject:userData];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [appDelegate.contactManager processNewContactsWithDB:db];
        }];
    });
    
    [appDelegate.mainMenu refreshMiniFeed];
}

- (void)contactManagerDidUnblockContact:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight affirmativeStrobeLight];
    appDelegate.contactManager.delegate = appDelegate.mainMenu; // Hand control back to the Home Menu.
    
    dismissViewButton.enabled = YES;
    [_contactCloud removeBubble:activeBubble permanently:YES animated:YES];
    activeBubble = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( int i = 0; i < appDelegate.mainMenu.contactCloud.cloudBubbles.count; i++ )
        {
            SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:i];
            int bubbleUserID = [[bubble.metadata objectForKey:@"user_id"] intValue];
            
            if ( bubbleUserID == userID.intValue )
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [bubble setBlocked:NO];
                    [bubble.metadata setObject:@"0" forKey:@"blocked"];
                });
                
                break;
            }
        }
    });
}

- (void)contactManagerRequestDidFailWithError:(NSError *)error
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight negativeStrobeLight];
    appDelegate.contactManager.delegate = appDelegate.mainMenu;
    dismissViewButton.enabled = YES;
    
    if ( error.code == 404 )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CHAT_CLOUD_TITLE_USER_NOT_FOUND", nil)
                                                        message:NSLocalizedString(@"CHAT_CLOUD_USER_NOT_FOUND", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil) otherButtonTitles:nil];
        [alert show];
    }
    
    usernameField.enabled = YES;
}

#pragma mark -
#pragma mark SHcontactCloudDelegate methods.

- (void)didSelectBubble:(SHChatBubble *)bubble inCloud:(SHContactCloud *)theCloud
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( _mode == SHRecipientPickerModeRecipients )
    {
        if ( isShowingSearchInterface )
        {
            
        }
    }
    else if ( _mode == SHRecipientPickerModeHidden )
    {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [bubble.metadata objectForKey:@"name_first"], [bubble.metadata objectForKey:@"name_last"]]
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"OPTION_ADD_CONTACT", nil), nil];
        
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        actionSheet.tag = 0;
        
        activeBubble = bubble;
        [actionSheet showFromRect:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44) inView:appDelegate.window animated:YES];
    }
    else if ( _mode == SHRecipientPickerModeBlocked )
    {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [bubble.metadata objectForKey:@"name_first"], [bubble.metadata objectForKey:@"name_last"]]
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"OPTION_UNBLOCK_CONTACT", nil), nil];
        
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        actionSheet.tag = 1;
        
        activeBubble = bubble;
        [actionSheet showFromRect:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44) inView:appDelegate.window animated:YES];
    }
}

- (void)didTapAndHoldBubble:(SHChatBubble *)bubble inCloud:(SHContactCloud *)theCloud
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( _mode == SHRecipientPickerModeHidden )
    {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [bubble.metadata objectForKey:@"name_first"], [bubble.metadata objectForKey:@"name_last"]]
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"OPTION_ADD_CONTACT", nil), nil];
        
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        actionSheet.tag = 0;
        
        activeBubble = bubble;
        [actionSheet showFromRect:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44) inView:appDelegate.window animated:YES];
    }
    else if ( _mode == SHRecipientPickerModeBlocked )
    {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [bubble.metadata objectForKey:@"name_first"], [bubble.metadata objectForKey:@"name_last"]]
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"OPTION_UNBLOCK_CONTACT", nil), nil];
        
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        actionSheet.tag = 1;
        
        activeBubble = bubble;
        [actionSheet showFromRect:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44) inView:appDelegate.window animated:YES];
    }
}

- (void)textFieldDidChange:(id)sender
{
    UITextField *textField = (UITextField *)sender;
    NSString *textFieldValue = textField.text;
    
    if ( textField.tag == 0 ) // Search box.
    {
        if ( textFieldValue.length > 0 )
        {
            if ( [textFieldValue isEqualToString:@" "] ) // Prevent whitespace searches.
            {
                textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }
            else
            {
                [self searchcontactCloudForQuery:textFieldValue];
            }
        }
        else
        {
            _contactCloud.cloudContainer.hidden = NO;
            
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                _contactCloud.cloudContainer.alpha = 1.0;
                _contactCloud.cloudSearchResultsContainer.alpha = 0.0;
            } completion:^(BOOL finished){
                
            }];
        }
    }
    else if ( textField.tag == 1 ) // Username box.
    {
        NSCharacterSet *notAllowedChars = [NSCharacterSet characterSetWithCharactersInString:@"!¿?,;:[]{}<>|@#%^&*()=+/\\…•'\""];
        textField.text = [[textField.text componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
        textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
}
    
#pragma mark -
#pragma mark UITextFieldDelegate methods.

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Monitor keystrokes in the search box.
    [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( textField.tag == 0 ) // Search box.
    {
        [self searchcontactCloudForQuery:textField.text];
        [searchBox resignFirstResponder];
    }
    else if ( textField.tag == 1 ) // Username box.
    {
        appDelegate.contactManager.delegate = self;
        [appDelegate.strobeLight activateStrobeLight];
        [appDelegate.contactManager addUsername:usernameField.text];
        [usernameField resignFirstResponder];
    }
    
    return NO;
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( actionSheet.tag == 0 ) // Unhide contact.
    {
        if ( buttonIndex == 0 )
        {
            dismissViewButton.enabled = NO;
            appDelegate.contactManager.delegate = self;
            [appDelegate.strobeLight activateStrobeLight];
            [appDelegate.contactManager unhideContact:[activeBubble.metadata objectForKey:@"user_id"]];
        }
        else
        {
            activeBubble = nil;
        }
    }
    else if ( actionSheet.tag == 1 ) // Unblock contact.
    {
        if ( buttonIndex == 0 )
        {
            dismissViewButton.enabled = NO;
            appDelegate.contactManager.delegate = self;
            [appDelegate.strobeLight activateStrobeLight];
            [appDelegate.contactManager unblockContact:[activeBubble.metadata objectForKey:@"user_id"]];
        }
        else
        {
            activeBubble = nil;
        }
    }
}

#pragma mark -
#pragma mark SHRecipientPickerDelegate methods

- (void)recipientPickerDidSelectRecipient:(NSMutableDictionary *)recipient
{
    if ( [_delegate respondsToSelector:@selector(recipientPickerDidSelectRecipient:)] )
    {
        [_delegate recipientPickerDidSelectRecipient:recipient];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
