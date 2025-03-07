//
//  MainMenuViewController.m
//  Scapes
//
//  Created by MachOSX on 8/3/13.
//
//

#import "MainMenuViewController.h"

#import <MobileCoreServices/UTCoreTypes.h>
#import <Audiotoolbox/AudioToolbox.h>

#import "AFHTTPRequestOperationManager.h"
#import "SHBoardViewController.h"
#import "SHCreateBoardViewController.h"
#import "SHStatusViewController.h"

@implementation MainMenuViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        batchNumber = 0;
        currentUnreadBadgeCycle = 0;
        
        _wallpaperIsAnimating = NO;
        wallpaperShouldAnimate = YES;
        wallpaperIsAnimatingRight = NO;
        wallpaperDidChange_dawn = NO;
        wallpaperDidChange_day = NO;
        wallpaperDidChange_dusk = NO;
        wallpaperDidChange_night = NO;
        isShowingSearchInterface = NO;
        isShowingNewPeerNotification = NO;
        _isRenamingContact = NO;
        _isPickingAliasDP = NO;
        _isPickingDP = NO;
        _isPickingMedia = NO;
        _miniFeedDidFinishDownloading = YES;
        miniFeedRefreshDidFailOnScroll = NO;
        _didDownloadInitialFeed = NO;
        _mediaPickerSourceIsCamera = NO;
        
        // Init table here to allow the loading of the cached feed entries.
        _SHMiniFeed = [[UITableView alloc] init];
        _SHMiniFeed.delegate = self;
        _SHMiniFeed.dataSource = self;
        
        _messagesView = [[MessagesViewController alloc] init];
        _profileView = [[SHProfileViewController alloc] init];
        _profileView.callbackView = self;
        
        _SHMiniFeedEntries = [[NSMutableArray alloc] init];
        _unreadThreadBubbles = [[NSMutableArray alloc] init];
        
        randomQuotes = @[@"Bazinga!",
                         @"I don't even know what a quail looks like.",
                         @"Too close for missiles, I'm switching to guns.",
                         @"That’s a negative, Ghostrider. The pattern is full.",
                         @"When life gives you lemons, make lemonade.",
                         @"The cake is a lie.",
                         @"Sarcasm Self Test complete.",
                         @"Now you know who you're fighting.",
                         @"an Ali Razzouk production",
                         @"We'll send you a Hogwarts toilet seat.",
                         @"Get the Snitch or die trying.",
                         @"I solemnly swear that I am up to no good.",
                         @"When 900 years old, you reach… Look as good, you will not.",
                         @"He’s holding a thermal detonator!",
                         @"It's a trap!",
                         @"Aren't you a little short for a stormtrooper?",
                         @"These aren’t the droids you’re looking for…",
                         @"I find your lack of faith disturbing.",
                         @"There's always a bigger fish.",
                         @"I am the one who knocks.",
                         @"Only a Sith deals in absolutes.",
                         @"Manners maketh man.",
                         @"A wizard is never late."];
        
        if ( appDelegate.SHToken ) // Only if a user is logged in.
        {
            [self setup];
        }
    }
    
    return self;
}

- (void)setup
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    // Load cached Mini Feed entries.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_thread INNER JOIN sh_cloud ON sh_thread.owner_id = sh_cloud.sh_user_id AND sh_cloud.hidden = 0 AND blocked = 0 AND thread_type NOT IN (1, 8) "
                               @"ORDER BY sh_thread.timestamp_sent DESC LIMIT :batch_size"
                       withParameterDictionary:@{@"batch_size": [NSNumber numberWithInt:FEED_BATCH_SIZE]}];
            
            // Read & store each contact's data.
            while ( [s1 next] )
            {
                NSString *userID = [s1 stringForColumn:@"sh_user_id"];
                NSString *lastViewTimestamp = [s1 stringForColumn:@"last_view_timestamp"];
                NSString *lastMessageTimestamp = [s1 stringForColumn:@"last_message_timestamp"];
                NSString *location_latitude = [s1 stringForColumn:@"location_latitude"];
                NSString *location_longitude = [s1 stringForColumn:@"location_longitude"];
                NSData *DP = [s1 dataForColumn:@"dp"];
                id aliasDP = [s1 dataForColumn:@"alias_dp"];
                
                if ( !lastViewTimestamp )
                {
                    lastViewTimestamp = @"";
                }
                
                if ( !lastMessageTimestamp )
                {
                    lastMessageTimestamp = @"";
                }
                
                if ( !location_latitude )
                {
                    location_latitude = @"";
                    location_longitude = @"";
                }
                
                if ( !DP )
                {
                    DP = UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0);
                }
                
                if ( !aliasDP )
                {
                    aliasDP = @"";
                }
                
                NSMutableDictionary *miniFeedEntryData = [[NSMutableDictionary alloc] initWithObjects:@[userID,
                                                                                                        [s1 stringForColumn:@"name_first"],
                                                                                                        [s1 stringForColumn:@"name_last"],
                                                                                                        [s1 stringForColumn:@"alias"],
                                                                                                        [s1 stringForColumn:@"user_handle"],
                                                                                                        [s1 stringForColumn:@"dp_hash"],
                                                                                                        DP,
                                                                                                        aliasDP,
                                                                                                        [s1 stringForColumn:@"email_address"],
                                                                                                        [s1 stringForColumn:@"gender"],
                                                                                                        [s1 stringForColumn:@"birthday"],
                                                                                                        [s1 stringForColumn:@"location_country"],
                                                                                                        [s1 stringForColumn:@"location_state"],
                                                                                                        [s1 stringForColumn:@"location_city"],
                                                                                                        [s1 stringForColumn:@"website"],
                                                                                                        [s1 stringForColumn:@"bio"],
                                                                                                        [s1 stringForColumn:@"last_status_id"],
                                                                                                        [s1 stringForColumn:@"total_messages_sent"],
                                                                                                        [s1 stringForColumn:@"total_messages_received"],
                                                                                                        [s1 stringForColumn:@"unread_thread_count"],
                                                                                                        [s1 stringForColumn:@"view_count"],
                                                                                                        lastViewTimestamp,
                                                                                                        lastMessageTimestamp,
                                                                                                        [s1 stringForColumn:@"coordinate_x"],
                                                                                                        [s1 stringForColumn:@"coordinate_y"],
                                                                                                        [s1 stringForColumn:@"rank_score"],
                                                                                                        [s1 stringForColumn:@"thread_id"],
                                                                                                        [s1 stringForColumn:@"thread_type"],
                                                                                                        [s1 stringForColumn:@"owner_id"],
                                                                                                        [s1 stringForColumn:@"owner_type"],
                                                                                                        [s1 stringForColumn:@"privacy"],
                                                                                                        [s1 stringForColumn:@"message"],
                                                                                                        [s1 stringForColumn:@"timestamp_sent"],
                                                                                                        location_latitude,
                                                                                                        location_longitude]
                                                                                              forKeys:@[@"user_id",
                                                                                                        @"name_first",
                                                                                                        @"name_last",
                                                                                                        @"alias",
                                                                                                        @"user_handle",
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
                                                                                                        @"last_status_id",
                                                                                                        @"total_messages_sent",
                                                                                                        @"total_messages_received",
                                                                                                        @"unread_thread_count",
                                                                                                        @"view_count",
                                                                                                        @"last_view_timestamp",
                                                                                                        @"last_message_timestamp",
                                                                                                        @"coordinate_x",
                                                                                                        @"coordinate_y",
                                                                                                        @"rank_score",
                                                                                                        @"thread_id",
                                                                                                        @"thread_type",
                                                                                                        @"owner_id",
                                                                                                        @"owner_type",
                                                                                                        @"privacy",
                                                                                                        @"message",
                                                                                                        @"timestamp_sent",
                                                                                                        @"location_latitude",
                                                                                                        @"location_longitude"]];
                
                if ( miniFeedEntryData.count > 0 )
                {
                    FMResultSet *s2 = [db executeQuery:@"SELECT * FROM sh_phone_numbers WHERE sh_user_id = :user_id"
                               withParameterDictionary:@{@"user_id": [miniFeedEntryData objectForKey:@"user_id"]}];
                    
                    while ( [s2 next] )
                    {
                        [miniFeedEntryData setObject:[s2 stringForColumn:@"country_calling_code"] forKey:@"country_calling_code"];
                        [miniFeedEntryData setObject:[s2 stringForColumn:@"prefix"] forKey:@"prefix"];
                        [miniFeedEntryData setObject:[s2 stringForColumn:@"phone_number"] forKey:@"phone_number"];
                    }
                    
                    [s2 close];
                    
                    s2 = [db executeQuery:@"SELECT * FROM sh_user_online_status WHERE user_id = :user_id"
                  withParameterDictionary:@{@"user_id": [miniFeedEntryData objectForKey:@"user_id"]}];
                    
                    while ( [s2 next] )
                    {
                        NSString *presenceTargetID = [s2 stringForColumn:@"target_id"];
                        NSString *audience = [s2 stringForColumn:@"audience"];
                        NSString *presenceTimestamp = @"";
                        
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
                        
                        [miniFeedEntryData setObject:[NSNumber numberWithInt:SHUserPresenceOffline] forKey:@"presence"]; // Everyone loads as offline initially.
                        [miniFeedEntryData setObject:presenceTargetID forKey:@"presence_target"];
                        [miniFeedEntryData setObject:audience forKey:@"audience"];
                        [miniFeedEntryData setObject:presenceTimestamp forKey:@"presence_timestamp"];
                    }
                    
                    [s2 close];
                }
                
                [miniFeedEntryData setObject:@"1" forKey:@"entry_type"];
                
                FMResultSet *s2 = [db executeQuery:@"SELECT * FROM sh_muted WHERE user_id = :user_id"
                           withParameterDictionary:@{@"user_id": [miniFeedEntryData objectForKey:@"user_id"]}];
                
                BOOL userIsMuted = NO;
                
                while ( [s2 next] )
                {
                    userIsMuted = YES;
                }
                
                [s2 close];
                
                if ( !userIsMuted )
                {
                    [_SHMiniFeedEntries addObject:miniFeedEntryData];
                }
            }
            
            [s1 close]; // Very important that you close this!
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [_SHMiniFeed reloadData];
                [self loadCloud];
            });
        }];
    });
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor blackColor];
    
    photoPicker = [[UIImagePickerController alloc] init];
    photoPicker.mediaTypes = @[(NSString *)kUTTypeImage];
    photoPicker.videoQuality = UIImagePickerControllerQualityTypeMedium;
    photoPicker.videoMaximumDuration = 60 * 10;
    photoPicker.delegate = self;
    
    _contactCloud = [[SHContactCloud alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 20 + appDelegate.screenBounds.size.height / 2)];
    _contactCloud.delegate = self;
    _contactCloud.cloudDelegate = self;
    _contactCloud.tag = 0;
    
    int rand = arc4random_uniform((int)randomQuotes.count);
    _contactCloud.footerLabel.text = [randomQuotes objectAtIndex:rand];
    
    float scaleFactor = appDelegate.screenBounds.size.height / 568;
    
    _wallpaper = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 750 * scaleFactor, appDelegate.screenBounds.size.height)]; // 750 is the actual width of the image.
    _wallpaper.backgroundColor = [UIColor blackColor];
    _wallpaper.opaque = YES;
    
    _windowCompositionLayer = [[UIScrollView alloc] initWithFrame:appDelegate.screenBounds];
    _windowCompositionLayer.contentSize = CGSizeMake(appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height);
    _windowCompositionLayer.pagingEnabled = YES;
    _windowCompositionLayer.showsHorizontalScrollIndicator = NO;
    _windowCompositionLayer.showsVerticalScrollIndicator = NO;
    _windowCompositionLayer.scrollEnabled = NO;
    _windowCompositionLayer.scrollsToTop = NO;
    _windowCompositionLayer.delegate = self;
    _windowCompositionLayer.tag = 66;
    
    _mainWindowContainer = [[UIView alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - ([UIApplication sharedApplication].statusBarFrame.size.height - 20))];
    
    _mainWindowNipple = [[UIImageView alloc] initWithFrame:CGRectMake(-7, 34, 7, 14)];
    _mainWindowNipple.image = [UIImage imageNamed:@"main_window_nipple"];
    _mainWindowNipple.opaque = YES;
    _mainWindowNipple.alpha = 0.0;
    _mainWindowNipple.hidden = YES;
    
    _searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_searchButton setBackgroundImage:[[UIImage imageNamed:@"button_round_white_transparent"] stretchableImageWithLeftCapWidth:18 topCapHeight:18] forState:UIControlStateNormal];
    [_searchButton addTarget:self action:@selector(showSearchInterface) forControlEvents:UIControlEventTouchUpInside];
    _searchButton.frame = CGRectMake(10, 25, 35, 35);
    _searchButton.adjustsImageWhenDisabled = NO;
    _searchButton.showsTouchWhenHighlighted = YES;
    _searchButton.opaque = YES;
    
    _createBoardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_createBoardButton setTitle:@"+" forState:UIControlStateNormal];
    [_createBoardButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_createBoardButton setBackgroundImage:[[UIImage imageNamed:@"button_round_white_transparent"] stretchableImageWithLeftCapWidth:18 topCapHeight:18] forState:UIControlStateNormal];
    [_createBoardButton addTarget:self action:@selector(showBoardCreator) forControlEvents:UIControlEventTouchUpInside];
    [_createBoardButton setTitleEdgeInsets:UIEdgeInsetsMake(-5, 0, 0, 0)];
    _createBoardButton.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    _createBoardButton.frame = CGRectMake(appDelegate.screenBounds.size.width / 2 - 17.5, 25, 35, 35);
    _createBoardButton.showsTouchWhenHighlighted = YES;
    _createBoardButton.opaque = YES;
    
    _refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_refreshButton setBackgroundImage:[[UIImage imageNamed:@"button_round_white_transparent"] stretchableImageWithLeftCapWidth:18 topCapHeight:18] forState:UIControlStateNormal];
    [_refreshButton addTarget:self action:@selector(refreshCloud) forControlEvents:UIControlEventTouchUpInside];
    _refreshButton.frame = CGRectMake(appDelegate.screenBounds.size.width - 45, 25, 35, 35);
    _refreshButton.showsTouchWhenHighlighted = YES;
    _refreshButton.opaque = YES;
    
    _cloudCenterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cloudCenterButton setBackgroundImage:[[UIImage imageNamed:@"button_round_white_transparent"] stretchableImageWithLeftCapWidth:18 topCapHeight:18] forState:UIControlStateNormal];
    [_cloudCenterButton addTarget:self action:@selector(jumpToChatCloudCenter) forControlEvents:UIControlEventTouchUpInside];
    _cloudCenterButton.frame = CGRectMake(-33, appDelegate.screenBounds.size.height / 2 - 25, 35, 35);
    _cloudCenterButton.showsTouchWhenHighlighted = YES;
    _cloudCenterButton.alpha = 0.0;
    _cloudCenterButton.opaque = YES;
    _cloudCenterButton.hidden = YES;
    
    _unreadBadgeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_unreadBadgeButton setBackgroundImage:[[UIImage imageNamed:@"button_round_white_transparent"] stretchableImageWithLeftCapWidth:18 topCapHeight:18] forState:UIControlStateNormal];
    [_unreadBadgeButton addTarget:self action:@selector(cycleUnreadThreads) forControlEvents:UIControlEventTouchUpInside];
    _unreadBadgeButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:MIN_MAIN_FONT_SIZE];
    _unreadBadgeButton.frame = CGRectMake(appDelegate.screenBounds.size.width - 55, appDelegate.screenBounds.size.height / 2 - 25, 35, 35);
    _unreadBadgeButton.showsTouchWhenHighlighted = YES;
    _unreadBadgeButton.alpha = 0.0;
    _unreadBadgeButton.opaque = YES;
    _unreadBadgeButton.hidden = YES;
    
    searchCancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [searchCancelButton setBackgroundImage:[[UIImage imageNamed:@"button_rect_bg_white"] stretchableImageWithLeftCapWidth:16 topCapHeight:16] forState:UIControlStateNormal];
    [searchCancelButton setTitle:NSLocalizedString(@"GENERIC_CANCEL", nil) forState:UIControlStateNormal];
    [searchCancelButton setTitleColor:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0] forState:UIControlStateNormal];
    [searchCancelButton addTarget:self action:@selector(dismissSearchInterface) forControlEvents:UIControlEventTouchUpInside];
    searchCancelButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
    searchCancelButton.frame = CGRectMake(250, 25, 70, 35);
    searchCancelButton.alpha = 0.0;
    searchCancelButton.opaque = YES;
    searchCancelButton.hidden = YES;
    
    settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsButton setBackgroundImage:[[UIImage imageNamed:@"button_round_white_transparent"] stretchableImageWithLeftCapWidth:18 topCapHeight:18] forState:UIControlStateNormal];
    [settingsButton addTarget:self action:@selector(showUserProfile) forControlEvents:UIControlEventTouchUpInside];
    settingsButton.frame = CGRectMake(appDelegate.screenBounds.size.width - 90, 5, 70, 33);
    settingsButton.showsTouchWhenHighlighted = YES;
    settingsButton.opaque = YES;
    
    inviteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [inviteButton setTitle:NSLocalizedString(@"SETTINGS_OPTION_INVITE", nil) forState:UIControlStateNormal];
    [inviteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [inviteButton addTarget:self action:@selector(showInvitationOptions) forControlEvents:UIControlEventTouchUpInside];
    inviteButton.frame = CGRectMake(20, (_contactCloud.frame.size.height / 2) + 50, _contactCloud.frame.size.width - 40, 33);
    inviteButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:MAIN_FONT_SIZE];
    inviteButton.titleLabel.clipsToBounds = NO;
    inviteButton.titleLabel.layer.masksToBounds = NO;
    inviteButton.titleLabel.layer.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
    inviteButton.titleLabel.layer.shadowRadius = 4.0f;
    inviteButton.titleLabel.layer.shadowOpacity = 0.9;
    inviteButton.titleLabel.layer.shadowOffset = CGSizeZero;
    inviteButton.opaque = YES;
    inviteButton.hidden = YES;
    
    UIImageView *searchIcon = [[UIImageView alloc] initWithFrame:CGRectMake(9, 9, 16, 16)];
    searchIcon.image = [UIImage imageNamed:@"search_white"];
    
    UIImageView *refreshIcon = [[UIImageView alloc] initWithFrame:CGRectMake(9, 9, 16, 16)];
    refreshIcon.image = [UIImage imageNamed:@"refresh_white"];
    
    UIImageView *cloudCenterIcon = [[UIImageView alloc] initWithFrame:CGRectMake(9.5, 9.5, 16, 16)];
    cloudCenterIcon.image = [UIImage imageNamed:@"center_white"];
    
    UIImageView *settingsIcon = [[UIImageView alloc] initWithFrame:CGRectMake(9, 8, 51, 16)];
    settingsIcon.image = [UIImage imageNamed:@"settings_1"];
    
    searchBox = [[UITextField alloc] initWithFrame:CGRectMake(30, 6, 188, 24)];
    searchBox.textColor  = [UIColor whiteColor];
    searchBox.placeholder = NSLocalizedString(@"CHAT_CLOUD_PLACEHOLDER_SEARCH", nil);
    searchBox.clearButtonMode = UITextFieldViewModeWhileEditing;
    searchBox.returnKeyType = UIReturnKeyGo;
    searchBox.enablesReturnKeyAutomatically = YES;
    searchBox.alpha = 0.0;
    searchBox.hidden = YES;
    searchBox.tag = 0;
    searchBox.delegate = self;
    
    contactCloudInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, (_contactCloud.frame.size.height / 2) - 20, _contactCloud.frame.size.width - 40, 55)];
    contactCloudInfoLabel.backgroundColor = [UIColor clearColor];
    contactCloudInfoLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:MAIN_FONT_SIZE];
    contactCloudInfoLabel.textColor = [UIColor whiteColor];
    contactCloudInfoLabel.textAlignment = NSTextAlignmentCenter;
    contactCloudInfoLabel.text = NSLocalizedString(@"CHAT_CLOUD_LOADING", nil);
    contactCloudInfoLabel.numberOfLines = 0;
    contactCloudInfoLabel.clipsToBounds = NO;
    contactCloudInfoLabel.layer.masksToBounds = NO;
    contactCloudInfoLabel.layer.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
    contactCloudInfoLabel.layer.shadowRadius = 4.0;
    contactCloudInfoLabel.layer.shadowOpacity = 0.9;
    contactCloudInfoLabel.layer.shadowOffset = CGSizeZero;
    contactCloudInfoLabel.opaque = YES;
    
    _activeRecipientBubble = [[SHChatBubble alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width - 90, 25, 35, 35) withMiniModeEnabled:YES];
    _activeRecipientBubble.delegate = self;
    _activeRecipientBubble.alpha = 0.0;
    _activeRecipientBubble.hidden = YES;
    _activeRecipientBubble.tag = -1; // This one has a special tag.
    [_activeRecipientBubble setPresence:SHUserPresenceOffline animated:NO];
    
    UIImageView *recipientBubbleShadow = [[UIImageView alloc] initWithFrame:CGRectMake(-7, _activeRecipientBubble.frame.size.height - 3, 50, 36)];
    recipientBubbleShadow.image = [UIImage imageNamed:@"chat_bubble_label_shadow"];
    recipientBubbleShadow.opaque = YES;
    
    _SHMiniFeedContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 20 + appDelegate.screenBounds.size.height / 2, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - (20 + appDelegate.screenBounds.size.height / 2))];
    
    UIButton *feedHeader = [UIButton buttonWithType:UIButtonTypeCustom];
    [feedHeader addTarget:self action:@selector(scrollToTopOfMiniFeed) forControlEvents:UIControlEventTouchUpInside];
    feedHeader.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, 44);
    feedHeader.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.35];
    
    UILabel *feedHeaderTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 120, 44)];
    feedHeaderTitle.backgroundColor = [UIColor clearColor];
    feedHeaderTitle.font = [UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE];
    feedHeaderTitle.textColor = [UIColor colorWithRed:220/255.0 green:220/255.0 blue:223/255.0 alpha:1.0];
    feedHeaderTitle.text = NSLocalizedString(@"MINI_FEED_TITLE", nil);
    
    // Initialized up in the init method of the view controller.
    _SHMiniFeed.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, _SHMiniFeedContainer.frame.size.height);
    _SHMiniFeed.backgroundColor = [UIColor clearColor];
    _SHMiniFeed.backgroundView = nil;
    _SHMiniFeed.separatorStyle = UITableViewCellSeparatorStyleNone;
    _SHMiniFeed.contentInset = UIEdgeInsetsMake(feedHeader.frame.size.height, 0, 0, 0);
    _SHMiniFeed.scrollIndicatorInsets = UIEdgeInsetsMake(feedHeader.frame.size.height, 0, 0, 0); // To account for the part hidden by the main window's side.
    _SHMiniFeed.scrollsToTop = YES;
    _SHMiniFeed.tag = 1;
    
    SHMiniFeedrefreshControl = [[UIRefreshControl alloc] init];
    [SHMiniFeedrefreshControl addTarget:self action:@selector(refreshMiniFeed) forControlEvents:UIControlEventValueChanged];
    
    UIColor *outerColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    UIColor *innerColor = [UIColor colorWithWhite:1.0 alpha:0.0];
    
    // Adding transparency to the top & bottom of the Chat Cloud.
    maskLayer_ContactCloud = [CAGradientLayer layer];
    maskLayer_ContactCloud.colors = [NSArray arrayWithObjects:(__bridge id)innerColor.CGColor, (__bridge id)outerColor.CGColor, (__bridge id)outerColor.CGColor, (__bridge id)innerColor.CGColor, nil];
    maskLayer_ContactCloud.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0],
                                     [NSNumber numberWithFloat:0.2],
                                     [NSNumber numberWithFloat:0.8],
                                     [NSNumber numberWithFloat:1.0], nil];
    
    maskLayer_ContactCloud.bounds = CGRectMake(0, 0, _contactCloud.frame.size.width, _contactCloud.frame.size.height);
    maskLayer_ContactCloud.position = CGPointMake(_contactCloud.contentOffset.x, _contactCloud.contentOffset.y);
    maskLayer_ContactCloud.anchorPoint = CGPointZero;
    _contactCloud.layer.mask = maskLayer_ContactCloud;
    
    // Adding transparency to the top & bottom of the Mini Feed.
    maskLayer_MiniFeed = [CAGradientLayer layer];
    maskLayer_MiniFeed.colors = [NSArray arrayWithObjects:(__bridge id)innerColor.CGColor, (__bridge id)innerColor.CGColor, (__bridge id)outerColor.CGColor, (__bridge id)outerColor.CGColor, (__bridge id)innerColor.CGColor, nil];
    maskLayer_MiniFeed.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0],
                                    [NSNumber numberWithFloat:0.06],
                                    [NSNumber numberWithFloat:0.2],
                                    [NSNumber numberWithFloat:0.8],
                                    [NSNumber numberWithFloat:1.0], nil];
    
    maskLayer_MiniFeed.bounds = CGRectMake(0, 0, _SHMiniFeed.frame.size.width, _SHMiniFeed.frame.size.height);
    maskLayer_MiniFeed.position = CGPointMake(0, _SHMiniFeed.contentOffset.y);
    maskLayer_MiniFeed.anchorPoint = CGPointZero;
    _SHMiniFeed.layer.mask = maskLayer_MiniFeed;
    
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        _searchButton.frame = CGRectMake(10, 30, 33, 33);
        searchCancelButton.frame = CGRectMake(250, 30, 70, 33);
        _activeRecipientBubble.frame = CGRectMake(_activeRecipientBubble.frame.origin.x, 26, _activeRecipientBubble.frame.size.width, _activeRecipientBubble.frame.size.height);
    }
    else
    {
        SHMiniFeedrefreshControl.tintColor = [UIColor whiteColor];
    }
    
    UILongPressGestureRecognizer *gesture_longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapAndHoldProfileButton:)];
    [settingsButton addGestureRecognizer:gesture_longPress];
    
    UIPanGestureRecognizer *gesture_activeRecipientBubbleDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(userDidDragActiveRecipientBubble:)];
    [_activeRecipientBubble addGestureRecognizer:gesture_activeRecipientBubbleDrag];
    
    gesture_mainWindowTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pushWindow:)];
    [_mainWindowContainer addGestureRecognizer:gesture_mainWindowTap];
    gesture_mainWindowTap.enabled = NO;
    
    [self updateUnreadBadge:-1];
    
    [_activeRecipientBubble addSubview:recipientBubbleShadow];
    [_activeRecipientBubble sendSubviewToBack:recipientBubbleShadow];
    
    [feedHeader addSubview:feedHeaderTitle];
    [_SHMiniFeed addSubview:SHMiniFeedrefreshControl];
    [_SHMiniFeedContainer addSubview:_SHMiniFeed];
    [_SHMiniFeedContainer addSubview:feedHeader];
    [_SHMiniFeedContainer addSubview:settingsButton];
    [_searchButton addSubview:searchIcon];
    [_refreshButton addSubview:refreshIcon];
    [_cloudCenterButton addSubview:cloudCenterIcon];
    [_searchButton addSubview:searchBox];
    [settingsButton addSubview:settingsIcon];
    [_mainWindowContainer addSubview:_mainWindowNipple];
    [_mainWindowContainer addSubview:appDelegate.mainWindowNavigationController.view];
    [contentView addSubview:_wallpaper];
    [contentView addSubview:_windowCompositionLayer];
    [_windowCompositionLayer addSubview:_SHMiniFeedContainer];
    [_windowCompositionLayer addSubview:_contactCloud];
    [_windowCompositionLayer addSubview:contactCloudInfoLabel];
    [_windowCompositionLayer addSubview:inviteButton];
    [_windowCompositionLayer addSubview:_searchButton];
    [_windowCompositionLayer addSubview:_createBoardButton];
    [_windowCompositionLayer addSubview:_refreshButton];
    [_windowCompositionLayer addSubview:_cloudCenterButton];
    [_windowCompositionLayer addSubview:_unreadBadgeButton];
    [_windowCompositionLayer addSubview:searchCancelButton];
    [_windowCompositionLayer addSubview:_activeRecipientBubble];
    [_windowCompositionLayer addSubview:_mainWindowContainer];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self startWallpaperAnimation];
    [self startTimeOfDayCheck];
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
            _wallpaperIsAnimating = YES;
            
            [self startWallpaperAnimation];
        }
    }];
}

