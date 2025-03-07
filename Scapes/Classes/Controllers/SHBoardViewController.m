//
//  SHBoardViewController.m
//  Nightboard
//
//  Created by Ali.cpp on 3/14/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import <GPUImage/GPUImage.h>

#import "SHBoardViewController.h"

#import "AFHTTPRequestOperationManager.h"
#import "AppDelegate.h"
#import "SHBoardItem.h"
#import "SHBoardDetailsViewController.h"
#import "SHBoardPostComposerViewController.h"
#import "SHBoardPostViewController.h"
#import "SHRecipientPickerViewController.h"
#import "SHSearchViewController.h"

@implementation SHBoardViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        memberPreviewList = [NSMutableArray array];
        posts = [NSMutableArray array];
        
        requestCount = 0;
        coverBlurRadius = 10.0;
        oldXOffset = 0.0;
        userIsMember = NO;
        userDidSendJoinRequest = NO;
        coverDidAnimate = NO;
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    postSize = (int)(appDelegate.screenBounds.size.width / 3);
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0];
    contentView.opaque = YES;
    
    closeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"browser_cancel"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissView)];
    self.navigationItem.leftBarButtonItem = closeButton;
    
    moreActionsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more_blue"] style:UIBarButtonItemStylePlain target:self action:@selector(moreBoardOptions)];
    self.navigationItem.rightBarButtonItem = moreActionsButton;
    
    titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width - 100, 44)];
    self.navigationItem.titleView = titleView;
    
    mainScrollView = [[UIScrollView alloc] initWithFrame:appDelegate.screenBounds];
    mainScrollView.contentSize = CGSizeMake(appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height + 1);
    mainScrollView.opaque = YES;
    mainScrollView.delegate = self;
    mainScrollView.tag = 1;
    
    cover = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 120)];
    cover.backgroundColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
    cover.contentMode = UIViewContentModeScaleAspectFill;
    cover.image = appDelegate.mainMenu.wallpaper.image;
    cover.alpha = 0.7;
    cover.opaque = YES;
    
    coverContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cover.frame.size.width, cover.frame.size.height + 40)];
    coverContainer.backgroundColor = [UIColor blackColor];
    coverContainer.clipsToBounds = YES;
    
    memberPreviewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 64, cover.frame.size.width, cover.frame.size.height + 40)];
    memberPreviewContainer.opaque = YES;
    
    headerBackground = [[UIView alloc] initWithFrame:CGRectMake(0, cover.frame.size.height, appDelegate.screenBounds.size.width, 44)];
    headerBackground.backgroundColor = [UIColor whiteColor];
    
    scrollViewBackground = [[UIView alloc] initWithFrame:CGRectMake(0, headerBackground.frame.origin.y + headerBackground.frame.size.height, appDelegate.screenBounds.size.width, 200)];
    scrollViewBackground.backgroundColor = [UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0];
    
    postContainer = [[UIView alloc] initWithFrame:CGRectMake(0, cover.frame.size.height + 80, appDelegate.screenBounds.size.width, 44)];
    postContainer.backgroundColor = [UIColor whiteColor];
    postContainer.hidden = YES;
    
    leavePostButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [leavePostButton addTarget:self action:@selector(presentPostComposer) forControlEvents:UIControlEventTouchUpInside];
    [leavePostButton setTitle:NSLocalizedString(@"BOARD_POST", nil) forState:UIControlStateNormal];
    [leavePostButton setTitleColor:[UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateNormal];
    [leavePostButton setTitleColor:[UIColor colorWithRed:138/255.0 green:194/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateHighlighted];
    [leavePostButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    leavePostButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:MIN_MAIN_FONT_SIZE];
    leavePostButton.frame = CGRectMake(20, 0, appDelegate.screenBounds.size.width - 40, 20);
    leavePostButton.opaque = YES;
    leavePostButton.hidden = YES;
    
    joinButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [joinButton addTarget:self action:@selector(joinBoard) forControlEvents:UIControlEventTouchUpInside];
    [joinButton setTitle:NSLocalizedString(@"BOARD_JOIN", nil) forState:UIControlStateNormal];
    [joinButton setTitleColor:[UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateNormal];
    [joinButton setTitleColor:[UIColor colorWithRed:138/255.0 green:194/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateHighlighted];
    [joinButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    joinButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:MIN_MAIN_FONT_SIZE];
    joinButton.frame = CGRectMake(20, 0, appDelegate.screenBounds.size.width - 40, 20);
    joinButton.opaque = YES;
    joinButton.hidden = YES;
    
    requestsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [requestsButton addTarget:self action:@selector(viewPendingRequests) forControlEvents:UIControlEventTouchUpInside];
    [requestsButton setTitle:@"0 pending join requests." forState:UIControlStateNormal];
    [requestsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [requestsButton setTitleColor:[UIColor colorWithRed:138/255.0 green:194/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateHighlighted];
    requestsButton.backgroundColor = [UIColor whiteColor];
    requestsButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    requestsButton.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
    requestsButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
    requestsButton.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, 44);
    requestsButton.opaque = YES;
    requestsButton.hidden = YES;
    
    leavePostIcon = [[UIImageView alloc] initWithFrame:CGRectMake(20, 3, 16, 16)];
    leavePostIcon.image = [UIImage imageNamed:@"leave_post"];
    
    joinIcon = [[UIImageView alloc] initWithFrame:CGRectMake(20, 3, 16, 16)];
    joinIcon.image = [UIImage imageNamed:@"join_board"];
    
    privacyIcon = [[UIImageView alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width - 26, 10, 16, 16)];
    privacyIcon.image = [UIImage imageNamed:@"lock_gray"];
    privacyIcon.hidden = YES;
    
    UIImageView *requestsButtonDisclosureIcon = [[UIImageView alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width - 43, 10.5, 16, 23)];
    requestsButtonDisclosureIcon.image = [UIImage imageNamed:@"disclosure_indicator"];
    
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, titleView.frame.size.height / 2 - 10, titleView.frame.size.width, 20)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:MAIN_FONT_SIZE];
    titleLabel.minimumScaleFactor = 8.0 / MAIN_FONT_SIZE;
    titleLabel.numberOfLines = 1;
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    
    subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, titleView.frame.size.width, 14.5)];
    subtitleLabel.backgroundColor = [UIColor clearColor];
    subtitleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:SECONDARY_FONT_SIZE];
    subtitleLabel.minimumScaleFactor = 11.0 / SECONDARY_FONT_SIZE;
    subtitleLabel.numberOfLines = 1;
    subtitleLabel.adjustsFontSizeToFitWidth = YES;
    subtitleLabel.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.alpha = 0.0;
    
    loadStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, appDelegate.screenBounds.size.height / 2 + 70, appDelegate.screenBounds.size.width - 40, 20)];
    loadStatusLabel.backgroundColor = [UIColor clearColor];
    loadStatusLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE];
    loadStatusLabel.minimumScaleFactor = 8.0 / MAIN_FONT_SIZE;
    loadStatusLabel.numberOfLines = 1;
    loadStatusLabel.adjustsFontSizeToFitWidth = YES;
    loadStatusLabel.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
    loadStatusLabel.textAlignment = NSTextAlignmentCenter;
    loadStatusLabel.text = NSLocalizedString(@"GENERIC_LOADING", nil);
    
    dateCreatedLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, appDelegate.screenBounds.size.width - 40, 20)];
    dateCreatedLabel.backgroundColor = [UIColor clearColor];
    dateCreatedLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:MIN_MAIN_FONT_SIZE];
    dateCreatedLabel.minimumScaleFactor = 8.0 / MIN_MAIN_FONT_SIZE;
    dateCreatedLabel.numberOfLines = 1;
    dateCreatedLabel.adjustsFontSizeToFitWidth = YES;
    dateCreatedLabel.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
    
    descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 40, appDelegate.screenBounds.size.width - 40, 20)];
    descriptionLabel.backgroundColor = [UIColor clearColor];
    descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
    descriptionLabel.numberOfLines = 0;
    descriptionLabel.textColor = [UIColor blackColor];
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshBoard) forControlEvents:UIControlEventValueChanged];
    refreshControl.bounds = CGRectMake(refreshControl.bounds.origin.x, headerBackground.frame.origin.y, refreshControl.bounds.size.width, refreshControl.bounds.size.height);
    
    if ( !(IS_IOS7) )
    {
        titleLabel.textColor = [UIColor whiteColor];
        subtitleLabel.textColor = [UIColor whiteColor];
        
        memberPreviewContainer.frame = CGRectMake(0, 0, cover.frame.size.width, cover.frame.size.height + 40);
        loadStatusLabel.frame = CGRectMake(20, appDelegate.screenBounds.size.height / 2 + 70, appDelegate.screenBounds.size.width - 40, 20);
    }
    else
    {
        cover.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, 184);
        coverContainer.frame = CGRectMake(0, -64, cover.frame.size.width, cover.frame.size.height + 40);
    }
    
    [joinButton addSubview:joinIcon];
    [leavePostButton addSubview:leavePostIcon];
    [requestsButton addSubview:requestsButtonDisclosureIcon];
    [titleView addSubview:titleLabel];
    [titleView addSubview:subtitleLabel];
    [coverContainer addSubview:cover];
    [coverContainer addSubview:memberPreviewContainer];
    [headerBackground addSubview:privacyIcon];
    [headerBackground addSubview:dateCreatedLabel];
    [headerBackground addSubview:descriptionLabel];
    [headerBackground addSubview:leavePostButton];
    [headerBackground addSubview:joinButton];
    [mainScrollView addSubview:coverContainer];
    [mainScrollView addSubview:scrollViewBackground];
    [mainScrollView addSubview:headerBackground];
    [mainScrollView addSubview:refreshControl];
    [mainScrollView addSubview:requestsButton];
    [mainScrollView addSubview:postContainer];
    [mainScrollView addSubview:loadStatusLabel];
    [contentView addSubview:mainScrollView];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    titleLabel.text = NSLocalizedString(@"GENERIC_LOADING", nil);
    
    [self loadBoardBatch:0];
}

