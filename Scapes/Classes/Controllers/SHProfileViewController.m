//
//  SHProfileViewController..m
//  Nightboard
//
//  Created by MachOSX on 8/20/13.
//
//

#import "SHProfileViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>

#import "AFHTTPRequestOperationManager.h"
#import "Base64.h"
#import "ContactInfoViewController.h"
#import "GalleryViewController.h"
#import "MapViewController.h"
#import "SettingsViewController.h"
#import "SHStatusViewController.h"
#import "WebBrowserViewController.h"

@implementation SHProfileViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        mediaCollection_Received = [NSMutableArray array];
        mediaCollection_Sent = [NSMutableArray array];
        activeMediaArray = mediaCollection_Received;
        
        activeMediaSegmentedControlIndex = 0;
        
        _ownerDataChunk = [NSMutableDictionary dictionary];
        _ownerID = @"";
        _shouldRefreshInfo = NO;
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    
    _upperPane = [[UIView alloc] initWithFrame:CGRectMake(0, -20, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height / 2 - 20)];
    
    // Button action added in viewWillAppear.
    backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setBackgroundImage:[UIImage imageNamed:@"chats_white"] forState:UIControlStateNormal];
    backButton.frame = CGRectMake(10, 5, 34, 34);
    backButton.showsTouchWhenHighlighted = YES;
    
    backButtonBadge = [[UIImageView alloc] initWithFrame:CGRectMake(backButton.frame.size.width + 7, -7, 21, 21)];
    backButtonBadge.image = [[UIImage imageNamed:@"notification_badge"] stretchableImageWithLeftCapWidth:14 topCapHeight:14];
    backButtonBadge.opaque = YES;
    backButtonBadge.alpha = 0.0;
    backButtonBadge.hidden = YES;
    
    backButtonBadgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, backButtonBadge.frame.size.width, backButtonBadge.frame.size.height)];
    backButtonBadgeLabel.backgroundColor = [UIColor clearColor];
    backButtonBadgeLabel.opaque = YES;
    backButtonBadgeLabel.textColor = [UIColor whiteColor];
    backButtonBadgeLabel.textAlignment = NSTextAlignmentCenter;
    backButtonBadgeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:SECONDARY_FONT_SIZE];
    backButtonBadgeLabel.minimumScaleFactor = 8.0 / SECONDARY_FONT_SIZE;
    backButtonBadgeLabel.adjustsFontSizeToFitWidth = YES;
    backButtonBadgeLabel.numberOfLines = 1;
    
    settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingsButton setBackgroundImage:[[UIImage imageNamed:@"button_round_white_transparent"] stretchableImageWithLeftCapWidth:17 topCapHeight:17] forState:UIControlStateNormal];
    [settingsButton addTarget:self action:@selector(presentSettings) forControlEvents:UIControlEventTouchUpInside];
    settingsButton.frame = CGRectMake(appDelegate.screenBounds.size.width - 45, 5, 35, 35);
    settingsButton.showsTouchWhenHighlighted = YES;
    settingsButton.opaque = YES;
    
    statusBubble = [UIButton buttonWithType:UIButtonTypeCustom];
    [statusBubble setBackgroundImage:[[UIImage imageNamed:@"button_round_white_transparent"] stretchableImageWithLeftCapWidth:17 topCapHeight:17] forState:UIControlStateNormal];
    [statusBubble addTarget:self action:@selector(showStatusOptions) forControlEvents:UIControlEventTouchUpInside];
    statusBubble.frame = CGRectMake(55, 5, appDelegate.screenBounds.size.width - (55 * 2), 33);
    statusBubble.alpha = 0.0;
    statusBubble.opaque = YES;
    
    phoneNumberButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [phoneNumberButton addTarget:self action:@selector(callPhoneNumber) forControlEvents:UIControlEventTouchUpInside];
    [phoneNumberButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [phoneNumberButton setTitleColor:[UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateHighlighted];
    phoneNumberButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    phoneNumberButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE];
    phoneNumberButton.frame = CGRectMake(20, 1, appDelegate.screenBounds.size.width - 40, 38);
    phoneNumberButton.opaque = YES;
    
    addressBookInfoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [addressBookInfoButton addTarget:self action:@selector(showAddressBookInfo) forControlEvents:UIControlEventTouchUpInside];
    [addressBookInfoButton setImage:[UIImage imageNamed:@"info_blue"] forState:UIControlStateNormal];
    addressBookInfoButton.frame = CGRectMake(appDelegate.screenBounds.size.width - 70, 0, 41, 41);
    addressBookInfoButton.opaque = YES;
    
    websiteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [websiteButton addTarget:self action:@selector(gotoWebsite) forControlEvents:UIControlEventTouchUpInside];
    [websiteButton setTitleColor:[UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateNormal];
    [websiteButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    websiteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    websiteButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE];
    websiteButton.frame = CGRectMake(20, 41, appDelegate.screenBounds.size.width - 40, 38);
    websiteButton.opaque = YES;
    
    UIImageView *settingsIcon = [[UIImageView alloc] initWithFrame:CGRectMake(9.5, 9.5, 16, 16)];
    settingsIcon.image = [UIImage imageNamed:@"settings_white"];
    settingsIcon.opaque = YES;
    
    UIImageView *detailIcon_sex = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 14, 14)];
    detailIcon_sex.image = [UIImage imageNamed:@"profile_sex_male"];
    detailIcon_sex.opaque = YES;
    detailIcon_sex.tag = 91;
    
    UIImageView *detailIcon_location = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 14, 14)];
    detailIcon_location.image = [UIImage imageNamed:@"profile_location"];
    detailIcon_location.opaque = YES;
    detailIcon_location.tag = 91;
    
    UIImageView *detailIcon_age = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 14, 14)];
    detailIcon_age.image = [UIImage imageNamed:@"profile_birthday"];
    detailIcon_age.opaque = YES;
    detailIcon_age.tag = 91;
    
    statusBubbleTrail_1 = [[UIImageView alloc] init];
    statusBubbleTrail_1.image = [UIImage imageNamed:@"bubble_trail_white_1"];
    statusBubbleTrail_1.opaque = YES;
    statusBubbleTrail_1.alpha = 0.0;
    
    statusBubbleTrail_2 = [[UIImageView alloc] init];
    statusBubbleTrail_2.image = [UIImage imageNamed:@"bubble_trail_white_2"];
    statusBubbleTrail_2.opaque = YES;
    statusBubbleTrail_2.alpha = 0.0;
    
    detailLine_1 = [[UIImageView alloc] init];
    detailLine_1.image = [[UIImage imageNamed:@"profile_detail_line"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    detailLine_1.opaque = YES;
    detailLine_1.alpha = 0.0;
    
    detailLine_2 = [[UIImageView alloc] init];
    detailLine_2.image = [[UIImage imageNamed:@"profile_detail_line"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    detailLine_2.opaque = YES;
    detailLine_2.alpha = 0.0;
    
    detailLine_3 = [[UIImageView alloc] init];
    detailLine_3.image = [[UIImage imageNamed:@"profile_detail_line"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    detailLine_3.opaque = YES;
    detailLine_3.alpha = 0.0;
    
    phoneIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"phone_blue"]];
    phoneIcon.frame = CGRectMake(appDelegate.screenBounds.size.width - 100, 7, 25, 25);
    phoneIcon.opaque = YES;
    
    userBubble = [[SHChatBubble alloc] initWithFrame:CGRectMake(_upperPane.frame.size.width / 2 - CHAT_CLOUD_BUBBLE_SIZE / 2, _upperPane.frame.size.height / 2 - CHAT_CLOUD_BUBBLE_SIZE / 2, CHAT_CLOUD_BUBBLE_SIZE, CHAT_CLOUD_BUBBLE_SIZE)];
    userBubble.alpha = 0.0;
    userBubble.delegate = self;
    
    statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 6, statusBubble.frame.size.width - 20, 17)];
    statusLabel.backgroundColor = [UIColor clearColor];
    statusLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
    statusLabel.numberOfLines = 0;
    statusLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    statusLabel.text = @"...";
    
    usernameLabel = [[UILabel alloc] init];
    usernameLabel.backgroundColor = [UIColor clearColor];
    usernameLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    usernameLabel.textAlignment = NSTextAlignmentCenter;
    usernameLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:SECONDARY_FONT_SIZE];
    usernameLabel.minimumScaleFactor = 8.0 / SECONDARY_FONT_SIZE;
    usernameLabel.adjustsFontSizeToFitWidth = YES;
    usernameLabel.numberOfLines = 1;
    usernameLabel.opaque = YES;
    
    lastSeenLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 16, appDelegate.screenBounds.size.width - 40, 18)];
    lastSeenLabel.backgroundColor = [UIColor clearColor];
    lastSeenLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
    lastSeenLabel.numberOfLines = 1;
    lastSeenLabel.minimumScaleFactor = 8.0 / MIN_MAIN_FONT_SIZE;
    lastSeenLabel.adjustsFontSizeToFitWidth = YES;
    lastSeenLabel.textAlignment = NSTextAlignmentCenter;
    lastSeenLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    lastSeenLabel.shadowOffset = CGSizeMake(0, 1);
    
    joinDateLabel = [[UILabel alloc] init];
    joinDateLabel.backgroundColor = [UIColor clearColor];
    joinDateLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:SECONDARY_FONT_SIZE];
    joinDateLabel.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
    joinDateLabel.numberOfLines = 1;
    joinDateLabel.minimumScaleFactor = 8.0 / SECONDARY_FONT_SIZE;
    joinDateLabel.adjustsFontSizeToFitWidth = YES;
    joinDateLabel.textAlignment = NSTextAlignmentCenter;
    joinDateLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    joinDateLabel.shadowOffset = CGSizeMake(0, 1);
    
    // These labels' widths are set when assigning their random positions in refreshView.
    detailLabel_locationDescription = [[UILabel alloc] initWithFrame:CGRectMake(18, 0, 0, 14)];
    detailLabel_locationDescription.backgroundColor = [UIColor clearColor];
    detailLabel_locationDescription.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:SECONDARY_FONT_SIZE];
    detailLabel_locationDescription.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    detailLabel_locationDescription.tag = 92;
    detailLabel_locationDescription.text = @"Located in";
    
    detailLabel_location = [[UILabel alloc] initWithFrame:CGRectMake(0, 16, 0, 14)];
    detailLabel_location.backgroundColor = [UIColor clearColor];
    detailLabel_location.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:SECONDARY_FONT_SIZE];
    detailLabel_location.numberOfLines = 1;
    detailLabel_location.minimumScaleFactor = 8.0 / SECONDARY_FONT_SIZE;
    detailLabel_location.adjustsFontSizeToFitWidth = YES;
    detailLabel_location.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    detailLabel_location.tag = 90;
    
    detailLabel_sex = [[UILabel alloc] initWithFrame:CGRectMake(18, 0, 0, 14)];
    detailLabel_sex.backgroundColor = [UIColor clearColor];
    detailLabel_sex.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:SECONDARY_FONT_SIZE];
    detailLabel_sex.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    detailLabel_sex.tag = 90;
    detailLabel_sex.text = @"male.";
    
    detailLabel_age = [[UILabel alloc] initWithFrame:CGRectMake(18, 0, 0, 14)];
    detailLabel_age.backgroundColor = [UIColor clearColor];
    detailLabel_age.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:SECONDARY_FONT_SIZE];
    detailLabel_age.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    detailLabel_age.tag = 90;
    
    detail_location = [[UIView alloc] init];
    detail_location.alpha = 0.0;
    
    detail_sex = [[UIView alloc] init];
    detail_sex.alpha = 0.0;
    
    detail_age = [[UIView alloc] init];
    detail_age.alpha = 0.0;
    
    panel_1 = [[UIView alloc] initWithFrame:CGRectMake(0, 5 + lastSeenLabel.frame.origin.y + lastSeenLabel.frame.size.height, appDelegate.screenBounds.size.width, 70)];
    panel_1.backgroundColor = [UIColor whiteColor];
    
    panel_2 = [[UIView alloc] initWithFrame:CGRectMake(0, 35 + panel_1.frame.origin.y + panel_1.frame.size.height, appDelegate.screenBounds.size.width, 90)];
    panel_2.backgroundColor = [UIColor whiteColor];
    
    panel_3 = [[UIView alloc] init];
    panel_3.backgroundColor = [UIColor whiteColor];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 3;
    layout.minimumInteritemSpacing = 0;
    
    mediaCollectionViewBG = [[UIView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 0)];
    mediaCollectionViewBG.backgroundColor = [UIColor whiteColor];
    mediaCollectionViewBG.opaque = YES;
    
    mediaCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 0) collectionViewLayout:layout];
    mediaCollectionView.backgroundColor = [UIColor whiteColor];
    mediaCollectionView.contentInset = UIEdgeInsetsMake(15, 0, 15, 0);
    mediaCollectionView.dataSource = self;
    mediaCollectionView.delegate = self;
    mediaCollectionView.opaque = YES;
    [mediaCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"CellIdentifier"];
    
    instagramButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [instagramButton addTarget:self action:@selector(gotoSocialProfile:) forControlEvents:UIControlEventTouchUpInside];
    [instagramButton setImage:[UIImage imageNamed:@"social_instagram"] forState:UIControlStateNormal];
    [instagramButton setImage:[UIImage imageNamed:@"social_instagram_highlighted"] forState:UIControlStateHighlighted];
    instagramButton.tag = 0;
    
    twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [twitterButton addTarget:self action:@selector(gotoSocialProfile:) forControlEvents:UIControlEventTouchUpInside];
    [twitterButton setImage:[UIImage imageNamed:@"social_twitter"] forState:UIControlStateNormal];
    [twitterButton setImage:[UIImage imageNamed:@"social_twitter_highlighted"] forState:UIControlStateHighlighted];
    twitterButton.tag = 1;
    
    facebookButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [facebookButton addTarget:self action:@selector(gotoSocialProfile:) forControlEvents:UIControlEventTouchUpInside];
    [facebookButton setImage:[UIImage imageNamed:@"social_facebook"] forState:UIControlStateNormal];
    [facebookButton setImage:[UIImage imageNamed:@"social_facebook_highlighted"] forState:UIControlStateHighlighted];
    facebookButton.tag = 2;
    
    windowSideline_left = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"chat_wallpaper_sideline"] stretchableImageWithLeftCapWidth:0 topCapHeight:0]];
    windowSideline_left.opaque = YES;
    
    panel_1_horizontalSeparator_1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 1)];
    panel_1_horizontalSeparator_1.image = [[UIImage imageNamed:@"separator_gray"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    
    panel_1_horizontalSeparator_2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, panel_1.frame.size.height - 1, appDelegate.screenBounds.size.width, 1)];
    panel_1_horizontalSeparator_2.image = [[UIImage imageNamed:@"separator_gray"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    
    panel_1_verticalSeparator_1 = [[UIImageView alloc] initWithFrame:CGRectMake(106, 0, 1, panel_1.frame.size.height)];
    panel_1_verticalSeparator_1.image = [[UIImage imageNamed:@"separator_gray"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    
    panel_1_verticalSeparator_2 = [[UIImageView alloc] initWithFrame:CGRectMake(212, 0, 1, panel_1.frame.size.height)];
    panel_1_verticalSeparator_2.image = [[UIImage imageNamed:@"separator_gray"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    
    panel_2_horizontalSeparator_1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 1)];
    panel_2_horizontalSeparator_1.image = [[UIImage imageNamed:@"separator_gray"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    
    panel_2_horizontalSeparator_2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, panel_2.frame.size.height - 1, appDelegate.screenBounds.size.width, 1)];
    panel_2_horizontalSeparator_2.image = [[UIImage imageNamed:@"separator_gray"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    
    panel_3_horizontalSeparator_1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 1)];
    panel_3_horizontalSeparator_1.image = [[UIImage imageNamed:@"separator_gray"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    
    panel_3_horizontalSeparator_2 = [[UIImageView alloc] initWithFrame:CGRectMake(20, 40, appDelegate.screenBounds.size.width - 20, 1)];
    panel_3_horizontalSeparator_2.image = [[UIImage imageNamed:@"separator_gray"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    
    panel_3_horizontalSeparator_3 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 82, appDelegate.screenBounds.size.width, 1)];
    panel_3_horizontalSeparator_3.image = [[UIImage imageNamed:@"separator_gray"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    
    statLabel_contacts = [[UILabel alloc] initWithFrame:CGRectMake(0, 16, appDelegate.screenBounds.size.width / 3, 20)];
    statLabel_contacts.backgroundColor = [UIColor clearColor];
    statLabel_contacts.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:MAIN_FONT_SIZE];
    statLabel_contacts.textAlignment = NSTextAlignmentCenter;
    
    statLabel_messagesSent = [[UILabel alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width / 3, 16, appDelegate.screenBounds.size.width / 3, 20)];
    statLabel_messagesSent.backgroundColor = [UIColor clearColor];
    statLabel_messagesSent.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:MAIN_FONT_SIZE];
    statLabel_messagesSent.textAlignment = NSTextAlignmentCenter;
    
    statLabel_messagesReceived = [[UILabel alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width / 3 * 2, 16, appDelegate.screenBounds.size.width / 3, 20)];
    statLabel_messagesReceived.backgroundColor = [UIColor clearColor];
    statLabel_messagesReceived.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:MAIN_FONT_SIZE];
    statLabel_messagesReceived.textAlignment = NSTextAlignmentCenter;
    
    descriptionLabel_contacts = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, appDelegate.screenBounds.size.width / 3, 14)];
    descriptionLabel_contacts.backgroundColor = [UIColor clearColor];
    descriptionLabel_contacts.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:SECONDARY_FONT_SIZE];
    descriptionLabel_contacts.textColor = [UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1.0];
    descriptionLabel_contacts.textAlignment = NSTextAlignmentCenter;
    
    descriptionLabel_messagesSent = [[UILabel alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width / 3, 40, appDelegate.screenBounds.size.width / 3, 14)];
    descriptionLabel_messagesSent.backgroundColor = [UIColor clearColor];
    descriptionLabel_messagesSent.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:SECONDARY_FONT_SIZE];
    descriptionLabel_messagesSent.textColor = [UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1.0];
    descriptionLabel_messagesSent.textAlignment = NSTextAlignmentCenter;
    
    descriptionLabel_messagesReceived = [[UILabel alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width / 3 * 2, 40, appDelegate.screenBounds.size.width / 3, 14)];
    descriptionLabel_messagesReceived.backgroundColor = [UIColor clearColor];
    descriptionLabel_messagesReceived.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:SECONDARY_FONT_SIZE];
    descriptionLabel_messagesReceived.textColor = [UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1.0];
    descriptionLabel_messagesReceived.textAlignment = NSTextAlignmentCenter;
    
    bioLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, appDelegate.screenBounds.size.width - 40, 20)];
    bioLabel.backgroundColor = [UIColor clearColor];
    bioLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE];
    bioLabel.numberOfLines = 0;
    
    noMediaLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 74, appDelegate.screenBounds.size.width, MAIN_FONT_SIZE + 5)]; // Hardcode the height because an empty gallery's height is 70px.
    noMediaLabel.backgroundColor = [UIColor clearColor];
    noMediaLabel.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
    noMediaLabel.textAlignment = NSTextAlignmentCenter;
    noMediaLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE];
    noMediaLabel.hidden = YES;
    
    mediaCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 383, appDelegate.screenBounds.size.width, MAIN_FONT_SIZE + 5)]; // Hardcode the height because a populated gallery's height is 350px.
    mediaCountLabel.backgroundColor = [UIColor clearColor];
    mediaCountLabel.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
    mediaCountLabel.textAlignment = NSTextAlignmentCenter;
    mediaCountLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE];
    mediaCountLabel.hidden = YES;
    
    mediaSenderControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"PROFILE_SEGMENT_MEDIA_RECEIVED", nil), NSLocalizedString(@"PROFILE_SEGMENT_MEDIA_SENT", nil)]];
    mediaSenderControl.selectedSegmentIndex = 0;
    [mediaSenderControl addTarget:self action:@selector(mediaSenderTypeChanged:) forControlEvents:UIControlEventValueChanged];
    mediaSenderControl.hidden = YES;
    
    _mainView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height)];
    _mainView.delegate = self;
    _mainView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    _mainView.contentSize = CGSizeMake(_mainView.frame.size.width, appDelegate.screenBounds.size.height + 1);
    _mainView.scrollsToTop = NO;
    _mainView.tag = 7;
    
    UIColor *outerColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    UIColor *innerColor = [UIColor colorWithWhite:1.0 alpha:0.0];
    
    // Adding transparency to the top of the main view.
    maskLayer_mainView = [CAGradientLayer layer];
    maskLayer_mainView.colors = [NSArray arrayWithObjects:(__bridge id)innerColor.CGColor, (__bridge id)innerColor.CGColor, (__bridge id)outerColor.CGColor, nil];
    maskLayer_mainView.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0],
                                    [NSNumber numberWithFloat:0.02],
                                    [NSNumber numberWithFloat:0.08], nil];
    
    maskLayer_mainView.bounds = CGRectMake(0, -20, _mainView.frame.size.width, _mainView.frame.size.height);
    maskLayer_mainView.position = CGPointMake(0, _mainView.contentOffset.y);
    maskLayer_mainView.anchorPoint = CGPointZero;
    _mainView.layer.mask = maskLayer_mainView;
    
    _BG = [[UIImageView alloc] initWithFrame:CGRectMake(0, _upperPane.frame.size.height - 9, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height * 2 + 200)];
    _BG.image = [[UIImage imageNamed:@"std_bg_gray"] stretchableImageWithLeftCapWidth:0 topCapHeight:11];
    _BG.userInteractionEnabled = YES;
    
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        statusLabel.frame = CGRectMake(10, 10, statusBubble.frame.size.width - 15, 17);
        _mainView.frame = CGRectMake(0, -20, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height);
    }
    
    // Show the tooltip on tap-and-hold.
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressStatus:)];
    [statusBubble addGestureRecognizer:longPressRecognizer];
    
    [backButtonBadge addSubview:backButtonBadgeLabel];
    [backButton addSubview:backButtonBadge];
    [settingsButton addSubview:settingsIcon];
    [statusBubble addSubview:statusLabel];
    [phoneNumberButton addSubview:phoneIcon];
    [phoneNumberButton addSubview:addressBookInfoButton];
    [detail_sex addSubview:detailIcon_sex];
    [detail_sex addSubview:detailLabel_sex];
    [detail_location addSubview:detailIcon_location];
    [detail_location addSubview:detailLabel_locationDescription];
    [detail_location addSubview:detailLabel_location];
    [detail_age addSubview:detailIcon_age];
    [detail_age addSubview:detailLabel_age];
    [panel_1 addSubview:panel_1_horizontalSeparator_1];
    [panel_1 addSubview:panel_1_horizontalSeparator_2];
    [panel_1 addSubview:panel_1_verticalSeparator_1];
    [panel_1 addSubview:panel_1_verticalSeparator_2];
    [panel_1 addSubview:statLabel_contacts];
    [panel_1 addSubview:statLabel_messagesSent];
    [panel_1 addSubview:statLabel_messagesReceived];
    [panel_1 addSubview:descriptionLabel_contacts];
    [panel_1 addSubview:descriptionLabel_messagesSent];
    [panel_1 addSubview:descriptionLabel_messagesReceived];
    [panel_2 addSubview:panel_2_horizontalSeparator_1];
    [panel_2 addSubview:panel_2_horizontalSeparator_2];
    [panel_2 addSubview:bioLabel];
    [panel_3 addSubview:panel_3_horizontalSeparator_1];
    [panel_3 addSubview:panel_3_horizontalSeparator_2];
    [panel_3 addSubview:panel_3_horizontalSeparator_3];
    [panel_3 addSubview:phoneNumberButton];
    [panel_3 addSubview:websiteButton];
    [mediaCollectionViewBG addSubview:mediaCollectionView];
    [mediaCollectionViewBG addSubview:mediaSenderControl];
    [mediaCollectionViewBG addSubview:noMediaLabel];
    [mediaCollectionViewBG addSubview:mediaCountLabel];
    [_BG addSubview:instagramButton];
    [_BG addSubview:twitterButton];
    [_BG addSubview:facebookButton];
    [_BG addSubview:lastSeenLabel];
    [_BG addSubview:joinDateLabel];
    [_BG addSubview:mediaCollectionViewBG];
    [_BG addSubview:panel_1];
    [_BG addSubview:panel_2];
    [_BG addSubview:panel_3];
    [_upperPane addSubview:backButton];
    [_upperPane addSubview:settingsButton];
    [_upperPane addSubview:statusBubbleTrail_1];
    [_upperPane addSubview:statusBubbleTrail_2];
    [_upperPane addSubview:statusBubble];
    [_upperPane addSubview:detailLine_1];
    [_upperPane addSubview:detailLine_2];
    [_upperPane addSubview:detailLine_3];
    [_upperPane addSubview:detail_sex];
    [_upperPane addSubview:detail_location];
    [_upperPane addSubview:detail_age];
    [_upperPane addSubview:usernameLabel];
    [_upperPane addSubview:userBubble];
    [_mainView addSubview:_BG];
    [_mainView addSubview:_upperPane];
    [_mainView addSubview:windowSideline_left];
    [contentView addSubview:_mainView];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( [[appDelegate.currentUser objectForKey:@"user_id"] intValue] == [[_ownerDataChunk objectForKey:@"user_id"] intValue] )
    {
        isCurrentUser = YES;
        
        mediaCollectionView.hidden = YES;
    }
    else
    {
        isCurrentUser = NO;
    }
    
    if ( (IS_IOS7) )
    {
        [appDelegate registerPrallaxEffectForView:statusBubbleTrail_1 depth:PARALLAX_DEPTH_LIGHT];
        [appDelegate registerPrallaxEffectForView:statusBubbleTrail_2 depth:PARALLAX_DEPTH_LIGHT];
        [appDelegate registerPrallaxEffectForView:userBubble depth:PARALLAX_DEPTH_HEAVY];
        [appDelegate registerPrallaxEffectForView:usernameLabel depth:PARALLAX_DEPTH_HEAVY];
    }
    
    // The "pop" animation the first time you load the view.
    [userBubble setTransform:CGAffineTransformMakeScale(0.1, 0.1)];
    
    [UIView animateWithDuration:0.25 delay:0.3 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        userBubble.transform = CGAffineTransformMakeScale(1.2, 1.2);
        detailLine_1.alpha = 1.0;
        detailLine_2.alpha = 1.0;
        detailLine_3.alpha = 1.0;
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            userBubble.transform = CGAffineTransformIdentity;
            detail_sex.alpha = 1.0;
            detail_location.alpha = 1.0;
            detail_age.alpha = 1.0;
        } completion:^(BOOL finished){
            
        }];
    }];
    
    [UIView animateWithDuration:0.25 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
        userBubble.alpha = 1.0;
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            statusBubbleTrail_1.alpha = 1.0;
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                statusBubbleTrail_2.alpha = 1.0;
            } completion:^(BOOL finished){
                [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    statusBubble.alpha = 1.0;
                } completion:^(BOOL finished){
                    
                }];
            }];
        }];
    }];
    
    if ( !isCurrentUser )
    {
        mediaSenderControl.hidden = NO;
        
        [self loadMediaFromUser:SHUserTypeRemoteUser reloadView:NO];
    }
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSArray *viewControllers = self.navigationController.viewControllers;
    _mainView.delegate = self;
    
    if ( viewControllers.count == 1 ) // Top level, meaning current user's profile.
    {
        [backButton addTarget:self action:@selector(presentMainMenu) forControlEvents:UIControlEventTouchUpInside];
        
        [_callbackView enableCompositionLayerScrolling]; // Unlock the layer.
    }
    else
    {
        // Overrides.
        [backButton setBackgroundImage:[UIImage imageNamed:@"back_white"] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
        backButton.frame = CGRectMake(10, 7, 31, 31);
        backButton.showsTouchWhenHighlighted = YES;
    }
    
    if ( _shouldRefreshInfo && [_ownerDataChunk objectForKey:@"user_id"] )
    {
        [self refreshViewWithDP:YES];
    }
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if ( !isCurrentUser )
    {
        _mainView.delegate = nil; // Callbacks get send to deallocated instance otherwise.
    }
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if ( viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count - 2] == self ) // View is disappearing because a new view controller was pushed onto the stack.
    {
        [_callbackView disableCompositionLayerScrolling]; // Lock the layer.
    }
    else if ( [viewControllers indexOfObject:self] == NSNotFound ) // View is disappearing because it was popped from the stack.
    {
        [_callbackView enableCompositionLayerScrolling]; // Unlock the layer.
    }
    
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.tintColor = nil;
    
    if ( (IS_IOS7) ) // iOS 7 only.
    {
        self.navigationController.navigationBar.barTintColor = nil;
    }
    
    [super viewDidAppear:animated];
}