// Call this function only after pausing wallpaper animation, not to start it.
- (void)resumeWallpaperAnimation
{
    if ( !_wallpaperIsAnimating )
    {
        wallpaperShouldAnimate = YES;
        _wallpaperIsAnimating = YES;
        
        [self startWallpaperAnimation];
    }
}

- (void)stopWallpaperAnimation
{
    wallpaperShouldAnimate = NO;
    _wallpaperIsAnimating = NO;
}

#pragma mark -
#pragma mark Check the time of the day to set the wallpaper accordingly.

- (void)startTimeOfDayCheck
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self checkTimeOfDay];
        
        if ( timer_timeOfDayCheck )
        {
            [timer_timeOfDayCheck invalidate];
            timer_timeOfDayCheck = nil;
        }
        
        timer_timeOfDayCheck = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(checkTimeOfDay) userInfo:nil repeats:YES]; // Run this every 1 minute.
    });
}

- (void)pauseTimeOfDayCheck
{
    [timer_timeOfDayCheck invalidate];
    timer_timeOfDayCheck = nil;
}

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

- (void)enableCompositionLayerScrolling
{
    _windowCompositionLayer.scrollEnabled = YES;
}

- (void)disableCompositionLayerScrolling
{
    _windowCompositionLayer.scrollEnabled = NO;
}

- (void)dismissWindow
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    appDelegate.activeWindow = 0;
    _profileView.mainView.scrollsToTop = NO;
    _mainWindowContainer.hidden = NO;
    
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _mainWindowContainer.frame = CGRectMake(appDelegate.screenBounds.size.width, _mainWindowContainer.frame.origin.y, _mainWindowContainer.frame.size.width, _mainWindowContainer.frame.size.height);
    } completion:^(BOOL finished){
        
    }];
    
    _windowCompositionLayer.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height);
    [self disableCompositionLayerScrolling];
    [self slideUIForWindow];
    
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
    [_windowCompositionLayer setContentOffset:CGPointMake(0, 0) animated:YES];
    
    if ( !_wallpaperIsAnimating )
    {
        [self resumeWallpaperAnimation];
    }
    
    // Restore the bubble of the open profile.
    if ( [_profileView.ownerDataChunk objectForKey:@"user_id"] )
    {
        NSMutableDictionary *metadata = [_profileView.ownerDataChunk mutableCopy]; // Save a copy in case it gets overwritten.
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for ( SHChatBubble *theBubble in _contactCloud.cloudBubbles )
            {
                int activeBubbleUserID = [[metadata objectForKey:@"user_id"] intValue];
                int targetBubbleUserID = [[theBubble.metadata objectForKey:@"user_id"] intValue];
                
                if ( targetBubbleUserID == activeBubbleUserID )
                {
                    _profileView.ownerID = @"";
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        theBubble.hidden = NO;
                        
                        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                            theBubble.alpha = 1.0;
                        } completion:^(BOOL finished){
                            
                        }];
                    });
                    
                    break;
                }
            }
        });
    }
}

- (void)hideMainWindowSide
{
    [_windowCompositionLayer scrollRectToVisible:CGRectMake(-40, 0, _mainWindowContainer.frame.size.width, _mainWindowContainer.frame.size.height) animated:YES];
    [self disableCompositionLayerScrolling];
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _mainWindowContainer.alpha = 0.0;
    } completion:^(BOOL finished){
        _mainWindowContainer.hidden = YES;
    }];
}

- (void)showMainWindowSide
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    _SHMiniFeed.scrollsToTop = YES;
    _messagesView.conversationTable.scrollsToTop = NO;
    _profileView.mainView.scrollsToTop = NO;
    appDelegate.mainWindowNavigationController.view.userInteractionEnabled = NO;
    _mainWindowContainer.hidden = NO;
    
    _windowCompositionLayer.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height);
    
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
    [_windowCompositionLayer setContentOffset:CGPointMake(0, 0) animated:YES];
    
    // Give it a slight delay here.
    long double delayInSeconds = 0.35;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        
        // Make sure the window is reset to its original position after any tamperings with its frame.
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            if ( !isShowingSearchInterface && appDelegate.activeWindow && appDelegate.activeWindow == SHAppWindowTypeMessages )
            {
                _mainWindowContainer.frame = CGRectMake(appDelegate.screenBounds.size.width - 40, _mainWindowContainer.frame.origin.y, _mainWindowContainer.frame.size.width, _mainWindowContainer.frame.size.height);
            }
            
            _mainWindowContainer.alpha = 1.0;
        } completion:^(BOOL finished){
            
            _messagesView.tableContainer.frame = CGRectMake(0, _messagesView.tableContainer.frame.origin.y, _messagesView.tableContainer.frame.size.width, _messagesView.tableContainer.frame.size.height);
            _messagesView.tableSideShadow.frame = CGRectMake(appDelegate.screenBounds.size.width, _messagesView.tableSideShadow.frame.origin.y, _messagesView.tableSideShadow.frame.size.width, _messagesView.tableSideShadow.frame.size.height);
        }];
    });
    
    if ( !_wallpaperIsAnimating )
    {
        [self resumeWallpaperAnimation];
    }
}

- (void)pushWindow:(SHAppWindowType)windowType
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    switch ( windowType )
    {
        case SHAppWindowTypeMessages:
        {
            appDelegate.mainWindowNavigationController.viewControllers = @[_messagesView];
            
            _windowCompositionLayer.contentSize = CGSizeMake(appDelegate.screenBounds.size.width * 3 - 40, appDelegate.screenBounds.size.height);
            _messagesView.conversationTable.scrollsToTop = YES;
            
            [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionNavigationBar];
            [_messagesView.navigationController setNavigationBarHidden:NO animated:YES];
            [self stopWallpaperAnimation];
            
            if ( IS_IOS7 )
            {
                if ( _messagesView.inPrivateMode )
                {
                    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
                }
                else
                {
                    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
                }
            }
            
            appDelegate.activeWindow = SHAppWindowTypeMessages;
            
            break;
        }
            
        case SHAppWindowTypeProfile:
        {
            if ( !_profileView )
            {
                _profileView = [[SHProfileViewController alloc] init];
            }
            
            appDelegate.mainWindowNavigationController.viewControllers = @[_profileView];
            
            if  ( (IS_IOS7) )
            {
                [appDelegate.mainWindowNavigationController.navigationBar setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor blackColor]}];
            }
            
            _windowCompositionLayer.contentSize = CGSizeMake(appDelegate.screenBounds.size.width * 2, appDelegate.screenBounds.size.height);
            _mainWindowNipple.hidden = YES;
            _profileView.mainView.scrollsToTop = YES;
            
            [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
            [_profileView.navigationController setNavigationBarHidden:YES animated:YES];
            
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                _activeRecipientBubble.alpha = 0.0;
            } completion:^(BOOL finished){
                _activeRecipientBubble.hidden = YES;
                [_messagesView clearViewAnimated:YES];
            }];
            
            appDelegate.activeWindow = SHAppWindowTypeProfile;
            
            break;
        }
            
        default:
        {
            break;
        }
    }
    
    if ( appDelegate.activeWindow ) // Check if there's a view previously loaded.
    {
        if ( (appDelegate.activeWindow == SHAppWindowTypeMessages && _messagesView.inPrivateMode) || appDelegate.activeWindow == SHAppWindowTypeProfile )
        {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        }
        else
        {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        }
        
        if ( appDelegate.activeWindow != SHAppWindowTypeProfile )
        {
            [self stopWallpaperAnimation];
        }
        
        if ( appDelegate.activeWindow == SHAppWindowTypeMessages )
        {
            // Listen for the keyboard.
            [[NSNotificationCenter defaultCenter] addObserver:_messagesView selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:_messagesView selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
            
            [_activeRecipientBubble setBadgeCount:0]; // Reset this.
            [_messagesView updateMenuButtonBadgeCount:appDelegate.messageManager.unreadThreadCount];
            [_messagesView resetView]; // Sometimes, the keyboard gets stuck. This takes care of that.
        }
        else if ( appDelegate.activeWindow == SHAppWindowTypeProfile )
        {
            [_profileView updateMenuButtonBadgeCount:appDelegate.messageManager.unreadThreadCount];
        }
        
        _SHMiniFeed.scrollsToTop = NO;
        appDelegate.mainWindowNavigationController.view.userInteractionEnabled = YES;
        
        [self enableCompositionLayerScrolling]; // Unlock the layer.
        [self slideUIForWindow];
        
        [_windowCompositionLayer scrollRectToVisible:CGRectMake(appDelegate.screenBounds.size.width, 0, _mainWindowContainer.frame.size.width, _mainWindowContainer.frame.size.height) animated:YES];
    }
}

- (void)restoreCurrentProfileBubble
{
    if ( [_profileView.ownerDataChunk objectForKey:@"user_id"] )
    {
        NSMutableDictionary *metadata = [_profileView.ownerDataChunk mutableCopy]; // Save a copy in case it gets overwritten.
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for ( SHChatBubble *theBubble in _contactCloud.cloudBubbles )
            {
                if ( theBubble.bubbleType == SHChatBubbleTypeUser )
                {
                    int activeBubbleUserID = [[metadata objectForKey:@"user_id"] intValue];
                    int targetBubbleUserID = [[theBubble.metadata objectForKey:@"user_id"] intValue];
                    
                    if ( targetBubbleUserID == activeBubbleUserID )
                    {
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            theBubble.hidden = NO;
                            
                            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                                theBubble.alpha = 1.0;
                            } completion:^(BOOL finished){
                                
                            }];
                        });
                        
                        break;
                    }
                }
            }
            
            // Restore the bubble of the current conversation window.
            if ( _activeRecipientBubble.metadata )
            {
                for ( SHChatBubble *theBubble in _contactCloud.cloudBubbles )
                {
                    if ( theBubble.bubbleType == SHChatBubbleTypeUser )
                    {
                        int activeBubbleUserID = [[_activeRecipientBubble.metadata objectForKey:@"user_id"] intValue];
                        int targetBubbleUserID = [[theBubble.metadata objectForKey:@"user_id"] intValue];
                        
                        if ( targetBubbleUserID == activeBubbleUserID )
                        {
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                theBubble.hidden = NO;
                                
                                [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                                    theBubble.alpha = 1.0;
                                } completion:^(BOOL finished){
                                    
                                }];
                            });
                            
                            break;
                        }
                    }
                }
                
                _activeRecipientBubble.metadata = nil;
            }
        });
    }
}

- (void)showUserProfile
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [self restoreCurrentProfileBubble];
    
    _profileView.ownerDataChunk = appDelegate.currentUser;
    _profileView.shouldRefreshInfo = YES;
    
    [self pushWindow:SHAppWindowTypeProfile];
}

- (void)showBoardForID:(NSString *)boardID
{
    SHBoardViewController *boardView = [[SHBoardViewController alloc] init];
    SHOrientationNavigationController *navigationController = [[SHOrientationNavigationController alloc] initWithRootViewController:boardView];
    navigationController.autoRotates = NO;
    
    boardView.boardID = boardID;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)showBoardCreator
{
    SHCreateBoardViewController *boardCreator = [[SHCreateBoardViewController alloc] init];
    SHOrientationNavigationController *navigationController = [[SHOrientationNavigationController alloc] initWithRootViewController:boardCreator];
    navigationController.autoRotates = NO;
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark -
#pragma mark Invite Friends

- (void)showInvitationOptions
{
    NSArray *activityItems = @[NSLocalizedString(@"SETTINGS_INVITATION_BODY", nil), [NSURL URLWithString:@"https://itunes.apple.com/us/app/nightboard/id963223746?ls=1&mt=8"]];
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [activityController setValue:NSLocalizedString(@"SETTINGS_INVITATION_SUBJECT", nil) forKey:@"subject"];
    
    if ( (IS_IOS7) )
    {
        activityController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop];
    }
    else
    {
        activityController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll];
    }
    
    [self presentViewController:activityController animated:YES completion:nil];
}

#pragma mark -
#pragma mark New Peer Notification

- (void)showNewPeerNotification
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( _windowCompositionLayer.contentOffset.x < appDelegate.screenBounds.size.width && !isShowingNewPeerNotification )
    {
        isShowingNewPeerNotification = YES;
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); // Vibrate.
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        
        UIView *peerNotificationBar = [[UIView alloc] initWithFrame:CGRectMake(0, -20, appDelegate.screenBounds.size.width, 20)];
        peerNotificationBar.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        peerNotificationBar.opaque = YES;
        
        UILabel *peerNotificationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, peerNotificationBar.frame.size.width - 40, 20)];
        peerNotificationLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:SECONDARY_FONT_SIZE];
        peerNotificationLabel.textAlignment = NSTextAlignmentCenter;
        peerNotificationLabel.textColor = [UIColor whiteColor];
        peerNotificationLabel.text = NSLocalizedString(@"ALERT_NEW_PEER", nil);
        
        [peerNotificationBar addSubview:peerNotificationLabel];
        [self.view addSubview:peerNotificationBar];
        
        [UIView animateWithDuration:0.25 delay:0.3 options:UIViewAnimationOptionCurveLinear animations:^{
            peerNotificationBar.frame = CGRectMake(peerNotificationBar.frame.origin.x, 0, peerNotificationBar.frame.size.width, peerNotificationBar.frame.size.height);
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.25 delay:3.2 options:UIViewAnimationOptionCurveLinear animations:^{
                peerNotificationBar.frame = CGRectMake(peerNotificationBar.frame.origin.x, -20, peerNotificationBar.frame.size.width, peerNotificationBar.frame.size.height);
            } completion:^(BOOL finished){
                [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
                [peerNotificationBar removeFromSuperview];
                
                isShowingNewPeerNotification = NO;
            }];
        }];
    }
}

#pragma mark -
#pragma mark Chat Cloud Search & Navigation

- (void)showRenamingInterfaceForBubble:(SHChatBubble *)bubble
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *renamingOverlay = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    renamingOverlay.opaque = YES;
    renamingOverlay.alpha = 0.0;
    renamingOverlay.tag = 777;
    
    UIImage *currentDP = [UIImage imageWithData:[bubble.metadata objectForKey:@"alias_dp"]];
    
    if ( !currentDP )
    {
        currentDP = [UIImage imageWithData:[bubble.metadata objectForKey:@"dp"]];
    }
    
    int upperPadding = 70;
    
    CGRect placeholderFrame = CGRectMake(appDelegate.screenBounds.size.width / 2 - (bubble.frame.size.width / 2), upperPadding, bubble.frame.size.width, bubble.frame.size.height);
    SHChatBubble *placeholderBubble = [[SHChatBubble alloc] initWithFrame:placeholderFrame andImage:currentDP withMiniModeEnabled:NO];
    placeholderBubble.enabled = NO;
    placeholderBubble.tag = 7770;
    
    UIImageView *textFieldBG = [[UIImageView alloc] initWithFrame:CGRectMake(20, placeholderBubble.frame.origin.y + placeholderBubble.frame.size.height + 15, appDelegate.screenBounds.size.width - 40, 35)];
    textFieldBG.image = [[UIImage imageNamed:@"button_round_white_transparent"] stretchableImageWithLeftCapWidth:18 topCapHeight:18];
    textFieldBG.userInteractionEnabled = YES;
    textFieldBG.opaque = YES;
    textFieldBG.tag = 7771;
    
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(13, 6, textFieldBG.frame.size.width - 11, 24)];
    textField.textColor  = [UIColor whiteColor];
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    textField.returnKeyType = UIReturnKeyDone;
    textField.tag = 7772;
    textField.delegate = self;
    
    UILabel *placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(13, 6, textFieldBG.frame.size.width - 11, 24)];
    placeholderLabel.backgroundColor = [UIColor clearColor];
    placeholderLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:MAIN_FONT_SIZE];
    placeholderLabel.numberOfLines = 1;
    placeholderLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    placeholderLabel.text = [NSString stringWithFormat:@"%@ %@", [bubble.metadata objectForKey:@"name_first"], [bubble.metadata objectForKey:@"name_last"]];
    placeholderLabel.opaque = YES;
    placeholderLabel.tag = 7773;
    
    NSString *currentAlias = [bubble.metadata objectForKey:@"alias"];
    
    if ( currentAlias.length > 0 )
    {
        textField.text = currentAlias;
        placeholderLabel.hidden = YES;
    }
    
    [textFieldBG addSubview:textField];
    [textFieldBG addSubview:placeholderLabel];
    [renamingOverlay addSubview:textFieldBG];
    [renamingOverlay addSubview:placeholderBubble];
    [self.view addSubview:renamingOverlay];
    
    [self disableCompositionLayerScrolling];
    
    _isRenamingContact = YES;
    _cloudCenterButton.hidden = YES;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        _activeRecipientBubble.frame = CGRectMake(appDelegate.screenBounds.size.width + _activeRecipientBubble.frame.size.width, _activeRecipientBubble.frame.origin.y, _activeRecipientBubble.frame.size.width, _activeRecipientBubble.frame.size.height);
        _SHMiniFeedContainer.frame = CGRectMake(_SHMiniFeedContainer.frame.origin.x, _SHMiniFeedContainer.frame.origin.y + 30, _SHMiniFeedContainer.frame.size.width, _SHMiniFeedContainer.frame.size.height);
        
        searchCancelButton.alpha = 0.0;
        _SHMiniFeedContainer.alpha = 0.0;
        _contactCloud.alpha = 0.0;
        _searchButton.alpha = 0.0;
        _createBoardButton.alpha = 0.0;
        _refreshButton.alpha = 0.0;
        _cloudCenterButton.alpha = 0.0;
        _unreadBadgeButton.alpha = 0.0;
        renamingOverlay.alpha = 1.0;
    } completion:^(BOOL finished){
        searchCancelButton.hidden = YES;
        _searchButton.hidden = YES;
        _contactCloud.hidden = YES;
        
        [textField becomeFirstResponder];
    }];
    
    [self hideMainWindowSide];
}

- (void)dismissRenamingInterface
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( appDelegate.activeWindow )
    {
        [self enableCompositionLayerScrolling];
    }
    
    UIView *renamingOverlay = [self.view viewWithTag:777];
    UITextField *textField = (UITextField *)[renamingOverlay viewWithTag:7772];
    
    [_contactCloud renameBubble:textField.text forUser:[activeBubble.metadata objectForKey:@"user_id"]];
    
    _isRenamingContact = NO;
    _searchButton.hidden = NO;
    _contactCloud.hidden = NO;
    _SHMiniFeedContainer.hidden = NO;
    _cloudCenterButton.hidden = NO;
    
    if ( isShowingSearchInterface )
    {
        searchCancelButton.hidden = NO;
    }
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        if ( !isShowingSearchInterface )
        {
            _activeRecipientBubble.frame = CGRectMake(appDelegate.screenBounds.size.width - 90, _activeRecipientBubble.frame.origin.y, _activeRecipientBubble.frame.size.width, _activeRecipientBubble.frame.size.height);
            _SHMiniFeedContainer.frame = CGRectMake(_SHMiniFeedContainer.frame.origin.x, 20 + appDelegate.screenBounds.size.height / 2, _SHMiniFeedContainer.frame.size.width, _SHMiniFeedContainer.frame.size.height);
            _SHMiniFeedContainer.alpha = 1.0;
        }
        
        if ( isShowingSearchInterface )
        {
            searchCancelButton.alpha = 1.0;
        }
        
        _contactCloud.alpha = 1.0;
        _searchButton.alpha = 1.0;
        _createBoardButton.alpha = 1.0;
        _refreshButton.alpha = 1.0;
        _cloudCenterButton.alpha = 1.0;
        _unreadBadgeButton.alpha = 1.0;
        renamingOverlay.alpha = 0.0;
    } completion:^(BOOL finished){
        [renamingOverlay removeFromSuperview];
        
        activeBubble = nil; // Reset this.
    }];
    
    [self showMainWindowSide];
}