- (void)viewDidAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [super viewDidAppear:animated];
    
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionNavigationBar];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dismissView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)moreBoardOptions
{
    SHBoardDetailsViewController *detailsView = [[SHBoardDetailsViewController alloc] init];
    detailsView.boardID = _boardID;
    detailsView.coverPhoto = coverPhoto;
    detailsView.boardName = boardName;
    detailsView.boardDescription = boardDescription;
    detailsView.privacy = boardPrivacy;
    
    if ( userIsMember && memberCount == 1 ) // The board will be deleted if they leave.
    {
        detailsView.isLastMember = YES;
    }
    
    [self.navigationController pushViewController:detailsView animated:YES];
}

- (void)presentPostComposer
{
    SHBoardPostComposerViewController *composer = [[SHBoardPostComposerViewController alloc] init];
    composer.boardID = _boardID;
    
    [self.navigationController pushViewController:composer animated:YES];
}

- (void)presentSearchWithQuery:(NSString *)query
{
    SHSearchViewController *searchView = [[SHSearchViewController alloc] init];
    searchView.boardID = _boardID;
    searchView.boardName = boardName;
    
    UINavigationController *searchViewNavigationController = [[UINavigationController alloc] initWithRootViewController:searchView];
    
    [self presentViewController:searchViewNavigationController animated:YES completion:^{
        if ( [query isKindOfClass:[NSString class]] )
        {
            [searchView searchForQuery:query];
        }
        else
        {
            [searchView clearSearchField];
            [searchView enableSearchInterface];
        }
    }];
}