- (void)refreshViewWithDP:(BOOL)refreshDP
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    _ownerID = [_ownerDataChunk objectForKey:@"user_id"];
    BOOL spottedUser = [[_ownerDataChunk objectForKey:@"spotted_user"] boolValue];
    BOOL followsUser = [[_ownerDataChunk objectForKey:@"follows_user"] boolValue];
    BOOL temp = NO;
    BOOL showsEmail = NO;
    
    if ( [[appDelegate.currentUser objectForKey:@"user_id"] intValue] == _ownerID.intValue )
    {
        isCurrentUser = YES;
    }
    else
    {
        temp = [[_ownerDataChunk objectForKey:@"temp"] boolValue];
        
        isCurrentUser = NO;
    }
    
    _shouldRefreshInfo = NO; // Reset this.
    
    FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT * FROM sh_thread WHERE thread_id = :last_status_id"
                                    withParameterDictionary:@{@"last_status_id": [_ownerDataChunk objectForKey:@"last_status_id"]}];
    
    while ( [s1 next] )
    {
        statusLabel.text = [s1 stringForColumn:@"message"];
    }
    
    [s1 close];
    
    if ( refreshDP )
    {
        UIImage *currentDP = [UIImage imageWithData:[_ownerDataChunk objectForKey:@"alias_dp"]];
        
        if ( !currentDP )
        {
            currentDP = [UIImage imageWithData:[_ownerDataChunk objectForKey:@"dp"]];
            
            if ( !currentDP )
            {
                currentDP = [UIImage imageNamed:@"user_placeholder"];
            }
        }
        
        [userBubble setImage:currentDP];
    }
    
    NSString *nameText = [_ownerDataChunk objectForKey:@"alias"];
    
    if ( nameText.length == 0 )
    {
        nameText = [NSString stringWithFormat:@"%@ %@", [_ownerDataChunk objectForKey:@"name_first"], [_ownerDataChunk objectForKey:@"name_last"]];
    }
    
    [userBubble setLabelText:nameText withFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:SECONDARY_FONT_SIZE]];
    [self updateNetworkStatus];
    
    if ( isCurrentUser )
    {
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        NSDate *joined = [dateFormatter dateFromString:[_ownerDataChunk objectForKey:@"join_date"]];
        
        [dateFormatter setDateFormat:@"cccc, d MMM, yyyy"];
        
        joinDate = [dateFormatter stringFromDate:joined];
        joinDateLabel.text = [NSString stringWithFormat:@"you joined on %@.", joinDate];
    }
    else
    {
        if ( _mode == SHProfileViewModeAcceptRequest )
        {
            [addUserButton setTitleColor:[UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateNormal];
            [addUserButton setTitle:NSLocalizedString(@"PROFILE_ACCEPT_REQUEST", nil) forState:UIControlStateNormal];
            
            addUserButton.frame = CGRectMake(10, 1, (appDelegate.screenBounds.size.width / 2) - 15, 50);
            addUserButton.hidden = NO;
            declineUserButton.hidden = NO;
        }
        else
        {
            if ( spottedUser )
            {
                if ( temp )
                {
                    [addUserButton setTitleColor:[UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateNormal];
                    [addUserButton setTitle:NSLocalizedString(@"PROFILE_ADD_USER", nil) forState:UIControlStateNormal];
                }
                else
                {
                    [addUserButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
                    [addUserButton setTitle:NSLocalizedString(@"PROFILE_REMOVE_USER", nil) forState:UIControlStateNormal];
                }
                
                addUserButton.frame = CGRectMake(20, 1, appDelegate.screenBounds.size.width - 40, 50);
                addUserButton.hidden = NO;
            }
            else
            {
                addUserButton.hidden = YES;
            }
            
            declineUserButton.hidden = YES;
        }
        
        addUserButton.enabled = YES;
        joinDateLabel.text = @"";
        
        if ( showsEmail && !isCurrentUser )
        {
            joinDateLabel.text = NSLocalizedString(@"PROFILE_HAS_USER_AS_CONTACT", nil);
        }
    }
    
    CGSize textSize_status = [statusLabel.text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE] constrainedToSize:CGSizeMake(statusLabel.frame.size.width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        statusBubble.frame = CGRectMake(55, 5, appDelegate.screenBounds.size.width - (55 * 2), textSize_status.height + 15);
        statusLabel.frame = CGRectMake(10, 10, statusLabel.frame.size.width, textSize_status.height - 3);
    }
    else
    {
        statusBubble.frame = CGRectMake(55, 5, appDelegate.screenBounds.size.width - (55 * 2), textSize_status.height + 17);
        statusLabel.frame = CGRectMake(10, 5, statusLabel.frame.size.width, textSize_status.height + 3);
    }
    
    statusBubbleTrail_1.frame = CGRectMake(110, 75 + (statusBubble.frame.size.height - 33), 9, 9);
    statusBubbleTrail_2.frame = CGRectMake(90, 55 + (statusBubble.frame.size.height - 33), 15, 15);
    
    userBubble.frame = CGRectMake(userBubble.frame.origin.x, (_upperPane.frame.size.height / 2 - CHAT_CLOUD_BUBBLE_SIZE / 2) + (statusBubble.frame.size.height - 33), userBubble.frame.size.width, userBubble.frame.size.height);
    usernameLabel.frame = CGRectMake(20, userBubble.frame.origin.y + userBubble.frame.size.height + 17, appDelegate.screenBounds.size.width - 40, 15);
    
    if ( [[[_ownerDataChunk objectForKey:@"gender"] lowercaseString] isEqualToString:@"m"] )
    {
        gender = @"male";
    }
    else if ( [[[_ownerDataChunk objectForKey:@"gender"] lowercaseString] isEqualToString:@"f"] )
    {
        gender = @"female";
    }
    else
    {
        gender = @"";
    }
    
    NSString *birthday = [_ownerDataChunk objectForKey:@"birthday"];
    NSString *country = [_ownerDataChunk objectForKey:@"location_country"];
    NSString *state = [_ownerDataChunk objectForKey:@"location_state"];
    NSString *city = [_ownerDataChunk objectForKey:@"location_city"];
    username = [_ownerDataChunk objectForKey:@"user_handle"];
    bio = [_ownerDataChunk objectForKey:@"bio"];
    website = [_ownerDataChunk objectForKey:@"website"];
    facebookHandle = [_ownerDataChunk objectForKey:@"facebook_id"];
    twitterHandle = [_ownerDataChunk objectForKey:@"twitter_id"];
    instagramHandle = [_ownerDataChunk objectForKey:@"instagram_id"];
    NSMutableArray *phoneNumbers = [_ownerDataChunk objectForKey:@"phone_numbers"];
    NSMutableArray *socialMediProfiles = [NSMutableArray array];
    BOOL showsPhoneNumber = NO;
    
    if ( isCurrentUser )
    {
        showsPhoneNumber = YES;
    }
    else // For other people, we only display numbers available on the current device.
    {
        for ( NSMutableDictionary *phoneNumberPack in phoneNumbers )
        {
            NSString *countryCallingCode = [phoneNumberPack objectForKey:@"country_calling_code"];
            NSString *prefix = [phoneNumberPack objectForKey:@"prefix"];
            NSString *number = [phoneNumberPack objectForKey:@"phone_number"];
            
            if ( [appDelegate.contactManager numberExistsInAddressBook:number
                                                withCountryCallingCode:countryCallingCode
                                                                prefix:prefix] )
            {
                showsPhoneNumber = YES;
                
                break;
            }
        }
    }
    
    // Sanitize the Facebook link to extract the username/ID.
    if ( [facebookHandle hasPrefix:@"http://www.facebook.com/"] ||
        [facebookHandle hasPrefix:@"https://www.facebook.com/"] ||
        [facebookHandle hasPrefix:@"http://facebook.com/"] ||
        [facebookHandle hasPrefix:@"https://facebook.com/"])
    {
        facebookHandle = [facebookHandle stringByReplacingOccurrencesOfString:@"http://www.facebook.com/" withString:@""];
        facebookHandle = [facebookHandle stringByReplacingOccurrencesOfString:@"https://www.facebook.com/" withString:@""];
        facebookHandle = [facebookHandle stringByReplacingOccurrencesOfString:@"http://facebook.com/" withString:@""];
        facebookHandle = [facebookHandle stringByReplacingOccurrencesOfString:@"https://facebook.com/" withString:@""];
    }
    
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        _upperPane.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height / 2 - 20 + (statusBubble.frame.size.height - 33));
    }
    else
    {
        _upperPane.frame = CGRectMake(0, -20, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height / 2 - 20 + (statusBubble.frame.size.height - 33));
    }
    
    _BG.frame = CGRectMake(_BG.frame.origin.x, _upperPane.frame.size.height - 9 + (statusBubble.frame.size.height - 33), _BG.frame.size.width, _BG.frame.size.height);
    windowSideline_left.frame = CGRectMake(0, _BG.frame.origin.y + 11, 1, _BG.frame.size.height - 11);
    _mainView.contentSize = CGSizeMake(_mainView.contentSize.width, appDelegate.screenBounds.size.height - (statusBubble.frame.size.height - 33));
    
    if ( birthday.length > 0 )
    {
        age = [NSString stringWithFormat:@"%ld", (long)[self ageFromDate:birthday]];
    }
    else
    {
        age = @"";
    }
    
    if ( city.length > 0 )
    {
        location = city;
        
        if ( state.length > 0 )
        {
            location = [location stringByAppendingString:[NSString stringWithFormat:@", %@", state]];
        }
        
        if ( country.length > 0 )
        {
            location = [location stringByAppendingString:[NSString stringWithFormat:@", %@", country]];
        }
    }
    else if ( state.length > 0 )
    {
        location = state;
        
        if ( country.length > 0 )
        {
            location = [location stringByAppendingString:[NSString stringWithFormat:@", %@", country]];
        }
    }
    else if ( country.length > 0 )
    {
        location = country;
    }
    else
    {
        location = @"";
    }
    
    if ( bio.length > 0 )
    {
        panel_2.hidden = NO;
        
        CGSize textSize_bio = [bio sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE] constrainedToSize:CGSizeMake(appDelegate.screenBounds.size.width - 40, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
        
        bioLabel.text = bio;
        bioLabel.frame = CGRectMake(bioLabel.frame.origin.x, bioLabel.frame.origin.y, bioLabel.frame.size.width, textSize_bio.height + 5);
        panel_2.frame = CGRectMake(0, panel_2.frame.origin.y, panel_2.frame.size.width, textSize_bio.height + 25);
        panel_3.frame = CGRectMake(0, panel_2.frame.origin.y + panel_2.frame.size.height + 35, appDelegate.screenBounds.size.width, 41);
        panel_2_horizontalSeparator_2.frame = CGRectMake(0, panel_2.frame.size.height - 1, appDelegate.screenBounds.size.width, 1);
                                         
        _mainView.contentSize = CGSizeMake(_mainView.contentSize.width, _mainView.contentSize.height + textSize_bio.height + 35);
    }
    else
    {
        panel_2.hidden = YES;
        panel_2.frame = CGRectMake(0, panel_2.frame.origin.y, panel_2.frame.size.width, 0);
        
        panel_3.frame = CGRectMake(0, panel_2.frame.origin.y, appDelegate.screenBounds.size.width, 41);
    }
    
    if ( showsPhoneNumber )
    {
        // For now, we're just going to use the first phone number in the array.
        NSDictionary *firstPhoneNumber = [phoneNumbers firstObject];
        NSString *preparedPhoneNumber = [NSString stringWithFormat:@"+%@%@%@", [firstPhoneNumber objectForKey:@"country_calling_code"], [firstPhoneNumber objectForKey:@"prefix"], [firstPhoneNumber objectForKey:@"phone_number"]];
        phoneNumber = [appDelegate.contactManager formatPhoneNumberForDisplay:preparedPhoneNumber];
        [phoneNumberButton setTitle:phoneNumber forState:UIControlStateNormal];
        
        phoneNumberButton.hidden = NO;
        panel_3_horizontalSeparator_2.hidden = NO;
        
        websiteButton.frame = CGRectMake(20, 41, 280, 38);
        panel_3.frame = CGRectMake(0, panel_3.frame.origin.y, appDelegate.screenBounds.size.width, 82);
    }
    else
    {
        phoneNumberButton.hidden = YES;
        panel_3_horizontalSeparator_2.hidden = YES;
        
        websiteButton.frame = CGRectMake(20, 1, 280, 38);
        panel_3.frame = CGRectMake(0, panel_3.frame.origin.y, appDelegate.screenBounds.size.width, 0);
    }
    
    if ( website.length > 0 )
    {
        panel_3_horizontalSeparator_2.frame = CGRectMake(20, 40, appDelegate.screenBounds.size.width - 20, 1);
        panel_3_horizontalSeparator_3.hidden = NO;
        
        [websiteButton setTitle:website forState:UIControlStateNormal];
        
        if ( showsPhoneNumber )
        {
            panel_3.frame = CGRectMake(0, panel_3.frame.origin.y, appDelegate.screenBounds.size.width, 82);
            _mainView.contentSize = CGSizeMake(_mainView.contentSize.width, _mainView.contentSize.height + 41);
        }
    }
    else
    {
        panel_3_horizontalSeparator_2.frame = CGRectMake(0, 40, appDelegate.screenBounds.size.width, 1);
        panel_3_horizontalSeparator_3.hidden = YES;
        
        if ( showsPhoneNumber )
        {
            panel_3.hidden = NO;
            panel_3.frame = CGRectMake(0, panel_3.frame.origin.y, appDelegate.screenBounds.size.width, 41);
        }
        else
        {
            panel_3.hidden = YES;
            panel_3.frame = CGRectMake(0, panel_2.frame.origin.y + panel_2.frame.size.height, appDelegate.screenBounds.size.width, 0);
            
            _mainView.contentSize = CGSizeMake(_mainView.contentSize.width, _mainView.contentSize.height - 41);
        }
    }
    
    BOOL didAccountForSocialButtons = NO;
    instagramButton.hidden = YES;
    twitterButton.hidden = YES;
    facebookButton.hidden = YES;
    
    if ( instagramHandle.length > 0 )
    {
        instagramButton.hidden = NO;
        instagramButton.frame = CGRectMake(45, 35 + panel_3.frame.origin.y + panel_3.frame.size.height, 50, 50);
        
        if ( !didAccountForSocialButtons )
        {
            _mainView.contentSize = CGSizeMake(_mainView.contentSize.width, _mainView.contentSize.height + 85);
            didAccountForSocialButtons = YES;
        }
        
        [socialMediProfiles addObject:instagramButton];
    }
    
    if ( twitterHandle.length > 0 )
    {
        twitterButton.hidden = NO;
        twitterButton.frame = CGRectMake(appDelegate.screenBounds.size.width / 2 - 25, 35 + panel_3.frame.origin.y + panel_3.frame.size.height, 50, 50);
        
        if ( !didAccountForSocialButtons )
        {
            _mainView.contentSize = CGSizeMake(_mainView.contentSize.width, _mainView.contentSize.height + 85);
            didAccountForSocialButtons = YES;
        }
        
        [socialMediProfiles addObject:twitterButton];
    }
    
    if ( facebookHandle.length > 0 )
    {
        facebookButton.hidden = NO;
        facebookButton.frame = CGRectMake(appDelegate.screenBounds.size.width - 95, 35 + panel_3.frame.origin.y + panel_3.frame.size.height, 50, 50);
        
        if ( !didAccountForSocialButtons )
        {
            _mainView.contentSize = CGSizeMake(_mainView.contentSize.width, _mainView.contentSize.height + 85);
            didAccountForSocialButtons = YES;
        }
        
        [socialMediProfiles addObject:facebookButton];
    }
    
    switch ( socialMediProfiles.count )
    {
        case 2:
        {
            UIButton *firstButton = [socialMediProfiles objectAtIndex:0];
            UIButton *secondButton = [socialMediProfiles objectAtIndex:1];
            
            firstButton.frame = CGRectMake(appDelegate.screenBounds.size.width / 2 - firstButton.frame.size.width - 20, firstButton.frame.origin.y, firstButton.frame.size.width, firstButton.frame.size.height);
            secondButton.frame = CGRectMake(appDelegate.screenBounds.size.width / 2 + 20, secondButton.frame.origin.y, secondButton.frame.size.width, secondButton.frame.size.height);
            
            break;
        }
            
        case 1:
        {
            UIButton *firstButton = [socialMediProfiles objectAtIndex:0];
            
            firstButton.frame = CGRectMake(appDelegate.screenBounds.size.width / 2 - (firstButton.frame.size.width / 2), firstButton.frame.origin.y, firstButton.frame.size.width, firstButton.frame.size.height);
            
            break;
        }
            
        default:
            break;
    }
    
    if ( isCurrentUser )
    {
        if ( didAccountForSocialButtons )
        {
            UIButton *firstSocialButton = [socialMediProfiles objectAtIndex:0];
            
            joinDateLabel.frame = CGRectMake(20, 35 + firstSocialButton.frame.origin.y + firstSocialButton.frame.size.height, appDelegate.screenBounds.size.width - 40, 15);
        }
        else
        {
            joinDateLabel.frame = CGRectMake(20, 35 + panel_3.frame.origin.y + panel_3.frame.size.height, appDelegate.screenBounds.size.width - 40, 15);
        }
        
        _mainView.contentSize = CGSizeMake(_mainView.contentSize.width, _mainView.contentSize.height + 25);
    }
    else
    {
        [self calculateMediaBrowserHeightAndScrollToVisible:NO];
    }
    
    if ( age.length > 0 )
    {
        detailLabel_age.text = [NSString stringWithFormat:@"%@ year%@ old.", age, age.intValue == 1 ? @"" : @"s"];
        detail_age.hidden = NO;
    }
    else
    {
        detail_age.hidden = YES;
    }
    
    if ( gender.length > 0 )
    {
        detailLabel_sex.text = [NSString stringWithFormat:@"%@.", gender];
        detail_sex.hidden = NO;
    }
    else
    {
        detail_sex.hidden = YES;
    }
    
    if ( location.length > 0 )
    {
        detailLabel_location.text = [NSString stringWithFormat:@"%@.", location];
        detail_location.hidden = NO;
    }
    else
    {
        detail_location.hidden = YES;
    }
    
    if ( username.length > 0 )
    {
        usernameLabel.text = [NSString stringWithFormat:@"@%@", username];
    }
    
    detailLine_1.hidden = NO;
    detailLine_2.hidden = NO;
    detailLine_3.hidden = NO;
    
    // Reset transforms. Frame drawing gets f'ed up otherwise.
    detailLine_2.transform = CGAffineTransformMakeRotation(0);
    detailLine_3.transform = CGAffineTransformMakeRotation(0);
    
    detailLine_1.frame = CGRectMake(appDelegate.screenBounds.size.width / 2 - 60, _upperPane.frame.size.height / 2 + 10 + (statusBubble.frame.size.height - 33), 70, 1);
    detailLine_2.frame = CGRectMake(appDelegate.screenBounds.size.width / 2 - 10, _upperPane.frame.size.height / 2 - 10 + (statusBubble.frame.size.height - 33), 70, 1);
    detailLine_3.frame = CGRectMake(appDelegate.screenBounds.size.width / 2 - 10, _upperPane.frame.size.height / 2 + 30 + (statusBubble.frame.size.height - 33), 70, 1);
    
    detailLine_2.transform = CGAffineTransformMakeRotation(-0.785398163);
    detailLine_3.transform = CGAffineTransformMakeRotation(0.34906585);
    
    // The detail frames are randomly assigned. (33 is the minimum height of the status bubble)
    CGRect frame_1 = CGRectMake(appDelegate.screenBounds.size.width / 2 - 157, _upperPane.frame.size.height / 2 + (statusBubble.frame.size.height - 33), 94, 14); // MAKE SURE YOU MOD THE CORRESPONDING IF CHECK BELOW FOR THE X CO-ORDINATE VALUE!
    CGRect frame_2 = CGRectMake(appDelegate.screenBounds.size.width / 2 + 53, _upperPane.frame.size.height / 2 - 50 + (statusBubble.frame.size.height - 33), 104, 14);
    CGRect frame_3 = CGRectMake(appDelegate.screenBounds.size.width / 2 + 63, _upperPane.frame.size.height / 2 + 50 + (statusBubble.frame.size.height - 33), 94, 14);
    
    NSMutableArray *frames = [NSMutableArray array];
    [frames addObject:[NSValue valueWithCGRect:frame_1]];
    [frames addObject:[NSValue valueWithCGRect:frame_2]];
    [frames addObject:[NSValue valueWithCGRect:frame_3]];
    
    while ( frames.count > 0 )
    {
        int rand = arc4random_uniform((int)frames.count);
        
        CGRect frame = [[frames objectAtIndex:rand] CGRectValue];
        UIView *targetView;
        
        switch ( frames.count )
        {
            case 1:
            {
                targetView = detail_sex;
                
                if ( detail_sex.hidden )
                {
                    if ( frame.origin.x == appDelegate.screenBounds.size.width / 2 - 157 )
                    {
                        detailLine_1.hidden = YES;
                    }
                    else if ( frame.origin.x == appDelegate.screenBounds.size.width / 2 + 53 )
                    {
                        detailLine_2.hidden = YES;
                    }
                    else
                    {
                        detailLine_3.hidden = YES;
                    }
                }
                
                break;
            }
                
            case 2:
            {
                targetView = detail_age;
                
                if ( detail_age.hidden )
                {
                    if ( frame.origin.x == appDelegate.screenBounds.size.width / 2 - 157 )
                    {
                        detailLine_1.hidden = YES;
                    }
                    else if ( frame.origin.x == appDelegate.screenBounds.size.width / 2 + 53 )
                    {
                        detailLine_2.hidden = YES;
                    }
                    else
                    {
                        detailLine_3.hidden = YES;
                    }
                }
                
                break;
            }
                
            case 3:
            {
                // The location label is taller than the rest.
                frame = CGRectMake(frame.origin.x, frame.origin.y - 11, frame.size.width, 44);
                targetView = detail_location;
                
                if ( detail_location.hidden )
                {
                    if ( frame.origin.x == appDelegate.screenBounds.size.width / 2 - 157 )
                    {
                        detailLine_1.hidden = YES;
                    }
                    else if ( frame.origin.x == appDelegate.screenBounds.size.width / 2 + 53 )
                    {
                        detailLine_2.hidden = YES;
                    }
                    else
                    {
                        detailLine_3.hidden = YES;
                    }
                }
                
                break;
            }
                
            default:
                break;
        }
        
        targetView.frame = frame;
        
        UILabel *label = (UILabel *)[targetView viewWithTag:90];
        UIImageView *icon = (UIImageView *)[targetView viewWithTag:91];
        UILabel *auxiliaryLabel = (UILabel *)[targetView viewWithTag:92];
        
        label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, frame.size.width - label.frame.origin.x, label.frame.size.height);
        
        if ( frame.origin.x == 3 ) // Left side. Align everything to the right.
        {
            label.textAlignment = NSTextAlignmentRight;
            
            if ( auxiliaryLabel )
            {
                label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, frame.size.width, label.frame.size.height);
                auxiliaryLabel.frame = CGRectMake(auxiliaryLabel.frame.origin.x, auxiliaryLabel.frame.origin.y, frame.size.width - auxiliaryLabel.frame.origin.x, auxiliaryLabel.frame.size.height);
                auxiliaryLabel.textAlignment = NSTextAlignmentRight;
                
                CGSize textSize_auxiliaryLabel = [auxiliaryLabel.text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:SECONDARY_FONT_SIZE] constrainedToSize:CGSizeMake(auxiliaryLabel.frame.size.width, 14) lineBreakMode:NSLineBreakByWordWrapping];
                
                icon.frame = CGRectMake(frame.size.width - textSize_auxiliaryLabel.width - icon.frame.size.width - 4, icon.frame.origin.y, icon.frame.size.width, icon.frame.size.height);
            }
            else
            {
                CGSize textSize_label = [label.text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:SECONDARY_FONT_SIZE] constrainedToSize:CGSizeMake(label.frame.size.width, 14) lineBreakMode:NSLineBreakByWordWrapping];
                
                icon.frame = CGRectMake(frame.size.width - textSize_label.width - icon.frame.size.width - 2, icon.frame.origin.y, icon.frame.size.width, icon.frame.size.height);
            }
        }
        else
        {
            icon.frame = CGRectMake(0, icon.frame.origin.y, icon.frame.size.width, icon.frame.size.height);
            label.textAlignment = NSTextAlignmentLeft;
            
            if ( auxiliaryLabel )
            {
                label.frame = CGRectMake(0, label.frame.origin.y, frame.size.width, label.frame.size.height);
                auxiliaryLabel.frame = CGRectMake(auxiliaryLabel.frame.origin.x, auxiliaryLabel.frame.origin.y, frame.size.width - auxiliaryLabel.frame.origin.x, auxiliaryLabel.frame.size.height);
                auxiliaryLabel.textAlignment = NSTextAlignmentLeft;
            }
        }
        
        [frames removeObjectAtIndex:rand];
    }
    
    NSDictionary *parameters = @{@"token": appDelegate.SHToken,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"user_id": _ownerID,
                                 @"full": @"0"};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/getuserinfo", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
            NSDictionary *response = [responseData objectForKey:@"response"];
            followingCount = [[response objectForKey:@"following_count"] intValue];
            followerCount = [[response objectForKey:@"follower_count"] intValue];
            
            [self updateStats];
        }
        
        //NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [appDelegate.strobeLight negativeStrobeLight];
        [self updateStats];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)updateStats
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    int messagesSent = [[_ownerDataChunk objectForKey:@"total_messages_sent"] intValue];
    int messagesReceived = [[_ownerDataChunk objectForKey:@"total_messages_received"] intValue];
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    statLabel_following.text = [formatter stringFromNumber:[NSNumber numberWithLong:followingCount]];
    statLabel_followers.text = [formatter stringFromNumber:[NSNumber numberWithLong:followerCount]];
    
    descriptionLabel_following.text = [NSString stringWithFormat:NSLocalizedString(@"PROFILE_STATS_FOLLOWING", nil), (followingCount == 1 ? @"person" : @"people")];
    descriptionLabel_followers.text = NSLocalizedString(@"PROFILE_STATS_FOLLOWERS", nil);
    
    statLabel_messagesSent.text = [formatter stringFromNumber:[NSNumber numberWithInt:messagesSent]];
    statLabel_messagesReceived.text = [formatter stringFromNumber:[NSNumber numberWithInt:messagesReceived]];
    
    descriptionLabel_messagesSent.text = [NSString stringWithFormat:NSLocalizedString(@"PROFILE_STATS_MESSAGES_SENT", nil), (messagesSent == 1 ? @"" : @"s")];
    descriptionLabel_messagesReceived.text = [NSString stringWithFormat:NSLocalizedString(@"PROFILE_STATS_MESSAGES_RECEIVED", nil), (messagesReceived == 1 ? @"" : @"s")];
    
    if ( isCurrentUser )
    {
        int contactCount = 0;
        
        FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT COUNT(*) FROM sh_cloud WHERE sh_user_id <> :current_user_id"
                                         withParameterDictionary:@{@"current_user_id": [_ownerDataChunk objectForKey:@"user_id"]}];
        
        while ( [s1 next] )
        {
            contactCount = [s1 intForColumnIndex:0];
        }
        
        [s1 close];
        [appDelegate.modelManager.results close];
        [appDelegate.modelManager.DB close];
        
        statLabel_contacts.text = [formatter stringFromNumber:[NSNumber numberWithInt:contactCount]];
        descriptionLabel_contacts.text = [NSString stringWithFormat:NSLocalizedString(@"PROFILE_STATS_CONTACTS", nil), (contactCount == 1 ? @"" : @"s")];
        
        statLabel_contacts.hidden = NO;
        descriptionLabel_contacts.hidden = NO;
        panel_1_verticalSeparator_1.hidden = NO;
        
        panel_1_verticalSeparator_1.frame = CGRectMake(appDelegate.screenBounds.size.width / 3, panel_1_verticalSeparator_2.frame.origin.y, panel_1_verticalSeparator_2.frame.size.width, panel_1_verticalSeparator_2.frame.size.height);
        panel_1_verticalSeparator_2.frame = CGRectMake(appDelegate.screenBounds.size.width / 3 * 2, panel_1_verticalSeparator_2.frame.origin.y, panel_1_verticalSeparator_2.frame.size.width, panel_1_verticalSeparator_2.frame.size.height);
        statLabel_messagesSent.frame = CGRectMake(appDelegate.screenBounds.size.width / 3, statLabel_messagesSent.frame.origin.y, appDelegate.screenBounds.size.width / 3, statLabel_messagesSent.frame.size.height);
        statLabel_messagesReceived.frame = CGRectMake(appDelegate.screenBounds.size.width / 3 * 2, statLabel_messagesReceived.frame.origin.y, appDelegate.screenBounds.size.width / 3, statLabel_messagesReceived.frame.size.height);
        descriptionLabel_messagesSent.frame = CGRectMake(appDelegate.screenBounds.size.width / 3, descriptionLabel_messagesSent.frame.origin.y, appDelegate.screenBounds.size.width / 3, descriptionLabel_messagesSent.frame.size.height);
        descriptionLabel_messagesReceived.frame = CGRectMake(appDelegate.screenBounds.size.width / 3 * 2, descriptionLabel_messagesReceived.frame.origin.y, appDelegate.screenBounds.size.width / 3, descriptionLabel_messagesReceived.frame.size.height);
    }
    else
    {
        statLabel_contacts.hidden = YES;
        descriptionLabel_contacts.hidden = YES;
        panel_1_verticalSeparator_1.hidden = YES;
        
        panel_1_verticalSeparator_2.frame = CGRectMake(appDelegate.screenBounds.size.width / 2, panel_1_verticalSeparator_2.frame.origin.y, panel_1_verticalSeparator_2.frame.size.width, panel_1_verticalSeparator_2.frame.size.height);
        statLabel_messagesSent.frame = CGRectMake(0, statLabel_messagesSent.frame.origin.y, appDelegate.screenBounds.size.width / 2, statLabel_messagesSent.frame.size.height);
        statLabel_messagesReceived.frame = CGRectMake(appDelegate.screenBounds.size.width / 2, statLabel_messagesReceived.frame.origin.y, appDelegate.screenBounds.size.width / 2, statLabel_messagesReceived.frame.size.height);
        descriptionLabel_messagesSent.frame = CGRectMake(0, descriptionLabel_messagesSent.frame.origin.y, appDelegate.screenBounds.size.width / 2, descriptionLabel_messagesSent.frame.size.height);
        descriptionLabel_messagesReceived.frame = CGRectMake(appDelegate.screenBounds.size.width / 2, descriptionLabel_messagesReceived.frame.origin.y, appDelegate.screenBounds.size.width / 2, descriptionLabel_messagesReceived.frame.size.height);
    }
}