- (void)showSearchInterface
{
    if ( !isShowingSearchInterface )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        searchBox.hidden = NO;
        searchCancelButton.hidden = NO;
        
        [searchBox becomeFirstResponder];
        [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionFullScreen];
        [self hideMainWindowSide];
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            searchCancelButton.alpha = 1.0;
            searchBox.alpha = 1.0;
            _createBoardButton.alpha = 0.0;
            _refreshButton.alpha = 0.0;
            _mainWindowContainer.alpha = 0.0;
            _SHMiniFeedContainer.alpha = 0.0;
            
            _contactCloud.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height);
            _searchButton.frame = CGRectMake(_searchButton.frame.origin.x, 10, appDelegate.screenBounds.size.width - searchCancelButton.frame.size.width - (_searchButton.frame.origin.x * 2), _searchButton.frame.size.height);
            searchCancelButton.frame = CGRectMake(appDelegate.screenBounds.size.width - searchCancelButton.frame.size.width - _searchButton.frame.origin.x + 5, 10, searchCancelButton.frame.size.width, searchCancelButton.frame.size.height);
            _cloudCenterButton.frame = CGRectMake(_cloudCenterButton.frame.origin.x, appDelegate.screenBounds.size.height - 45, _cloudCenterButton.frame.size.width, _cloudCenterButton.frame.size.height);
            _unreadBadgeButton.frame = CGRectMake(appDelegate.screenBounds.size.width - 45, appDelegate.screenBounds.size.height - _unreadBadgeButton.frame.size.width - 10, _unreadBadgeButton.frame.size.width, _unreadBadgeButton.frame.size.height);
            
            _activeRecipientBubble.frame = CGRectMake(appDelegate.screenBounds.size.width + _activeRecipientBubble.frame.size.width, _activeRecipientBubble.frame.origin.y, _activeRecipientBubble.frame.size.width, _activeRecipientBubble.frame.size.height);
            _SHMiniFeedContainer.frame = CGRectMake(_SHMiniFeedContainer.frame.origin.x, _SHMiniFeedContainer.frame.origin.y + 30, _SHMiniFeedContainer.frame.size.width, _SHMiniFeedContainer.frame.size.height);
            maskLayer_ContactCloud.bounds = CGRectMake(0, 0, _contactCloud.frame.size.width, _contactCloud.frame.size.height);
        } completion:^(BOOL finished){
            _mainWindowContainer.hidden = YES;
            _SHMiniFeedContainer.hidden = YES;
            
            isShowingSearchInterface = YES;
            
            [self setMaxMinZoomScalesForChatCloudBounds];
            [_contactCloud jumpToCenter];
        }];
    }
}

- (void)dismissSearchInterface
{
    if ( isShowingSearchInterface )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        [searchBox resignFirstResponder];
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
        _mainWindowContainer.hidden = NO;
        _SHMiniFeedContainer.hidden = NO;
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            searchCancelButton.alpha = 0.0;
            searchBox.alpha = 0.0;
            _createBoardButton.alpha = 1.0;
            _refreshButton.alpha = 1.0;
            _mainWindowContainer.alpha = 1.0;
            _SHMiniFeedContainer.alpha = 1.0;
            _contactCloud.cloudContainer.alpha = 1.0;
            _contactCloud.cloudSearchResultsContainer.alpha = 0.0;
            
            _contactCloud.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, 20 + appDelegate.screenBounds.size.height / 2);
            _cloudCenterButton.frame = CGRectMake(10, appDelegate.screenBounds.size.height / 2 - 25, _cloudCenterButton.frame.size.width, _cloudCenterButton.frame.size.height);
            _unreadBadgeButton.frame = CGRectMake(appDelegate.screenBounds.size.width - _unreadBadgeButton.frame.size.width - 20, appDelegate.screenBounds.size.height / 2 - 25, _unreadBadgeButton.frame.size.width, _unreadBadgeButton.frame.size.height);
            _searchButton.frame = CGRectMake(_searchButton.frame.origin.x, 30, 35, _searchButton.frame.size.height);
            searchCancelButton.frame = CGRectMake(250, 30, searchCancelButton.frame.size.width, searchCancelButton.frame.size.height);
            _activeRecipientBubble.frame = CGRectMake(appDelegate.screenBounds.size.width - 90, _activeRecipientBubble.frame.origin.y, _activeRecipientBubble.frame.size.width, _activeRecipientBubble.frame.size.height);
            _SHMiniFeedContainer.frame = CGRectMake(_SHMiniFeedContainer.frame.origin.x, 20 + appDelegate.screenBounds.size.height / 2, _SHMiniFeedContainer.frame.size.width, _SHMiniFeedContainer.frame.size.height);
            
            _SHMiniFeedContainer.alpha = 1.0;
            
            maskLayer_ContactCloud.bounds = CGRectMake(0, 0, _contactCloud.frame.size.width, _contactCloud.frame.size.height);
        } completion:^(BOOL finished){
            _contactCloud.isInSearchMode = NO;
            isShowingSearchInterface = NO;
            searchBox.hidden = YES;
            searchCancelButton.hidden = YES;
            _contactCloud.cloudContainer.hidden = NO;
            
            searchBox.text = @"";
            
            [_contactCloud.searchResultsBubbles removeAllObjects];
            [self setMaxMinZoomScalesForChatCloudBounds];
            [_contactCloud jumpToCenter];
        }];
    }
}

- (void)showChatCloudCenterJumpButton
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

- (void)dismissChatCloudCenterJumpButton
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

- (void)searchChatCloudForQuery:(NSString *)query
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

- (void)showEmptyCloud
{
    inviteButton.hidden = NO;
    contactCloudInfoLabel.hidden = NO;
    contactCloudInfoLabel.text = NSLocalizedString(@"CHAT_CLOUD_EMPTY", nil);
}

- (void)jumpToChatCloudCenter
{
    [_contactCloud jumpToCenter];
}

- (void)updateUnreadBadge:(int)count
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    __block int number = count;
    
    if ( count == -1 )
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
            [queue inDatabase:^(FMDatabase *db) {
                FMResultSet *s1 = [db executeQuery:@"SELECT COUNT(*) FROM sh_cloud WHERE unread_thread_count > 0 AND hidden = 0"
                           withParameterDictionary:nil];
                
                while ( [s1 next] )
                {
                    number = [s1 intForColumnIndex:0];
                }
                
                [s1 close];
                
                NSString *countText = [NSString stringWithFormat:@"%d", number];
                
                if ( number > 99 )
                {
                    countText = @"99+";
                }
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [_unreadBadgeButton setTitle:countText forState:UIControlStateNormal];
                    
                    if ( number == 0 )
                    {
                        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                            _unreadBadgeButton.alpha = 0.0;
                        } completion:^(BOOL finished){
                            _unreadBadgeButton.hidden = YES;
                        }];
                    }
                    else
                    {
                        _unreadBadgeButton.hidden = NO;
                        
                        if ( _windowCompositionLayer.contentOffset.x <= 0 )
                        {
                            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                                _unreadBadgeButton.alpha = 1.0;
                            } completion:^(BOOL finished){
                                
                            }];
                        }
                    }
                    
                    CGSize textSize_count = [countText sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:MIN_MAIN_FONT_SIZE] constrainedToSize:CGSizeMake(50, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
                    
                    float width = MAX(textSize_count.width + 15, 35);
                    _unreadBadgeButton.frame = CGRectMake(appDelegate.screenBounds.size.width - width - 20, _unreadBadgeButton.frame.origin.y, width, _unreadBadgeButton.frame.size.height);
                });
            }];
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            NSString *countText = [NSString stringWithFormat:@"%d", number];
            
            if ( number > 99 )
            {
                countText = @"99+";
            }
            
            [_unreadBadgeButton setTitle:countText forState:UIControlStateNormal];
            
            if ( number == 0 )
            {
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    _unreadBadgeButton.alpha = 0.0;
                } completion:^(BOOL finished){
                    _unreadBadgeButton.hidden = YES;
                }];
            }
            else
            {
                _unreadBadgeButton.hidden = NO;
                
                if ( _windowCompositionLayer.contentOffset.x <= 0 )
                {
                    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                        _unreadBadgeButton.alpha = 1.0;
                    } completion:^(BOOL finished){
                        
                    }];
                }
            }
            
            CGSize textSize_count = [countText sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:MIN_MAIN_FONT_SIZE] constrainedToSize:CGSizeMake(50, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
            
            float width = MAX(textSize_count.width + 15, 35);
            _unreadBadgeButton.frame = CGRectMake(appDelegate.screenBounds.size.width - width - 20, _unreadBadgeButton.frame.origin.y, width, _unreadBadgeButton.frame.size.height);
        });
    }
}

- (void)addBubbleToUnreadQueue:(SHChatBubble *)bubble
{
    int userID = [[bubble.metadata objectForKey:@"user_id"] intValue];
    
    SHChatBubble *dummyCopy = [[SHChatBubble alloc] initWithFrame:CGRectMake([[bubble.metadata objectForKey:@"coordinate_x"] intValue], [[bubble.metadata objectForKey:@"coordinate_y"] intValue], bubble.frame.size.width, bubble.frame.size.height)];
    [dummyCopy setMetadata:[bubble.metadata mutableCopy]];
    [dummyCopy.metadata setObject:@"" forKey:@"dp"]; // Reduce memory overhead.
    [dummyCopy.metadata setObject:@"" forKey:@"alais_dp"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( SHChatBubble *unreadBubble in _unreadThreadBubbles )
        {
            int targetUserID = [[unreadBubble.metadata objectForKey:@"user_id"] intValue];
            
            if ( userID == targetUserID ) // Already in queue.
            {
                return;
            }
        }
        
        [_unreadThreadBubbles addObject:dummyCopy];
    });
}

- (void)removeBubbleWithUserIDFromUnreadQueue:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [db executeUpdate:@"UPDATE sh_cloud "
                                @"SET unread_thread_count = 0 "
                                @"WHERE sh_user_id = :user_id"
                    withParameterDictionary:@{@"user_id": userID}];
        }];
        
        [appDelegate.messageManager updateUnreadThreadCount];
        
        int activeRecipientBubbleID = [[_activeRecipientBubble.metadata objectForKey:@"unread_thread_count"] intValue];
        
        if ( activeRecipientBubbleID == userID.intValue && _windowCompositionLayer.contentOffset.x != 0 ) // If the existing active chat is with this user & the menu is shown, don't hide the badge.
        {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [_activeRecipientBubble setBadgeCount:0]; // Reset this.
            });
        }
        
        for ( int i = 0; i < _unreadThreadBubbles.count; i++ )
        {
            SHChatBubble *targetBubble = [_unreadThreadBubbles objectAtIndex:i];
            int targetUserID = [[targetBubble.metadata objectForKey:@"user_id"] intValue];
            int bubbleUserID = userID.intValue;
            
            if ( targetUserID == bubbleUserID )
            {
                [_unreadThreadBubbles removeObjectAtIndex:i];
                
                break;
            }
        }
    });
}

- (void)cycleUnreadThreads
{
    [_contactCloud gotoCellForBubble:[_unreadThreadBubbles objectAtIndex:currentUnreadBadgeCycle] animated:YES];
    
    if ( currentUnreadBadgeCycle == _unreadThreadBubbles.count - 1 )
    {
        currentUnreadBadgeCycle = 0; // Loop back.
    }
    else
    {
        currentUnreadBadgeCycle++;
    }
}

- (void)slideUIForWindow
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( appDelegate.activeWindow == SHAppWindowTypeMessages )
    {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            settingsButton.frame = CGRectMake(appDelegate.screenBounds.size.width - settingsButton.frame.size.width - 60, settingsButton.frame.origin.y, settingsButton.frame.size.width, settingsButton.frame.size.height);
            _refreshButton.alpha = 0.0;
        } completion:^(BOOL finished){
            _refreshButton.hidden = YES;
        }];
    }
    else
    {
        _refreshButton.hidden = NO;
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            settingsButton.frame = CGRectMake(appDelegate.screenBounds.size.width - settingsButton.frame.size.width - 20, settingsButton.frame.origin.y, settingsButton.frame.size.width, settingsButton.frame.size.height);
            _refreshButton.alpha = 1.0;
        } completion:^(BOOL finished){
            
        }];
    }
}

- (void)loadConversationForUser:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [self removeBubbleWithUserIDFromUnreadQueue:userID];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( SHChatBubble *bubble in _contactCloud.cloudBubbles )
        {
            int targetUserID = [[bubble.metadata objectForKey:@"user_id"] intValue];
            
            if ( userID.intValue == targetUserID )
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [bubble setBadgeCount:0];
                    [bubble hideMessagePreview];
                    [bubble hideTypingIndicator];
                    
                    // Animate the bubble out of the view.
                    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                        bubble.transform = CGAffineTransformMakeScale(1.5, 1.5);
                    } completion:^(BOOL finished){
                        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                            bubble.transform = CGAffineTransformIdentity;
                        } completion:^(BOOL finished){
                            
                        }];
                    }];
                    
                    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        bubble.alpha = 0.0;
                    } completion:^(BOOL finished){
                        bubble.hidden = YES;
                    }];
                });
                
                // Restore the bubble of the previous conversation window.
                if ( _activeRecipientBubble.metadata )
                {
                    NSMutableDictionary *metadata = _activeRecipientBubble.metadata; // Save a copy in case it gets overwritten.
                    
                    for ( SHChatBubble *theBubble in _contactCloud.cloudBubbles )
                    {
                        int activeBubbleUserID = [[metadata objectForKey:@"user_id"] intValue];
                        int targetBubbleUserID = [[theBubble.metadata objectForKey:@"user_id"] intValue];
                        
                        if ( targetBubbleUserID == activeBubbleUserID )
                        {
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                theBubble.hidden = NO;
                                
                                [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                                    theBubble.alpha = 1.0;
                                } completion:^(BOOL finished){
                                    
                                }];
                            });
                            
                            break;
                        }
                    }
                }
                
                break;
            }
        }
    });
    
    [_messagesView setAdHocMode:NO withOriginalRecipients:nil];
    [_messagesView clearViewAnimated:NO];
    [_messagesView setRecipientDataForUser:userID];
    _messagesView.recipientID = userID; // Just to be on the safe side (threading mess).
    [self pushWindow:SHAppWindowTypeMessages];
    
    long double delayInSeconds = 0.18;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [_messagesView loadMessagesForRecipient];
        [appDelegate.contactManager incrementViewCountForUser:userID];
    });
    
    if ( _activeRecipientBubble.hidden )
    {
        _activeRecipientBubble.hidden = NO;
        _mainWindowNipple.hidden = NO;
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            _activeRecipientBubble.alpha = 1.0;
            _mainWindowNipple.alpha = 1.0;
        } completion:^(BOOL finished){
            
        }];
    }
}

#pragma mark -
#pragma mark Media Picker

- (void)showMediaPicker_Camera
{
    _mediaPickerSourceIsCamera = YES;
    photoPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    photoPicker.modalPresentationStyle = UIModalPresentationFullScreen;
    
    if ( _isPickingAliasDP || _isPickingDP )
    {
        //photoPicker.mediaTypes = @[(NSString *)kUTTypeImage];
        photoPicker.allowsEditing = YES;
    }
    else
    {
        //photoPicker.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
        photoPicker.allowsEditing = NO;
    }
    
    [self presentViewController:photoPicker animated:YES completion:NULL];
}

- (void)showMediaPicker_Library
{
    _mediaPickerSourceIsCamera = NO;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    if ( _isPickingAliasDP || _isPickingDP )
    {
        //photoPicker.mediaTypes = @[(NSString *)kUTTypeImage];
        photoPicker.allowsEditing = YES;
    }
    else
    {
        //photoPicker.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
        photoPicker.allowsEditing = NO;
    }
    
    photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:photoPicker animated:YES completion:NULL];
}

- (void)dismissMediaPicker
{
    [photoPicker dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark -
#pragma mark Contact Management

- (void)confirmContactDeletion
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"CONFIRMATION_DELETE_CONTACT", nil), [activeBubble.metadata objectForKey:@"name_first"], [activeBubble.metadata objectForKey:@"name_last"]]
                                                             delegate:self
                                                    cancelButtonTitle:[NSString stringWithFormat:NSLocalizedString(@"GENERIC_CANCEL", nil)]
                                               destructiveButtonTitle:[NSString stringWithFormat:NSLocalizedString(@"OPTION_DELETE_CONTACT", nil)]
                                                    otherButtonTitles:nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.tag = 1;
    [actionSheet showFromRect:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44) inView:appDelegate.window animated:YES];
}

- (void)confirmHistoryDeletion
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"CONFIRMATION_DELETE_HISTORY", nil), [activeBubble.metadata objectForKey:@"name_first"], [activeBubble.metadata objectForKey:@"name_last"]]
                                                             delegate:self
                                                    cancelButtonTitle:[NSString stringWithFormat:NSLocalizedString(@"GENERIC_CANCEL", nil)]
                                               destructiveButtonTitle:[NSString stringWithFormat:NSLocalizedString(@"OPTION_DELETE_HISTORY", nil)]
                                                    otherButtonTitles:nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.tag = 2;
    [actionSheet showFromRect:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44) inView:appDelegate.window animated:YES];
}

#pragma mark -
#pragma mark Contacts & Boards

- (void)loadCloud
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [_unreadThreadBubbles removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_contactCloud beginUpdates];
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id <> :current_user_id AND temp = 0 AND hidden = 0"
                       withParameterDictionary:@{@"current_user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
            
            // Read & store each contact's data.
            // NOOOOTE: Some of this data gets overwritten/updated by the contact manager once it refreshes the contacts.
            while ( [s1 next] )
            {
                NSString *alias = [s1 stringForColumn:@"alias"];
                NSString *lastViewTimestamp = [s1 stringForColumn:@"last_view_timestamp"];
                NSString *lastMessageTimestamp = [s1 stringForColumn:@"last_message_timestamp"];
                NSData *DP = [s1 dataForColumn:@"dp"];
                id aliasDP = [s1 dataForColumn:@"alias_dp"];
                
                if ( !alias )
                {
                    alias = @"";
                }
                
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
                
                if ( !aliasDP )
                {
                    aliasDP = @"";
                }
                
                NSMutableDictionary *contactData = [[NSMutableDictionary alloc] initWithObjects:@[[NSString stringWithFormat:@"%d", SHChatBubbleTypeUser],
                                                                                                  [s1 stringForColumn:@"sh_user_id"],
                                                                                                  [s1 stringForColumn:@"name_first"],
                                                                                                  [s1 stringForColumn:@"name_last"],
                                                                                                  alias,
                                                                                                  [s1 stringForColumn:@"user_handle"],
                                                                                                  [s1 stringForColumn:@"blocked"],
                                                                                                  [s1 stringForColumn:@"dp_hash"],
                                                                                                  DP,
                                                                                                  aliasDP,
                                                                                                  [s1 stringForColumn:@"email_address"],
                                                                                                  [s1 stringForColumn:@"gender"],
                                                                                                  [s1 stringForColumn:@"birthday"],
                                                                                                  [s1 stringForColumn:@"location_country"],
                                                                                                  [s1 stringForColumn:@"location_state"],
                                                                                                  [s1 stringForColumn:@"location_city"],
                                                                                                  [s1 stringForColumn:@"website"],
                                                                                                  [s1 stringForColumn:@"bio"],
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
                                                                                        forKeys:@[@"bubble_type",
                                                                                                  @"user_id",
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
                    FMResultSet *s2 = [db executeQuery:@"SELECT * FROM sh_phone_numbers WHERE sh_user_id = :user_id"
                               withParameterDictionary:@{@"user_id": [contactData objectForKey:@"user_id"]}];
                    
                    NSMutableArray *phoneNumbers = [NSMutableArray array];
                    
                    while ( [s2 next] )
                    {
                        NSDictionary *phoneNumberPack = @{@"country_calling_code": [s2 stringForColumn:@"country_calling_code"],
                                                          @"prefix": [s2 stringForColumn:@"prefix"],
                                                          @"phone_number": [s2 stringForColumn:@"phone_number"]};
                        
                        [phoneNumbers addObject:phoneNumberPack];
                    }
                    
                    [contactData setObject:phoneNumbers forKey:@"phone_numbers"];
                    
                    [s2 close];
                    
                    s2 = [db executeQuery:@"SELECT * FROM sh_user_online_status WHERE user_id = :user_id"
                            withParameterDictionary:@{@"user_id": [contactData objectForKey:@"user_id"]}];
                    
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
                    [bubble setBubbleMetadata:contactData];
                    [bubble setBadgeCount:[[contactData objectForKey:@"unread_thread_count"] intValue]];
                    [bubble setBlocked:[[contactData objectForKey:@"blocked"] boolValue]];
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [_contactCloud insertBubble:bubble atPoint:CGPointMake([[contactData objectForKey:@"coordinate_x"] intValue], [[contactData objectForKey:@"coordinate_y"] intValue]) animated:YES];
                        
                        if ( [[contactData objectForKey:@"unread_thread_count"] intValue] > 0 )
                        {
                            [self addBubbleToUnreadQueue:bubble];
                        }
                    });
                    
                    // It's possible that by the time this runs a conversation is already loaded via push notifs, so hide the bubble in that case.
                    if ( [[contactData objectForKey:@"user_id"] intValue] == _messagesView.recipientID.intValue )
                    {
                        bubble.alpha = 0.0;
                        bubble.hidden = YES;
                    }
                });
            }
            
            s1 = [db executeQuery:@"SELECT * FROM sh_board"
                        withParameterDictionary:nil];
            
            // Read & store each board's data.
            while ( [s1 next] )
            {
                NSString *lastViewTimestamp = [s1 stringForColumn:@"last_view_timestamp"];
                NSData *DP = [s1 dataForColumn:@"dp"];
                
                if ( !lastViewTimestamp )
                {
                    lastViewTimestamp = @"";
                }
                
                if ( !DP )
                {
                    DP = UIImageJPEGRepresentation([UIImage imageNamed:@"board_placeholder"], 1.0);
                }
                
                NSMutableDictionary *boardData = [[NSMutableDictionary alloc] initWithObjects:@[[NSString stringWithFormat:@"%d", SHChatBubbleTypeBoard],
                                                                                                [s1 stringForColumn:@"board_id"],
                                                                                                [s1 stringForColumn:@"name"],
                                                                                                [s1 stringForColumn:@"description"],
                                                                                                [s1 stringForColumn:@"privacy"],
                                                                                                [s1 stringForColumn:@"cover_hash"],
                                                                                                DP,
                                                                                                [s1 stringForColumn:@"date_created"],
                                                                                                [s1 stringForColumn:@"view_count"],
                                                                                                lastViewTimestamp,
                                                                                                [s1 stringForColumn:@"coordinate_x"],
                                                                                                [s1 stringForColumn:@"coordinate_y"],
                                                                                                [s1 stringForColumn:@"rank_score"]]
                                                                                      forKeys:@[@"bubble_type",
                                                                                                @"board_id",
                                                                                                @"name",
                                                                                                @"description",
                                                                                                @"privacy",
                                                                                                @"cover_hash",
                                                                                                @"dp",
                                                                                                @"date_created",
                                                                                                @"view_count",
                                                                                                @"last_view_timestamp",
                                                                                                @"coordinate_x",
                                                                                                @"coordinate_y",
                                                                                                @"rank_score"]];
                
                UIImage *currentDP = [UIImage imageWithData:[boardData objectForKey:@"dp"]];
                
                // Give it a slight delay here to achieve a nice animation effect.
                long double delayInSeconds = 1.0;
                
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    SHChatBubble *bubble = [[SHChatBubble alloc] initWithFrame:CGRectMake(0, 0, CHAT_CLOUD_BUBBLE_SIZE, CHAT_CLOUD_BUBBLE_SIZE) andImage:currentDP withMiniModeEnabled:NO];
                    [bubble setBubbleMetadata:boardData];
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [_contactCloud insertBubble:bubble atPoint:CGPointMake([[boardData objectForKey:@"coordinate_x"] intValue], [[boardData objectForKey:@"coordinate_y"] intValue]) animated:YES];
                    });
                });
            }
            
            [s1 close]; // Very important that you close this!
            
            long double delayInSeconds = 1.2; // Slightly longer than the delay to insert the first bubble.
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if ( _contactCloud.cloudBubbles.count == 0 )
                {
                    inviteButton.hidden = NO;
                    contactCloudInfoLabel.hidden = NO;
                    contactCloudInfoLabel.text = NSLocalizedString(@"CHAT_CLOUD_EMPTY", nil);
                }
                else
                {
                    inviteButton.hidden = YES;
                    contactCloudInfoLabel.hidden = YES;
                }
                
                [_contactCloud endUpdates];
                
                [self setMaxMinZoomScalesForChatCloudBounds];
                
                // Center the cloud's offset.
                CGFloat centerOffset_x = (_contactCloud.contentSize.width / 2) - (_contactCloud.bounds.size.width / 2);
                CGFloat centerOffset_y = (_contactCloud.contentSize.height / 2) - (_contactCloud.bounds.size.height / 2);
                [_contactCloud setContentOffset:CGPointMake(centerOffset_x, centerOffset_y) animated:YES];
            });
        }];
    });
    
    _contactCloud.transform = CGAffineTransformMakeScale(2.0, 2.0);
    
    [UIView animateWithDuration:0.37 delay:1.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _contactCloud.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        // Clear the bubble data.
        
    }];
}

- (void)refreshContacts
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    appDelegate.contactManager.delegate = self;
    
    if ( appDelegate.preference_UseAddressBook )
    {
        [appDelegate.contactManager requestAddressBookAccess];
    }
    else
    {
        [appDelegate.contactManager fetchAddressBookContacts];
    }
}