- (void)tappedPost:(id)sender
{
    SHBoardItem *tappedItem = (SHBoardItem *)sender;
    SHBoardPostViewController *postView = [[SHBoardPostViewController alloc] init];
    postView.boardName = boardName;
    [postView setPost:tappedItem.data];
    
    [self.navigationController pushViewController:postView animated:YES];
}

- (void)viewPendingRequests
{
    SHRecipientPickerViewController *recipientPicker = [[SHRecipientPickerViewController alloc] init];
    recipientPicker.boardID = _boardID;
    recipientPicker.mode = SHRecipientPickerModeBoardRequests;
    
    [self.navigationController pushViewController:recipientPicker animated:YES];
}

- (void)markPostAsViewed:(NSString *)postID
{
    for ( int i = 0; i < posts.count; i++ )
    {
        SHBoardItem *post = [posts objectAtIndex:i];
        NSString *targetPostID = [post.data objectForKey:@"post_id"];
        
        if ( targetPostID.intValue == postID.intValue )
        {
            [post.data setObject:@"1" forKey:@"viewed"];
            [posts setObject:post atIndexedSubscript:i];
            
            break;
        }
    }
}

- (void)joinBoard
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight activateStrobeLight];
    
    joinButton.enabled = NO;
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[_boardID]
                                                                          forKeys:@[@"board_id"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/joinboard", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                if ( boardPrivacy == SHPrivacySettingPrivate )
                {
                    userDidSendJoinRequest = YES;
                }
                else
                {
                    userIsMember = YES;
                    userDidSendJoinRequest = NO;
                }
                
                [self loadBoardBatch:0];
                [appDelegate.strobeLight affirmativeStrobeLight];
            }
            else
            {
                [self showNetworkError];
            }
        }
        else
        {
            [self showNetworkError];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        joinButton.enabled = NO;
        
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)loadBoardBatch:(int)batchNo
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight activateStrobeLight];
    [refreshControl beginRefreshing];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[_boardID]
                                                                          forKeys:@[@"board_id"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/getboardinfo", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                // Clear out all post views & member bubbles.
                [[postContainer subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
                [[memberPreviewContainer subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
                
                NSDictionary *response = [responseData objectForKey:@"response"];
                memberPreviewList = [[response objectForKey:@"members"] mutableCopy];
                posts = [[response objectForKey:@"posts"] mutableCopy];
                boardName = [response objectForKey:@"name"];
                memberCount = [[response objectForKey:@"member_count"] intValue];
                boardPrivacy = [[response objectForKey:@"privacy"] intValue];
                userIsMember = [[response objectForKey:@"user_is_member"] boolValue];
                dateCreated = [dateFormatter dateFromString:[response objectForKey:@"date_created"]];
                
                if ( boardPrivacy == SHPrivacySettingPrivate )
                {
                    requestCount = [[response objectForKey:@"request_count"] intValue];
                    userDidSendJoinRequest = [[response objectForKey:@"user_requested_join"] boolValue];
                }
                else
                {
                    requestCount = 0;
                    userDidSendJoinRequest = NO;
                }
                
                for ( int i = 0; i < posts.count; i++ )
                {
                    NSMutableDictionary *post = [[posts objectAtIndex:i] mutableCopy];
                    [post setObject:@"0" forKey:@"viewed"];
                    
                    [posts setObject:post atIndexedSubscript:i];
                }
                
                if ( [response objectForKey:@"description"] && ![[NSNull null] isEqual:[response objectForKey:@"description"]] )
                {
                    boardDescription = [response objectForKey:@"description"];
                }
                else
                {
                    boardDescription = @"";
                }
                
                if ( [response objectForKey:@"cover_hash"] && ![[NSNull null] isEqual:[response objectForKey:@"cover_hash"]] )
                {
                    coverHash = [response objectForKey:@"cover_hash"];
                }
                else
                {
                    coverHash = @"";
                }
                
                [appDelegate.modelManager executeUpdate:@"UPDATE sh_board SET name = :name, description = :description, privacy = :privacy "
                 @"WHERE board_id = :board_id"
                                withParameterDictionary:@{@"name": boardName,
                                                          @"description": boardDescription,
                                                          @"privacy": [NSString stringWithFormat:@"%d", boardPrivacy],
                                                          @"board_id": _boardID}];
                
                [self loadCoverPhoto];
                [self reloadBoardData];
                [self processMemberPreview];
                [appDelegate.strobeLight deactivateStrobeLight];
            }
            else
            {
                [self showNetworkError];
            }
        }
        else
        {
            [self showNetworkError];
        }
        
        [refreshControl endRefreshing];
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [refreshControl endRefreshing];
        [self showNetworkError];
        [self loadBoardBatch:batchNo];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)refreshBoard
{
    batch = 0;
    
    [self loadBoardBatch:batch];
}

- (void)reloadBoardData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( boardPrivacy == SHPrivacySettingPrivate )
    {
        if ( userIsMember )
        {
            loadStatusLabel.hidden = YES;
            joinButton.hidden = YES;
            leavePostButton.hidden = NO;
            privacyIcon.hidden = NO;
            postContainer.hidden = NO;
            moreActionsButton.enabled = YES;
            
            if ( requestCount > 0 )
            {
                requestsButton.hidden = NO;
            }
            else
            {
                requestsButton.hidden = YES;
            }
        }
        else
        {
            if ( userDidSendJoinRequest )
            {
                [joinButton setTitle:NSLocalizedString(@"BOARD_REQUEST_SENT", nil) forState:UIControlStateNormal];
                joinButton.enabled = NO;
                
                joinIcon.alpha = 0.5;
            }
            else
            {
                [joinButton setTitle:NSLocalizedString(@"BOARD_REQUEST", nil) forState:UIControlStateNormal];
                joinButton.enabled = YES;
                
                joinIcon.alpha = 1.0;
            }
            
            joinButton.hidden = NO;
            
            loadStatusLabel.text = NSLocalizedString(@"BOARD_PRIVATE", nil);
            loadStatusLabel.hidden = NO;
            leavePostButton.hidden = YES;
            privacyIcon.hidden = YES;
            requestsButton.hidden = YES;
            postContainer.hidden = YES;
            moreActionsButton.enabled = NO;
        }
    }
    else
    {
        privacyIcon.hidden = YES;
        requestsButton.hidden = YES;
        postContainer.hidden = NO;
        joinButton.enabled = YES;
        
        if ( userIsMember )
        {
            joinButton.hidden = YES;
            leavePostButton.hidden = NO;
            moreActionsButton.enabled = YES;
        }
        else
        {
            [joinButton setTitle:NSLocalizedString(@"BOARD_JOIN", nil) forState:UIControlStateNormal];
            
            joinIcon.alpha = 1.0;
            
            leavePostButton.hidden = YES;
            joinButton.hidden = NO;
            moreActionsButton.enabled = NO;
        }
        
        if ( posts.count == 0 )
        {
            loadStatusLabel.text = NSLocalizedString(@"BOARD_EMPTY", nil);
            loadStatusLabel.hidden = NO;
        }
        else
        {
            loadStatusLabel.hidden = YES;
        }
    }
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    NSString *prettyMemberCount = [formatter stringFromNumber:[NSNumber numberWithLong:memberCount]];
    NSString *prettyRequestCount = [formatter stringFromNumber:[NSNumber numberWithLong:requestCount]];
    
    titleLabel.text = boardName;
    subtitleLabel.text = [NSString stringWithFormat:@"%@ member%@.", prettyMemberCount, memberCount == 1 ? @"" : @"s"];
    dateCreatedLabel.text = [[NSString stringWithFormat:@"created %@.", [appDelegate dayForTime:dateCreated relative:YES condensed:NO]] uppercaseString];
    descriptionLabel.text = boardDescription;
    [requestsButton setTitle:[NSString stringWithFormat:@"%@ pending join request%@.", prettyRequestCount, requestCount == 1 ? @"" : @"s"] forState:UIControlStateNormal];
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        titleLabel.frame = CGRectMake(titleLabel.frame.origin.x, 5, titleLabel.frame.size.width, titleLabel.frame.size.height);
        subtitleLabel.alpha = 1.0;
    } completion:^(BOOL finished){
        
    }];
    
    int rows = floor(posts.count / 3);
    
    if ( posts.count % 3 != 0 )
    {
        rows += posts.count % 3;
    }
    
    for ( int i = 0; i < rows; i++ )
    {
        for ( int j = 0; j < 3; j++ )
        {
            int currentIndex = (i * 3) + j;
            
            if ( currentIndex < posts.count )
            {
                NSMutableDictionary *post = [posts objectAtIndex:currentIndex];
                
                SHBoardItem *item = [[SHBoardItem alloc] init];
                [item addTarget:self action:@selector(tappedPost:) forControlEvents:UIControlEventTouchUpInside];
                SHPostColor color = [[post objectForKey:@"color"] intValue];
                item.data = post;
                
                // Add some padding between the items.
                CGRect frame = CGRectMake(postSize * j, postSize * i, postSize - 1, postSize - 1);
                
                // Column padding.
                if ( j == 1 )
                {
                    frame = CGRectMake(postSize * j + 0.5, frame.origin.y, frame.size.width, frame.size.height);
                }
                else if ( j == 2)
                {
                    frame = CGRectMake(postSize * j + 1, frame.origin.y, frame.size.width, frame.size.height);
                }
                
                if ( i > 0 )
                {
                    frame = CGRectMake(frame.origin.x, postSize * i + 1, frame.size.width, frame.size.height);
                }
                
                item.frame = frame;
                [item setText:[post objectForKey:@"text"]]; // NOTE: set the text AFTER the frame.
                [item setColor:[appDelegate colorForCode:color]];
                
                [posts setObject:item atIndexedSubscript:currentIndex];
                [postContainer addSubview:item];
            }
        }
    }
    
    CGSize maxSize = CGSizeMake(appDelegate.screenBounds.size.width - 40, CGFLOAT_MAX);
    CGSize textSize_description = [boardDescription sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE] constrainedToSize:maxSize lineBreakMode:NSLineBreakByWordWrapping];
    CGSize textSize_leavePost = [leavePostButton.titleLabel.text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:MIN_MAIN_FONT_SIZE] constrainedToSize:maxSize lineBreakMode:NSLineBreakByWordWrapping];
    CGSize textSize_join = [joinButton.titleLabel.text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:MIN_MAIN_FONT_SIZE] constrainedToSize:maxSize lineBreakMode:NSLineBreakByWordWrapping];
    
    leavePostIcon.frame = CGRectMake((joinButton.frame.size.width / 2) - (textSize_leavePost.width / 2) - leavePostIcon.frame.size.width - 10, leavePostIcon.frame.origin.y, leavePostIcon.frame.size.width, leavePostIcon.frame.size.height);
    joinIcon.frame = CGRectMake((joinButton.frame.size.width / 2) - (textSize_join.width / 2)  - joinIcon.frame.size.width - 10, joinIcon.frame.origin.y, joinIcon.frame.size.width, joinIcon.frame.size.height);
    descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y, descriptionLabel.frame.size.width, textSize_description.height);
    joinButton.frame = CGRectMake(joinButton.frame.origin.x, textSize_description.height + 60, joinButton.frame.size.width, joinButton.frame.size.height);
    leavePostButton.frame = CGRectMake(leavePostButton.frame.origin.x, textSize_description.height + 60, leavePostButton.frame.size.width, leavePostButton.frame.size.height);
    descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y, descriptionLabel.frame.size.width, textSize_description.height);
    headerBackground.frame = CGRectMake(0, headerBackground.frame.origin.y, headerBackground.frame.size.width, textSize_description.height + joinButton.frame.size.height + 80);
    scrollViewBackground.frame = CGRectMake(0, headerBackground.frame.origin.y + headerBackground.frame.size.height, appDelegate.screenBounds.size.width, 200);
                            
    if ( requestCount > 0 )
    {
        requestsButton.frame = CGRectMake(requestsButton.frame.origin.x, headerBackground.frame.origin.y + headerBackground.frame.size.height + 20, requestsButton.frame.size.width, requestsButton.frame.size.height);
    }
    else
    {
        requestsButton.frame = CGRectMake(requestsButton.frame.origin.x, headerBackground.frame.origin.y + headerBackground.frame.size.height - requestsButton.frame.size.height, requestsButton.frame.size.width, requestsButton.frame.size.height);
    }
    
    postContainer.frame = CGRectMake(postContainer.frame.origin.x, requestsButton.frame.origin.y + requestsButton.frame.size.height + 20, postContainer.frame.size.width, rows * postSize);
    
    if ( !(IS_IOS7) )
    {
        mainScrollView.contentSize = CGSizeMake(mainScrollView.frame.size.width, MAX(appDelegate.screenBounds.size.height - 1, postContainer.frame.origin.y + postContainer.frame.size.height + 44));
    }
    else
    {
        mainScrollView.contentSize = CGSizeMake(mainScrollView.frame.size.width, MAX(appDelegate.screenBounds.size.height - 63, postContainer.frame.origin.y + postContainer.frame.size.height));
    }
}