- (void)updateNetworkStatus
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( isCurrentUser )
    {
        if ( appDelegate.networkManager.networkState == SHNetworkStateConnected )
        {
            [userBubble setPresence:SHUserPresenceOnline animated:NO];
            lastSeenLabel.text = [NSLocalizedString(@"NETWORK_CONNECTION_STATUS_CONNECTED", nil) uppercaseString];
        }
        else if ( appDelegate.networkManager.networkState == SHNetworkStateConnecting )
        {
            lastSeenLabel.text = [NSLocalizedString(@"NETWORK_CONNECTION_STATUS_CONNECTING", nil) uppercaseString];
        }
        else
        {
            [userBubble setPresence:SHUserPresenceOffline animated:NO];
            lastSeenLabel.text = [NSLocalizedString(@"NETWORK_CONNECTION_STATUS_OFFLINE", nil) uppercaseString];
        }
    }
    else
    {
        NSDate *presenceTimestampDate = [dateFormatter dateFromString:[_ownerDataChunk objectForKey:@"presence_timestamp"]];
        NSString *presenceTimestampString = [appDelegate relativeTimefromDate:presenceTimestampDate shortened:NO condensed:NO];
        SHUserPresence presence = [[_ownerDataChunk objectForKey:@"presence"] intValue];
        
        [userBubble setPresence:presence animated:YES];
        
        if ( presence == SHUserPresenceOffline )
        {
            lastSeenLabel.text = [[NSString stringWithFormat:@"last seen %@", presenceTimestampString] uppercaseString];
        }
        else if ( presence == SHUserPresenceOfflineMasked )
        {
            lastSeenLabel.text = @"OFFLINE.";
        }
        else if ( presence == SHUserPresenceAway )
        {
            lastSeenLabel.text = @"AWAY.";
        }
        else
        {
            lastSeenLabel.text = @"ONLINE.";
        }
    }
}