- (void)refreshCloud
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    _refreshButton.enabled = NO;
    
    if ( appDelegate.preference_UseBluetooth )
    {
        // Restart BT services.
        [appDelegate.peerManager stopAdvertising];
        [appDelegate.peerManager stopScanning];
        [appDelegate.peerManager startAdvertising];
        [appDelegate.peerManager startScanning];
    }
    
    [appDelegate.contactManager requestRecommendationListForced:YES];
}

- (void)removeBoard:(NSString *)boardID
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( int i = 0; i < _contactCloud.cloudBubbles.count; i++ )
        {
            SHChatBubble *bubble = [_contactCloud.cloudBubbles objectAtIndex:i];
            
            if ( bubble.bubbleType == SHChatBubbleTypeBoard )
            {
                int bubbleID = [[bubble.metadata objectForKey:@"board_id"] intValue];
                
                if ( bubbleID == boardID.intValue )
                {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [_contactCloud removeBubble:bubble permanently:YES animated:YES];
                    });
                    
                    [_contactCloud.cloudBubbles removeObjectAtIndex:i];
                    
                    break;
                }
            }
        }
        
        if ( _contactCloud.cloudBubbles.count == 0 )
        {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self showEmptyCloud];
            });
        }
    });
}

- (void)hideContact:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight activateStrobeLight];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[userID]
                                                                          forKeys:@[@"user_id"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/deleteuser", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                [appDelegate.strobeLight deactivateStrobeLight];
                [_contactCloud removeBubble:activeBubble permanently:YES animated:YES];
                activeBubble = nil;
                
                [appDelegate.modelManager executeUpdate:@"UPDATE sh_cloud "
                 @"SET hidden = 1 WHERE sh_user_id = :user_id"
                                withParameterDictionary:@{@"user_id": userID}];
                
                // Clean up.
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    for ( int i = 0; i < appDelegate.contactManager.allContacts.count; i++ )
                    {
                        NSMutableDictionary *contact = [appDelegate.contactManager.allContacts objectAtIndex:i];
                        int targetID = [[contact objectForKey:@"user_id"] intValue];
                        
                        if ( userID.intValue == targetID )
                        {
                            [appDelegate.contactManager.allContacts removeObjectAtIndex:i];
                            appDelegate.contactManager.contactCount--;
                            
                            break;
                        }
                    }
                    
                    for ( int i = 0; i < _SHMiniFeedEntries.count; i++ )
                    {
                        NSMutableDictionary *entry = [_SHMiniFeedEntries objectAtIndex:i];
                        int entryType = [[entry objectForKey:@"entry_type"] intValue];
                        
                        if ( entryType == 1 )
                        {
                            int targetID = [[entry objectForKey:@"user_id"] intValue];
                            
                            if ( userID.intValue == targetID )
                            {
                                [_SHMiniFeedEntries removeObjectAtIndex:i];
                                i--; // Backtrack!
                            }
                        }
                        else
                        {
                            NSMutableArray *originalParticipantData = [entry objectForKey:@"original_participant_data"];
                            NSMutableDictionary *participant_1 = [originalParticipantData objectAtIndex:0];
                            NSMutableDictionary *participant_2 = [originalParticipantData objectAtIndex:1];
                            int participantID_1 = [[participant_1 objectForKey:@"user_id"] intValue];
                            int participantID_2 = [[participant_2 objectForKey:@"user_id"] intValue];
                            
                            if ( userID.intValue == participantID_1 || userID.intValue == participantID_2 )
                            {
                                [_SHMiniFeedEntries removeObjectAtIndex:i];
                                i--;
                            }
                        }
                    }
                    
                    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
                    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                        [appDelegate.contactManager processNewContactsWithDB:db];
                    }];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [_SHMiniFeed reloadData];
                    });
                });
            }
        }
        else // Some error occurred...
        {
            [appDelegate.strobeLight negativeStrobeLight];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [appDelegate.strobeLight negativeStrobeLight];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

#pragma mark -
#pragma mark Mini Feed

// Scroll to the top of the Mini Feed when the user taps the feed header.
- (void)scrollToTopOfMiniFeed
{
    [_SHMiniFeed scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)downloadMiniFeed
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    _miniFeedDidFinishDownloading = NO;
    [_SHMiniFeed reloadData];
    
    if ( batchNumber == 0 )
    {
        [SHMiniFeedrefreshControl beginRefreshing];
    }
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[[NSNumber numberWithInt:batchNumber]]
                                                                          forKeys:@[@"batch"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/downloadminifeed", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        if ( responseData )
        {
            NSLog(@"Fetched feed!");
            
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            miniFeedRefreshDidFailOnScroll = NO;
            _miniFeedDidFinishDownloading = YES;
            _didDownloadInitialFeed = YES;
            
            [SHMiniFeedrefreshControl endRefreshing];
            
            if ( errorCode == 0 )
            {
                [_SHMiniFeed beginUpdates];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    @synchronized( _SHMiniFeedEntries )
                    {
                        NSMutableArray *freshEntries = [[responseData objectForKey:@"response"] mutableCopy];
                        NSMutableArray *freshPostIndexPaths = [NSMutableArray array]; // Use a set to ensure unique values.
                        NSMutableArray *stalePostIndexPaths = [NSMutableArray array];
                        
                        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
                        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                            if ( batchNumber == 0 )
                            {
                                int i_table = 0; // The table needs its own immutable counter.
                                
                                for ( int i = 0; i < _SHMiniFeedEntries.count; i++ )
                                {
                                    NSMutableDictionary *entry = [[_SHMiniFeedEntries objectAtIndex:i] mutableCopy];
                                    int entryType = [[entry objectForKey:@"entry_type"] intValue];
                                    int statusID = [[entry objectForKey:@"thread_id"] intValue];
                                    int matchIndex = -1;
                                    
                                    if ( entryType != 1 ) // Ad hoc entry.
                                    {
                                        continue;
                                    }
                                    
                                    // First, we clean out stories that are no longer visible in the feed.
                                    for ( int j = 0; j < freshEntries.count; j++ )
                                    {
                                        NSDictionary *targetEntry = [freshEntries objectAtIndex:j];
                                        int targetStatusID = [[targetEntry objectForKey:@"thread_id"] intValue];
                                        
                                        // Don't insert the entry if it's from a muted user.
                                        FMResultSet *s2 = [db executeQuery:@"SELECT * FROM sh_muted WHERE user_id = :user_id"
                                                   withParameterDictionary:@{@"user_id": [targetEntry objectForKey:@"owner_id"]}];
                                        
                                        BOOL userIsMuted = NO;
                                        
                                        while ( [s2 next] )
                                        {
                                            userIsMuted = YES;
                                        }
                                        
                                        [s2 close];
                                        
                                        if ( userIsMuted )
                                        {
                                            [freshEntries removeObjectAtIndex:matchIndex];
                                            j--; // Backtrack to make up for the removed element!
                                            
                                            continue;
                                        }
                                        
                                        if ( targetStatusID == statusID )
                                        {
                                            matchIndex = j;
                                            [freshEntries removeObjectAtIndex:matchIndex];
                                            j--; // Backtrack to make up for the removed element!
                                            
                                            // Now update the rest of the person's info.
                                            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :user_id"
                                                       withParameterDictionary:@{@"user_id": [entry objectForKey:@"owner_id"]}];
                                            
                                            // Read & store each contact's data.
                                            while ( [s1 next] )
                                            {
                                                NSString *lastViewTimestamp = [s1 stringForColumn:@"last_view_timestamp"];
                                                NSString *lastMessageTimestamp = [s1 stringForColumn:@"last_message_timestamp"];
                                                NSData *DP = [s1 dataForColumn:@"dp"];
                                                id aliasDP = [s1 dataForColumn:@"alias_dp"];
                                                
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
                                                
                                                if ( !aliasDP )
                                                {
                                                    aliasDP = @"";
                                                }
                                                
                                                [entry setObject:[s1 stringForColumn:@"sh_user_id"] forKey:@"user_id"];
                                                [entry setObject:[s1 stringForColumn:@"name_first"] forKey:@"name_first"];
                                                [entry setObject:[s1 stringForColumn:@"name_last"] forKey:@"name_last"];
                                                [entry setObject:[s1 stringForColumn:@"alias"] forKey:@"alias"];
                                                [entry setObject:[s1 stringForColumn:@"user_handle"] forKey:@"user_handle"];
                                                [entry setObject:[s1 stringForColumn:@"dp_hash"] forKey:@"dp_hash"];
                                                [entry setObject:DP forKey:@"dp"];
                                                [entry setObject:aliasDP forKey:@"alias_dp"];
                                                [entry setObject:[s1 stringForColumn:@"email_address"] forKey:@"email_address"];
                                                [entry setObject:[s1 stringForColumn:@"gender"] forKey:@"gender"];
                                                [entry setObject:[s1 stringForColumn:@"birthday"] forKey:@"birthday"];
                                                [entry setObject:[s1 stringForColumn:@"location_country"] forKey:@"location_country"];
                                                [entry setObject:[s1 stringForColumn:@"location_state"] forKey:@"location_state"];
                                                [entry setObject:[s1 stringForColumn:@"location_city"] forKey:@"location_city"];
                                                [entry setObject:[s1 stringForColumn:@"website"] forKey:@"website"];
                                                [entry setObject:[s1 stringForColumn:@"bio"] forKey:@"bio"];
                                                [entry setObject:[s1 stringForColumn:@"last_status_id"] forKey:@"last_status_id"];
                                                [entry setObject:[s1 stringForColumn:@"total_messages_sent"] forKey:@"total_messages_sent"];
                                                [entry setObject:[s1 stringForColumn:@"total_messages_received"] forKey:@"total_messages_received"];
                                                [entry setObject:[s1 stringForColumn:@"unread_thread_count"] forKey:@"unread_thread_count"];
                                                [entry setObject:[s1 stringForColumn:@"view_count"] forKey:@"view_count"];
                                                [entry setObject:lastViewTimestamp forKey:@"last_view_timestamp"];
                                                [entry setObject:lastMessageTimestamp forKey:@"last_message_timestamp"];
                                                [entry setObject:[s1 stringForColumn:@"coordinate_x"] forKey:@"coordinate_x"];
                                                [entry setObject:[s1 stringForColumn:@"coordinate_y"] forKey:@"coordinate_y"];
                                                [entry setObject:[s1 stringForColumn:@"rank_score"] forKey:@"rank_score"];
                                                
                                                if ( entry.count > 0 )
                                                {
                                                    NSString *userID = [entry objectForKey:@"user_id"];
                                                    
                                                    FMResultSet *s2 = [db executeQuery:@"SELECT * FROM sh_phone_numbers WHERE sh_user_id = :sh_user_id"
                                                               withParameterDictionary:@{@"sh_user_id": userID}];
                                                    
                                                    while ( [s2 next] )
                                                    {
                                                        [entry setObject:[s2 stringForColumn:@"country_calling_code"] forKey:@"country_calling_code"];
                                                        [entry setObject:[s2 stringForColumn:@"prefix"] forKey:@"prefix"];
                                                        [entry setObject:[s2 stringForColumn:@"phone_number"] forKey:@"phone_number"];
                                                    }
                                                    
                                                    [s2 close];
                                                    
                                                    s2 = [db executeQuery:@"SELECT * FROM sh_user_online_status WHERE user_id = :sh_user_id"
                                                  withParameterDictionary:@{@"sh_user_id": userID}];
                                                    
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
                                                        
                                                        [entry setObject:presence forKey:@"presence"];
                                                        [entry setObject:presenceTargetID forKey:@"presence_target"];
                                                        [entry setObject:audience forKey:@"audience"];
                                                        [entry setObject:presenceTimestamp forKey:@"presence_timestamp"];
                                                    }
                                                    
                                                    [s2 close];
                                                }
                                            }
                                            
                                            [s1 close];
                                            
                                            [_SHMiniFeedEntries setObject:entry atIndexedSubscript:i];
                                            
                                            break;
                                        }
                                    }
                                    
                                    if ( matchIndex == -1 ) // No matches found in the current list. Delete the row.
                                    {
                                        [db executeUpdate:@"DELETE FROM sh_thread "
                                                            @"WHERE thread_type NOT IN (1, 8) AND thread_id = :thread_id AND thread_id <> :last_status_id AND thread_id <> :current_user_last_status_id"
                                            withParameterDictionary:@{@"thread_id": [NSNumber numberWithInt:statusID],
                                                                      @"last_status_id": [entry objectForKey:@"last_status_id"],
                                                                      @"current_user_last_status_id": [appDelegate.currentUser objectForKey:@"last_status_id"]}];
                                        
                                        [stalePostIndexPaths addObject:[NSIndexPath indexPathForRow:i_table inSection:0]];
                                        [_SHMiniFeedEntries removeObjectAtIndex:i];
                                        
                                        // Backtrack to make up for the removed element!
                                        i--;
                                    }
                                    
                                    i_table++;
                                }
                                
                                if ( stalePostIndexPaths.count > 0 )
                                {
                                    dispatch_async(dispatch_get_main_queue(), ^(void){
                                        [_SHMiniFeed deleteRowsAtIndexPaths:stalePostIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                                    });
                                }
                            }
                            
                            // Response was less than a full batch, we've reached the end of the feed.
                            if ( [[responseData objectForKey:@"response"] count] < FEED_BATCH_SIZE )
                            {
                                endOfMiniFeed = YES;
                            }
                            else
                            {
                                endOfMiniFeed = NO;
                            }
                            
                            // Next, find the rest of the user's data & insert the new stories.
                            // Start from the end to insert the oldest stories first.
                            for ( int i = (int)freshEntries.count - 1; i >= 0; i-- )
                            {
                                NSMutableDictionary *entry = [[freshEntries objectAtIndex:i] mutableCopy];
                                NSDictionary *mediaExtra = [NSJSONSerialization JSONObjectWithData:[[entry objectForKey:@"media_extra"] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
                                int userID = [[entry objectForKey:@"owner_id"] intValue];
                                int currentUserID = [[appDelegate.currentUser objectForKey:@"user_id"] intValue];
                                int statusID = [[entry objectForKey:@"thread_id"] intValue];
                                int currentUserLastStatusID = [[appDelegate.currentUser objectForKey:@"last_status_id"] intValue];
                                NSString *location_latitude = [entry objectForKey:@"location_latitude"];
                                NSString *location_longitude = [entry objectForKey:@"location_longitude"];
                                
                                if ( statusID == currentUserLastStatusID ) // The current user's current status is among the batch, so we can delete our old cached copy of it.
                                {
                                    [db executeUpdate:@"DELETE FROM sh_thread WHERE thread_id = :last_status_id"
                              withParameterDictionary:@{@"last_status_id": [appDelegate.currentUser objectForKey:@"last_status_id"]}];
                                }
                                
                                if ( [[NSNull null] isEqual:[entry objectForKey:@"location_latitude"]] )
                                {
                                    location_latitude = @"";
                                    location_longitude = @"";
                                    
                                    [entry setObject:location_latitude forKey:@"location_latitude"];
                                    [entry setObject:location_longitude forKey:@"location_longitude"];
                                }
                                
                                [entry setObject:@"1" forKey:@"entry_type"];
                                [entry setObject:@"" forKey:@"media_local_path"];
                                [entry setObject:@"" forKey:@"media_data"];
                                
                                NSData *mediaExtraData = [NSJSONSerialization dataWithJSONObject:mediaExtra options:NSJSONWritingPrettyPrinted error:nil];
                                [entry setObject:mediaExtraData forKey:@"media_extra"];
                                
                                [db executeUpdate:@"INSERT INTO sh_thread "
                                                    @"(thread_id, thread_type, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                                                    @"VALUES (:thread_id, :thread_type, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent,  :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                                    withParameterDictionary:entry];
                                
                                NSDictionary *targetUser;
                                
                                if ( userID == currentUserID ) // Check if this status belongs to the current user.
                                {
                                    targetUser = appDelegate.currentUser;
                                    
                                    [entry addEntriesFromDictionary:targetUser]; // Add the rest of the user's data.
                                }
                                else
                                {
                                    int threadType = [[entry objectForKey:@"thread_type"] intValue];
                                    
                                    if ( threadType == 2 || threadType == 3 || threadType == 4 )
                                    {
                                        [db executeUpdate:@"UPDATE sh_cloud SET last_status_id = :status_id WHERE sh_user_id = :user_id"
                                  withParameterDictionary:@{@"status_id": [entry objectForKey:@"thread_id"],
                                                            @"user_id": [entry objectForKey:@"owner_id"]}];
                                        
                                        if ( userID == _messagesView.recipientID.intValue )
                                        {
                                            [_messagesView receivedStatusUpdate:entry fresh:NO];
                                        }
                                    }
                                    
                                    FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :user_id"
                                               withParameterDictionary:@{@"user_id": [entry objectForKey:@"owner_id"]}];
                                    
                                    // Read & store each contact's data.
                                    while ( [s1 next] )
                                    {
                                        NSString *lastViewTimestamp = [s1 stringForColumn:@"last_view_timestamp"];
                                        NSString *lastMessageTimestamp = [s1 stringForColumn:@"last_message_timestamp"];
                                        NSData *DP = [s1 dataForColumn:@"dp"];
                                        id aliasDP = [s1 dataForColumn:@"alias_dp"];
                                        
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
                                        
                                        if ( !aliasDP )
                                        {
                                            aliasDP = @"";
                                        }
                                        
                                        [entry setObject:[s1 stringForColumn:@"sh_user_id"] forKey:@"user_id"];
                                        [entry setObject:[s1 stringForColumn:@"name_first"] forKey:@"name_first"];
                                        [entry setObject:[s1 stringForColumn:@"name_last"] forKey:@"name_last"];
                                        [entry setObject:[s1 stringForColumn:@"alias"] forKey:@"alias"];
                                        [entry setObject:[s1 stringForColumn:@"user_handle"] forKey:@"user_handle"];
                                        [entry setObject:[s1 stringForColumn:@"dp_hash"] forKey:@"dp_hash"];
                                        [entry setObject:DP forKey:@"dp"];
                                        [entry setObject:aliasDP forKey:@"alias_dp"];
                                        [entry setObject:[s1 stringForColumn:@"email_address"] forKey:@"email_address"];
                                        [entry setObject:[s1 stringForColumn:@"gender"] forKey:@"gender"];
                                        [entry setObject:[s1 stringForColumn:@"birthday"] forKey:@"birthday"];
                                        [entry setObject:[s1 stringForColumn:@"location_country"] forKey:@"location_country"];
                                        [entry setObject:[s1 stringForColumn:@"location_state"] forKey:@"location_state"];
                                        [entry setObject:[s1 stringForColumn:@"location_city"] forKey:@"location_city"];
                                        [entry setObject:[s1 stringForColumn:@"website"] forKey:@"website"];
                                        [entry setObject:[s1 stringForColumn:@"bio"] forKey:@"bio"];
                                        [entry setObject:[s1 stringForColumn:@"last_status_id"] forKey:@"last_status_id"];
                                        [entry setObject:[s1 stringForColumn:@"total_messages_sent"] forKey:@"total_messages_sent"];
                                        [entry setObject:[s1 stringForColumn:@"total_messages_received"] forKey:@"total_messages_received"];
                                        [entry setObject:[s1 stringForColumn:@"unread_thread_count"] forKey:@"unread_thread_count"];
                                        [entry setObject:[s1 stringForColumn:@"view_count"] forKey:@"view_count"];
                                        [entry setObject:lastViewTimestamp forKey:@"last_view_timestamp"];
                                        [entry setObject:lastMessageTimestamp forKey:@"last_message_timestamp"];
                                        [entry setObject:[s1 stringForColumn:@"coordinate_x"] forKey:@"coordinate_x"];
                                        [entry setObject:[s1 stringForColumn:@"coordinate_y"] forKey:@"coordinate_y"];
                                        [entry setObject:[s1 stringForColumn:@"rank_score"] forKey:@"rank_score"];
                                        
                                        if ( entry.count > 0 )
                                        {
                                            NSString *userID = [entry objectForKey:@"user_id"];
                                            
                                            FMResultSet *s2 = [db executeQuery:@"SELECT * FROM sh_phone_numbers WHERE sh_user_id = :sh_user_id"
                                                       withParameterDictionary:@{@"sh_user_id": userID}];
                                            
                                            while ( [s2 next] )
                                            {
                                                [entry setObject:[s2 stringForColumn:@"country_calling_code"] forKey:@"country_calling_code"];
                                                [entry setObject:[s2 stringForColumn:@"prefix"] forKey:@"prefix"];
                                                [entry setObject:[s2 stringForColumn:@"phone_number"] forKey:@"phone_number"];
                                            }
                                            
                                            [s2 close];
                                            
                                            s2 = [db executeQuery:@"SELECT * FROM sh_user_online_status WHERE user_id = :sh_user_id"
                                          withParameterDictionary:@{@"sh_user_id": userID}];
                                            
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
                                                
                                                [entry setObject:presence forKey:@"presence"];
                                                [entry setObject:presenceTargetID forKey:@"presence_target"];
                                                [entry setObject:audience forKey:@"audience"];
                                                [entry setObject:presenceTimestamp forKey:@"presence_timestamp"];
                                            }
                                            
                                            [s2 close];
                                        }
                                    }
                                    
                                    [s1 close];
                                }
                                
                                // Now, we insert the new story.
                                if ( batchNumber == 0 )
                                {
                                    [_SHMiniFeedEntries insertObject:entry atIndex:0];
                                    [freshPostIndexPaths addObject:[NSIndexPath indexPathForRow:(freshEntries.count - (i + 1)) inSection:0]];
                                }
                                else
                                {
                                    [_SHMiniFeedEntries addObject:entry];
                                    [freshPostIndexPaths addObject:[NSIndexPath indexPathForRow:(_SHMiniFeedEntries.count - 1) inSection:0]];
                                }
                            }
                            
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                if ( freshPostIndexPaths.count > 0 )
                                {
                                    [_SHMiniFeed insertRowsAtIndexPaths:freshPostIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                                }
                                
                                [_SHMiniFeed endUpdates];
                                
                                // We need a slight delay here.
                                long double delayInSeconds = 0.5;
                                
                                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                    [_SHMiniFeed reloadData];
                                });
                            });
                        }];
                    }
                });
            }
            else if ( errorCode == 404 )
            {
                endOfMiniFeed = YES;
                
                [_SHMiniFeed reloadData];
            }
            
            NSString *timeNow = [appDelegate.modelManager dateTodayString];
            
            [appDelegate.currentUser setObject:timeNow forKey:@"last_mini_feed_refresh"];
            
            [appDelegate.modelManager executeUpdate:@"UPDATE sh_current_user SET last_mini_feed_refresh = :last_refresh_time"
                            withParameterDictionary:@{@"last_refresh_time": timeNow}];
            
            // Kill this timer.
            if ( timer_miniFeedRefreshResume )
            {
                [timer_miniFeedRefreshResume invalidate];
                timer_miniFeedRefreshResume = nil;
            }
        }
        else
        {
            NSLog(@"Error while fetching feed!");
        }
        
        //NSLog(@"Response: %@", operation.responseString);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        miniFeedRefreshDidFailOnScroll = YES;
        _miniFeedDidFinishDownloading = YES;
        
        [SHMiniFeedrefreshControl endRefreshing];
        [_SHMiniFeed reloadData];
        
        // Kill this timer.
        if ( timer_miniFeedRefreshResume )
        {
            [timer_miniFeedRefreshResume invalidate];
            timer_miniFeedRefreshResume = nil;
        }
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)refreshMiniFeed
{
    batchNumber = 0;
    [self downloadMiniFeed];
}

- (void)beginMiniFeedRefreshCycle
{
    if ( timer_miniFeedRefresh )
    {
        [timer_miniFeedRefresh invalidate];
        timer_miniFeedRefresh = nil;
    }
    
    timer_miniFeedRefresh = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(refreshMiniFeed) userInfo:nil repeats:YES]; // Run this every 5 minutes.
}

- (void)pauseMiniFeedRefreshCycle
{
    [timer_miniFeedRefresh invalidate];
    timer_miniFeedRefresh = nil;
}

- (void)resumeMiniFeedRefreshCycle
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    
    NSDate *dateToday = [NSDate date];
    NSString *lastRefresh = [appDelegate.currentUser objectForKey:@"last_mini_feed_refresh"];
    NSDate *lastRefreshTime;
    
    if ( lastRefresh.length > 0 )
    {
        lastRefreshTime = [dateFormatter dateFromString:lastRefresh];
    }
    
    // Perform a refresh every 5 minutes.
    if ( lastRefresh.length == 0 || [dateToday timeIntervalSinceDate:lastRefreshTime] > 300 ) // More than 5 minutes have already passed.
    {
        [self refreshMiniFeed];
    }
    else // Less than 5 mins have passed. Set the timer for when 5 mins have passed.
    {
        if ( timer_miniFeedRefresh )
        {
            [timer_miniFeedRefresh invalidate];
            timer_miniFeedRefresh = nil;
        }
        
        if ( timer_miniFeedRefreshResume )
        {
            [timer_miniFeedRefreshResume invalidate];
            timer_miniFeedRefreshResume = nil;
        }
        
        timer_miniFeedRefreshResume = [NSTimer scheduledTimerWithTimeInterval:(300 - [dateToday timeIntervalSinceDate:lastRefreshTime]) target:self selector:@selector(refreshMiniFeed) userInfo:nil repeats:NO];
    }
}