- (void)processMemberPreview
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int padding = 20;
        int bubblesAcross = appDelegate.screenBounds.size.width / (CHAT_CLOUD_BUBBLE_SIZE_MINI + padding);
        
        for ( int i = 0; i < 2; i++ )
        {
            for ( int j = 0; j < bubblesAcross; j++ )
            {
                int index = bubblesAcross * i + j;
                
                if ( index < memberPreviewList.count )
                {
                    NSMutableDictionary *member = [[memberPreviewList objectAtIndex:i] mutableCopy];
                    UIImage *currentDP = [UIImage imageNamed:@"user_placeholder"];
                    NSString *userID = [member objectForKey:@"user_id"];
                    NSString *DPHash = @"";
                    
                    
                    if ( [member objectForKey:@"dp_hash"] && ![[NSNull null] isEqual:[member objectForKey:@"dp_hash"]] )
                    {
                        DPHash = [member objectForKey:@"dp_hash"];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        SHChatBubble *bubble = [[SHChatBubble alloc] initWithFrame:CGRectMake((CHAT_CLOUD_BUBBLE_SIZE_MINI + padding) * j + padding,
                                                                                              (CHAT_CLOUD_BUBBLE_SIZE_MINI + padding) * i + (padding / 2) + 2,
                                                                                              CHAT_CLOUD_BUBBLE_SIZE_MINI,
                                                                                              CHAT_CLOUD_BUBBLE_SIZE_MINI)
                                                                          andImage:currentDP
                                                               withMiniModeEnabled:YES];
                        bubble.delegate = self;
                        [bubble setBubbleMetadata:member];
                        [memberPreviewContainer addSubview:bubble];
                    });
                    
                    // DP loading.
                    if ( DPHash && DPHash.length > 0 )
                    {
                        NSURL *DPURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/userphotos/%@/profile/f_%@.jpg", SH_DOMAIN, userID, DPHash]];
                        
                        NSURLRequest *request = [NSURLRequest requestWithURL:DPURL];
                        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                            UIImage *testDP = [UIImage imageWithData:data];
                            
                            if ( testDP )
                            {
                                // Now we update the list directly.
                                for ( SHChatBubble *bubble in memberPreviewContainer.subviews )
                                {
                                    int bubbleID = [[member objectForKey:@"user_id"] intValue];
                                    
                                    if ( bubbleID == userID.intValue )
                                    {
                                        dispatch_async(dispatch_get_main_queue(), ^(void){
                                            [bubble setImage:[UIImage imageWithData:data]];
                                        });
                                        
                                        break;
                                    }
                                }
                            }
                        }];
                    }
                }
            }
        }
    });
}