- (void)updateMenuButtonBadgeCount:(int)count
{
    backButtonBadgeLabel.text = [NSString stringWithFormat:@"%d", count];
    
    if ( count > 99 )
    {
        backButtonBadgeLabel.text = @"99+";
    }
    
    CGSize textSize_count = [backButtonBadgeLabel.text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:SECONDARY_FONT_SIZE] constrainedToSize:CGSizeMake(50, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    
    float width = MAX(textSize_count.width + 10, 21);
    
    if ( count == 0 )
    {
        [backButton setBackgroundImage:[UIImage imageNamed:@"chats_white"] forState:UIControlStateNormal];
        
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            backButtonBadge.frame = CGRectMake(backButton.frame.size.width + 5 - width, backButtonBadge.frame.origin.y, width, backButtonBadge.frame.size.height);
            backButtonBadgeLabel.frame = CGRectMake(backButtonBadgeLabel.frame.origin.x, backButtonBadgeLabel.frame.origin.y, backButtonBadge.frame.size.width, backButtonBadge.frame.size.height);
            backButtonBadge.alpha = 0.0;
        } completion:^(BOOL finished){
            backButtonBadge.hidden = YES;
        }];
    }
    else
    {
        [backButton setBackgroundImage:[UIImage imageNamed:@"chats_white_filled"] forState:UIControlStateNormal];
        
        backButtonBadge.hidden = NO;
        
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            backButtonBadge.frame = CGRectMake(backButton.frame.size.width + 5 - width, backButtonBadge.frame.origin.y, width, backButtonBadge.frame.size.height);
            backButtonBadgeLabel.frame = CGRectMake(backButtonBadgeLabel.frame.origin.x, backButtonBadgeLabel.frame.origin.y, backButtonBadge.frame.size.width, backButtonBadge.frame.size.height);
            backButtonBadge.alpha = 1.0;
        } completion:^(BOOL finished){
            
        }];
    }
}