- (void)deleteFeedStatus
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight activateStrobeLight];
    
    NSString *statusID = [[_SHMiniFeedEntries objectAtIndex:activeMiniFeedIndexPath.row] objectForKey:@"thread_id"];
    NSString *statusType = [[_SHMiniFeedEntries objectAtIndex:activeMiniFeedIndexPath.row] objectForKey:@"thread_type"];
    
    if ( statusType.intValue == 7 )
    {
        return;
    }
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[statusID,
                                                                                    statusType]
                                                                          forKeys:@[@"status_id",
                                                                                    @"status_type"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/deletestatus", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                @synchronized( _SHMiniFeedEntries )
                {
                    NSMutableDictionary *lastStatusData = [[responseData objectForKey:@"response"] mutableCopy];
                    NSString *oldStatusID = [lastStatusData objectForKey:@"thread_id"];
                    
                    [_SHMiniFeed beginUpdates];
                    
                    [_SHMiniFeedEntries removeObjectAtIndex:activeMiniFeedIndexPath.row];
                    [_SHMiniFeed deleteRowsAtIndexPaths:[NSArray arrayWithObject:activeMiniFeedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    
                    [_SHMiniFeed endUpdates];
                    
                    [appDelegate.modelManager executeUpdate:@"DELETE FROM sh_thread WHERE thread_id = :last_status_id"
                                    withParameterDictionary:@{@"last_status_id": statusID}];
                    
                    // Backtrack & update our records.
                    [appDelegate.modelManager executeUpdate:@"UPDATE sh_cloud SET last_status_id = :thread_id WHERE sh_user_id = :current_user_id"
                                    withParameterDictionary:@{@"thread_id": oldStatusID,
                                                              @"current_user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
                    
                    [appDelegate.modelManager executeUpdate:@"UPDATE sh_current_user SET last_status_id = :thread_id"
                                    withParameterDictionary:@{@"thread_id": oldStatusID}];
                    
                    [appDelegate.currentUser setObject:oldStatusID forKey:@"last_status_id"];
                    
                    // Check if we already have a copy saved.
                    FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT COUNT(thread_id) FROM sh_thread WHERE thread_id == :thread_id"
                                                     withParameterDictionary:@{@"thread_id": oldStatusID}];
                    
                    BOOL oldStatusAlreadyStored = NO;
                    
                    while ( [s1 next] )
                    {
                        int matchCount = [s1 intForColumnIndex:0];
                        
                        if ( matchCount > 0 )
                        {
                            oldStatusAlreadyStored = YES;
                        }
                    }
                    
                    [s1 close];
                    [appDelegate.modelManager.results close];
                    [appDelegate.modelManager.DB close];
                    
                    // We don't have a copy of the older status. Save it now.
                    if ( !oldStatusAlreadyStored )
                    {
                        NSData *mediaExtraData = [NSJSONSerialization dataWithJSONObject:[lastStatusData objectForKey:@"media_extra"] options:NSJSONWritingPrettyPrinted error:nil];
                        [lastStatusData setObject:mediaExtraData forKey:@"media_extra"];
                        
                        [appDelegate.modelManager executeUpdate:@"INSERT INTO sh_thread "
                                                                @"(thread_id, thread_type, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                                                                @"VALUES (:thread_id, :thread_type, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent, :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                                        withParameterDictionary:lastStatusData];
                    }
                    
                    activeMiniFeedIndexPath = nil;
                }
                
                [appDelegate.strobeLight deactivateStrobeLight];
            }
            else if ( errorCode == 500 )
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"ALERT_DELETING_LAST_STATUS", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil) otherButtonTitles:nil];
                [alert show];
            }
            else
            {
                [appDelegate.strobeLight negativeStrobeLight];
            }
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [appDelegate.strobeLight negativeStrobeLight];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)muteUpdatesForUser:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT * FROM sh_muted WHERE user_id = :user_id"
                                     withParameterDictionary:@{@"user_id": userID}];
    
    BOOL userIsMuted = NO;
    
    while ( [s1 next] )
    {
        userIsMuted = YES;
    }
    
    [s1 close];
    [appDelegate.modelManager.results close];
    [appDelegate.modelManager.DB close];
    
    if ( userIsMuted ) // Unmute.
    {
        [appDelegate.modelManager executeUpdate:@"DELETE FROM sh_muted WHERE user_id = :user_id"
                       withParameterDictionary:@{@"user_id": userID}];
    }
    else
    {
        [appDelegate.modelManager executeUpdate:@"INSERT INTO sh_muted "
                                                @"(user_id, group_id, mute_type, timestamp) "
                                                @"VALUES (:user_id, :group_id, :mute_type, :timestamp)"
                        withParameterDictionary:@{@"user_id": userID,
                                                  @"group_id": @"-1",
                                                  @"mute_type": @"1",
                                                  @"timestamp": [appDelegate.modelManager dateTodayString]}];
        
        // Clean up.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for ( int i = 0; i < _SHMiniFeedEntries.count; i++ )
            {
                NSMutableDictionary *entry = [_SHMiniFeedEntries objectAtIndex:i];
                int entryType = [[entry objectForKey:@"entry_type"] intValue];
                
                if ( entryType == 1 )
                {
                    int targetID = [[entry objectForKey:@"user_id"] intValue];
                    
                    if ( userID.intValue == targetID )
                    {
                        [_SHMiniFeedEntries removeObjectAtIndex:i];
                        i--; // Backtrack!
                    }
                }
                else
                {
                    NSMutableArray *originalParticipantData = [entry objectForKey:@"original_participant_data"];
                    NSMutableDictionary *participant_1 = [originalParticipantData objectAtIndex:0];
                    NSMutableDictionary *participant_2 = [originalParticipantData objectAtIndex:1];
                    int participantID_1 = [[participant_1 objectForKey:@"user_id"] intValue];
                    int participantID_2 = [[participant_2 objectForKey:@"user_id"] intValue];
                    
                    if ( userID.intValue == participantID_1 || userID.intValue == participantID_2 )
                    {
                        [_SHMiniFeedEntries removeObjectAtIndex:i];
                        i--;
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [_SHMiniFeed reloadData];
            });
        });
    }
}

#pragma mark -
#pragma mark Gestures

- (void)userDidTapAndHoldProfileButton:(UILongPressGestureRecognizer *)longPress
{
    if ( longPress.state == UIGestureRecognizerStateBegan )
    {
        SHStatusViewController *statusView = [[SHStatusViewController alloc] init];
        SHOrientationNavigationController *navigationController = [[SHOrientationNavigationController alloc] initWithRootViewController:statusView];
        navigationController.autoRotates = NO;
        
        [self hideMainWindowSide];
        
        [self presentViewController:navigationController animated:YES completion:nil];
        [self stopWallpaperAnimation];
    }
}

- (void)userDidTapAndHoldMiniFeedRow:(UILongPressGestureRecognizer *)longPress
{
    if ( longPress.state == UIGestureRecognizerStateBegan )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        CGPoint pressLocation = [longPress locationInView:_SHMiniFeed];
        activeMiniFeedIndexPath = [_SHMiniFeed indexPathForRowAtPoint:pressLocation];
        
        NSMutableDictionary *entry = [_SHMiniFeedEntries objectAtIndex:activeMiniFeedIndexPath.row];
        int entryType = [[entry objectForKey:@"entry_type"] intValue];
        int statusType = [[entry objectForKey:@"thread_type"] intValue];
        int ownerID = [[entry objectForKey:@"owner_id"] intValue];
        int currentUserID = [[appDelegate.currentUser objectForKey:@"user_id"] intValue];
        
        if ( entryType == 1 ) // Only for statuses!
        {
            if ( ownerID == currentUserID )
            {
                UIActionSheet *actionSheet;
                
                if ( statusType == 7 ) // Type: join. Can't delete this.
                {
                    actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"ALERT_STATUS_UNDELETABLE", nil)
                                                              delegate:self
                                                     cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil)
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:nil];
                    actionSheet.tag = 3;
                }
                else
                {
                    actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                                destructiveButtonTitle:NSLocalizedString(@"OPTION_DELETE_STATUS", nil)
                                                     otherButtonTitles:nil];
                    actionSheet.tag = 4;
                }
                
                actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
                [actionSheet showFromRect:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44) inView:appDelegate.window animated:YES];
            }
            else
            {
                FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT * FROM sh_muted WHERE user_id = :user_id"
                                                 withParameterDictionary:@{@"user_id": [NSNumber numberWithInt:ownerID]}];
                
                BOOL userIsMuted = NO;
                
                while ( [s1 next] )
                {
                    userIsMuted = YES;
                }
                
                [s1 close];
                [appDelegate.modelManager.results close];
                [appDelegate.modelManager.DB close];
                
                UIActionSheet *actionSheet;
                
                if ( userIsMuted )
                {
                    actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [entry objectForKey:@"name_first"], [entry objectForKey:@"name_last"]]
                                                              delegate:self
                                                     cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:NSLocalizedString(@"OPTION_UNMUTE_UPDATES", nil), nil];
                }
                else
                {
                    actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [entry objectForKey:@"name_first"], [entry objectForKey:@"name_last"]]
                                                              delegate:self
                                                     cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                                destructiveButtonTitle:NSLocalizedString(@"OPTION_MUTE_UPDATES", nil)
                                                     otherButtonTitles:nil];
                }
                
                actionSheet.tag = 5;
                actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
                [actionSheet showFromRect:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44) inView:appDelegate.window animated:YES];
            }
        }
    }
}

/*
 * The user can drag the active bubble out in order to
 * close the active conversation.
 */
- (void)userDidDragActiveRecipientBubble:(UIPanGestureRecognizer *)drag
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    activeRecipientBubblePanCoordinate = [drag locationInView:self.view];
    activeRecipientBubblePanCoordinate = CGPointMake(activeRecipientBubblePanCoordinate.x - _activeRecipientBubble.frame.size.width / 2, activeRecipientBubblePanCoordinate.y - _activeRecipientBubble.frame.size.height / 2);
    
    UIImageView *vignette;
    
    if ( drag.state == UIGestureRecognizerStateBegan )
    {
        vignette = [[UIImageView alloc] initWithFrame:appDelegate.screenBounds];
        vignette.image = [UIImage imageNamed:@"chat_close_vignette"];
        vignette.alpha = 0.0;
        vignette.tag = 99;
        
        [_windowCompositionLayer addSubview:vignette];
        [_windowCompositionLayer bringSubviewToFront:_activeRecipientBubble];
        [_windowCompositionLayer bringSubviewToFront:_mainWindowContainer];
        [_activeRecipientBubble hideMessagePreview];
        [_activeRecipientBubble hideTypingIndicator];
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            _activeRecipientBubble.transform = CGAffineTransformMakeScale(2.0, 2.0);
            vignette.alpha = 1.0;
        } completion:^(BOOL finished){
            
        }];
    }
    else if ( drag.state == UIGestureRecognizerStateChanged )
    {
        if ( activeRecipientBubblePanCoordinate.x <=  appDelegate.screenBounds.size.width - 90)
        {
            _activeRecipientBubble.frame = CGRectMake(activeRecipientBubblePanCoordinate.x, activeRecipientBubblePanCoordinate.y, _activeRecipientBubble.frame.size.width, _activeRecipientBubble.frame.size.height);
        }
    }
    else if ( drag.state == UIGestureRecognizerStateEnded )
    {
        vignette = (UIImageView *)[_windowCompositionLayer viewWithTag:99];
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            vignette.alpha = 0.0;
        } completion:^(BOOL finished){
            [vignette removeFromSuperview];
        }];
        
        if ( activeRecipientBubblePanCoordinate.x < appDelegate.screenBounds.size.width - 110 && activeRecipientBubblePanCoordinate.y > 110 ) // Close the conversation.
        {
            [self closeCurrentChat];
            [self dismissWindow];
        }
        else // Return the bubble to its original position.
        {
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                _activeRecipientBubble.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished){
                [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    _activeRecipientBubble.frame = CGRectMake(appDelegate.screenBounds.size.width - 90, 25, _activeRecipientBubble.frame.size.width, _activeRecipientBubble.frame.size.height);
                } completion:^(BOOL finished){
                    
                }];
            }];
        }
    }
    else // Gesture failed. Return the bubble to its original position.
    {
        vignette = (UIImageView *)[_windowCompositionLayer viewWithTag:99];
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            _activeRecipientBubble.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                _activeRecipientBubble.frame = CGRectMake(appDelegate.screenBounds.size.width - 90, 25, _activeRecipientBubble.frame.size.width, _activeRecipientBubble.frame.size.height);
                vignette.alpha = 0.0;
            } completion:^(BOOL finished){
                [vignette removeFromSuperview];
            }];
        }];
    }
}

- (void)closeCurrentChat
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        _activeRecipientBubble.alpha = 0.0;
    } completion:^(BOOL finished){
        _activeRecipientBubble.transform = CGAffineTransformIdentity;
        _activeRecipientBubble.frame = CGRectMake(appDelegate.screenBounds.size.width - 90, 25, _activeRecipientBubble.frame.size.width, _activeRecipientBubble.frame.size.height); // Restore its position.
        _activeRecipientBubble.hidden = YES;
        _mainWindowNipple.hidden = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableDictionary *metadata = _activeRecipientBubble.metadata;
            
            // Restore the bubble in the Chat Cloud.
            for ( SHChatBubble *theBubble in _contactCloud.cloudBubbles )
            {
                int activeBubbleUserID = [[metadata objectForKey:@"user_id"] intValue];
                int targetBubbleUserID = [[theBubble.metadata objectForKey:@"user_id"] intValue];
                
                if ( targetBubbleUserID == activeBubbleUserID )
                {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        theBubble.hidden = NO;
                        
                        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                            theBubble.alpha = 1.0;
                        } completion:^(BOOL finished){
                            // Clear stale data.
                            _activeRecipientBubble.metadata = nil;
                            
                            [_messagesView.recipientDataChunk removeAllObjects];
                        }];
                    });
                    
                    break;
                }
            }
        });
    }];
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        _activeRecipientBubble.transform = CGAffineTransformMakeScale(2.8, 2.8);
    } completion:^(BOOL finished){
        
    }];
    
    [self dismissWindow];
    [_messagesView clearViewAnimated:YES];
}