- (void)loadCoverPhoto
{
    BOOL shouldUpdateCover = YES;
    
    if ( _currentCoverHash && _currentCoverHash.length > 0 )
    {
        if ( [_currentCoverHash isEqualToString:coverHash] )
        {
            shouldUpdateCover = NO;
            coverPhoto = _currentCover;
        }
    }
    
    if ( !shouldUpdateCover )
    {
        [self processCoverPhoto];
        
        return;
    }
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/userphotos/scapes/boards/%@/photos/f_%@.jpg", SH_DOMAIN, _boardID, coverHash]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        UIImage *testDP = [UIImage imageWithData:data];
        
        if ( testDP )
        {
            coverPhoto = testDP;
        }
        else // Download failed.
        {
            coverPhoto = nil;
        }
        
        [self processCoverPhoto];
    }];
}
- (void)processCoverPhoto
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( coverPhoto )
    {
        cover.image = coverPhoto; // The blurred version of the image will be set later on below.
        
        [appDelegate.modelManager executeUpdate:@"UPDATE sh_board SET cover_hash = :cover_hash, dp = :dp "
                                                @"WHERE board_id = :board_id"
                        withParameterDictionary:@{@"cover_hash": coverHash,
                                                  @"dp": UIImageJPEGRepresentation(coverPhoto, 1.0),
                                                  @"board_id": _boardID}];
    }
    else
    {
        cover.image = appDelegate.mainMenu.wallpaper.image;
        
        [appDelegate.modelManager executeUpdate:@"UPDATE sh_board SET cover_hash = :cover_hash, dp = :dp "
                                                @"WHERE board_id = :board_id"
                        withParameterDictionary:@{@"cover_hash": @"",
                                                  @"dp": @"",
                                                  @"board_id": _boardID}];
    }
    
    if ( cover.image.size.height > cover.frame.size.height ) // Center the frame if the image overflows.
    {
        float oldWidth = cover.image.size.width;
        float scaleFactor = cover.frame.size.width / oldWidth;
        
        float newHeight = cover.image.size.height * scaleFactor;
        
        if ( newHeight > cover.frame.size.height )
        {
            int delta = newHeight - cover.frame.size.height;
            cover.frame = CGRectMake(cover.frame.origin.x, -delta / 4, cover.frame.size.width, cover.frame.size.height);
        }
        else
        {
            cover.frame = CGRectMake(cover.frame.origin.x, 0, cover.frame.size.width, cover.frame.size.height);
        }
    }
    else
    {
        cover.frame = CGRectMake(cover.frame.origin.x, 0, cover.frame.size.width, cover.frame.size.height);
    }
    
    if ( (IS_IOS7) )
    {
        // When the board loads, all the frame resetting scrolls the view, which fucks up the y-pos of the cover.
        // Reset it again here.
        coverContainer.frame = CGRectMake(0, -64, coverContainer.frame.size.width, coverContainer.frame.size.height);
    }
    
    [self obscureCover];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( int i = 0; i < appDelegate.mainMenu.contactCloud.cloudBubbles.count; i++ )
        {
            SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:i];
            
            if ( bubble.bubbleType == SHChatBubbleTypeBoard )
            {
                int bubbleID = [[bubble.metadata objectForKey:@"board_id"] intValue];
                
                if ( bubbleID == _boardID.intValue )
                {
                    [bubble.metadata setObject:boardName forKey:@"name"];
                    [bubble.metadata setObject:boardDescription forKey:@"description"];
                    [bubble.metadata setObject:[NSString stringWithFormat:@"%d", boardPrivacy] forKey:@"privacy"];
                    [bubble.metadata setObject:coverHash forKey:@"cover_hash"];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [bubble setLabelText:boardName];
                        
                        if ( coverPhoto )
                        {
                            [bubble.metadata setObject:UIImageJPEGRepresentation(coverPhoto, 1.0) forKey:@"dp"];
                            [bubble setImage:coverPhoto];
                        }
                        else
                        {
                            [bubble.metadata setObject:@"" forKey:@"dp"];
                            [bubble setImage:[UIImage imageNamed:@"board_placeholder"]];
                        }
                    });
                    
                    break;
                }
            }
        }
    });
}