- (void)presentMainMenu
{
    [_callbackView dismissWindow];
}

- (void)goBack
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.mainMenu stopWallpaperAnimation];
    
    appDelegate.mainMenu.activeRecipientBubble.hidden = NO;
    appDelegate.mainMenu.windowCompositionLayer.scrollEnabled = YES;
    appDelegate.mainMenu.windowCompositionLayer.contentSize = CGSizeMake(appDelegate.screenBounds.size.width * 3 - 40, appDelegate.screenBounds.size.height);
    appDelegate.viewIsDraggable = YES;
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionNavigationBar];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
    
    if ( !appDelegate.mainMenu.messagesView.inPrivateMode )
    {
        if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
        {
            [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav_bar_legacy_white"] forBarMetrics:UIBarMetricsDefault];
            self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:224/255.0 green:224/255.0 blue:224/255.0 alpha:1.0];
            self.navigationController.navigationBar.shadowImage = [UIImage imageNamed:@"nav_bar_shadow_line"];
        }
        else
        {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
            self.navigationController.navigationBar.tintColor = nil;
            self.navigationController.navigationBar.barTintColor = nil;
        }
    }
    else
    {
        if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
        {
            [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav_bar_legacy_dark"] forBarMetrics:UIBarMetricsDefault];
            self.navigationController.navigationBar.tintColor = [UIColor blackColor];
        }
        else
        {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
            self.navigationController.navigationBar.tintColor = nil;
            self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
        }
    }
    
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        appDelegate.mainMenu.wallpaper.alpha = 0.0;
    } completion:^(BOOL finished){
        
    }];
}

- (void)loadMediaFromUser:(SHUserType)userType reloadView:(BOOL)reloadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    noMediaLabel.hidden = NO;
    noMediaLabel.text = NSLocalizedString(@"GENERIC_LOADING", nil);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            if ( userType == SHUserTypeRemoteUser ) // Received.
            {
                if ( mediaCollection_Received.count == 0 )
                {
                    FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_thread "
                                                        @"INNER JOIN sh_message_dispatch "
                                                        @"ON sh_thread.thread_id = sh_message_dispatch.thread_id AND sh_thread.hidden = 0 AND sh_thread.temp = 0 AND (sh_thread.thread_type = :location_type OR sh_thread.media_hash <> -1) AND (sh_message_dispatch.sender_id = :sender_id AND sh_message_dispatch.recipient_id = :recipient_id)"
                               withParameterDictionary:@{@"sender_id": _ownerID,
                                                         @"recipient_id": [appDelegate.currentUser objectForKey:@"user_id"],
                                                         @"location_type": [NSNumber numberWithInt:SHThreadTypeMessageLocation]}];
                    
                    while ( [s1 next] )
                    {
                        NSDictionary *media = [[NSDictionary alloc] initWithObjects:@[[s1 stringForColumn:@"thread_type"],
                                                                                      [s1 stringForColumn:@"location_latitude"],
                                                                                      [s1 stringForColumn:@"location_longitude"],
                                                                                      [s1 dataForColumn:@"media_data"],
                                                                                      [s1 stringForColumn:@"media_local_path"],
                                                                                      [NSJSONSerialization JSONObjectWithData:[s1 dataForColumn:@"media_extra"] options:NSJSONReadingAllowFragments error:nil]]
                                                                            forKeys:@[@"thread_type",
                                                                                      @"location_latitude",
                                                                                      @"location_longitude",
                                                                                      @"media_data",
                                                                                      @"media_local_path",
                                                                                      @"media_extra"]];
                        
                        [mediaCollection_Received addObject:media];
                    }
                    
                    [s1 close];
                }
                
                activeMediaArray = mediaCollection_Received;
            }
            else if ( userType == SHUserTypeCurrentUser ) // Sent.
            {
                if ( mediaCollection_Sent.count == 0 )
                {
                    FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_thread "
                                                        @"INNER JOIN sh_message_dispatch "
                                                        @"ON sh_thread.thread_id = sh_message_dispatch.thread_id AND sh_thread.hidden = 0 AND sh_thread.temp = 0 AND (sh_thread.thread_type = :location_type OR sh_thread.media_hash <> -1) AND (sh_message_dispatch.sender_id = :sender_id AND sh_message_dispatch.recipient_id = :recipient_id)"
                               withParameterDictionary:@{@"sender_id": [appDelegate.currentUser objectForKey:@"user_id"],
                                                         @"recipient_id": _ownerID,
                                                         @"location_type": [NSNumber numberWithInt:SHThreadTypeMessageLocation]}];
                    
                    while ( [s1 next] )
                    {
                        NSDictionary *media = [[NSDictionary alloc] initWithObjects:@[[s1 stringForColumn:@"thread_type"],
                                                                                      [s1 stringForColumn:@"location_latitude"],
                                                                                      [s1 stringForColumn:@"location_longitude"],
                                                                                      [s1 dataForColumn:@"media_data"],
                                                                                      [s1 stringForColumn:@"media_local_path"],
                                                                                      [NSJSONSerialization JSONObjectWithData:[s1 dataForColumn:@"media_extra"] options:NSJSONReadingAllowFragments error:nil]]
                                                                            forKeys:@[@"thread_type",
                                                                                      @"location_latitude",
                                                                                      @"location_longitude",
                                                                                      @"media_data",
                                                                                      @"media_local_path",
                                                                                      @"media_extra"]];
                        
                        [mediaCollection_Sent addObject:media];
                    }
                    
                    [s1 close];
                }
                
                activeMediaArray = mediaCollection_Sent;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [mediaCollectionView reloadData];
                
                if ( reloadView )
                {
                    [self calculateMediaBrowserHeightAndScrollToVisible:YES];
                }
                
                if ( activeMediaArray.count == 0 )
                {
                    noMediaLabel.text = NSLocalizedString(@"PROFILE_NO_MEDIA", nil);
                    mediaCountLabel.hidden = YES;
                }
                else
                {
                    noMediaLabel.hidden = YES;
                    mediaCountLabel.hidden = NO;
                    
                    NSNumberFormatter *formatter = [NSNumberFormatter new];
                    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
                    
                    NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithInteger:activeMediaArray.count]];
                    
                    mediaCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"PROFILE_MEDIA_COUNT", nil), formattedNumber, (activeMediaArray.count == 1 ? @"" : @"s")];
                }
            });
        }];
    });
}