- (void)setMaxMinZoomScalesForChatCloudBounds
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
    
    _contactCloud.footerLabel.frame = CGRectMake(_contactCloud.footerLabel.frame.origin.x, _contactCloud.contentSize.height + 15, _contactCloud.footerLabel.frame.size.width, _contactCloud.footerLabel.frame.size.height);
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods.

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ( scrollView.tag == 0 ) // Chat Cloud
    {
        [searchBox resignFirstResponder]; // Give the user more viewing space.
        
        _contactCloud.headerLabel.text = [NSString stringWithFormat:@"%d connection%@.", (int)_contactCloud.cloudBubbles.count, _contactCloud.cloudBubbles.count == 1 ? @"" : @"s"];
    }
    
    if ( scrollView.tag != 66 )
    {
        [self disableCompositionLayerScrolling]; // Lock this layer so it doesn't scroll once we reach the edges of any other scroll view.
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    // Check in case the user dragged the Cloud without momentum, we should unlock the layer.
    if ( scrollView.tag == 0 && !decelerate && appDelegate.viewIsDraggable && appDelegate.activeWindow )
    {
        [self enableCompositionLayerScrolling]; // Unlock the layer.
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( appDelegate.activeWindow && appDelegate.viewIsDraggable )
    {
        [self enableCompositionLayerScrolling]; // Unlock the layer.
    }
    
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
                [self dismissChatCloudCenterJumpButton];
            }
        }
    }
    else if ( scrollView.tag == 66 ) // Composition Layer
    {
        if ( _windowCompositionLayer.contentOffset.x == 0 ) // The Home Menu is active.
        {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
            [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
            
            _SHMiniFeed.scrollsToTop = YES;
            _messagesView.conversationTable.scrollsToTop = NO;
            _profileView.mainView.scrollsToTop = NO;
            gesture_mainWindowTap.enabled = YES;
            appDelegate.mainWindowNavigationController.view.userInteractionEnabled = NO;
            
            // Re-enable these.
            _windowCompositionLayer.userInteractionEnabled = YES;
            _SHMiniFeed.allowsSelection = YES;
            
            [_messagesView resetView]; // Hide the keyboard/attachments panel BEFORE removing the keyboard notification observer.
            [[NSNotificationCenter defaultCenter] removeObserver:_messagesView name:UIKeyboardWillShowNotification object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:_messagesView name:UIKeyboardWillHideNotification object:nil];
            
            if ( appDelegate.activeWindow == SHAppWindowTypeProfile )
            {
                [self dismissWindow];
            }
            
            if ( !_wallpaperIsAnimating )
            {
                [self resumeWallpaperAnimation];
            }
            
            // Make sure the window is reset to its original position after any tamperings with its frame.
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                if ( appDelegate.activeWindow && appDelegate.activeWindow == SHAppWindowTypeMessages )
                {
                    _mainWindowContainer.frame = CGRectMake(appDelegate.screenBounds.size.width - 40, _mainWindowContainer.frame.origin.y, _mainWindowContainer.frame.size.width, _mainWindowContainer.frame.size.height);
                }
                else
                {
                    _mainWindowContainer.frame = CGRectMake(appDelegate.screenBounds.size.width, _mainWindowContainer.frame.origin.y, _mainWindowContainer.frame.size.width, _mainWindowContainer.frame.size.height);
                }
                
                _messagesView.tableContainer.frame = CGRectMake(0, _messagesView.tableContainer.frame.origin.y, _messagesView.tableContainer.frame.size.width, _messagesView.tableContainer.frame.size.height);
                _messagesView.tableSideShadow.frame = CGRectMake(appDelegate.screenBounds.size.width, _messagesView.tableSideShadow.frame.origin.y, _messagesView.tableSideShadow.frame.size.width, _messagesView.tableSideShadow.frame.size.height);
            } completion:^(BOOL finished){
                
            }];
        }
        else if ( _windowCompositionLayer.contentOffset.x == appDelegate.screenBounds.size.width ) // Main Window is active
        {
            _contactCloud.hidden = YES;
            _SHMiniFeedContainer.hidden = YES;
            _SHMiniFeed.scrollsToTop = NO;
            gesture_mainWindowTap.enabled = NO;
            appDelegate.mainWindowNavigationController.view.userInteractionEnabled = YES;
            
            if ( appDelegate.activeWindow != SHAppWindowTypeProfile )
            {
                [self stopWallpaperAnimation];
            }
            
            if ( appDelegate.activeWindow == SHAppWindowTypeMessages )
            {
                _messagesView.conversationTable.scrollsToTop = YES;
                
                [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionNavigationBar];
                
                // Make sure the conversation is reset to its original position after any tamperings with its frame.
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    _messagesView.tableContainer.frame = CGRectMake(0, _messagesView.tableContainer.frame.origin.y, _messagesView.tableContainer.frame.size.width, _messagesView.tableContainer.frame.size.height);
                    _messagesView.tableSideShadow.frame = CGRectMake(appDelegate.screenBounds.size.width, _messagesView.tableSideShadow.frame.origin.y, _messagesView.tableSideShadow.frame.size.width, _messagesView.tableSideShadow.frame.size.height);
                } completion:^(BOOL finished){
                    
                }];
                
                if ( (IS_IOS7) && _messagesView.inPrivateMode )
                {
                    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
                }
                else
                {
                    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
                }
                
                [_activeRecipientBubble setBadgeCount:0]; // Reset this.
                
                // Listen for the keyboard.
                // NOTE: this method gets called even if you never scroll horizontally, so remove observers before adding them again!
                [[NSNotificationCenter defaultCenter] removeObserver:_messagesView name:UIKeyboardWillShowNotification object:nil];
                [[NSNotificationCenter defaultCenter] removeObserver:_messagesView name:UIKeyboardWillHideNotification object:nil];
                
                [[NSNotificationCenter defaultCenter] addObserver:_messagesView selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:_messagesView selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
            }
            else if ( appDelegate.activeWindow == SHAppWindowTypeProfile )
            {
                _profileView.mainView.scrollsToTop = YES;
                
                [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
            }
        }
        else if ( _windowCompositionLayer.contentOffset.x == appDelegate.screenBounds.size.width * 2 - 40 && appDelegate.activeWindow == SHAppWindowTypeMessages ) // Under-conversation panel.
        {
            [_messagesView resetView]; // Hide the keyboard/attachments panel BEFORE removing the keyboard notification observer.
            [[NSNotificationCenter defaultCenter] removeObserver:_messagesView name:UIKeyboardWillShowNotification object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:_messagesView name:UIKeyboardWillHideNotification object:nil];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    if ( scrollView.tag == 0 ) // Chat Cloud
    {
        CGFloat centerOffset_x = (_contactCloud.contentSize.width / 2) - (_contactCloud.bounds.size.width / 2);
        CGFloat centerOffset_y = (_contactCloud.contentSize.height / 2) - (_contactCloud.bounds.size.height / 2);
        
        maskLayer_ContactCloud.position = CGPointMake(_contactCloud.contentOffset.x, _contactCloud.contentOffset.y);
        _contactCloud.headerLabel.frame = CGRectMake(20 + _contactCloud.contentOffset.x, _contactCloud.headerLabel.frame.origin.y, _contactCloud.headerLabel.frame.size.width, _contactCloud.headerLabel.frame.size.height);
        _contactCloud.footerLabel.frame = CGRectMake(_contactCloud.contentOffset.x + 20, _contactCloud.footerLabel.frame.origin.y, _contactCloud.footerLabel.frame.size.width, _contactCloud.footerLabel.frame.size.height);
        
        // Show the Center Jump button only if we're straggling outside the center.
        if ( _contactCloud.contentOffset.x > centerOffset_x + 200 || _contactCloud.contentOffset.x < centerOffset_x - 200 ||
             _contactCloud.contentOffset.y > centerOffset_y + 200 || _contactCloud.contentOffset.y < centerOffset_y - 200 )
        {
            if ( _cloudCenterButton.hidden )
            {
                [self showChatCloudCenterJumpButton];
            }
        }
        else
        {
            if ( _cloudCenterButton.alpha >= 1.0 )
            {
                [self dismissChatCloudCenterJumpButton];
            }
        }
    }
    else if ( scrollView.tag == 1 ) // Mini Feed
    {
        maskLayer_MiniFeed.position = CGPointMake(0, scrollView.contentOffset.y);
        
        if ( appDelegate.activeWindow ) // Unlock the layer here to avoid a delay for the user if they want to quickly switch to the convo window.
        {
            [self enableCompositionLayerScrolling];
        }
        
        // Auto-pagination on scroll when you're close to the bottom.
        if ( !miniFeedRefreshDidFailOnScroll && _SHMiniFeed.contentOffset.y >= _SHMiniFeed.contentSize.height - 420 && _SHMiniFeedEntries.count > 0 && _miniFeedDidFinishDownloading && !endOfMiniFeed )
        {
            batchNumber++;
            [self downloadMiniFeed];
        }
    }
    else if ( scrollView.tag == 66 && appDelegate.viewIsDraggable ) // Composition Layer
    {
        // We need to fix all these elements in place regardless of how the container is scrolled.
        _contactCloud.frame = CGRectMake(_windowCompositionLayer.contentOffset.x, _contactCloud.frame.origin.y, _contactCloud.frame.size.width, _contactCloud.frame.size.height);
        contactCloudInfoLabel.frame = CGRectMake(_windowCompositionLayer.contentOffset.x, contactCloudInfoLabel.frame.origin.y, contactCloudInfoLabel.frame.size.width, contactCloudInfoLabel.frame.size.height);
        inviteButton.frame = CGRectMake(_windowCompositionLayer.contentOffset.x, inviteButton.frame.origin.y, inviteButton.frame.size.width, inviteButton.frame.size.height);
        _searchButton.frame = CGRectMake(_windowCompositionLayer.contentOffset.x + 10, _searchButton.frame.origin.y, _searchButton.frame.size.width, _searchButton.frame.size.height);
        _cloudCenterButton.frame = CGRectMake(_windowCompositionLayer.contentOffset.x + 10, _cloudCenterButton.frame.origin.y, _cloudCenterButton.frame.size.width, _cloudCenterButton.frame.size.height);
        _createBoardButton.frame = CGRectMake(_windowCompositionLayer.contentOffset.x + (appDelegate.screenBounds.size.width / 2 - 17.5), _createBoardButton.frame.origin.y, _createBoardButton.frame.size.width, _createBoardButton.frame.size.height);
        _refreshButton.frame = CGRectMake(_windowCompositionLayer.contentOffset.x + appDelegate.screenBounds.size.width - 45, _refreshButton.frame.origin.y, _refreshButton.frame.size.width, _refreshButton.frame.size.height);
        _unreadBadgeButton.frame = CGRectMake(appDelegate.screenBounds.size.width - _unreadBadgeButton.frame.size.width - 20 + _windowCompositionLayer.contentOffset.x, _unreadBadgeButton.frame.origin.y, _unreadBadgeButton.frame.size.width, _unreadBadgeButton.frame.size.height);
        searchCancelButton.frame = CGRectMake(_windowCompositionLayer.contentOffset.x, searchCancelButton.frame.origin.y, searchCancelButton.frame.size.width, searchCancelButton.frame.size.height);
        _activeRecipientBubble.frame = CGRectMake(_windowCompositionLayer.contentOffset.x + appDelegate.screenBounds.size.width - 90, _activeRecipientBubble.frame.origin.y, _activeRecipientBubble.frame.size.width, _activeRecipientBubble.frame.size.height);
        _SHMiniFeedContainer.frame = CGRectMake(_windowCompositionLayer.contentOffset.x, _SHMiniFeedContainer.frame.origin.y, _SHMiniFeedContainer.frame.size.width, _SHMiniFeedContainer.frame.size.height);
        
        if ( !isShowingSearchInterface && _windowCompositionLayer.contentOffset.x <= appDelegate.screenBounds.size.width )
        {
            _contactCloud.hidden = NO;
            _SHMiniFeedContainer.hidden = NO;
            
            // Animate the alpha values.
            float x = _windowCompositionLayer.contentOffset.x + _windowCompositionLayer.frame.size.width;
            float width = _windowCompositionLayer.contentSize.width;
            
            if ( appDelegate.activeWindow == SHAppWindowTypeMessages )
            {
                width -= appDelegate.screenBounds.size.width; // Subtract the last segment which is the under-conversation panel.
            }
            
            float alphaValue = (1 - (x / width - 1) * 4) - 1;
            
            contactCloudInfoLabel.alpha = alphaValue;
            inviteButton.alpha = alphaValue;
            _searchButton.alpha = alphaValue;
            _createBoardButton.alpha = alphaValue;
            _refreshButton.alpha = alphaValue;
            _cloudCenterButton.alpha = alphaValue;
            _unreadBadgeButton.alpha = alphaValue;
            _contactCloud.alpha = alphaValue;
            _SHMiniFeedContainer.alpha = alphaValue;
            
            if ( appDelegate.activeWindow != SHAppWindowTypeProfile ) // Alpha value shouldn't be affected if it's the profile window since the wallpaper shows through.
            {
                _wallpaper.alpha = alphaValue;
            }
            else
            {
                _profileView.upperPane.alpha = alphaValue + 1;
            }
        }
        
        if ( _windowCompositionLayer.contentOffset.x <= 40 )
        {
            _mainWindowContainer.frame = CGRectMake(appDelegate.screenBounds.size.width - 40, _mainWindowContainer.frame.origin.y, _mainWindowContainer.frame.size.width, _mainWindowContainer.frame.size.height);
        }
        
        if ( _windowCompositionLayer.contentOffset.x >= appDelegate.screenBounds.size.width - 40 ) // Fix the main window at this point.
        {
            // Re-enable these.
            _windowCompositionLayer.userInteractionEnabled = YES;
            _SHMiniFeed.allowsSelection = YES;
            
            _mainWindowContainer.frame = CGRectMake(_windowCompositionLayer.contentOffset.x, _mainWindowContainer.frame.origin.y, _mainWindowContainer.frame.size.width, _mainWindowContainer.frame.size.height);
        }
        
        if ( _windowCompositionLayer.contentOffset.x > appDelegate.screenBounds.size.width && appDelegate.activeWindow == SHAppWindowTypeMessages ) // At this point, we start revealing the drawer that lies under the convo table.
        {
            _messagesView.tableContainer.frame = CGRectMake(-(_windowCompositionLayer.contentOffset.x - appDelegate.screenBounds.size.width) + 1, _messagesView.tableContainer.frame.origin.y, _messagesView.tableContainer.frame.size.width, _messagesView.tableContainer.frame.size.height);
            _messagesView.tableSideShadow.frame = CGRectMake(_messagesView.tableContainer.frame.size.width + _messagesView.tableContainer.frame.origin.x, _messagesView.tableSideShadow.frame.origin.y, _messagesView.tableSideShadow.frame.size.width, _messagesView.tableSideShadow.frame.size.height);
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

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    if ( scrollView.tag == 0 ) // Contact Cloud
    {
        _contactCloud.footerLabel.hidden = YES;
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    if ( scrollView.tag == 0 ) // Contact Cloud
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
        _contactCloud.layer.mask = maskLayer_ContactCloud; // Restore the mask.
        
        if ( scrollView.zoomScale == scrollView.minimumZoomScale )
        {
            _contactCloud.footerLabel.hidden = NO;
        }
    }
}

#pragma mark -
#pragma mark SHPresenceManagerDelegate methods.

- (void)currentUserPresenceDidChange
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( appDelegate.activeWindow == SHAppWindowTypeMessages )
    {
        [_messagesView currentUserPresenceDidChange];
    }
    else if ( appDelegate.activeWindow == SHAppWindowTypeProfile )
    {
        [_profileView currentUserPresenceDidChange];
    }
}

- (void)presenceDidChange:(SHUserPresence)presence forUserID:(NSString *)userID withTargetID:(NSString *)presenceTargetID forAudience:(SHUserPresenceAudience)audience
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *timeNow = [appDelegate.modelManager dateTodayString];
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            BOOL updatedChatCloud = NO;
            BOOL updatedRecipientBubble = NO;
            int activeRecipientUserID = [[_activeRecipientBubble.metadata objectForKey:@"user_id"] intValue];
            
            if ( _messagesView.recipientID.intValue == userID.intValue )
            {
                [_messagesView presenceDidChange:presence time:timeNow forRecipientWithTargetID:presenceTargetID forAudience:audience withDB:db];
            }
            
            for ( int i = 0; i < _contactCloud.cloudBubbles.count; i++ )
            {
                SHChatBubble *bubble = [_contactCloud.cloudBubbles objectAtIndex:i];
                int bubbleUserID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                
                if ( bubbleUserID == userID.intValue )
                {
                    [bubble.metadata setObject:[NSNumber numberWithInt:presence] forKey:@"presence"];
                    [bubble.metadata setObject:presenceTargetID forKey:@"presence_target"];
                    [bubble.metadata setObject:[NSNumber numberWithInt:audience] forKey:@"audience"];
                    [bubble.metadata setObject:timeNow forKey:@"presence_timestamp"];
                    
                    [_contactCloud.cloudBubbles setObject:bubble atIndexedSubscript:i];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [bubble setPresence:presence animated:YES];
                        
                        // Show a typing indicator if the current user is the target.
                        if ( [presenceTargetID intValue] == [[appDelegate.currentUser objectForKey:@"user_id"] intValue] )
                        {
                            if ( presence == SHUserPresenceTyping ) // Show the typing bubble.
                            {
                                [bubble showTypingIndicatorFromDirection:SHChatBubbleTypingIndicatorDirectionLeft];
                            }
                            else
                            {
                                [bubble hideTypingIndicator];
                            }
                        }
                        else
                        {
                            if ( bubble.isShowingTypingIndicator )
                            {
                                [bubble hideTypingIndicator];
                            }
                        }
                    });
                    
                    updatedChatCloud = YES;
                }
                
                if ( _activeRecipientBubble.metadata )
                {
                    if ( bubbleUserID == userID.intValue && bubbleUserID == activeRecipientUserID )
                    {
                        [_activeRecipientBubble.metadata setObject:[NSNumber numberWithInt:presence] forKey:@"presence"];
                        [_activeRecipientBubble.metadata setObject:presenceTargetID forKey:@"presence_target"];
                        [_activeRecipientBubble.metadata setObject:[NSNumber numberWithInt:audience] forKey:@"audience"];
                        [_activeRecipientBubble.metadata setObject:timeNow forKey:@"presence_timestamp"];
                        
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            [_activeRecipientBubble setPresence:presence animated:YES];
                            
                            // Show a typing indicator if the current user is the target.
                            if ( presenceTargetID.intValue == [[appDelegate.currentUser objectForKey:@"user_id"] intValue] )
                            {
                                if ( presence == SHUserPresenceTyping ) // Show the typing bubble.
                                {
                                    [_activeRecipientBubble showTypingIndicatorFromDirection:SHChatBubbleTypingIndicatorDirectionRight];
                                }
                                else
                                {
                                    [_activeRecipientBubble hideTypingIndicator];
                                }
                            }
                            else
                            {
                                if ( _activeRecipientBubble.isShowingTypingIndicator )
                                {
                                    [_activeRecipientBubble hideTypingIndicator];
                                }
                            }
                        });
                        
                        updatedRecipientBubble = YES;
                    }
                }
                else // No active recipient.
                {
                    updatedRecipientBubble = YES;
                }
                
                if ( updatedChatCloud && updatedRecipientBubble )
                {
                    break;
                }
            }
            
            for ( int i = 0; i < _SHMiniFeedEntries.count; i++ )
            {
                NSMutableDictionary *entry = [_SHMiniFeedEntries objectAtIndex:i];
                int entryType = [[entry objectForKey:@"entry_type"] intValue];
                
                if ( entryType == 1 )
                {
                    int targetUserID = [[entry objectForKey:@"user_id"] intValue];
                    
                    if ( targetUserID == userID.intValue )
                    {
                        [entry setObject:[NSNumber numberWithInt:presence] forKey:@"presence"];
                        [_SHMiniFeedEntries setObject:entry atIndexedSubscript:i];
                        
                        break;
                    }
                }
                else if ( entryType == 2 )
                {
                    NSArray *originalParticipants = [[entry objectForKey:@"tag"] allObjects];
                    NSMutableArray *originalParticipantData = [entry objectForKey:@"original_participant_data"];
                    
                    int originalParticipant_1 = [[originalParticipants objectAtIndex:0] intValue];
                    int originalParticipant_2 = [[originalParticipants objectAtIndex:1] intValue];
                    
                    if ( originalParticipant_1 == userID.intValue )
                    {
                        NSMutableDictionary *participant_1 = [originalParticipantData objectAtIndex:0];
                        int index = 0;
                        
                        if ( [[participant_1 objectForKey:@"user_id"] intValue] != originalParticipant_1 )
                        {
                            participant_1 = [originalParticipantData objectAtIndex:1];
                            index = 1;
                        }
                        
                        [participant_1 setObject:[NSNumber numberWithInt:presence] forKey:@"presence"];
                        [originalParticipantData setObject:participant_1 atIndexedSubscript:index];
                        [entry setObject:originalParticipantData forKey:@"original_participant_data"];
                        [_SHMiniFeedEntries setObject:entry atIndexedSubscript:i];
                        
                        break;
                    }
                    else if ( originalParticipant_2 == userID.intValue )
                    {
                        NSMutableDictionary *participant_2 = [originalParticipantData objectAtIndex:1];
                        int index = 1;
                        
                        if ( [[participant_2 objectForKey:@"user_id"] intValue] != originalParticipant_2 )
                        {
                            participant_2 = [originalParticipantData objectAtIndex:0];
                            index = 0;
                        }
                        
                        [participant_2 setObject:[NSNumber numberWithInt:presence] forKey:@"presence"];
                        [originalParticipantData setObject:participant_2 atIndexedSubscript:index];
                        [entry setObject:originalParticipantData forKey:@"original_participant_data"];
                        [_SHMiniFeedEntries setObject:entry atIndexedSubscript:i];
                        
                        break;
                    }
                }
            }
            
            if ( presence == SHUserPresenceOffline || presence == SHUserPresenceOfflineMasked ) // Search the feed for ad hocs when someone goes offline.
            {
                for ( int i = 0; i < _SHMiniFeedEntries.count; i++ )
                {
                    NSMutableDictionary *entry = [_SHMiniFeedEntries objectAtIndex:i];
                    int entryType = [[entry objectForKey:@"entry_type"] intValue];
                    
                    if ( entryType == 2 )
                    {
                        NSMutableArray *originalParticipantData = [entry objectForKey:@"original_participant_data"];
                        NSMutableDictionary *participant_1 = [originalParticipantData objectAtIndex:0];
                        NSMutableDictionary *participant_2 = [originalParticipantData objectAtIndex:1];
                        SHUserPresence presence_participant_1 = [[participant_1 objectForKey:@"presence"] intValue];
                        SHUserPresence presence_participant_2 = [[participant_2 objectForKey:@"presence"] intValue];
                        
                        // If 2 main participants in an ad hoc convo go offline, the convo entry disappears.
                        if ( (presence_participant_1 == SHUserPresenceOffline || presence_participant_1 == SHUserPresenceOfflineMasked) &&
                            (presence_participant_2 == SHUserPresenceOffline || presence_participant_2 == SHUserPresenceOfflineMasked) )
                        {
                            [_SHMiniFeedEntries removeObjectAtIndex:i];
                            i--; // Backtrack to make up for the removed element!
                        }
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if ( presence == SHUserPresenceOffline || presence == SHUserPresenceOfflineMasked
                    || presence == SHUserPresenceOnline || presence == SHUserPresenceOnlineMasked
                    || presence == SHUserPresenceAway )
                {
                    [_SHMiniFeed reloadData]; // To refresh the presence states.
                }
            });
        }];
    });
}

#pragma mark -
#pragma mark SHMessageManagerDelegate methods.

- (void)messageManagerDidReceiveMessage:(NSDictionary *)messageData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int messageOwnerID = [[messageData objectForKey:@"owner_id"] intValue];
        
        if ( appDelegate.activeWindow && appDelegate.activeWindow == SHAppWindowTypeMessages )
        {
            NSMutableDictionary *messageData_mutable = [messageData mutableCopy];
            int currentRecipientID = _messagesView.recipientID.intValue;
            
            if ( currentRecipientID == messageOwnerID ) // Mark as read.
            {
                [messageData_mutable setObject:@"1" forKey:@"status_read"];
                [_messagesView receivedMessage:messageData_mutable];
                
                NSString *threadID = [messageData_mutable objectForKey:@"thread_id"];
                
                [appDelegate.messageManager acknowledgeReadForMessage:threadID toOwnerID:_messagesView.recipientID];
                
                if ( _windowCompositionLayer.contentOffset.x == 0 ) // The Home Menu is active, so we show a badge on the active recipient's bubble.
                {
                    int unreadMessageCount = [[_activeRecipientBubble.metadata objectForKey:@"unread_thread_count"] intValue] + 1; // Increment the notification badge count.
                    SHMediaType mediaType = [[messageData objectForKey:@"media_type"] intValue];
                    NSString *messagePreview = [messageData objectForKey:@"message"];
                    
                    if ( mediaType == SHMediaTypePhoto )
                    {
                        NSString *messagePreviewIcon = @"📷";
                        
                        if ( messagePreview.length > 0 )
                        {
                            messagePreviewIcon = @"📷 ";
                        }
                        
                        messagePreview = [messagePreviewIcon stringByAppendingString:messagePreview];
                    }
                    else if ( mediaType == SHMediaTypeMovie )
                    {
                        NSString *messagePreviewIcon = @"📹";
                        
                        if ( messagePreview.length > 0 )
                        {
                            messagePreviewIcon = @"📹 ";
                        }
                        
                        messagePreview = [messagePreviewIcon stringByAppendingString:messagePreview];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [_activeRecipientBubble setBadgeCount:unreadMessageCount];
                        [_activeRecipientBubble showPreviewForMessage:messagePreview fromDirection:SHChatBubbleTypingIndicatorDirectionRight];
                    });
                }
                
                [self removeBubbleWithUserIDFromUnreadQueue:_messagesView.recipientID];
                [appDelegate.messageManager updateUnreadThreadCount];
                
                for ( SHChatBubble *theBubble in _contactCloud.cloudBubbles )
                {
                    int targetUserID = [[theBubble.metadata objectForKey:@"user_id"] intValue];
                    
                    if ( currentRecipientID == targetUserID )
                    {
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            [theBubble setBadgeCount:0];
                            [self updateUnreadBadge:appDelegate.messageManager.unreadThreadCount];
                        });
                        
                        break;
                    }
                }
                
                return;
            }
        }
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for ( int i = 0; i < _contactCloud.cloudBubbles.count; i++ )
            {
                SHChatBubble *bubble = [_contactCloud.cloudBubbles objectAtIndex:i];
                int bubbleUserID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                
                if ( bubbleUserID == messageOwnerID )
                {
                    int unreadMessageCount = 0;
                    
                    FMResultSet *s1 = [db executeQuery:@"SELECT unread_thread_count FROM sh_cloud WHERE sh_user_id = :user_id"
                               withParameterDictionary:@{@"user_id": [NSNumber numberWithInt:messageOwnerID]}];
                    
                    // Read & store each contact's data.
                    while ( [s1 next] )
                    {
                        unreadMessageCount = [s1 intForColumnIndex:0] + 1;
                    }
                    
                    [s1 close];
                    
                    [db executeUpdate:@"UPDATE sh_cloud "
                                        @"SET unread_thread_count = :unread_thread_count "
                                        @"WHERE sh_user_id = :user_id"
                            withParameterDictionary:@{@"user_id": [NSNumber numberWithInt:messageOwnerID],
                                                      @"unread_thread_count": [NSNumber numberWithInt:unreadMessageCount]}];
                    
                    [self addBubbleToUnreadQueue:bubble];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [bubble setBadgeCount:unreadMessageCount];
                        
                        if ( _windowCompositionLayer.contentOffset.x == 0 ) // The Home Menu is active, so we show a popup balloon.
                        {
                            SHMediaType mediaType = [[messageData objectForKey:@"media_type"] intValue];
                            NSString *messagePreview = [messageData objectForKey:@"message"];
                            
                            if ( mediaType == SHMediaTypePhoto )
                            {
                                NSString *messagePreviewIcon = @"📷";
                                
                                if ( messagePreview.length > 0 )
                                {
                                    messagePreviewIcon = @"📷 ";
                                }
                                
                                messagePreview = [messagePreviewIcon stringByAppendingString:messagePreview];
                            }
                            else if ( mediaType == SHMediaTypeMovie )
                            {
                                NSString *messagePreviewIcon = @"📹";
                                
                                if ( messagePreview.length > 0 )
                                {
                                    messagePreviewIcon = @"📹 ";
                                }
                                
                                messagePreview = [messagePreviewIcon stringByAppendingString:messagePreview];
                            }
                            
                            [bubble showPreviewForMessage:messagePreview fromDirection:SHChatBubbleTypingIndicatorDirectionLeft];
                        }
                    });
                    
                    break;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    // Update the unread count AFTER the block above (which sets a needed value).
                    [appDelegate.messageManager updateUnreadThreadCount];
                });
            });
        }];
    });
}

- (void)messageManagerDidReceiveMessageBatch:(NSMutableArray *)messages
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *messagesForCurrentRecipient = [NSMutableArray array];
        int currentRecipientID = [_messagesView.recipientID intValue];
        
        for ( NSDictionary *message in messages )
        {
            int messageOwnerID = [[message objectForKey:@"owner_id"] intValue];
            
            if ( appDelegate.activeWindow && appDelegate.activeWindow == SHAppWindowTypeMessages )
            {
                NSMutableDictionary *messageData_mutable = [message mutableCopy];
                
                if ( currentRecipientID == messageOwnerID ) // Mark as read.
                {
                    [messageData_mutable setObject:@"1" forKey:@"status_read"];
                    [messagesForCurrentRecipient addObject:messageData_mutable];
                    
                    NSString *threadID = [messageData_mutable objectForKey:@"thread_id"];
                    
                    [appDelegate.messageManager acknowledgeReadForMessage:threadID toOwnerID:_messagesView.recipientID];
                    
                    continue;
                }
            }
            
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
            [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                for ( int i = 0; i < _contactCloud.cloudBubbles.count; i++ )
                {
                    SHChatBubble *bubble = [_contactCloud.cloudBubbles objectAtIndex:i];
                    int bubbleUserID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                    
                    if ( bubbleUserID == messageOwnerID )
                    {
                        int unreadMessageCount = 0;
                        
                        FMResultSet *s1 = [db executeQuery:@"SELECT unread_thread_count FROM sh_cloud WHERE sh_user_id = :user_id"
                                   withParameterDictionary:@{@"user_id": [NSNumber numberWithInt:messageOwnerID]}];
                        
                        // Read & store each contact's data.
                        while ( [s1 next] )
                        {
                            unreadMessageCount = [s1 intForColumnIndex:0] + 1;
                        }
                        
                        [s1 close];
                        
                        [db executeUpdate:@"UPDATE sh_cloud "
                                            @"SET unread_thread_count = :unread_thread_count "
                                            @"WHERE sh_user_id = :user_id"
                                withParameterDictionary:@{@"user_id": [NSNumber numberWithInt:messageOwnerID],
                                                          @"unread_thread_count": [NSNumber numberWithInt:unreadMessageCount]}];
                        
                        [self addBubbleToUnreadQueue:bubble];
                        NSLog(@"LOOOOLA");
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            [bubble setBadgeCount:unreadMessageCount];
                            
                            if ( _windowCompositionLayer.contentOffset.x == 0 ) // The Home Menu is active, so we show a popup balloon.
                            {
                                SHMediaType mediaType = [[message objectForKey:@"media_type"] intValue];
                                NSString *messagePreview = [message objectForKey:@"message"];
                                
                                if ( mediaType == SHMediaTypePhoto )
                                {
                                    NSString *messagePreviewIcon = @"📷";
                                    
                                    if ( messagePreview.length > 0 )
                                    {
                                        messagePreviewIcon = @"📷 ";
                                    }
                                    
                                    messagePreview = [messagePreviewIcon stringByAppendingString:messagePreview];
                                }
                                else if ( mediaType == SHMediaTypeMovie )
                                {
                                    NSString *messagePreviewIcon = @"📹";
                                    
                                    if ( messagePreview.length > 0 )
                                    {
                                        messagePreviewIcon = @"📹 ";
                                    }
                                    
                                    messagePreview = [messagePreviewIcon stringByAppendingString:messagePreview];
                                }
                                
                                [bubble showPreviewForMessage:messagePreview fromDirection:SHChatBubbleTypingIndicatorDirectionLeft];
                            }
                        });
                        
                        break;
                    }
                }
            }];
        }
        
        [_messagesView receivedMessageBatch:messagesForCurrentRecipient];
        
        if ( messagesForCurrentRecipient.count > 0 )
        {
            if ( _windowCompositionLayer.contentOffset.x == 0 ) // The Home Menu is active, so we show a badge on the active recipient's bubble.
            {
                int unreadMessageCount = [[_activeRecipientBubble.metadata objectForKey:@"unread_thread_count"] intValue] + 1; // Increment the notification badge count.
                SHMediaType mediaType = [[[messagesForCurrentRecipient lastObject] objectForKey:@"media_type"] intValue];
                NSString *messagePreview = [[messagesForCurrentRecipient lastObject] objectForKey:@"message"];
                
                if ( mediaType == SHMediaTypePhoto )
                {
                    NSString *messagePreviewIcon = @"📷";
                    
                    if ( messagePreview.length > 0 )
                    {
                        messagePreviewIcon = @"📷 ";
                    }
                    
                    messagePreview = [messagePreviewIcon stringByAppendingString:messagePreview];
                }
                else if ( mediaType == SHMediaTypeMovie )
                {
                    NSString *messagePreviewIcon = @"📹";
                    
                    if ( messagePreview.length > 0 )
                    {
                        messagePreviewIcon = @"📹 ";
                    }
                    
                    messagePreview = [messagePreviewIcon stringByAppendingString:messagePreview];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [_activeRecipientBubble setBadgeCount:unreadMessageCount];
                    [_activeRecipientBubble showPreviewForMessage:messagePreview fromDirection:SHChatBubbleTypingIndicatorDirectionRight];
                });
            }
            
            [self removeBubbleWithUserIDFromUnreadQueue:_messagesView.recipientID];
            
            for ( SHChatBubble *theBubble in _contactCloud.cloudBubbles )
            {
                int targetUserID = [[theBubble.metadata objectForKey:@"user_id"] intValue];
                
                if ( currentRecipientID == targetUserID )
                {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [theBubble setBadgeCount:0];
                        [self updateUnreadBadge:appDelegate.messageManager.unreadThreadCount];
                    });
                    
                    break;
                }
            }
        }
        
        // Update the unread count AFTER the block above (which sets a needed value).
        [appDelegate.messageManager updateUnreadThreadCount];
    });
}