- (void)revealCover
{
    if ( !coverDidAnimate )
    {
        coverDidAnimate = YES;
        
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            coverContainer.backgroundColor = [UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0];
            memberPreviewContainer.alpha = 0.0;
            cover.alpha = 1.0;
        } completion:^(BOOL finished){
            
        }];
        
        if ( coverPhoto )
        {
            cover.image = coverPhoto;
        }
    }
}

- (void)obscureCover
{
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        coverContainer.backgroundColor = [UIColor blackColor];
        memberPreviewContainer.alpha = 1.0;
        cover.alpha = 0.7;
    } completion:^(BOOL finished){
        
    }];
    
    if ( coverPhoto )
    {
        UIImage *blurredImage = [self blurImage:coverPhoto radius:coverBlurRadius];
        cover.image = blurredImage;
    }
}

- (UIImage *)blurImage:(UIImage *)sourceImage radius:(float)radius
{
    // Gaussian Blur
    GPUImageGaussianBlurFilter *blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
    blurFilter.blurRadiusInPixels = radius;
    
    return [blurFilter imageByFilteringImage: sourceImage];
}

- (void)showNetworkError
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight negativeStrobeLight];
    [HUD hide:YES];
    
    loadStatusLabel.text = @":(";
    
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
#pragma mark SHChatBubbleDelegate methods.