- (void)calculateMediaBrowserHeightAndScrollToVisible:(BOOL)visible
{
    _mainView.contentSize = CGSizeMake(_mainView.contentSize.width, _mainView.contentSize.height - mediaCollectionViewBG.frame.size.height); // Remove it's current height first.
    
    NSMutableArray *socialMediProfiles = [NSMutableArray array];
    BOOL didAccountForSocialButtons = NO;
    
    if ( instagramHandle.length > 0 )
    {
        didAccountForSocialButtons = YES;
        
        [socialMediProfiles addObject:instagramButton];
    }
    
    if ( twitterHandle.length > 0 )
    {
        didAccountForSocialButtons = YES;
        
        [socialMediProfiles addObject:twitterButton];
    }
    
    if ( facebookHandle.length > 0 )
    {
        didAccountForSocialButtons = YES;
        
        [socialMediProfiles addObject:facebookButton];
    }
    
    float collectionViewHeight = MEDIA_GALLERY_PREVIEW_SIZE * 3 + 35;
    
    if ( activeMediaArray.count == 0 )
    {
        collectionViewHeight = 104;
    }
    
    if ( didAccountForSocialButtons )
    {
        UIButton *firstSocialButton = [socialMediProfiles objectAtIndex:0];
        
        mediaCollectionViewBG.frame = CGRectMake(mediaCollectionViewBG.frame.origin.x, 35 + firstSocialButton.frame.origin.y + firstSocialButton.frame.size.height, mediaCollectionViewBG.frame.size.width, collectionViewHeight + 68);
    }
    else
    {
        mediaCollectionViewBG.frame = CGRectMake(mediaCollectionViewBG.frame.origin.x, 35 + panel_3.frame.origin.y + panel_3.frame.size.height, mediaCollectionViewBG.frame.size.width, collectionViewHeight + 68);
    }
    
    mediaSenderControl.frame = CGRectMake((mediaCollectionViewBG.frame.size.width / 2) - 100, 10, 200, 29);
    mediaCollectionView.frame = CGRectMake(0, 34, mediaCollectionViewBG.frame.size.width, collectionViewHeight);
    
    _mainView.contentSize = CGSizeMake(_mainView.contentSize.width, _mainView.contentSize.height + mediaCollectionViewBG.frame.size.height);
    
    if ( visible )
    {
        CGPoint bottomOffset = CGPointMake(0, _mainView.contentSize.height - _mainView.bounds.size.height);
        [_mainView setContentOffset:bottomOffset animated:NO];
    }
}

- (void)presentSettings
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( [[appDelegate.currentUser objectForKey:@"user_id"] intValue] == [[_ownerDataChunk objectForKey:@"user_id"] intValue] )
    {
        SettingsViewController *settingsView = [[SettingsViewController alloc] init];
        [self.navigationController pushViewController:settingsView animated:YES];
        
        _shouldRefreshInfo = YES;
    }
    else
    {
        BOOL blocked = [[_ownerDataChunk objectForKey:@"blocked"] boolValue];
        
        UIActionSheet *actionSheet;
        
        if ( blocked )
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [_ownerDataChunk objectForKey:@"name_first"], [_ownerDataChunk objectForKey:@"name_last"]]
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"OPTION_UNBLOCK_CONTACT", nil), nil];
        }
        else
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [_ownerDataChunk objectForKey:@"name_first"], [_ownerDataChunk objectForKey:@"name_last"]]
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                        destructiveButtonTitle:NSLocalizedString(@"OPTION_BLOCK_CONTACT", nil)
                                             otherButtonTitles:nil];
        }
        
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        actionSheet.tag = 1;
        
        [actionSheet showFromRect:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44) inView:appDelegate.window animated:YES];
    }
}

- (void)showStatusOptions
{
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if ( viewControllers.count == 1 ) // Top level, meaning current user's profile.
    {
        SHStatusViewController *statusView = [[SHStatusViewController alloc] init];
        SHOrientationNavigationController *navigationController = [[SHOrientationNavigationController alloc] initWithRootViewController:statusView];
        navigationController.autoRotates = NO;
        
        [_callbackView dismissWindow];
        [_callbackView setShouldEnterFullscreen:NO];
        [_callbackView presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)showAddressBookInfo
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSMutableArray *phoneNumbers = [_ownerDataChunk objectForKey:@"phone_numbers"];
    
    ContactInfoViewController *infoView = [[ContactInfoViewController alloc] init];
    infoView.phoneNumber = [phoneNumbers firstObject];
    
    if ( (IS_IOS7) )
    {
        [appDelegate.mainWindowNavigationController.navigationBar setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor blackColor]}];
    }
    
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionNavigationBar];
    [self.navigationController pushViewController:infoView animated:YES];
}

- (void)showGalleryForMedia:(id)media atPath:(NSString *)path
{
    NSString *nameText = [_ownerDataChunk objectForKey:@"alias"];
    
    if ( nameText.length == 0 )
    {
        nameText = [_ownerDataChunk objectForKey:@"name_first"];
    }
    
    if ( [media isKindOfClass:[UIImage class]] )
    {
        GalleryViewController *galleryView = [[GalleryViewController alloc] init];
        galleryView.initialMediaData = UIImageJPEGRepresentation(media, 1.0);
        galleryView.mediaLocalPath = path;
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nameText style:UIBarButtonItemStylePlain target:nil action:nil];
        
        [self.navigationController pushViewController:galleryView animated:YES];
    }
}

- (void)showMapForLocation:(NSDictionary *)mediaLocation
{
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([[mediaLocation objectForKey:@"location_latitude"] floatValue], [[mediaLocation objectForKey:@"location_longitude"] floatValue]);
    
    MapViewController *mapView = [[MapViewController alloc] init];
    mapView.locationToLoad = coordinate;
    
    if ( [[mediaLocation objectForKey:@"attachment_value"] isEqualToString:@"venue"] )
    {
        mapView.calloutTitle = [mediaLocation objectForKey:@"venue_name"];
        mapView.calloutSubtitle = [mediaLocation objectForKey:@"venue_country"];
    }
    else
    {
        NSData *base64Data_userThumbnail = [NSData dataWithBase64EncodedString:[mediaLocation objectForKey:@"user_thumbnail"]];
        UIImage *userThumbnail = [UIImage imageWithData:base64Data_userThumbnail];
        
        mapView.thumbnail = userThumbnail;
    }
    
    NSString *nameText = [_ownerDataChunk objectForKey:@"alias"];
    
    if ( nameText.length == 0 )
    {
        nameText = [_ownerDataChunk objectForKey:@"name_first"];
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nameText style:UIBarButtonItemStylePlain target:nil action:nil];
    
    [self.navigationController pushViewController:mapView animated:YES];
}

- (void)addUser
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( !isCurrentUser )
    {
        if ( _mode == SHProfileViewModeAcceptRequest )
        {
            [self acceptUserRequest];
        }
        else
        {
            BOOL temp = [[_ownerDataChunk objectForKey:@"temp"] boolValue];
            
            if ( temp )
            {
                [appDelegate.strobeLight activateStrobeLight];
                [appDelegate.contactManager addUser:_ownerID];
                
                // Show the HUD.
                HUD = [[MBProgressHUD alloc] initWithView:self.view];
                [self.view addSubview:HUD];
                
                HUD.customView = [[UIImageView alloc] init];
                HUD.mode = MBProgressHUDModeIndeterminate;
                HUD.dimBackground = YES;
                HUD.delegate = self;
                [HUD show:YES];
                
                addUserButton.enabled = NO;
            }
            else
            {
                UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", [_ownerDataChunk objectForKey:@"name_first"], [_ownerDataChunk objectForKey:@"name_last"]]
                                                                         delegate:self
                                                                cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                                           destructiveButtonTitle:NSLocalizedString(@"OPTION_DELETE_CONTACT", nil)
                                                                otherButtonTitles:nil];
                
                actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
                actionSheet.tag = 2;
                actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
                [actionSheet showFromRect:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44) inView:appDelegate.window animated:YES];
            }
        }
    }
}

- (void)removeUser
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight activateStrobeLight];
    [appDelegate.contactManager removeUser:_ownerID];
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    addUserButton.enabled = NO;
}

- (void)acceptUserRequest
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight activateStrobeLight];
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    addUserButton.enabled = NO;
    declineUserButton.enabled = NO;
    
    SHRecipientPickerViewController *recipientPicker = (SHRecipientPickerViewController *)_callbackView;
    
    NSDictionary *parameters = @{@"token": appDelegate.SHToken,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"board_id": recipientPicker.boardID,
                                 @"user_id": _ownerID};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/acceptboardrequest", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        [HUD hide:YES];
        
        if ( errorCode == 0 )
        {
            [addUserButton setTitle:NSLocalizedString(@"PROFILE_REQUEST_ACCEPTED", nil) forState:UIControlStateNormal];
            [addUserButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [recipientPicker removeBubbleForUser:_ownerID];
            [appDelegate.strobeLight affirmativeStrobeLight];
            
            addUserButton.frame = CGRectMake(20, 1, appDelegate.screenBounds.size.width - 40, 50);
            
            declineUserButton.hidden = YES;
            
            // We need a slight delay here.
            long double delayInSeconds = 0.45;
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                HUD = [[MBProgressHUD alloc] initWithView:self.view];
                [self.view addSubview:HUD];
                
                HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_white"]];
                
                // Set custom view mode.
                HUD.mode = MBProgressHUDModeCustomView;
                HUD.dimBackground = YES;
                HUD.delegate = self;
                
                [HUD show:YES];
                [HUD hide:YES afterDelay:2];
            });
        }
        else
        {
            addUserButton.enabled = YES;
            declineUserButton.enabled = YES;
            
            [appDelegate.strobeLight negativeStrobeLight];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [appDelegate.strobeLight negativeStrobeLight];
        addUserButton.enabled = YES;
        declineUserButton.enabled = YES;
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)declineUserRequest
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight activateStrobeLight];
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    addUserButton.enabled = NO;
    declineUserButton.enabled = NO;
    
    SHRecipientPickerViewController *recipientPicker = (SHRecipientPickerViewController *)_callbackView;
    
    NSDictionary *parameters = @{@"token": appDelegate.SHToken,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"board_id": recipientPicker.boardID,
                                 @"user_id": _ownerID};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/declineboardrequest", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        [HUD hide:YES];
        
        if ( errorCode == 0 )
        {
            [addUserButton setTitle:NSLocalizedString(@"PROFILE_REQUEST_DECLINED", nil) forState:UIControlStateNormal];
            [addUserButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [recipientPicker removeBubbleForUser:_ownerID];
            [appDelegate.strobeLight deactivateStrobeLight];
            
            addUserButton.frame = CGRectMake(20, 1, appDelegate.screenBounds.size.width - 40, 50);
            
            declineUserButton.hidden = YES;
        }
        else
        {
            addUserButton.enabled = YES;
            declineUserButton.enabled = YES;
            
            [appDelegate.strobeLight negativeStrobeLight];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [appDelegate.strobeLight negativeStrobeLight];
        addUserButton.enabled = YES;
        declineUserButton.enabled = YES;
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)presentFollowing
{
    SHRecipientPickerViewController *recipientPicker = [[SHRecipientPickerViewController alloc] init];
    recipientPicker.userID = _ownerID;
    recipientPicker.mode = SHRecipientPickerModeFollowing;
    
    [self.navigationController pushViewController:recipientPicker animated:YES];
}

- (void)presentFollowers
{
    SHRecipientPickerViewController *recipientPicker = [[SHRecipientPickerViewController alloc] init];
    recipientPicker.userID = _ownerID;
    recipientPicker.mode = SHRecipientPickerModeFollowers;
    
    [self.navigationController pushViewController:recipientPicker animated:YES];
}

- (void)emailUser
{
    NSString *preparedEmail = [NSString stringWithFormat:@"mailto:%@", email];
    NSURL *URL = [NSURL URLWithString:preparedEmail];
    
    [[UIApplication sharedApplication] openURL:URL];
}

- (void)callPhoneNumber
{
    UIDevice *device = [UIDevice currentDevice];
    
    if ([[device model] isEqualToString:@"iPhone"] )
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""]]]]; // Needs to be a URL, so no spaces.
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                               message:NSLocalizedString(@"PROFILE_CALL_ERROR", nil)
                                                              delegate:nil
                                                     cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil)
                                                     otherButtonTitles:nil];
        [alert show];
    }
}

- (void)gotoWebsite
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionNavigationBar];
    
    WebBrowserViewController *webBrowser = [[WebBrowserViewController alloc] init];
    webBrowser.URL = [_ownerDataChunk objectForKey:@"website"];
    webBrowser.shouldReportEndOfActivity = NO;
    
    [self.navigationController pushViewController:webBrowser animated:YES];
}