- (void)messageManagerDidReceiveAdHocMessage:(NSDictionary *)messageData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *messageData_mutable = [messageData mutableCopy];
        NSArray *originalParticipants = [messageData_mutable objectForKey:@"tag"];
        NSSet *tag = [NSSet setWithArray:originalParticipants];
        
        if ( appDelegate.activeWindow && appDelegate.activeWindow == SHAppWindowTypeMessages )
        {
            if ( [_messagesView.adHocTag isEqualToSet:tag] )
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    // The message manager leaves it to the delegate to decide whether a vibration should occur or not.
                    if ( appDelegate.preference_Vibrate )
                    {
                        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); // Vibrate.
                    }
                });
                
                [_messagesView receivedMessage:messageData_mutable];
            }
        }
        
        @synchronized( _SHMiniFeedEntries )
        {
            for ( int i = 0; i < _SHMiniFeedEntries.count; i++ )
            {
                NSMutableDictionary *entry = [_SHMiniFeedEntries objectAtIndex:i];
                int entryType = [[entry objectForKey:@"entry_type"] intValue];
                
                if ( entryType == 2 && [[entry objectForKey:@"tag"] isEqualToSet:tag] ) // Entry already exists, animate the new message.
                {
                    SHMiniFeedCell *targetCell = (SHMiniFeedCell *)[_SHMiniFeed cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [targetCell insertAdHocMessage:messageData];
                    });
                    
                    NSMutableArray *currentMessages = [entry objectForKey:@"message_data"];
                    [currentMessages addObject:messageData];
                    
                    if ( currentMessages.count > 2 )
                    {
                        [currentMessages removeObjectAtIndex:0];
                    }
                    
                    [entry setObject:currentMessages forKey:@"message_data"];
                    
                    [_SHMiniFeedEntries setObject:entry atIndexedSubscript:i];
                    
                    return;
                }
            }
            
            // At this point, no entry was found. Create a new one.
            NSMutableDictionary *adHocEntry = [NSMutableDictionary dictionary];
            NSMutableArray *currentMessages = [[NSMutableArray alloc] initWithObjects:messageData, nil];
            
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
            [queue inDatabase:^(FMDatabase *db) {
                NSMutableArray *originalParticipantData = [NSMutableArray array];
                
                for ( NSString *participantID in originalParticipants )
                {
                    FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :user_id"
                               withParameterDictionary:@{@"user_id": participantID}];
                    
                    // Read & store each contact's data.
                    while ( [s1 next] )
                    {
                        NSMutableDictionary *data = [NSMutableDictionary dictionary];
                        
                        NSData *DP = [s1 dataForColumn:@"dp"];
                        
                        if ( !DP )
                        {
                            DP = UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0);
                        }
                        
                        [data setObject:[s1 stringForColumn:@"sh_user_id"] forKey:@"user_id"];
                        [data setObject:[s1 stringForColumn:@"name_first"] forKey:@"name_first"];
                        [data setObject:[s1 stringForColumn:@"name_last"] forKey:@"name_last"];
                        [data setObject:[s1 stringForColumn:@"alias"] forKey:@"alias"];
                        [data setObject:[s1 stringForColumn:@"user_handle"] forKey:@"user_handle"];
                        [data setObject:[s1 stringForColumn:@"dp_hash"] forKey:@"dp_hash"];
                        [data setObject:DP forKey:@"dp"];
                        [data setObject:[s1 dataForColumn:@"alias_dp"] forKey:@"alias_dp"];
                        
                        FMResultSet *s2 = [db executeQuery:@"SELECT * FROM sh_user_online_status WHERE user_id = :user_id"
                                   withParameterDictionary:@{@"user_id": participantID}];
                        
                        while ( [s2 next] )
                        {
                            NSString *presence = [s2 stringForColumn:@"status"];
                            NSString *presenceTargetID = [s2 stringForColumn:@"target_id"];
                            NSString *audience = [s2 stringForColumn:@"audience"];
                            NSString *presenceTimestamp = @"";
                            
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
                            
                            [data setObject:presence forKey:@"presence"]; // Everyone loads as offline initially.
                            [data setObject:presenceTargetID forKey:@"presence_target"];
                            [data setObject:audience forKey:@"audience"];
                            [data setObject:presenceTimestamp forKey:@"presence_timestamp"];
                        }
                        
                        [s2 close];
                        
                        [originalParticipantData addObject:data];
                    }
                    
                    [s1 close];
                }
                
                [adHocEntry setObject:originalParticipantData forKey:@"original_participant_data"];
                [adHocEntry setObject:currentMessages forKey:@"message_data"];
                [adHocEntry setObject:tag forKey:@"tag"];
                [adHocEntry setObject:@"2" forKey:@"entry_type"];
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [_SHMiniFeed beginUpdates];
                    
                    [_SHMiniFeedEntries insertObject:adHocEntry atIndex:0];
                    [_SHMiniFeed insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic]; // Insert a new row at the top.
                    
                    [_SHMiniFeed endUpdates];
                });
            }];
        }
    });
}

- (void)messageManagerDidReceiveStatusUpdate:(NSDictionary *)statusData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int statusOwnerID = [[statusData objectForKey:@"owner_id"] intValue];
        
        if ( appDelegate.activeWindow && appDelegate.activeWindow == SHAppWindowTypeMessages )
        {
            int currentRecipientID = _messagesView.recipientID.intValue;
            
            if ( currentRecipientID == statusOwnerID )
            {
                [_messagesView receivedStatusUpdate:statusData fresh:YES];
            }
        }
        
        // Next, add the new status to the feed.
        // First, make sure it's not reloading!
        if ( _miniFeedDidFinishDownloading )
        {
            NSMutableDictionary *statusData_mutable = [statusData mutableCopy];
            
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
            [queue inDatabase:^(FMDatabase *db) {
                FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :user_id"
                           withParameterDictionary:@{@"user_id": [statusData objectForKey:@"owner_id"]}];
                
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
                    
                    [statusData_mutable setObject:[s1 stringForColumn:@"sh_user_id"] forKey:@"user_id"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"name_first"] forKey:@"name_first"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"name_last"] forKey:@"name_last"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"alias"] forKey:@"alias"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"user_handle"] forKey:@"user_handle"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"dp_hash"] forKey:@"dp_hash"];
                    [statusData_mutable setObject:DP forKey:@"dp"];
                    [statusData_mutable setObject:[s1 dataForColumn:@"alias_dp"] forKey:@"alias_dp"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"email_address"] forKey:@"email_address"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"gender"] forKey:@"gender"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"birthday"] forKey:@"birthday"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"location_country"] forKey:@"location_country"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"location_state"] forKey:@"location_state"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"location_city"] forKey:@"location_city"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"website"] forKey:@"website"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"bio"] forKey:@"bio"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"last_status_id"] forKey:@"last_status_id"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"total_messages_sent"] forKey:@"total_messages_sent"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"total_messages_received"] forKey:@"total_messages_received"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"unread_thread_count"] forKey:@"unread_thread_count"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"view_count"] forKey:@"view_count"];
                    [statusData_mutable setObject:lastViewTimestamp forKey:@"last_view_timestamp"];
                    [statusData_mutable setObject:lastMessageTimestamp forKey:@"last_message_timestamp"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"coordinate_x"] forKey:@"coordinate_x"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"coordinate_y"] forKey:@"coordinate_y"];
                    [statusData_mutable setObject:[s1 stringForColumn:@"rank_score"] forKey:@"rank_score"];
                    
                    if ( statusData_mutable.count > 0 )
                    {
                        FMResultSet *s2 = [db executeQuery:@"SELECT * FROM sh_phone_numbers WHERE sh_user_id = :sh_user_id"
                                   withParameterDictionary:@{@"sh_user_id": [statusData objectForKey:@"owner_id"]}];
                        
                        while ( [s2 next] )
                        {
                            [statusData_mutable setObject:[s2 stringForColumn:@"country_calling_code"] forKey:@"country_calling_code"];
                            [statusData_mutable setObject:[s2 stringForColumn:@"prefix"] forKey:@"prefix"];
                            [statusData_mutable setObject:[s2 stringForColumn:@"phone_number"] forKey:@"phone_number"];
                        }
                        
                        [s2 close];
                    }
                }
                
                [s1 close];
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [_SHMiniFeed beginUpdates];
                
                [_SHMiniFeedEntries insertObject:statusData_mutable atIndex:0];
                [_SHMiniFeed insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic]; // Insert a new row at the top.
                
                [_SHMiniFeed endUpdates];
            });
        }
    });
}

- (void)messageManagerDidFetchMessageState:(NSMutableArray *)messages forUserID:(NSString *)userID
{
    int currentRecipientID = _messagesView.recipientID.intValue;
    
    if ( currentRecipientID == userID.intValue )
    {
        [_messagesView didFetchMessageStateForCurrentRecipient:messages];
    }
}

- (void)message:(NSDictionary *)messageData statusDidChange:(SHThreadStatus)status
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            int currentRecipientID = _messagesView.recipientID.intValue;
            int messageOwnerID = 0;
            
            FMResultSet *s1 = [db executeQuery:@"SELECT recipient_id "
                               @"FROM sh_message_dispatch "
                               @"WHERE thread_id = :thread_id"
                       withParameterDictionary:@{@"thread_id": [messageData objectForKey:@"thread_id"]}];
            
            while ( [s1 next] )
            {
                messageOwnerID = [s1 intForColumnIndex:0];
            }
            
            if ( currentRecipientID == messageOwnerID ) // Message is from the user we're currently talking to.
            {
                [_messagesView message:messageData statusDidChange:status];
            }
        }];
    });
}

- (void)conversation:(NSString *)userID privacyDidChange:(SHThreadPrivacy)newPrivacy
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    int currentRecipientID = _messagesView.recipientID.intValue;
    
    if ( currentRecipientID == userID.intValue )
    {
        [_messagesView privacyDidChange:newPrivacy];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            // Since the primary key is auto-incremented, there's no way to verify if an entry already exists. Best to delete it first anyways.
            [db executeUpdate:@"DELETE FROM sh_private_conversations "
                                @"WHERE user_id = :user_id"
                    withParameterDictionary:@{@"user_id": userID}];
            
            if ( newPrivacy == SHThreadPrivacyPrivate )
            {
                [db executeUpdate:@"INSERT INTO sh_private_conversations "
                                    @"(user_id, group_id) "
                                    @"VALUES (:user_id, :group_id)"
                    withParameterDictionary:@{@"user_id": userID,
                                              @"group_id": @"-1"}];
            }
        }];
    });
}

#pragma mark -
#pragma mark SHChatBubbleDelegate methods.

- (void)didSelectBubble:(SHChatBubble *)bubble
{
    if ( bubble.tag == -1 )
    {
        [self pushWindow:0];
    }
}

#pragma mark -
#pragma mark SHChatCloudDelegate methods.

- (void)didSelectBubble:(SHChatBubble *)bubble inCloud:(SHContactCloud *)theCloud
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    BOOL temp = [[bubble.metadata objectForKey:@"temp"] boolValue];
    
    if ( isShowingSearchInterface )
    {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
        [self dismissSearchInterface];
    }
    
    if ( bubble.bubbleType == SHChatBubbleTypeUser )
    {
        if ( bubble.isBlocked )
        {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [bubble.metadata objectForKey:@"name_first"], [bubble.metadata objectForKey:@"name_last"]]
                                                                     delegate:self
                                                            cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:NSLocalizedString(@"OPTION_UNBLOCK_CONTACT", nil), nil];
            
            actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
            actionSheet.tag = 6;
            
            activeBubble = bubble;
            [actionSheet showFromRect:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44) inView:appDelegate.window animated:YES];
        }
        else
        {
            [self removeBubbleWithUserIDFromUnreadQueue:[bubble.metadata objectForKey:@"user_id"]];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // Restore the bubble of the previous conversation window.
                if ( _activeRecipientBubble.metadata )
                {
                    NSMutableDictionary *metadata = _activeRecipientBubble.metadata; // Save a copy in case it gets overwritten.
                    
                    for ( SHChatBubble *theBubble in theCloud.cloudBubbles )
                    {
                        int activeBubbleUserID = [[metadata objectForKey:@"user_id"] intValue];
                        int targetBubbleUserID = [[theBubble.metadata objectForKey:@"user_id"] intValue];
                        
                        if ( targetBubbleUserID == activeBubbleUserID )
                        {
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                theBubble.hidden = NO;
                                
                                [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                                    theBubble.alpha = 1.0;
                                } completion:^(BOOL finished){
                                    
                                }];
                            });
                            
                            break;
                        }
                    }
                }
            });
            
            [_messagesView setAdHocMode:NO withOriginalRecipients:nil];
            [_messagesView clearViewAnimated:NO];
            
            long double delayInSeconds_windowPush = 0.0;
            long double delayInSeconds_messageLoading = 0.2;
            
            if ( isShowingSearchInterface )
            {
                [self dismissSearchInterface];
                delayInSeconds_windowPush = 0.25;
                delayInSeconds_messageLoading = 0.5; // We need a slight delay here.
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    for ( SHChatBubble *theBubble in theCloud.cloudBubbles )
                    {
                        int activeBubbleUserID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                        int targetBubbleUserID = [[theBubble.metadata objectForKey:@"user_id"] intValue];
                        
                        if ( targetBubbleUserID == activeBubbleUserID )
                        {
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                // Animate the bubble equivalent outside the Chat Cloud search container out of the view.
                                [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                                    theBubble.transform = CGAffineTransformMakeScale(1.5, 1.5);
                                } completion:^(BOOL finished){
                                    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                                        theBubble.transform = CGAffineTransformIdentity;
                                    } completion:^(BOOL finished){
                                        
                                    }];
                                }];
                                
                                [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                                    theBubble.alpha = 0.0;
                                } completion:^(BOOL finished){
                                    theBubble.hidden = YES;
                                }];
                            });
                            
                            break;
                        }
                    }
                });
            }
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds_windowPush * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [_messagesView setRecipientDataForUser:[bubble.metadata objectForKey:@"user_id"]];
                _messagesView.recipientID = [bubble.metadata objectForKey:@"user_id"]; // Just to be on the safe side (threading mess).
                [self pushWindow:SHAppWindowTypeMessages]; // Slight delay here to prevent a choppy animation.
            });
            
            popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds_messageLoading * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [_messagesView loadMessagesForRecipient];
                [appDelegate.contactManager incrementViewCountForUser:[bubble.metadata objectForKey:@"user_id"]];
            });
            
            [bubble setBadgeCount:0];
            [bubble hideMessagePreview];
            [bubble hideTypingIndicator];
            
            if ( _activeRecipientBubble.hidden )
            {
                _activeRecipientBubble.hidden = NO;
                _mainWindowNipple.hidden = NO;
                
                [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    _activeRecipientBubble.alpha = 1.0;
                    _mainWindowNipple.alpha = 1.0;
                } completion:^(BOOL finished){
                    
                }];
            }
        }
    }
    else if ( bubble.bubbleType == SHChatBubbleTypeBoard )
    {
        SHBoardViewController *boardView = [[SHBoardViewController alloc] init];
        SHOrientationNavigationController *navigationController = [[SHOrientationNavigationController alloc] initWithRootViewController:boardView];
        navigationController.autoRotates = NO;
        
        boardView.boardID = [bubble.metadata objectForKey:@"board_id"];
        boardView.currentCoverHash = [bubble.metadata objectForKey:@"cover_hash"];
        boardView.currentCover = [UIImage imageWithData:[bubble.metadata objectForKey:@"dp"]];
        
        [self presentViewController:navigationController animated:YES completion:nil];
        
        if ( !temp )
        {
            [appDelegate.contactManager incrementViewCountForBoard:[bubble.metadata objectForKey:@"board_id"]];
        }
    }
    
    // Animate the bubble out of the view.
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        bubble.transform = CGAffineTransformMakeScale(1.5, 1.5);
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            bubble.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished){
            
        }];
    }];
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        bubble.alpha = 0.0;
    } completion:^(BOOL finished){
        bubble.hidden = YES;
    }];
    
    if ( bubble.bubbleType == SHChatBubbleTypeBoard )
    {
        // We need a slight delay here.
        long double delayInSeconds = 1.0;
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            bubble.hidden = NO;
            
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                bubble.alpha = 1.0;
            } completion:^(BOOL finished){
                
            }];
        });
    }
}

- (void)didTapAndHoldBubble:(SHChatBubble *)bubble inCloud:(SHContactCloud *)theCloud
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIActionSheet *actionSheet;
    activeBubble = bubble;
    
    if ( bubble.bubbleType == SHChatBubbleTypeUser )
    {
        NSString *userID = [bubble.metadata objectForKey:@"user_id"];
        
        if ( userID.intValue != [[appDelegate.currentUser objectForKey:@"user_id"] intValue] )
        {
            if ( bubble.isBlocked )
            {
                actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [bubble.metadata objectForKey:@"name_first"], [bubble.metadata objectForKey:@"name_last"]]
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:NSLocalizedString(@"OPTION_UNBLOCK_CONTACT", nil), nil];
                
                actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
                actionSheet.tag = 6;
            }
            else
            {
                UIImage *customDP = [UIImage imageWithData:[bubble.metadata objectForKey:@"alias_dp"]];
                
                FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT * FROM sh_muted WHERE user_id = :user_id"
                                                 withParameterDictionary:@{@"user_id": [bubble.metadata objectForKey:@"user_id"]}];
                
                BOOL userIsMuted = NO;
                
                while ( [s1 next] )
                {
                    userIsMuted = YES;
                }
                
                [s1 close];
                [appDelegate.modelManager.results close];
                [appDelegate.modelManager.DB close];
                
                if ( !customDP ) // No custom pic set.
                {
                    if ( userIsMuted )
                    {
                        actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [bubble.metadata objectForKey:@"name_first"], [bubble.metadata objectForKey:@"name_last"]]
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                                    destructiveButtonTitle:NSLocalizedString(@"OPTION_DELETE_CONTACT", nil)
                                                         otherButtonTitles:NSLocalizedString(@"OPTION_DELETE_HISTORY", nil), NSLocalizedString(@"OPTION_RENAME_CONTACT", nil), NSLocalizedString(@"OPTION_CHANGE_CONTACT_PICTURE_ADD", nil), NSLocalizedString(@"OPTION_UNMUTE_UPDATES", nil), nil];
                    }
                    else
                    {
                        actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [bubble.metadata objectForKey:@"name_first"], [bubble.metadata objectForKey:@"name_last"]]
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                                    destructiveButtonTitle:NSLocalizedString(@"OPTION_DELETE_CONTACT", nil)
                                                         otherButtonTitles:NSLocalizedString(@"OPTION_DELETE_HISTORY", nil), NSLocalizedString(@"OPTION_RENAME_CONTACT", nil), NSLocalizedString(@"OPTION_CHANGE_CONTACT_PICTURE_ADD", nil), nil];
                    }
                }
                else // User has a custom pic set. Add an extra option to remove it.
                {
                    if ( userIsMuted )
                    {
                        actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [bubble.metadata objectForKey:@"name_first"], [bubble.metadata objectForKey:@"name_last"]]
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                                    destructiveButtonTitle:NSLocalizedString(@"OPTION_DELETE_CONTACT", nil)
                                                         otherButtonTitles:NSLocalizedString(@"OPTION_DELETE_HISTORY", nil), NSLocalizedString(@"OPTION_RENAME_CONTACT", nil), NSLocalizedString(@"OPTION_CHANGE_CONTACT_PICTURE_ADD", nil), NSLocalizedString(@"OPTION_CHANGE_CONTACT_PICTURE_REMOVE", nil), NSLocalizedString(@"OPTION_UNMUTE_UPDATES", nil), nil];
                    }
                    else
                    {
                        actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [bubble.metadata objectForKey:@"name_first"], [bubble.metadata objectForKey:@"name_last"]]
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                                    destructiveButtonTitle:NSLocalizedString(@"OPTION_DELETE_CONTACT", nil)
                                                         otherButtonTitles:NSLocalizedString(@"OPTION_DELETE_HISTORY", nil), NSLocalizedString(@"OPTION_RENAME_CONTACT", nil), NSLocalizedString(@"OPTION_CHANGE_CONTACT_PICTURE_ADD", nil), NSLocalizedString(@"OPTION_CHANGE_CONTACT_PICTURE_REMOVE", nil), nil];
                    }
                }
                
                actionSheet.tag = 0;
                
                [activeBubble.metadata setObject:[NSNumber numberWithBool:userIsMuted] forKey:@"is_muted"];
            }
            
            actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
            [actionSheet showFromRect:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44) inView:appDelegate.window animated:YES];
        }
    }
}

#pragma mark -
#pragma mark SHContactManagerDelegate methods.

- (void)contactManagerDidFetchFollowing:(NSMutableArray *)list
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_contactCloud beginUpdates];
        
        // Read & store each new contact's data.
        for ( NSMutableDictionary *entry in list )
        {
            SHChatBubbleType entryType = [[entry objectForKey:@"entry_type"] intValue];
            NSMutableDictionary *entryData = [entry objectForKey:@"entry_data"];
            int ID;
            BOOL bubbleExists = NO;
            
            if ( entryType == SHChatBubbleTypeUser )
            {
                ID = [[entryData objectForKey:@"user_id"] intValue];
            }
            else
            {
                ID = [[entryData objectForKey:@"board_id"] intValue];
            }
            
            [entryData setObject:[entry objectForKey:@"entry_type"] forKey:@"bubble_type"];
            
            // First make sure this person isn't already in the cloud.
            for ( int i = 0; i < _contactCloud.cloudBubbles.count; i++ )
            {
                SHChatBubble *bubble = [_contactCloud.cloudBubbles objectAtIndex:i];
                int bubbleID;
                
                if ( bubble.bubbleType == SHChatBubbleTypeUser )
                {
                    bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                }
                else
                {
                    bubbleID = [[bubble.metadata objectForKey:@"board_id"] intValue];
                }
                
                if ( bubbleID == ID )
                {
                    bubbleExists = YES;
                }
            }
            
            if ( bubbleExists )
            {
                continue;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                // Set the image here on the main queue.
                UIImage *currentDP;
                
                if ( entryType == SHChatBubbleTypeUser )
                {
                    currentDP = [UIImage imageWithData:[entryData objectForKey:@"alias_dp"]];
                    
                    if ( !currentDP )
                    {
                        currentDP = [UIImage imageWithData:[entryData objectForKey:@"dp"]];
                    }
                }
                else
                {
                    currentDP = [UIImage imageWithData:[entryData objectForKey:@"dp"]];
                }
                
                SHChatBubble *bubble = [[SHChatBubble alloc] initWithFrame:CGRectMake(0, 0, CHAT_CLOUD_BUBBLE_SIZE, CHAT_CLOUD_BUBBLE_SIZE) andImage:currentDP withMiniModeEnabled:NO];
                [bubble setBubbleMetadata:entryData];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [_contactCloud insertBubble:bubble atPoint:CGPointMake([[entryData objectForKey:@"coordinate_x"] intValue], [[entryData objectForKey:@"coordinate_y"] intValue]) animated:YES];
                });
            });
        }
        
        // We need a slight delay here.
        long double delayInSeconds = 0.45;
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if ( _contactCloud.cloudBubbles.count == 0 )
            {
                [self showEmptyCloud];
            }
            else
            {
                inviteButton.hidden = YES;
                contactCloudInfoLabel.hidden = YES;
            }
            
            // Center the cloud's offset.
            CGFloat centerOffset_x = (_contactCloud.contentSize.width / 2) - (_contactCloud.bounds.size.width / 2);
            CGFloat centerOffset_y = (_contactCloud.contentSize.height / 2) - (_contactCloud.bounds.size.height / 2);
            [_contactCloud setContentOffset:CGPointMake(centerOffset_x, centerOffset_y) animated:YES];
            [_contactCloud endUpdates];
            [self setMaxMinZoomScalesForChatCloudBounds];
            
            [appDelegate.contactManager.freshContacts removeAllObjects]; // Clear this out, or it'll get passed to the delegate every time the Magic Numbers are refreshed!
            [appDelegate.contactManager.freshBoards removeAllObjects];
            [self refreshMiniFeed];
            [self refreshCloud];
        });
    });
}