- (void)didSelectBubble:(SHChatBubble *)bubble
{
    SHRecipientPickerViewController *recipientPicker = [[SHRecipientPickerViewController alloc] init];
    recipientPicker.boardID = _boardID;
    recipientPicker.mode = SHRecipientPickerModeBoardMembers;
    
    [self.navigationController pushViewController:recipientPicker animated:YES];
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods.

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ( scrollView.tag == 1 ) // Main View.
    {
        // These 2 lines are a hack to make sure the end scrolling delegate gets called.
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(scrollViewDidEndScrollingAnimation:) withObject:nil afterDelay:0.1];
        
        if ( !(IS_IOS7) )
        {
            if ( scrollView.contentOffset.y <= 0 )
            {
                if ( coverPhoto )
                {
                    if ( oldXOffset > scrollView.contentOffset.y )
                    {
                        [self revealCover];
                    }
                }
                
                coverContainer.frame = CGRectMake(0, scrollView.contentOffset.y, coverContainer.frame.size.width, coverContainer.frame.size.height);
            }
            else
            {
                coverContainer.frame = CGRectMake(0, 0, coverContainer.frame.size.width, coverContainer.frame.size.height);
            }
        }
        else
        {
            if ( scrollView.contentOffset.y <= -128 )
            {
                coverContainer.frame = CGRectMake(0, scrollView.contentOffset.y + 64, coverContainer.frame.size.width, coverContainer.frame.size.height);
            }
            else
            {
                coverContainer.frame = CGRectMake(0, -64, coverContainer.frame.size.width, coverContainer.frame.size.height);
            }
            
            if ( coverPhoto && scrollView.contentOffset.y <= -64 )
            {
                if ( oldXOffset > scrollView.contentOffset.y )
                {
                    [self revealCover];
                }
            }
        }
        
        oldXOffset = scrollView.contentOffset.y;
    }
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    coverDidAnimate = NO;
    
    [self obscureCover];
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
    // Dispose of any resources that can be recreated.
}

@end