- (void)gotoSocialProfile:(id)sender
{
    UIButton *socialButton = (UIButton *)sender;
    NSString *formattedURL = @"";
    NSString *formattedAppURL = @"";
    
    switch ( socialButton.tag )
    {
        case 0:
        {
            formattedURL = [NSString stringWithFormat:@"http://instagram.com/%@", instagramHandle];
            formattedAppURL = [NSString stringWithFormat:@"instagram://user?username=%@", instagramHandle];
            
            break;
        }
        
        case 1:
        {
            formattedURL = [NSString stringWithFormat:@"http://twitter.com/%@", twitterHandle];
            formattedAppURL = [NSString stringWithFormat:@"twitter://user?screen_name=%@", twitterHandle];
            
            break;
        }
        
        case 2:
        {
            formattedURL = [NSString stringWithFormat:@"http://facebook.com/%@", facebookHandle];
            formattedAppURL = [NSString stringWithFormat:@"fb://profile/%@", facebookHandle];
            
            break;
        }
        
        default:
            break;
    }
    
    NSURL *url = [NSURL URLWithString:formattedURL];
    NSURL *appUrl = [NSURL URLWithString:formattedAppURL];
    
    if ( ![[UIApplication sharedApplication] openURL:appUrl] )
    {
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (NSInteger)ageFromDate:(NSString *)dateString
{
    if ( dateString.length > 0 )
    {
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        
        NSDate *targetDate = [dateFormatter dateFromString:dateString];
        NSDate *today = [NSDate date];
        NSDateComponents *ageComponents = [[NSCalendar currentCalendar]
                                           components:NSYearCalendarUnit
                                           fromDate:targetDate
                                           toDate:today
                                           options:0];
        return ageComponents.year;
    }
    else
    {
        return -1;
    }
}

- (void)mediaSenderTypeChanged:(id)sender
{
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    
    if ( segmentedControl.selectedSegmentIndex == 0 &&
        segmentedControl.selectedSegmentIndex != activeMediaSegmentedControlIndex )
    {
        [self loadMediaFromUser:SHUserTypeRemoteUser reloadView:YES];
    }
    else if ( segmentedControl.selectedSegmentIndex == 1 &&
             segmentedControl.selectedSegmentIndex != activeMediaSegmentedControlIndex )
    {
        [self loadMediaFromUser:SHUserTypeCurrentUser reloadView:YES];
    }
    
    activeMediaSegmentedControlIndex = segmentedControl.selectedSegmentIndex;
}

#pragma mark -
#pragma mark DP Options

- (void)showDPOptions
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIActionSheet *actionSheet;
    NSString *currentDPHash = [appDelegate.currentUser objectForKey:@"dp_hash"];
    
    if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ) // If the device has a camera.
    {
        if ( currentDPHash.length == 0 )
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"SIGNUP_DP_SHEET_TITLE", nil)
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"GENERIC_PHOTO_CAMERA_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LIBRARY_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LAST_TAKEN", nil), nil];
        }
        else
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"SIGNUP_DP_SHEET_TITLE", nil)
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                        destructiveButtonTitle:NSLocalizedString(@"GENERIC_PHOTO_REMOVE", nil)
                                             otherButtonTitles:NSLocalizedString(@"GENERIC_PHOTO_CAMERA_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LIBRARY_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LAST_TAKEN", nil), nil];
        }
    }
    else
    {
        if ( currentDPHash.length == 0 )
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"SIGNUP_DP_SHEET_TITLE", nil)
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"GENERIC_PHOTO_LIBRARY_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LAST_TAKEN", nil), nil];
        }
        else
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"SIGNUP_DP_SHEET_TITLE", nil)
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                        destructiveButtonTitle:NSLocalizedString(@"GENERIC_PHOTO_REMOVE", nil)
                                             otherButtonTitles:NSLocalizedString(@"GENERIC_PHOTO_LIBRARY_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LAST_TAKEN", nil), nil];
        }
    }
    
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.tag = 0;
    
    [actionSheet showFromRect:self.view.frame inView:appDelegate.window animated:YES];
}

- (void)DP_UseLastPhotoTaken
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    // Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop){
        
        // Within the group enumeration block, filter to enumerate just photos.
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        
        // Chooses the photo at the last index
        [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:[group numberOfAssets] - 1] options:0 usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop){
            
            // The end of the enumeration is signaled by asset == nil.
            if ( alAsset )
            {
                ALAssetRepresentation *representation = [alAsset defaultRepresentation];
                UIImage *selectedImage = [UIImage imageWithCGImage:[representation fullScreenImage]];
                
                CGImageRef imageRef = CGImageCreateWithImageInRect([selectedImage CGImage], CGRectMake(selectedImage.size.width / 2 - 160, selectedImage.size.height / 2 - 160, 320, 320));
                selectedImage = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
                
                UIImageView *preview = [[UIImageView alloc] initWithImage:selectedImage];
                preview.frame = CGRectMake(0, 0, 320, 320);
                
                // Next, we basically take a screenshot of it again.
                UIGraphicsBeginImageContext(preview.bounds.size);
                [preview.layer renderInContext:UIGraphicsGetCurrentContext()];
                UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                newSelectedDP = thumbnail;
                
                [self uploadDP];
            }
        }];
    } failureBlock: ^(NSError *error){
        // Typically you should handle an error more gracefully than this.
        NSLog(@"No groups");
    }];
}

- (void)uploadDP
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight activateStrobeLight];
    
    NSData *imageData = UIImageJPEGRepresentation(newSelectedDP, 1.0);
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[@"mum's the word"]
                                                                          forKeys:@[@"dummy"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"request": jsonString,
                                 @"scope": appDelegate.SHTokenID};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/dpupload", SH_DOMAIN] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        if ( imageData )
        {
            [formData appendPartWithFileData:imageData name:@"image_file" fileName:@"image_file.jpg" mimeType:@"image/jpeg"];
        }
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        [HUD hide:YES];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        if ( errorCode == 0 )
        {
            [appDelegate.strobeLight affirmativeStrobeLight];
            
            NSString *newHash = [responseData objectForKey:@"response"];
            [appDelegate.currentUser setObject:UIImageJPEGRepresentation(newSelectedDP, 1.0) forKey:@"dp"];
            [appDelegate.currentUser setObject:newHash forKey:@"dp_hash"];
            [userBubble setImage:newSelectedDP];
            
            [appDelegate.modelManager executeUpdate:@"UPDATE sh_current_user SET dp_hash = :dp_hash, dp = :dp"
                            withParameterDictionary:@{@"dp_hash": newHash,
                                                      @"dp": UIImageJPEGRepresentation(newSelectedDP, 1.0)}];
            
            [appDelegate.modelManager executeUpdate:@"UPDATE sh_cloud SET dp_hash = :dp_hash, dp = :dp "
             @"WHERE sh_user_id = :user_id"
                            withParameterDictionary:@{@"dp_hash": newHash,
                                                      @"dp": UIImageJPEGRepresentation(newSelectedDP, 1.0),
                                                      @"user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
            
            [appDelegate.mainMenu refreshMiniFeed];
            
            // We need a slight delay here.
            long double delayInSeconds = 0.45;
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                HUD = [[MBProgressHUD alloc] initWithView:self.view];
                [self.view addSubview:HUD];
                
                HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_white"]];
                
                // Set custom view mode.
                HUD.mode = MBProgressHUDModeCustomView;
                HUD.dimBackground = YES;
                HUD.delegate = self;
                
                [HUD show:YES];
                [HUD hide:YES afterDelay:2];
            });
        }
        else
        {
            [self showNetworkError];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)removeCurrentDP
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight activateStrobeLight];
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[@"mum's the word"]
                                                                          forKeys:@[@"dummy"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"request": jsonString,
                                 @"scope": appDelegate.SHTokenID};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/dpremove", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
            [appDelegate.strobeLight affirmativeStrobeLight];
            
            newSelectedDP = [UIImage imageNamed:@"user_placeholder"];
            [appDelegate.currentUser setObject:UIImageJPEGRepresentation(newSelectedDP, 1.0) forKey:@"dp"];
            [appDelegate.currentUser setObject:@"" forKey:@"dp_hash"];
            [userBubble setImage:newSelectedDP];
            
            [appDelegate.modelManager executeUpdate:@"UPDATE sh_current_user SET dp_hash = :dp_hash, dp = :dp"
                            withParameterDictionary:@{@"dp_hash": @"",
                                                      @"dp": @""}];
            
            [appDelegate.modelManager executeUpdate:@"UPDATE sh_cloud SET dp_hash = :dp_hash, dp = :dp "
             @"WHERE sh_user_id = :user_id"
                            withParameterDictionary:@{@"dp_hash": @"",
                                                      @"dp": @"",
                                                      @"user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
            
            [appDelegate.mainMenu refreshMiniFeed];
            
            [HUD hide:YES];
            
            // We need a slight delay here.
            long double delayInSeconds = 0.45;
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                HUD = [[MBProgressHUD alloc] initWithView:self.view];
                [self.view addSubview:HUD];
                
                HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_white"]];
                
                // Set custom view mode.
                HUD.mode = MBProgressHUDModeCustomView;
                HUD.dimBackground = YES;
                HUD.delegate = self;
                
                [HUD show:YES];
                [HUD hide:YES afterDelay:2];
            });
        }
        else
        {
            [self showNetworkError];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)copyCurrentStatus
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = statusLabel.text;
}

- (void)showDPOverlay
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSString *DPHash = [_ownerDataChunk objectForKey:@"dp_hash"];
    
    if ( DPHash.length == 0 ) // Don't show the overlay for people with no pics.
    {
        return;
    }
    
    UIView *overlay = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.9];
    overlay.opaque = YES;
    overlay.userInteractionEnabled = YES;
    overlay.alpha = 0.0;
    overlay.tag = 777;
    
    UIImageView *preview = [[UIImageView alloc] initWithFrame:userBubble.frame];
    preview.contentMode = UIViewContentModeScaleAspectFit;
    preview.opaque = YES;
    preview.tag = 7771;
    
    UIButton *dismissOverlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [dismissOverlayButton setImage:[UIImage imageNamed:@"back_white"] forState:UIControlStateNormal];
    [dismissOverlayButton addTarget:self action:@selector(dismissDPOverlay) forControlEvents:UIControlEventTouchUpInside];
    dismissOverlayButton.frame = CGRectMake(20, overlay.frame.size.height - 53, 33, 33);
    dismissOverlayButton.showsTouchWhenHighlighted = YES;
    
    UIButton *saveDPButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [saveDPButton setImage:[UIImage imageNamed:@"save_white"] forState:UIControlStateNormal];
    [saveDPButton addTarget:self action:@selector(saveDP) forControlEvents:UIControlEventTouchUpInside];
    saveDPButton.frame = CGRectMake(overlay.frame.size.width - 53, overlay.frame.size.height - 53, 33, 33);
    saveDPButton.showsTouchWhenHighlighted = YES;
    
    UIImage *currentDP = [UIImage imageWithData:[_ownerDataChunk objectForKey:@"alias_dp"]];
    
    if ( !currentDP )
    {
        currentDP = [UIImage imageWithData:[_ownerDataChunk objectForKey:@"dp"]];
    }
    
    preview.image = currentDP;
    [overlay addSubview:preview];
    [overlay addSubview:dismissOverlayButton];
    [overlay addSubview:saveDPButton];
    [self.view addSubview:overlay];
    
    [appDelegate.mainMenu disableCompositionLayerScrolling];
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionFullScreen];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        overlay.alpha = 1.0;
        preview.frame = overlay.frame;
    } completion:^(BOOL finished){
        
    }];
}

- (void)dismissDPOverlay
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *overlay = [self.view viewWithTag:777];
    UIImageView *preview = (UIImageView *)[overlay viewWithTag:7771];
    
    [appDelegate.mainMenu enableCompositionLayerScrolling];
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        overlay.alpha = 0.0;
        preview.transform = CGAffineTransformMakeScale(2.0, 2.0);
    } completion:^(BOOL finished){
        [overlay removeFromSuperview];
    }];
}

- (void)saveDP
{
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_white"]];
    
    // Set custom view mode.
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    HUD.labelText = NSLocalizedString(@"MESSAGES_HUD_SAVED_DP", nil);
    
    [HUD show:YES];
    [HUD hide:YES afterDelay:3];
    
    UIImage *currentDP = [UIImage imageWithData:[_ownerDataChunk objectForKey:@"alias_dp"]];
    
    if ( !currentDP )
    {
        currentDP = [UIImage imageWithData:[_ownerDataChunk objectForKey:@"dp"]];
    }
    
    // Save to Camera Roll.
    UIImageWriteToSavedPhotosAlbum(currentDP, nil, nil, nil);
}

#pragma mark -
#pragma mark Gestures

- (BOOL)canPerformAction:(SEL)selector withSender:(id)sender
{
    if ( selector == @selector(copyCurrentStatus) )
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)didLongPressStatus:(UILongPressGestureRecognizer *)longPress
{
    if ( [longPress state] == UIGestureRecognizerStateBegan )
    {
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(copyCurrentStatus)];
        
        [statusBubble becomeFirstResponder];
        [menuController setMenuItems:[NSArray arrayWithObject:menuItem]];
        [menuController setTargetRect:statusBubble.frame inView:self.view];
        [menuController setMenuVisible:YES animated:YES];
    }
}

// These methods are not delegate methods. They're manually called by the Home Menu.
- (void)currentUserPresenceDidChange
{
    [self updateNetworkStatus];
}

- (void)mediaPickerDidFinishPickingDP:(UIImage *)newDP
{
    newSelectedDP = newDP;
    
    [self uploadDP];
}