- (void)contactManagerDidFetchRecommendations:(NSMutableArray *)list
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_contactCloud beginUpdates];
        
        // Read & store each new contact's data.
        for ( NSMutableDictionary *entry in list )
        {
            SHChatBubbleType entryType = [[entry objectForKey:@"entry_type"] intValue];
            NSMutableDictionary *entryData = [entry objectForKey:@"entry_data"];
            int ID;
            BOOL bubbleExists = NO;
            
            if ( entryType == SHChatBubbleTypeUser )
            {
                ID = [[entryData objectForKey:@"user_id"] intValue];
            }
            else
            {
                ID = [[entryData objectForKey:@"board_id"] intValue];
            }
            
            [entryData setObject:[entry objectForKey:@"entry_type"] forKey:@"bubble_type"];
            
            // First make sure this person isn't already in the cloud.
            for ( int i = 0; i < _contactCloud.cloudBubbles.count; i++ )
            {
                SHChatBubble *bubble = [_contactCloud.cloudBubbles objectAtIndex:i];
                int bubbleID;
                
                if ( bubble.bubbleType == SHChatBubbleTypeUser )
                {
                    bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                }
                else
                {
                    bubbleID = [[bubble.metadata objectForKey:@"board_id"] intValue];
                }
                
                if ( bubbleID == ID )
                {
                    bubbleExists = YES;
                }
            }
            
            if ( bubbleExists )
            {
                continue;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                // Set the image here on the main queue.
                UIImage *currentDP = [UIImage imageWithData:[entryData objectForKey:@"dp"]];
                SHChatBubble *bubble = [[SHChatBubble alloc] initWithFrame:CGRectMake(0, 0, CHAT_CLOUD_BUBBLE_SIZE, CHAT_CLOUD_BUBBLE_SIZE) andImage:currentDP withMiniModeEnabled:NO];
                [bubble setBubbleMetadata:entryData];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [_contactCloud insertBubble:bubble atPoint:CGPointMake([[entryData objectForKey:@"coordinate_x"] intValue], [[entryData objectForKey:@"coordinate_y"] intValue]) animated:YES];
                });
            });
        }
        
        // We need a slight delay here.
        long double delayInSeconds = 0.45;
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if ( _contactCloud.cloudBubbles.count == 0 )
            {
                inviteButton.hidden = NO;
                contactCloudInfoLabel.hidden = NO;
                contactCloudInfoLabel.text = NSLocalizedString(@"CHAT_CLOUD_EMPTY", nil);
            }
            else
            {
                inviteButton.hidden = YES;
                contactCloudInfoLabel.hidden = YES;
            }
            
            // Center the cloud's offset.
            CGFloat centerOffset_x = (_contactCloud.contentSize.width / 2) - (_contactCloud.bounds.size.width / 2);
            CGFloat centerOffset_y = (_contactCloud.contentSize.height / 2) - (_contactCloud.bounds.size.height / 2);
            [_contactCloud setContentOffset:CGPointMake(centerOffset_x, centerOffset_y) animated:YES];
            
            _refreshButton.enabled = YES;
            
            [_contactCloud endUpdates];
            [self setMaxMinZoomScalesForChatCloudBounds];
        });
    });
}

- (void)contactManagerDidAddNewContact:(NSMutableDictionary *)userData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight affirmativeStrobeLight];
    
    int userID = [[userData objectForKey:@"user_id"] intValue];
    
    if ( appDelegate.activeWindow && userID == _profileView.ownerID.intValue )
    {
        [_profileView didAddUser];
    }
    else
    {
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        
        HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_white"]];
        
        // Set custom view mode.
        HUD.mode = MBProgressHUDModeCustomView;
        HUD.dimBackground = YES;
        HUD.delegate = self;
        
        [HUD show:YES];
        [HUD hide:YES afterDelay:2];
        
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( int i = 0; i < _contactCloud.cloudBubbles.count; i++ )
        {
            SHChatBubble *bubble = [_contactCloud.cloudBubbles objectAtIndex:i];
            
            if ( bubble.bubbleType == SHChatBubbleTypeUser )
            {
                int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                
                if ( bubbleID == userID )
                {
                    [bubble.metadata setObject:@"0" forKey:@"temp"];
                    
                    break;
                }
            }
        }
        
        if ( isShowingSearchInterface )
        {
            for ( int i = 0; i < _contactCloud.searchResultsBubbles.count; i++ )
            {
                SHChatBubble *bubble = [_contactCloud.searchResultsBubbles objectAtIndex:i];
                
                if ( bubble.bubbleType == SHChatBubbleTypeUser )
                {
                    int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                    
                    if ( bubbleID == userID )
                    {
                        [bubble.metadata setObject:@"0" forKey:@"temp"];
                        
                        break;
                    }
                }
            }
        }
    });
    
    NSLog(@"added new contact!");
}

- (void)contactManagerDidHideContact:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight deactivateStrobeLight];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( int i = 0; i < _contactCloud.cloudBubbles.count; i++ )
        {
            SHChatBubble *bubble = [_contactCloud.cloudBubbles objectAtIndex:i];
            
            if ( bubble.bubbleType == SHChatBubbleTypeUser )
            {
                int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                
                if ( bubbleID == userID.intValue )
                {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [_contactCloud removeBubble:bubble permanently:YES animated:YES];
                    });
                    
                    [_contactCloud.cloudBubbles removeObjectAtIndex:i];
                    
                    break;
                }
            }
        }
        
        if ( isShowingSearchInterface )
        {
            for ( int i = 0; i < _contactCloud.searchResultsBubbles.count; i++ )
            {
                SHChatBubble *bubble = [_contactCloud.searchResultsBubbles objectAtIndex:i];
                
                if ( bubble.bubbleType == SHChatBubbleTypeUser )
                {
                    int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                    
                    if ( bubbleID == userID.intValue )
                    {
                        [_contactCloud.searchResultsBubbles removeObjectAtIndex:i];
                        
                        break;
                    }
                }
            }
        }
    });
}

- (void)contactManagerDidRemoveContact:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( appDelegate.activeWindow && userID.intValue == _profileView.ownerID.intValue )
    {
        [_profileView didRemoveUser];
    }
    
    [appDelegate.strobeLight deactivateStrobeLight];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( int i = 0; i < _contactCloud.cloudBubbles.count; i++ )
        {
            SHChatBubble *bubble = [_contactCloud.cloudBubbles objectAtIndex:i];
            
            if ( bubble.bubbleType == SHChatBubbleTypeUser )
            {
                int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                
                if ( bubbleID == userID.intValue )
                {
                    [bubble.metadata setObject:@"1" forKey:@"temp"];
                    
                    break;
                }
            }
        }
        
        if ( isShowingSearchInterface )
        {
            for ( int i = 0; i < _contactCloud.searchResultsBubbles.count; i++ )
            {
                SHChatBubble *bubble = [_contactCloud.searchResultsBubbles objectAtIndex:i];
                
                if ( bubble.bubbleType == SHChatBubbleTypeUser )
                {
                    int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                    
                    if ( bubbleID == userID.intValue )
                    {
                        [bubble.metadata setObject:@"1" forKey:@"temp"];
                        
                        break;
                    }
                }
            }
        }
    });
}

- (void)contactManagerDidBlockContact:(NSString *)userID
{
    [self dismissWindow];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( int i = 0; i < _contactCloud.cloudBubbles.count; i++ )
        {
            SHChatBubble *bubble = [_contactCloud.cloudBubbles objectAtIndex:i];
            
            if ( bubble.bubbleType == SHChatBubbleTypeUser )
            {
                int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                
                if ( bubbleID == userID.intValue )
                {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [bubble setBlocked:YES];
                        [bubble.metadata setObject:@"1" forKey:@"blocked"];
                    });
                    
                    break;
                }
            }
        }
        
        if ( isShowingSearchInterface )
        {
            for ( int i = 0; i < _contactCloud.searchResultsBubbles.count; i++ )
            {
                SHChatBubble *bubble = [_contactCloud.searchResultsBubbles objectAtIndex:i];
                
                if ( bubble.bubbleType == SHChatBubbleTypeUser )
                {
                    int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                    
                    if ( bubbleID == userID.intValue )
                    {
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            [bubble setBlocked:YES];
                            [bubble.metadata setObject:@"1" forKey:@"blocked"];
                        });
                        
                        break;
                    }
                }
            }
        }
    });
}

- (void)contactManagerDidUnblockContact:(NSString *)userID
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( int i = 0; i < _contactCloud.cloudBubbles.count; i++ )
        {
            SHChatBubble *bubble = [_contactCloud.cloudBubbles objectAtIndex:i];
            
            if ( bubble.bubbleType == SHChatBubbleTypeUser )
            {
                int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                
                if ( bubbleID == userID.intValue )
                {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [bubble setBlocked:NO];
                        [bubble.metadata setObject:@"0" forKey:@"blocked"];
                    });
                    
                    break;
                }
            }
        }
        
        if ( isShowingSearchInterface )
        {
            for ( int i = 0; i < _contactCloud.searchResultsBubbles.count; i++ )
            {
                SHChatBubble *bubble = [_contactCloud.searchResultsBubbles objectAtIndex:i];
                
                if ( bubble.bubbleType == SHChatBubbleTypeUser )
                {
                    int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                    
                    if ( bubbleID == userID.intValue )
                    {
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            [bubble setBlocked:NO];
                            [bubble.metadata setObject:@"0" forKey:@"blocked"];
                        });
                        
                        break;
                    }
                }
            }
        }
    });
}

- (void)contactManagerRequestDidFailWithError:(NSError *)error
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight negativeStrobeLight];
    NSLog(@"Contact Manager failed: %@", error);
    [self beginMiniFeedRefreshCycle];
    [self refreshMiniFeed];
}

#pragma mark -
#pragma mark UITableViewDataSource methods.

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _SHMiniFeedEntries.count + 1; // +1 to account for the load more cell.
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor clearColor];
    cell.backgroundView = [UIView new];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UITableViewCell *assembledCell;
    int lastIndex = (int)(_SHMiniFeedEntries.count - 1);
    
    if ( indexPath.row == _SHMiniFeedEntries.count )
    {
		static NSString *cellIdentifier = @"LoadMoreCell";
		miniFeedLoadMoreCell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        UIActivityIndicatorView *activityIndicator;
        UIImageView *reloadIcon;
        
		if ( miniFeedLoadMoreCell == nil )
        {
            miniFeedLoadMoreCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            miniFeedLoadMoreCell.frame = CGRectZero;
            
            activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            activityIndicator.frame = CGRectMake(130, 22, 20, 20);
            activityIndicator.tag = 5;
            
            reloadIcon = [[UIImageView alloc] initWithImage:[appDelegate imageFilledWith:[UIColor whiteColor] using:[UIImage imageNamed:@"browser_reload"]]];
            reloadIcon.frame = CGRectMake(118, 1, 32, 41);
            reloadIcon.opaque = YES;
            reloadIcon.tag = 7;
            reloadIcon.hidden = YES;
            
            [activityIndicator startAnimating];
            [miniFeedLoadMoreCell.contentView addSubview:activityIndicator];
            [miniFeedLoadMoreCell.contentView addSubview:reloadIcon];
		}
		
        reloadIcon = (UIImageView *)[miniFeedLoadMoreCell viewWithTag:7];
        activityIndicator = (UIActivityIndicatorView *)[miniFeedLoadMoreCell viewWithTag:5];
        
        if ( _miniFeedDidFinishDownloading )
        {
            if ( endOfMiniFeed )
            {
                miniFeedLoadMoreCell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            else
            {
                miniFeedLoadMoreCell.selectionStyle = UITableViewCellSelectionStyleBlue;
            }
            
            reloadIcon.hidden = YES;
            [activityIndicator stopAnimating];
        }
        else
        {
            if ( miniFeedRefreshDidFailOnScroll )
            {
                reloadIcon.hidden = NO;
            }
            else
            {
                reloadIcon.hidden = YES;
                miniFeedLoadMoreCell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                [activityIndicator startAnimating];
            }
        }
        
		assembledCell = miniFeedLoadMoreCell;
		
	}
    else if ( indexPath.row <= lastIndex )
    {
        static NSString *cellIdentifier = @"MiniFeedCell";
        miniFeedCell = (SHMiniFeedCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        
        if ( miniFeedCell == nil )
        {
            miniFeedCell = [[SHMiniFeedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            miniFeedCell.selectionStyle = UITableViewCellSelectionStyleNone;
            miniFeedCell.frame = CGRectZero;
            
            UILongPressGestureRecognizer *gesture_longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapAndHoldMiniFeedRow:)];
            [miniFeedCell addGestureRecognizer:gesture_longPress];
        }
        
        [miniFeedCell populateCellWithData:[_SHMiniFeedEntries objectAtIndex:indexPath.row]];
        
        assembledCell = miniFeedCell;
    }
    
    return assembledCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.row == _SHMiniFeedEntries.count ) // Cell for loading more.
    {
        return 64;
    }
    else
    {
        int entryType = [[[_SHMiniFeedEntries objectAtIndex:indexPath.row] objectForKey:@"entry_type"] intValue];
        
        if ( entryType == 2 )
        {
            return 85;
        }
        
        NSString *statusText = [[_SHMiniFeedEntries objectAtIndex:indexPath.row] objectForKey:@"message"];
        CGSize textSize_status = [statusText sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE] constrainedToSize:CGSizeMake(200, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
        
        return MAX(75, textSize_status.height + 59);
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    // Disable these to prevent multiple taps.
    _windowCompositionLayer.userInteractionEnabled = NO;
    _SHMiniFeed.allowsSelection = NO;
    
    int lastIndex = (int)_SHMiniFeedEntries.count - 1;
    
    if ( _SHMiniFeedEntries.count > 0 && indexPath.row <= lastIndex )
    {
        NSMutableDictionary *entry = [_SHMiniFeedEntries objectAtIndex:indexPath.row];
        int entryType = [[entry objectForKey:@"entry_type"] intValue];
        int ownerID = [[entry objectForKey:@"owner_id"] intValue];
        int currentUserID = [[appDelegate.currentUser objectForKey:@"user_id"] intValue];
        
        if ( ownerID == currentUserID )
        {
            [self pushWindow:SHAppWindowTypeProfile];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // Restore the bubble of the current conversation window.
                if ( _activeRecipientBubble.metadata )
                {
                    for ( SHChatBubble *theBubble in _contactCloud.cloudBubbles )
                    {
                        int activeBubbleUserID = [[_activeRecipientBubble.metadata objectForKey:@"user_id"] intValue];
                        int targetBubbleUserID = [[theBubble.metadata objectForKey:@"user_id"] intValue];
                        
                        if ( targetBubbleUserID == activeBubbleUserID )
                        {
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                theBubble.hidden = NO;
                                
                                [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                                    theBubble.alpha = 1.0;
                                } completion:^(BOOL finished){
                                    
                                }];
                            });
                            
                            break;
                        }
                    }
                }
                
                _activeRecipientBubble.metadata = nil;
            });
        }
        else
        {
            if ( entryType == 1 )
            {
                [self loadConversationForUser:[entry objectForKey:@"user_id"]];
            }
            else if ( entryType == 2 ) // Ad hoc entry.
            {
                NSSet *tag = [entry objectForKey:@"tag"];
                [_messagesView setAdHocMode:YES withOriginalRecipients:tag];
                [_messagesView clearViewAnimated:NO];
                [_messagesView setRecipientDataForUser:nil];
                [self pushWindow:SHAppWindowTypeMessages];
                
                long double delayInSeconds = 0.15;
                
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [_messagesView loadMessagesForRecipient];
                });
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    // Restore the bubble of the previous conversation window.
                    if ( _activeRecipientBubble.metadata )
                    {
                        for ( SHChatBubble *theBubble in _contactCloud.cloudBubbles )
                        {
                            int activeBubbleUserID = [[_activeRecipientBubble.metadata objectForKey:@"user_id"] intValue];
                            int targetBubbleUserID = [[theBubble.metadata objectForKey:@"user_id"] intValue];
                            
                            if ( targetBubbleUserID == activeBubbleUserID )
                            {
                                dispatch_async(dispatch_get_main_queue(), ^(void){
                                    theBubble.hidden = NO;
                                    
                                    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                                        theBubble.alpha = 1.0;
                                    } completion:^(BOOL finished){
                                        
                                    }];
                                });
                                
                                break;
                            }
                        }
                    }
                    
                    _activeRecipientBubble.metadata = nil;
                });
                
                _mainWindowNipple.hidden = YES;
                
                [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    _activeRecipientBubble.alpha = 0.0;
                } completion:^(BOOL finished){
                    _activeRecipientBubble.hidden = YES;
                }];
            }
        }
    }
    else if ( _miniFeedDidFinishDownloading && !endOfMiniFeed ) // Pagination. Load more feed entries.
    {
        batchNumber++;
        [self downloadMiniFeed];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( _isPickingAliasDP || _isPickingDP )
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    }
    else if ( _isPickingMedia )
    {
        if ( _messagesView.inPrivateMode )
        {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        }
        else
        {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        }
        
        [appDelegate.presenceManager setPresence:SHUserPresenceActivityStopped withTargetID:_messagesView.recipientID forAudience:SHUserPresenceAudienceEveryone];
    }
    
    _isPickingAliasDP = NO;
    _isPickingDP = NO;
    _isPickingMedia = NO;
    _mediaPickerSourceIsCamera = NO;
    activeBubble = nil;
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if ( _isPickingAliasDP || _isPickingDP )
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        
        UIImage *selectedImage = [info objectForKey:UIImagePickerControllerEditedImage];
        
        UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
        container.clipsToBounds = YES;
        
        UIImageView *preview = [[UIImageView alloc] initWithImage:selectedImage];
        preview.contentMode = UIViewContentModeScaleAspectFill;
        preview.frame = CGRectMake(0, 0, 320, 320);
        
        // Center the preview inside the container.
        float oldWidth = selectedImage.size.width;
        float scaleFactor = container.frame.size.width / oldWidth;
        
        float newHeight = selectedImage.size.height * scaleFactor;
        
        if ( newHeight > container.frame.size.height )
        {
            int delta = fabs(newHeight - container.frame.size.height);
            preview.frame = CGRectMake(0, -delta / 2, preview.frame.size.width, preview.frame.size.height);
        }
        else
        {
            preview.frame = CGRectMake(0, 0, preview.frame.size.width, preview.frame.size.height);
        }
        
        [container addSubview:preview];
        
        // Next, we basically take a screenshot of it again.
        UIGraphicsBeginImageContext(container.bounds.size);
        [container.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if ( _isPickingAliasDP )
        {
            [_contactCloud setDP:thumbnail forUser:[activeBubble.metadata objectForKey:@"user_id"]];
        }
        else
        {
            [_profileView mediaPickerDidFinishPickingDP:thumbnail];
        }
    }
    else if ( _isPickingMedia )
    {
        __block id selectedMedia;
        
        if ([mediaType isEqualToString:@"public.image"])
        {
            UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
            selectedMedia = selectedImage;
            
            if ( appDelegate.preference_AutosaveMedia && _mediaPickerSourceIsCamera )
            {
                // Save to Camera Roll.
                UIImageWriteToSavedPhotosAlbum(selectedImage, nil, nil, nil);
            }
            
            [_messagesView beginMediaUploadWithMedia:selectedMedia];
        }
        else if ( [mediaType isEqualToString:@"public.movie"] )
        {
            NSURL *movieURL = [info objectForKey:UIImagePickerControllerMediaURL];
            NSData *webData = [NSData dataWithContentsOfURL:movieURL];
            selectedMedia = webData;
            
            [_messagesView beginMediaUploadWithMedia:selectedMedia];
            
            /*NSString *filePath = nil;
            
            NSString *extension = [movieURL pathExtension];
            NSString *fileNameNoExtension = [[movieURL URLByDeletingPathExtension] lastPathComponent];
            filePath = NSTemporaryDirectory();
            filePath = [filePath stringByAppendingPathComponent:fileNameNoExtension];
            filePath = [filePath stringByAppendingPathExtension:extension];
            
            NSURL *outputURL = [NSURL fileURLWithPath:filePath];
            
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:movieURL options:nil];
            AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
            exportSession.outputURL = outputURL;
            exportSession.outputFileType = AVFileTypeMPEG4;
            [exportSession exportAsynchronouslyWithCompletionHandler:^(void){
                NSData *webData = [NSData dataWithContentsOfURL:outputURL];
                selectedMedia = webData;
                
                [_messagesView beginMediaUploadWithMedia:selectedMedia];
            }];*/
        }
        
        if ( _messagesView.inPrivateMode )
        {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        }
        else
        {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        }
    }
    
    _isPickingAliasDP = NO;
    _isPickingDP = NO;
    _isPickingMedia = NO;
    _mediaPickerSourceIsCamera = NO;
    activeBubble = nil;
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
                [self searchChatCloudForQuery:textFieldValue];
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
    else if ( textField.tag == 7772 ) // Renaming bubble.
    {
        UIView *renamingOverlay = [self.view viewWithTag:777];
        UILabel *placeholderLabel = (UILabel *)[renamingOverlay viewWithTag:7773];
        
        if ( textFieldValue.length > 0 )
        {
            if ( [textFieldValue isEqualToString:@" "] ) // Prevent whitespace searches.
            {
                placeholderLabel.hidden = NO;
                textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }
            else
            {
                placeholderLabel.hidden = YES;
            }
        }
        else
        {
            placeholderLabel.hidden = NO;
        }
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
    if ( textField.tag == 0 ) // Search box.
    {
        [self searchChatCloudForQuery:textField.text];
        [searchBox resignFirstResponder];
    }
    else if ( textField.tag == 7772 ) // Renaming bubble.
    {
        [textField resignFirstResponder];
        [self dismissRenamingInterface];
    }
    
    return NO;
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( actionSheet.tag == 0 ) // Chat Cloud bubble options.
    {
        if ( buttonIndex == 0 )      // Remove contact.
        {
            [self confirmContactDeletion];
        }
        else if ( buttonIndex == 1 ) // Delete chat history.
        {
            [self confirmHistoryDeletion];
        }
        else if ( buttonIndex == 2 ) // Rename contact.
        {
            [self showRenamingInterfaceForBubble:activeBubble];
        }
        else if ( buttonIndex == 3 ) // Change contact picture.
        {
            _isPickingAliasDP = YES;
            
            [self showMediaPicker_Library];
        }
        else if ( buttonIndex == 4 )
        {
            UIImage *customDP = [UIImage imageWithData:[activeBubble.metadata objectForKey:@"alias_dp"]];
            
            if ( customDP ) // Custom pic set for active contact bubble. Remove the pic.
            {
                [_contactCloud removeDPForUser:[activeBubble.metadata objectForKey:@"user_id"]];
            }
            else
            {
                BOOL userIsMuted = [[activeBubble.metadata objectForKey:@"is_muted"] boolValue];
                
                if ( userIsMuted )
                {
                    [self muteUpdatesForUser:[activeBubble.metadata objectForKey:@"user_id"]];
                }
            }
            
            activeBubble = nil;
        }
        else if ( buttonIndex == 5 )
        {
            BOOL userIsMuted = [[activeBubble.metadata objectForKey:@"is_muted"] boolValue];
            
            if ( userIsMuted )
            {
                [self muteUpdatesForUser:[activeBubble.metadata objectForKey:@"user_id"]];
            }
            
            activeBubble = nil;
        }
        else
        {
            activeBubble = nil;
        }
    }
    else if ( actionSheet.tag == 1 ) // Delete contact confirmation.
    {
        if ( buttonIndex == 0 )
        {
            [self hideContact:[activeBubble.metadata objectForKey:@"user_id"]];
        }
    }
    else if ( actionSheet.tag == 2 ) // Delete chat history confirmation.
    {
        if ( buttonIndex == 0 )
        {
            [appDelegate.messageManager deleteConversationHistoryWithUser:[activeBubble.metadata objectForKey:@"user_id"]];
        }
        
        activeBubble = nil;
    }
    else if ( actionSheet.tag == 4 ) // Delete status.
    {
        if ( buttonIndex == 0 )
        {
            [self deleteFeedStatus];
        }
    }
    else if ( actionSheet.tag == 5 ) // Mute/unmute user updates.
    {
        if ( buttonIndex == 0 )
        {
            NSString *userID = [[_SHMiniFeedEntries objectAtIndex:activeMiniFeedIndexPath.row] objectForKey:@"owner_id"];
            
            [self muteUpdatesForUser:userID];
        }
    }
    else if ( actionSheet.tag == 6 ) // Unblock user.
    {
        if ( buttonIndex == 0 )
        {
            [appDelegate.contactManager unblockContact:[activeBubble.metadata objectForKey:@"user_id"]];
        }
        
        activeBubble = nil;
    }
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    // Remove HUD from screen when the HUD was hidden.
    [HUD removeFromSuperview];
    HUD = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