- (void)loadInfoOverNetwork
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDictionary *parameters = @{@"token": appDelegate.SHToken,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"user_id": _ownerID,
                                 @"full": @"1"};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/getuserinfo", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
            _ownerDataChunk = [[responseData objectForKey:@"response"] mutableCopy];
            
            NSString *DPHash = @"";
            
            NSString *lastStatusID = [NSString stringWithFormat:@"%@", [_ownerDataChunk objectForKey:@"thread_id"]];
            [_ownerDataChunk setObject:lastStatusID forKey:@"thread_id"];
            
            if ( [_ownerDataChunk objectForKey:@"user_handle"] && ![[NSNull null] isEqual:[_ownerDataChunk objectForKey:@"user_handle"]] )
            {
                
            }
            else
            {
                [_ownerDataChunk setObject:@"" forKey:@"user_handle"];
            }
            
            if ( [_ownerDataChunk objectForKey:@"dp_hash"] && ![[NSNull null] isEqual:[_ownerDataChunk objectForKey:@"dp_hash"]] )
            {
                
            }
            else
            {
                [_ownerDataChunk setObject:@"" forKey:@"dp_hash"];
            }
            
            if ( [_ownerDataChunk objectForKey:@"email_address"] && ![[NSNull null] isEqual:[_ownerDataChunk objectForKey:@"email_address"]] )
            {
                
            }
            else
            {
                [_ownerDataChunk setObject:@"" forKey:@"email_address"];
            }
            
            if ( [_ownerDataChunk objectForKey:@"gender"] && ![[NSNull null] isEqual:[_ownerDataChunk objectForKey:@"gender"]] )
            {
                
            }
            else
            {
                [_ownerDataChunk setObject:@"" forKey:@"gender"];
            }
            
            if ( [_ownerDataChunk objectForKey:@"location_country"] && ![[NSNull null] isEqual:[_ownerDataChunk objectForKey:@"location_country"]] )
            {
                
            }
            else
            {
                [_ownerDataChunk setObject:@"" forKey:@"location_country"];
            }
            
            if ( [_ownerDataChunk objectForKey:@"location_state"] && ![[NSNull null] isEqual:[_ownerDataChunk objectForKey:@"location_state"]] )
            {
                
            }
            else
            {
                [_ownerDataChunk setObject:@"" forKey:@"location_state"];
            }
            
            if ( [_ownerDataChunk objectForKey:@"location_city"] && ![[NSNull null] isEqual:[_ownerDataChunk objectForKey:@"location_city"]] )
            {
                
            }
            else
            {
                [_ownerDataChunk setObject:@"" forKey:@"location_city"];
            }
            
            if ( [_ownerDataChunk objectForKey:@"website"] && ![[NSNull null] isEqual:[_ownerDataChunk objectForKey:@"website"]] )
            {
                
            }
            else
            {
                [_ownerDataChunk setObject:@"" forKey:@"website"];
            }
            
            if ( [_ownerDataChunk objectForKey:@"bio"] && ![[NSNull null] isEqual:[_ownerDataChunk objectForKey:@"bio"]] )
            {
                
            }
            else
            {
                [_ownerDataChunk setObject:@"" forKey:@"bio"];
            }
            
            if ( [_ownerDataChunk objectForKey:@"facebook_id"] && ![[NSNull null] isEqual:[_ownerDataChunk objectForKey:@"facebook_id"]] )
            {
                
            }
            else
            {
                [_ownerDataChunk setObject:@"" forKey:@"facebook_id"];
            }
            
            if ( [_ownerDataChunk objectForKey:@"twitter_id"] && ![[NSNull null] isEqual:[_ownerDataChunk objectForKey:@"twitter_id"]] )
            {
                
            }
            else
            {
                [_ownerDataChunk setObject:@"" forKey:@"twitter_id"];
            }
            
            if ( [_ownerDataChunk objectForKey:@"instagram_id"] && ![[NSNull null] isEqual:[_ownerDataChunk objectForKey:@"instagram_id"]] )
            {
                
            }
            else
            {
                [_ownerDataChunk setObject:@"" forKey:@"instagram_id"];
            }
            
            if ( [_ownerDataChunk objectForKey:@"location_latitude"] && ![[NSNull null] isEqual:[_ownerDataChunk objectForKey:@"location_latitude"]] )
            {
                
            }
            else
            {
                [_ownerDataChunk setObject:@"" forKey:@"location_latitude"];
                [_ownerDataChunk setObject:@"" forKey:@"location_longitude"];
            }
            
            if ( [_ownerDataChunk objectForKey:@"birthday"] && ![[NSNull null] isEqual:[_ownerDataChunk objectForKey:@"birthday"]] )
            {
                
            }
            else
            {
                [_ownerDataChunk setObject:@"" forKey:@"birthday"];
            }
            
            // DP loading.
            if ( DPHash && DPHash.length > 0 )
            {
                NSURL *DPURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/userphotos/%@/profile/f_%@.jpg", SH_DOMAIN, _ownerID, DPHash]];
                
                NSURLRequest *request = [NSURLRequest requestWithURL:DPURL];
                [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                    UIImage *DP = [UIImage imageWithData:data];
                    
                    if ( DP )
                    {
                        [_ownerDataChunk setObject:data forKey:@"dp"];
                        
                        [userBubble setImage:DP];
                    }
                }];
            }
            
            FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT sh_user_id FROM sh_cloud WHERE sh_user_id = :user_id"
                                             withParameterDictionary:@{@"user_id": _ownerID}];
            
            [_ownerDataChunk setObject:@"1" forKey:@"temp"];
            
            // Check if the contact's already stored.
            while ( [s1 next] )
            {
                [_ownerDataChunk setObject:@"0" forKey:@"temp"];
            }
            
            [s1 close];
            
            long double delayInSeconds = 0.3; // Give it a small delay till everything loads.
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [appDelegate.mainMenu pushWindow:SHAppWindowTypeProfile];
            });
        }
        
        //NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)didAddUser
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
    
    [addUserButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [addUserButton setTitle:NSLocalizedString(@"PROFILE_REMOVE_USER", nil) forState:UIControlStateNormal];
    addUserButton.enabled = YES;
    
    followerCount++;
    [self updateStats];
    
    [_ownerDataChunk setObject:@"0" forKey:@"temp"];
}

- (void)didRemoveUser
{
    [addUserButton setTitleColor:[UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateNormal];
    [addUserButton setTitle:NSLocalizedString(@"PROFILE_ADD_USER", nil) forState:UIControlStateNormal];
    addUserButton.enabled = YES;
    
    followerCount--;
    [self updateStats];
    
    [_ownerDataChunk setObject:@"1" forKey:@"temp"];
}

- (void)lastOperationFailedWithError:(NSError *)error
{
    addUserButton.enabled = YES;
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
#pragma mark UIScrollViewDelegate methods.

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    if ( scrollView.tag == 7 ) // Main View.
    {
        int offset = -40;
        
        if ( !(IS_IOS7) )
        {
            offset = -20;
        }
        
        if ( scrollView.contentOffset.y <= offset )
        {
            _upperPane.frame = CGRectMake(0, scrollView.contentOffset.y + 20, _upperPane.frame.size.width, _upperPane.frame.size.height);
        }
        
        maskLayer_mainView.position = CGPointMake(0, scrollView.contentOffset.y);
    }
    
    [CATransaction commit];
}

#pragma mark -
#pragma mark UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return activeMediaArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CellIdentifier" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    cell.opaque = YES;
    
    NSDictionary *media = [activeMediaArray objectAtIndex:indexPath.row];
    SHThreadType threadType = [[media objectForKey:@"thread_type"] intValue];
    
    if ( threadType == SHThreadTypeMessageLocation )
    {
        NSDictionary *mediaExtra = [media objectForKey:@"media_extra"];
        NSDictionary *attachment = [mediaExtra objectForKey:@"attachment"];
        NSString *location_longitude = [media objectForKey:@"location_longitude"];
        NSString *location_latitude = [media objectForKey:@"location_latitude"];
        
        MKMapView *map = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, MEDIA_GALLERY_PREVIEW_SIZE, MEDIA_GALLERY_PREVIEW_SIZE)];
        map.layer.borderWidth = 0.5;
        map.layer.borderColor = [UIColor colorWithRed:232/255.0 green:232/255.0 blue:232/255.0 alpha:1.0].CGColor;
        map.userInteractionEnabled = NO;
        map.opaque = YES;
        
        MKPointAnnotation *mapPin = [[MKPointAnnotation alloc] init];
        
        SHChatBubble *attachmentUserBubble = [[SHChatBubble alloc] initWithFrame:CGRectMake((MEDIA_GALLERY_PREVIEW_SIZE / 2) - (35 / 2), (MEDIA_GALLERY_PREVIEW_SIZE / 2) - (35 / 2), 35, 35) withMiniModeEnabled:YES];
        attachmentUserBubble.enabled = NO;
        
        MKCoordinateRegion mapRegion;
        mapRegion.span.latitudeDelta = 0.008;
        mapRegion.span.longitudeDelta = 0.008;
        CLLocationCoordinate2D mediaLocation = CLLocationCoordinate2DMake([location_latitude floatValue], [location_longitude floatValue]);
        
        mapRegion.center = mediaLocation;
        [map setRegion:mapRegion animated:NO];
        [map removeAnnotation:mapPin];
        
        if ( [[mediaExtra objectForKey:@"attachment_value"] isEqualToString:@"venue"] )
        {
            mapPin.coordinate = mediaLocation;
            
            [map addAnnotation:mapPin];
        }
        else
        {
            NSData *base64Data_userThumbnail = [NSData dataWithBase64EncodedString:[attachment objectForKey:@"user_thumbnail"]];
            UIImage *userThumbnail = [UIImage imageWithData:base64Data_userThumbnail];
            
            if ( userThumbnail )
            {
                [attachmentUserBubble setImage:userThumbnail];
            }
            else
            {
                [attachmentUserBubble setImage:[UIImage imageNamed:@"user_placeholder"]];
            }
            
            [map addSubview:attachmentUserBubble];
        }
        
        [cell addSubview:map];
    }
    else
    {
        UIImageView *imagePreview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, MEDIA_GALLERY_PREVIEW_SIZE, MEDIA_GALLERY_PREVIEW_SIZE)];
        imagePreview.backgroundColor = [UIColor blackColor];
        imagePreview.layer.borderWidth = 0.5;
        imagePreview.layer.borderColor = [UIColor colorWithRed:232/255.0 green:232/255.0 blue:232/255.0 alpha:1.0].CGColor;
        imagePreview.image = [UIImage imageWithData:[media objectForKey:@"media_data"]];
        imagePreview.opaque = YES;
        
        [cell addSubview:imagePreview];
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(MEDIA_GALLERY_PREVIEW_SIZE, MEDIA_GALLERY_PREVIEW_SIZE);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *media = [activeMediaArray objectAtIndex:indexPath.row];
    SHThreadType threadType = [[media objectForKey:@"thread_type"] intValue];
    
    if ( threadType == SHThreadTypeMessageLocation )
    {
        NSDictionary *mediaExtra = [media objectForKey:@"media_extra"];
        NSMutableDictionary *attachment = [[mediaExtra objectForKey:@"attachment"] mutableCopy];
        NSString *location_longitude = [media objectForKey:@"location_longitude"];
        NSString *location_latitude = [media objectForKey:@"location_latitude"];
        
        [attachment setObject:[mediaExtra objectForKey:@"attachment_value"] forKey:@"attachment_value"];
        [attachment setObject:location_latitude forKey:@"location_latitude"];
        [attachment setObject:location_longitude forKey:@"location_longitude"];
        
        [self showMapForLocation:attachment];
    }
    else
    {
        [self showGalleryForMedia:[UIImage imageWithData:[media objectForKey:@"media_data"]] atPath:[media objectForKey:@"media_local_path"]];
    }
    
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark SHChatBubbleDelegate methods.

- (void)didSelectBubble:(SHChatBubble *)bubble
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( _ownerID.intValue == [[appDelegate.currentUser objectForKey:@"user_id"] intValue] )
    {
        [self showDPOptions];
    }
    else
    {
        [self showDPOverlay];
    }
}

- (void)didTapAndHoldBubble:(SHChatBubble *)bubble
{
    [self showDPOverlay];
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( actionSheet.tag == 0 ) // DP options.
    {
        NSString *currentDPHash = [appDelegate.currentUser objectForKey:@"dp_hash"];
        
        if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ) // If the device has a camera.
        {
            if ( currentDPHash.length == 0 )
            {
                if ( buttonIndex == 0 )      // Camera.
                {
                    appDelegate.mainMenu.isPickingDP = YES;
                    [appDelegate.mainMenu showMediaPicker_Camera];
                }
                else if ( buttonIndex == 1 ) // Library.
                {
                    appDelegate.mainMenu.isPickingDP = YES;
                    [appDelegate.mainMenu showMediaPicker_Library];
                }
                else if ( buttonIndex == 2 ) // Last photo taken.
                {
                    [self DP_UseLastPhotoTaken];
                }
            }
            else
            {
                if ( buttonIndex == 0 )      // Remove photo.
                {
                    [self removeCurrentDP];
                }
                else if ( buttonIndex == 1 ) // Camera.
                {
                    appDelegate.mainMenu.isPickingDP = YES;
                    [appDelegate.mainMenu showMediaPicker_Camera];
                }
                else if ( buttonIndex == 2 ) // Library.
                {
                    appDelegate.mainMenu.isPickingDP = YES;
                    [appDelegate.mainMenu showMediaPicker_Library];
                }
                else if ( buttonIndex == 3 ) // Last photo taken.
                {
                    [self DP_UseLastPhotoTaken];
                }
            }
        }
        else
        {
            if ( currentDPHash.length == 0 )
            {
                if ( buttonIndex == 0 ) // Library.
                {
                    appDelegate.mainMenu.isPickingDP = YES;
                    [appDelegate.mainMenu showMediaPicker_Library];
                }
                else if ( buttonIndex == 1 ) // Last photo taken.
                {
                    [self DP_UseLastPhotoTaken];
                }
            }
            else
            {
                if ( buttonIndex == 0 )      // Remove photo.
                {
                    [self removeCurrentDP];
                }
                else if ( buttonIndex == 1 ) // Library.
                {
                    appDelegate.mainMenu.isPickingDP = YES;
                    [appDelegate.mainMenu showMediaPicker_Library];
                }
                else if ( buttonIndex == 2 ) // Last photo taken.
                {
                    [self DP_UseLastPhotoTaken];
                }
            }
        }
    }
    else if ( actionSheet.tag == 1 ) // Blocking options.
    {
        if ( buttonIndex == 0 )
        {
            BOOL blocked = [[_ownerDataChunk objectForKey:@"blocked"] boolValue];
            
            if ( blocked )
            {
                [appDelegate.contactManager unblockContact:_ownerID];
            }
            else
            {
                [appDelegate.contactManager blockContact:_ownerID];
            }
            
            [self.navigationController popToRootViewControllerAnimated:YES];
            
            long double delayInSeconds = 0.25;
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [appDelegate.mainMenu dismissWindow];
                [appDelegate.mainMenu closeCurrentChat];
            });
        }
    }
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
