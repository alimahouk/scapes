//
//  MessagesViewController.m
//  Scapes
//
//  Created by MachOSX on 8/3/13.
//
//

#import "MessagesViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>

#import "AFHTTPRequestOperationManager.h"
#import "Base64.h"
#import "GalleryViewController.h"
#import "MapViewController.h"
#import "SHGrowingTextViewInternal.h"
#import "SHProfileViewController.h"
#import "Sound.h"
#import "UIDeviceHardware.h"
#import "WebBrowserViewController.h"

@implementation MessagesViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        activeMediaUploadRecipients = [[NSMutableArray alloc] init];
        processedMediaUploads = [[NSMutableArray alloc] init];
        _threads = [[NSMutableArray alloc] init];
        _initialMessagesFetchedIDs = [[NSMutableArray alloc] init];
        _recipientID = @"";
        _recipientDataChunk = [[NSMutableDictionary alloc] init];
        
        endOfConversation = NO;
        isShowingExactLastSeenTime = NO;
        tableIsScrolling = NO;
        isSendingMedia = NO;
        shouldReloadTable = NO;
        UIShouldSlideDown = YES;
        shouldLoadMessagesOnScroll = NO;
        shouldShowAttachmentsPanel = NO;
        shouldUseLightTheme = NO;
        canSendAcknowledgement = NO;
        didAnimateAcknowledgementIcon = NO;
        didGainPrivacyMerit = NO;
        _keyboardIsShown = NO;
        _attachmentsPanelIsShown = NO;
        _inAdHocMode = NO;
        _inPrivateMode = NO;
        
        batchNumber = 0;
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        didPlayTutorial_Privacy = [[userDefaults stringForKey:@"SHBDTutorialPrivacy"] boolValue];
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor whiteColor];
    
    hood = [[UIView alloc] initWithFrame:CGRectMake(0, 64, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height)];
    hood.backgroundColor = [UIColor colorWithRed:61/255.0 green:62/255.0 blue:66/255.0 alpha:1.0];
    
    backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setBackgroundImage:[UIImage imageNamed:@"chats_blue"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(presentMainMenu) forControlEvents:UIControlEventTouchUpInside];
    backButton.frame = CGRectMake(0, 0, 32, 32);
    backButton.showsTouchWhenHighlighted = YES;
    leftButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    self.navigationItem.leftBarButtonItem = leftButtonItem;
    
    backButtonBadge = [[UIImageView alloc] initWithFrame:CGRectMake(backButton.frame.size.width + 7, -5, 21, 21)];
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
    
    UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [titleButton addTarget:self action:@selector(showProfileForRecipient) forControlEvents:UIControlEventTouchUpInside];
    [titleButton addTarget:self action:@selector(titleButtonHighlighted) forControlEvents:UIControlEventTouchDown];
    [titleButton addTarget:self action:@selector(resetHeaderLabels) forControlEvents:UIControlEventTouchUpOutside];
    [titleButton addTarget:self action:@selector(resetHeaderLabels) forControlEvents:UIControlEventTouchCancel];
    titleButton.frame = CGRectMake(0, 0, 206, 44);
    titleButton.tag = 0;
    
    self.navigationItem.titleView = titleButton;
    
    connectionStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 64, appDelegate.screenBounds.size.width, 25)];
    connectionStatusLabel.backgroundColor = [UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:0.9];
    connectionStatusLabel.textAlignment = NSTextAlignmentCenter;
    connectionStatusLabel.textColor = [UIColor whiteColor];
    connectionStatusLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:SECONDARY_FONT_SIZE];
    connectionStatusLabel.minimumScaleFactor = 8.0 / MAIN_FONT_SIZE;
    connectionStatusLabel.numberOfLines = 1;
    connectionStatusLabel.adjustsFontSizeToFitWidth = YES;
    connectionStatusLabel.text = NSLocalizedString(@"NETWORK_CONNECTION_STATUS_CONNECTING", nil);
    connectionStatusLabel.opaque = YES;
    
    headerNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, titleButton.frame.size.width, 20)];
    headerNameLabel.backgroundColor = [UIColor clearColor];
    headerNameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:MAIN_FONT_SIZE];
    headerNameLabel.minimumScaleFactor = 8.0 / MAIN_FONT_SIZE;
    headerNameLabel.numberOfLines = 1;
    headerNameLabel.adjustsFontSizeToFitWidth = YES;
    headerNameLabel.textColor = [UIColor blackColor];
    headerNameLabel.textAlignment = NSTextAlignmentCenter;
    
    headerStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, titleButton.frame.size.width, 14.5)];
    headerStatusLabel.backgroundColor = [UIColor clearColor];
    headerStatusLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:SECONDARY_FONT_SIZE];
    headerStatusLabel.minimumScaleFactor = 11.0 / SECONDARY_FONT_SIZE;
    headerStatusLabel.numberOfLines = 1;
    headerStatusLabel.adjustsFontSizeToFitWidth = YES;
    headerStatusLabel.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
    headerStatusLabel.textAlignment = NSTextAlignmentCenter;
    
    recipientStatusBubbleLabel = [[UILabel alloc] init];
    recipientStatusBubbleLabel.backgroundColor = [UIColor clearColor];
    recipientStatusBubbleLabel.textColor = [UIColor whiteColor];
    recipientStatusBubbleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:13];
    recipientStatusBubbleLabel.numberOfLines = 0;
    recipientStatusBubbleLabel.opaque = YES;
    
    attachLabel_camera = [[UILabel alloc] init];
    attachLabel_camera.backgroundColor = [UIColor clearColor];
    attachLabel_camera.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
    attachLabel_camera.minimumScaleFactor = 8.0 / MIN_MAIN_FONT_SIZE;
    attachLabel_camera.numberOfLines = 1;
    attachLabel_camera.adjustsFontSizeToFitWidth = YES;
    attachLabel_camera.textColor = [UIColor whiteColor];
    attachLabel_camera.highlightedTextColor = [UIColor blackColor];
    attachLabel_camera.textAlignment = NSTextAlignmentCenter;
    attachLabel_camera.text = NSLocalizedString(@"MESSAGES_ATTACH_CAMERA", nil);
    
    attachLabel_library = [[UILabel alloc] init];
    attachLabel_library.backgroundColor = [UIColor clearColor];
    attachLabel_library.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
    attachLabel_library.minimumScaleFactor = 8.0 / MIN_MAIN_FONT_SIZE;
    attachLabel_library.numberOfLines = 1;
    attachLabel_library.adjustsFontSizeToFitWidth = YES;
    attachLabel_library.textColor = [UIColor whiteColor];
    attachLabel_library.highlightedTextColor = [UIColor blackColor];
    attachLabel_library.textAlignment = NSTextAlignmentCenter;
    attachLabel_library.text = NSLocalizedString(@"MESSAGES_ATTACH_LIBRARY", nil);
    
    attachLabel_lastPhoto = [[UILabel alloc] init];
    attachLabel_lastPhoto.backgroundColor = [UIColor clearColor];
    attachLabel_lastPhoto.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
    attachLabel_lastPhoto.minimumScaleFactor = 8.0 / MIN_MAIN_FONT_SIZE;
    attachLabel_lastPhoto.numberOfLines = 1;
    attachLabel_lastPhoto.adjustsFontSizeToFitWidth = YES;
    attachLabel_lastPhoto.textColor = [UIColor whiteColor];
    attachLabel_lastPhoto.highlightedTextColor = [UIColor blackColor];
    attachLabel_lastPhoto.textAlignment = NSTextAlignmentCenter;
    attachLabel_lastPhoto.text = NSLocalizedString(@"MESSAGES_ATTACH_LAST_PHOTO", nil);
    
    attachLabel_location = [[UILabel alloc] init];
    attachLabel_location.backgroundColor = [UIColor clearColor];
    attachLabel_location.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
    attachLabel_location.minimumScaleFactor = 8.0 / MIN_MAIN_FONT_SIZE;
    attachLabel_location.numberOfLines = 1;
    attachLabel_location.adjustsFontSizeToFitWidth = YES;
    attachLabel_location.textColor = [UIColor whiteColor];
    attachLabel_location.highlightedTextColor = [UIColor blackColor];
    attachLabel_location.textAlignment = NSTextAlignmentCenter;
    attachLabel_location.text = NSLocalizedString(@"MESSAGES_ATTACH_LOCATION", nil);
    
    attachLabel_contact = [[UILabel alloc] init];
    attachLabel_contact.backgroundColor = [UIColor clearColor];
    attachLabel_contact.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
    attachLabel_contact.minimumScaleFactor = 8.0 / MIN_MAIN_FONT_SIZE;
    attachLabel_contact.numberOfLines = 1;
    attachLabel_contact.adjustsFontSizeToFitWidth = YES;
    attachLabel_contact.textColor = [UIColor whiteColor];
    attachLabel_contact.highlightedTextColor = [UIColor blackColor];
    attachLabel_contact.textAlignment = NSTextAlignmentCenter;
    attachLabel_contact.text = NSLocalizedString(@"MESSAGES_ATTACH_CONTACT", nil);
    
    attachLabel_file = [[UILabel alloc] init];
    attachLabel_file.backgroundColor = [UIColor clearColor];
    attachLabel_file.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
    attachLabel_file.minimumScaleFactor = 8.0 / MIN_MAIN_FONT_SIZE;
    attachLabel_file.numberOfLines = 1;
    attachLabel_file.adjustsFontSizeToFitWidth = YES;
    attachLabel_file.textColor = [UIColor whiteColor];
    attachLabel_file.highlightedTextColor = [UIColor blackColor];
    attachLabel_file.textAlignment = NSTextAlignmentCenter;
    attachLabel_file.text = NSLocalizedString(@"MESSAGES_ATTACH_FILE", nil);
    
    privacyToggleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 22, 200, 15)];
    privacyToggleLabel.backgroundColor = [UIColor clearColor];
    privacyToggleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:MIN_MAIN_FONT_SIZE];
    privacyToggleLabel.minimumScaleFactor = 8.0 / MIN_MAIN_FONT_SIZE;
    privacyToggleLabel.numberOfLines = 1;
    privacyToggleLabel.adjustsFontSizeToFitWidth = YES;
    privacyToggleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    privacyToggleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.8];
    privacyToggleLabel.shadowOffset = CGSizeMake(0, 1);
    privacyToggleLabel.text = NSLocalizedString(@"MESSAGES_TOGGLE_LABEL_PRIVACY", nil);
    
    _recipientBubble = [[SHChatBubble alloc] initWithFrame:CGRectMake(10, 0, 35, 35) withMiniModeEnabled:YES];
    _recipientBubble.delegate = self;
    
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_recipientBubble];
    
    self.navigationItem.rightBarButtonItem = rightButtonItem;
    
    participantsPane = [[UIScrollView alloc] initWithFrame:CGRectMake(0, appDelegate.screenBounds.size.height - 104 - ([UIApplication sharedApplication].statusBarFrame.size.height - 20), appDelegate.screenBounds.size.width, 40)];
    participantsPane.backgroundColor = [UIColor colorWithRed:97/255.0 green:99/255.0 blue:109/255.0 alpha:1.0];
    participantsPane.contentSize = CGSizeMake(MAX(appDelegate.screenBounds.size.width + 1, 0), 40); // Add the width of the Add Participant button.
    participantsPane.showsHorizontalScrollIndicator = NO;
    participantsPane.showsVerticalScrollIndicator = NO;
    participantsPane.contentInset = UIEdgeInsetsMake(0, 40, 0, 0);
    participantsPane.scrollsToTop = NO;
    
    lastPhotoTakenPreview = [[UIImageView alloc] initWithFrame:CGRectMake(16, 1, 48, 48)];
    lastPhotoTakenPreview.opaque = YES;
    
    CGSize messageBoxPlaceholderTextSize = [NSLocalizedString(@"MESSAGES_MESSAGE_BOX_PLACEHOLDER", nil) sizeWithFont:[UIFont systemFontOfSize:16] constrainedToSize:CGSizeMake(211, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    
    messageBoxBubble = [[UIImageView alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width - messageBoxPlaceholderTextSize.width - 60, 10, messageBoxPlaceholderTextSize.width + 48, messageBoxPlaceholderTextSize.height + 19)];
    messageBoxBubble.image = [[UIImage imageNamed:@"message_bubble_right"] stretchableImageWithLeftCapWidth:12 topCapHeight:13];
    messageBoxBubble.userInteractionEnabled = YES;
    messageBoxBubble.opaque = YES;
    
    messageBoxBubbleImagePreview = [[UIImageView alloc] init];
    messageBoxBubbleImagePreview.backgroundColor = [UIColor blackColor];
    messageBoxBubbleImagePreview.contentMode = UIViewContentModeScaleAspectFit;
    messageBoxBubbleImagePreview.layer.masksToBounds = YES;
    messageBoxBubbleImagePreview.opaque = YES;
    messageBoxBubbleImagePreview.hidden = YES;
    
    _messageBox = [[SHGrowingTextView alloc] initWithFrame:CGRectMake(15, 1, 221, 30)];
    _messageBox.delegate = self;
    _messageBox.backgroundColor = [UIColor clearColor];
    _messageBox.font = [UIFont systemFontOfSize:16];
    _messageBox.textAlignment = NSTextAlignmentLeft;
    _messageBox.textColor = [UIColor blackColor];
    _messageBox.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    _messageBox.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    _messageBox.isScrollable = NO;
    _messageBox.internalTextView.scrollsToTop = NO;
    _messageBox.minNumberOfLines = 1;
    _messageBox.maxNumberOfLines = 999;
    _messageBox.placeholder = NSLocalizedString(@"MESSAGES_MESSAGE_BOX_PLACEHOLDER", nil);
    _messageBox.placeholderColor = [UIColor colorWithRed:144/255.0 green:143/255.0 blue:149/255.0 alpha:1.0];
    
    sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sendButton addTarget:self action:@selector(sendTextMessage) forControlEvents:UIControlEventTouchUpInside];
    [sendButton setImage:[UIImage imageNamed:@"send"] forState:UIControlStateNormal];
    [sendButton setBackgroundImage:[UIImage imageNamed:@"button_round_white"] forState:UIControlStateNormal];
    sendButton.adjustsImageWhenDisabled = NO;
    sendButton.frame = CGRectMake(appDelegate.screenBounds.size.width - 55, 3, 50, 50);
    sendButton.opaque = YES;
    sendButton.alpha = 0.0;
    sendButton.hidden = YES;
    
    uploadActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    uploadActivityIndicator.frame = CGRectMake(15, 15, 21, 21);
    uploadActivityIndicator.alpha = 0.0;
    uploadActivityIndicator.hidden = YES;
    
    recipientStatusBubble = [UIButton buttonWithType:UIButtonTypeCustom];
    [recipientStatusBubble setBackgroundImage:[[UIImage imageNamed:@"message_bubble_transparent_left"] stretchableImageWithLeftCapWidth:18 topCapHeight:22] forState:UIControlStateNormal];
    [recipientStatusBubble setBackgroundImage:[[UIImage imageNamed:@"message_bubble_transparent_left"] stretchableImageWithLeftCapWidth:18 topCapHeight:22] forState:UIControlStateDisabled];
    [recipientStatusBubble addTarget:self action:@selector(showExactLastSeenTime) forControlEvents:UIControlEventTouchUpInside];
    recipientStatusBubble.opaque = YES;
    
    attachButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [attachButton addTarget:self action:@selector(showAttachmentOptions) forControlEvents:UIControlEventTouchUpInside];
    [attachButton setTitle:@"+" forState:UIControlStateNormal];
    [attachButton setTitleColor:[UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    [attachButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [attachButton setBackgroundImage:[UIImage imageNamed:@"button_round_white"] forState:UIControlStateNormal];
    attachButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:24];
    attachButton.titleLabel.shadowColor = [UIColor whiteColor];
    attachButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
    attachButton.titleEdgeInsets = UIEdgeInsetsMake(-4, 1, 0, 0);
    attachButton.frame = CGRectMake(5, 3, 50, 50);
    attachButton.opaque = YES;
    attachButton.enabled = NO;
    
    if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ) // If the device has a camera.
    {
        attachButton_camera = [UIButton buttonWithType:UIButtonTypeCustom];
        [attachButton_camera addTarget:self action:@selector(media_Camera) forControlEvents:UIControlEventTouchUpInside];
        [attachButton_camera setImage:[UIImage imageNamed:@"attachments_camera"] forState:UIControlStateNormal];
        [attachButton_camera setImage:[UIImage imageNamed:@"attachments_camera_highlighted"] forState:UIControlStateHighlighted];
        attachButton_camera.tag = 0;
    }
    
    attachButton_library = [UIButton buttonWithType:UIButtonTypeCustom];
    [attachButton_library addTarget:self action:@selector(media_Library) forControlEvents:UIControlEventTouchUpInside];
    [attachButton_library setImage:[UIImage imageNamed:@"attachments_library"] forState:UIControlStateNormal];
    [attachButton_library setImage:[UIImage imageNamed:@"attachments_library_highlighted"] forState:UIControlStateHighlighted];
    attachButton_library.tag = 1;
    attachButton_library.opaque = YES;
    
    attachButton_lastPhoto = [UIButton buttonWithType:UIButtonTypeCustom];
    [attachButton_lastPhoto addTarget:self action:@selector(media_UseLastPhotoTaken) forControlEvents:UIControlEventTouchUpInside];
    [attachButton_lastPhoto setImage:[UIImage imageNamed:@"attachments_last_photo"] forState:UIControlStateNormal];
    [attachButton_lastPhoto setImage:[UIImage imageNamed:@"attachments_last_photo_highlighted"] forState:UIControlStateHighlighted];
    attachButton_lastPhoto.tag = 2;
    attachButton_lastPhoto.opaque = YES;
    
    attachButton_location = [UIButton buttonWithType:UIButtonTypeCustom];
    [attachButton_location addTarget:self action:@selector(attachLocation) forControlEvents:UIControlEventTouchUpInside];
    [attachButton_location setImage:[UIImage imageNamed:@"attachments_location"] forState:UIControlStateNormal];
    [attachButton_location setImage:[UIImage imageNamed:@"attachments_location_highlighted"] forState:UIControlStateHighlighted];
    attachButton_location.tag = 3;
    attachButton_location.opaque = YES;
    
    attachButton_contact = [UIButton buttonWithType:UIButtonTypeCustom];
    //[attachButton_contact addTarget:self action:@selector(attach:) forControlEvents:UIControlEventTouchUpInside];
    [attachButton_contact setImage:[UIImage imageNamed:@"attachments_contact"] forState:UIControlStateNormal];
    [attachButton_contact setImage:[UIImage imageNamed:@"attachments_contact_highlighted"] forState:UIControlStateHighlighted];
    attachButton_contact.tag = 4;
    attachButton_contact.opaque = YES;
    
    attachButton_file = [UIButton buttonWithType:UIButtonTypeCustom];
    //[attachButton_file addTarget:self action:@selector(attach:) forControlEvents:UIControlEventTouchUpInside];
    [attachButton_file setImage:[UIImage imageNamed:@"attachments_file"] forState:UIControlStateNormal];
    [attachButton_file setImage:[UIImage imageNamed:@"attachments_file_highlighted"] forState:UIControlStateHighlighted];
    attachButton_file.tag = 5;
    attachButton_file.opaque = YES;
    
    /*widgetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [widgetButton addTarget:self action:@selector(attach:) forControlEvents:UIControlEventTouchUpInside];
    [widgetButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:1.0] forState:UIControlStateNormal];
    [widgetButton setTitleColor:[UIColor colorWithWhite:0.5 alpha:1.0] forState:UIControlStateHighlighted];
    [widgetButton setBackgroundImage:[[UIImage imageNamed:@"button_dark_bg"] stretchableImageWithLeftCapWidth:5.0 topCapHeight:5.0] forState:UIControlStateNormal];
    widgetButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:MIN_MAIN_FONT_SIZE];
    widgetButton.titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.8];
    widgetButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
    widgetButton.frame = CGRectMake(50, 60, 260, 36);
    widgetButton.opaque = YES;*/
    
    addParticipantButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [addParticipantButton addTarget:self action:@selector(addParticipant) forControlEvents:UIControlEventTouchUpInside];
    [addParticipantButton setBackgroundImage:[UIImage imageNamed:@"round_metal_button_add"] forState:UIControlStateNormal];
    [addParticipantButton setBackgroundImage:[UIImage imageNamed:@"round_metal_button_add_highlighted"] forState:UIControlStateHighlighted];
    addParticipantButton.frame = CGRectMake(5, 2, 35, 37);
    addParticipantButton.opaque = YES;
    
    privacyToggle = [[UISwitch alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width - 60, 15, 0, 0)];
    [privacyToggle addTarget:self action:@selector(didToggleSwitch:) forControlEvents: UIControlEventTouchUpInside];
    //privacyToggle.onTintColor = [UIColor colorWithRed:0/255.0 green:115/255.0 blue:185/255.0 alpha:1.0];
    privacyToggle.opaque = YES;
    privacyToggle.enabled = NO; // Load disabled until the network connects.
    privacyToggle.tag = 0;
    
    if ( !(IS_IOS7) )
    {
        attachmentsPanel = [[UIView alloc] initWithFrame:CGRectMake(0, appDelegate.screenBounds.size.height - 64, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height / 2)];
        attachmentsPanel.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];
        attachmentsPanel.opaque = YES;
        attachmentsPanel.alpha = 0.0;
        attachmentsPanel.hidden = YES;
    }
    else
    {
        attachmentsPanel_toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, appDelegate.screenBounds.size.height - 64, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height / 2)];
        attachmentsPanel_toolbar.barTintColor = [UIColor colorWithWhite:0.15 alpha:1.0];
        attachmentsPanel_toolbar.alpha = 0.0;
        attachmentsPanel_toolbar.hidden = YES;
    }
    
    attachmentsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, attachmentsPanel.frame.size.width, attachmentsPanel.frame.size.height)];
    attachmentsScrollView.pagingEnabled = YES;
    attachmentsScrollView.showsHorizontalScrollIndicator = NO;
    attachmentsScrollView.showsVerticalScrollIndicator = NO;
    attachmentsScrollView.scrollsToTop = NO;
    attachmentsScrollView.opaque = YES;
    
    _tableContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 64, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height)];
    _tableContainer.clipsToBounds = YES;
    _tableContainer.opaque = YES;
    
    _tableSideShadow = [[UIImageView alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width, 0, 7, appDelegate.screenBounds.size.height)];
    _tableSideShadow.image = [[UIImage imageNamed:@"shadow_vertical_right"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    _tableSideShadow.opaque = YES;
    _tableSideShadow.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
    
    float scaleFactor = appDelegate.screenBounds.size.width / 744;
    
    _wallpaper = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 1392 * scaleFactor)]; // 744 is the actual width of the image.
    _wallpaper.backgroundColor = [UIColor whiteColor];
    _wallpaper.contentMode = UIViewContentModeScaleAspectFill;
    _wallpaper.opaque = YES;
    
    UIImageView *wallpaperSideline_left = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 1, appDelegate.screenBounds.size.height)];
    wallpaperSideline_left.image = [[UIImage imageNamed:@"chat_wallpaper_sideline"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    wallpaperSideline_left.opaque = YES;
    
    UIImageView *wallpaperSideline_right = [[UIImageView alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width - 1, 0, 1, appDelegate.screenBounds.size.height)];
    wallpaperSideline_right.image = [[UIImage imageNamed:@"chat_wallpaper_sideline"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    wallpaperSideline_right.opaque = YES;
    
    NSData *wallpaperData = [appDelegate.currentUser objectForKey:@"chat_wallpaper"];
    
    if ( [UIImage imageWithData:wallpaperData] )
    {
        UIImage *wallpaper = [UIImage imageWithData:wallpaperData];
        
        [self setCurrentWallpaper:wallpaper];
    }
    
    if ( appDelegate.networkManager.networkState == SHNetworkStateConnected )
    {
        connectionStatusLabel.frame = CGRectMake(connectionStatusLabel.frame.origin.x, 19, connectionStatusLabel.frame.size.width, connectionStatusLabel.frame.size.height);
    }
    
    _conversationTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - 64)];
    _conversationTable.backgroundColor = [UIColor clearColor];
    _conversationTable.backgroundView = nil;
    _conversationTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    _conversationTable.delegate = self;
    _conversationTable.dataSource = self;
    _conversationTable.scrollsToTop = NO;
    _conversationTable.alpha = 0.0;
    _conversationTable.tag = 7;
    
    conversationTableFooter = [[UIView alloc] init];
    conversationTableFooter.opaque = YES;
    
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        if ( appDelegate.networkManager.networkState == SHNetworkStateConnected )
        {
            connectionStatusLabel.frame = CGRectMake(connectionStatusLabel.frame.origin.x, -25, connectionStatusLabel.frame.size.width, connectionStatusLabel.frame.size.height);
        }
        else
        {
            connectionStatusLabel.frame = CGRectMake(connectionStatusLabel.frame.origin.x, 0, appDelegate.screenBounds.size.width, 25);
        }
        
        participantsPane.frame = CGRectMake(0, appDelegate.screenBounds.size.height - 114, appDelegate.screenBounds.size.width, 50);
        
        _messageBox.contentInset = UIEdgeInsetsMake(0, -8, 0, -8); // Fix the message box padding.
        _messageBox.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 6, 5);
        
        attachButton.titleLabel.shadowOffset = CGSizeMake(0, 0);
        lastPhotoTakenPreview.frame = CGRectMake(16.5, 1.5, 46.5, 46.5);
        
        _tableSideShadow.frame = CGRectMake(appDelegate.screenBounds.size.width, 0, 7, appDelegate.screenBounds.size.height - 64);
        _tableContainer.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height);
        
        hood.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height);
        privacyToggle.frame = CGRectMake(appDelegate.screenBounds.size.width - 90, 15, 0, 0);
        
        if ( [UIApplication sharedApplication].statusBarFrame.size.height > 20 )
        {
            
        }
    }
    else
    {
        if ( [UIApplication sharedApplication].statusBarFrame.size.height > 20 )
        {
            if ( appDelegate.networkManager.networkState == SHNetworkStateConnected )
            {
                connectionStatusLabel.frame = CGRectMake(connectionStatusLabel.frame.origin.x, -25, connectionStatusLabel.frame.size.width, connectionStatusLabel.frame.size.height);
            }
            else
            {
                connectionStatusLabel.frame = CGRectMake(connectionStatusLabel.frame.origin.x, 0, appDelegate.screenBounds.size.width, 25);
            }
            
            hood.frame = CGRectMake(hood.frame.origin.x, 44, hood.frame.size.width, hood.frame.size.height);
            _tableContainer.frame = CGRectMake(_tableContainer.frame.origin.x, 25, _tableContainer.frame.size.width, _tableContainer.frame.size.height);
        }
    }
    
    // Gestures.
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetView)];
    [_conversationTable addGestureRecognizer:_tapRecognizer];
    
    UITapGestureRecognizer *conversationTableFooterTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetView)];
    [conversationTableFooter addGestureRecognizer:conversationTableFooterTapRecognizer];
    
    [_tableContainer addSubview:_wallpaper];
    [_tableContainer addSubview:wallpaperSideline_left];
    [_tableContainer addSubview:wallpaperSideline_right];
    [_tableContainer addSubview:_conversationTable];
    //[_tableContainer addSubview:bottomBar];
    
    if ( !(IS_IOS7) )
    {
        [_tableContainer addSubview:attachmentsPanel];
        [attachmentsPanel addSubview:attachmentsScrollView];
    }
    else
    {
        [_tableContainer addSubview:attachmentsPanel_toolbar];
        [attachmentsPanel_toolbar addSubview:attachmentsScrollView];
    }
    
    [attachmentsScrollView addSubview:attachButton_camera];
    [attachmentsScrollView addSubview:attachButton_library];
    [attachmentsScrollView addSubview:attachButton_lastPhoto];
    [attachmentsScrollView addSubview:attachButton_location];
    //[attachmentsScrollView addSubview:attachButton_contact];
    //[attachmentsScrollView addSubview:attachButton_file];
    [backButtonBadge addSubview:backButtonBadgeLabel];
    [backButton addSubview:backButtonBadge];
    [sendButton addSubview:uploadActivityIndicator];
    [titleButton addSubview:headerNameLabel];
    [titleButton addSubview:headerStatusLabel];
    [recipientStatusBubble addSubview:recipientStatusBubbleLabel];
    [messageBoxBubble addSubview:messageBoxBubbleImagePreview];
    [messageBoxBubble addSubview:_messageBox];
    [conversationTableFooter addSubview:messageBoxBubble];
    [conversationTableFooter addSubview:sendButton];
    [conversationTableFooter addSubview:attachButton];
    [conversationTableFooter addSubview:recipientStatusBubble];
    [attachButton_camera addSubview:attachLabel_camera];
    [attachButton_library addSubview:attachLabel_library];
    [attachButton_lastPhoto addSubview:lastPhotoTakenPreview];
    [attachButton_lastPhoto addSubview:attachLabel_lastPhoto];
    [attachButton_location addSubview:attachLabel_location];
    [attachButton_contact addSubview:attachLabel_contact];
    [attachButton_file addSubview:attachLabel_file];
    //[participantsPane addSubview:addParticipantButton];
    [hood addSubview:privacyToggleLabel];
    [hood addSubview:privacyToggle];
    //[hood addSubview:widgetButton];
    [hood addSubview:participantsPane];
    [contentView addSubview:hood];
    [contentView addSubview:_tableSideShadow];
    [contentView addSubview:_tableContainer];
    [contentView addSubview:connectionStatusLabel];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( appDelegate.activeWindow )
    {
        appDelegate.mainMenu.windowCompositionLayer.scrollEnabled = YES; // Unlock the layer.
        appDelegate.viewIsDraggable = YES;
        
        [[NSNotificationCenter defaultCenter] removeObserver:appDelegate.mainMenu.messagesView name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:appDelegate.mainMenu.messagesView name:UIKeyboardWillHideNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:appDelegate.mainMenu.messagesView selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:appDelegate.mainMenu.messagesView selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    }
    
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        if ( _inPrivateMode )
        {
            [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav_bar_legacy_dark"] forBarMetrics:UIBarMetricsDefault];
            self.navigationController.navigationBar.tintColor = [UIColor blackColor];
            self.navigationController.navigationBar.shadowImage = [UIImage new];
        }
        else
        {
            [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav_bar_legacy_white"] forBarMetrics:UIBarMetricsDefault];
            self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0];
            self.navigationController.navigationBar.shadowImage = [UIImage imageNamed:@"nav_bar_shadow_line"];
        }
    }
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if ( viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count - 2] == self ) // View is disappearing because a new view controller was pushed onto the stack.
    {
        appDelegate.mainMenu.windowCompositionLayer.scrollEnabled = NO; // Lock the layer.
        appDelegate.viewIsDraggable = NO;
    }
    else if ( [viewControllers indexOfObject:self] == NSNotFound ) // View is disappearing because it was popped from the stack.
    {
        
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:appDelegate.mainMenu.messagesView name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:appDelegate.mainMenu.messagesView name:UIKeyboardWillHideNotification object:nil];
    
    [super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark Orientation Changes

- (void)enterLandscapeFullscreen
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        appDelegate.mainMenu.mainWindowContainer.frame = CGRectMake(50, appDelegate.mainMenu.mainWindowContainer.frame.origin.y, appDelegate.screenBounds.size.width - 50, appDelegate.screenBounds.size.height + 20);
        _conversationTable.frame = CGRectMake(0, _conversationTable.frame.origin.y, appDelegate.screenBounds.size.width - 50, appDelegate.screenBounds.size.height + 20);
        _recipientBubble.alpha = 0.0;
    } completion:^(BOOL finished){
        _recipientBubble.hidden = YES;
    }];
}

- (void)exitLandscapeFullscreen
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    _recipientBubble.hidden = NO;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        appDelegate.mainMenu.mainWindowContainer.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height);
        _conversationTable.frame = CGRectMake(0, _conversationTable.frame.origin.y, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height);
        _recipientBubble.alpha = 1.0;
    } completion:^(BOOL finished){
        
    }];
}

- (void)presentMainMenu
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [self resetView];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [appDelegate.mainMenu showMainWindowSide];
}

- (void)showWebBrowserForURL:(NSString *)URL reportEndOfActivity:(BOOL)shouldReportEndOfActivity
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSRange rangeOfSubstring = [URL rangeOfString:@"/Scapes.app/www"];
    
    if ( rangeOfSubstring.location != NSNotFound )
    {
        URL = [URL substringFromIndex:rangeOfSubstring.location + 12];
    }
    
    if ( ![URL hasPrefix:@"http://"] &&
        ![URL hasPrefix:@"https://"] &&
        ![URL hasPrefix:@"ftp://"] &&
        ![URL hasPrefix:@"ftps://"] )
    {
        URL = [NSString stringWithFormat:@"http://%@", URL];
    }
    
    WebBrowserViewController *webBrowser = [[WebBrowserViewController alloc] init];
    webBrowser.URL = URL;
    webBrowser.resetsViewWhenPopped = YES;
    webBrowser.shouldReportEndOfActivity = shouldReportEndOfActivity;
    
    appDelegate.mainMenu.windowCompositionLayer.contentSize = CGSizeMake(appDelegate.screenBounds.size.width * 2 - 40, appDelegate.screenBounds.size.height);
    [appDelegate.mainMenu.windowCompositionLayer setContentOffset:CGPointMake(280, 0) animated:NO];
    [appDelegate.mainMenu.messagesView resetView];
    
    appDelegate.mainMenu.windowCompositionLayer.scrollEnabled = NO;
    appDelegate.viewIsDraggable = NO;
    
    if ( recipientName_alias.length > 0 )
    {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:recipientName_alias style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    else
    {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:recipientName_first style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    
    [self.navigationController pushViewController:webBrowser animated:YES];
}

- (void)showGalleryForMedia:(id)media atPath:(NSString *)path
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( [media isKindOfClass:[UIImage class]] )
    {
        GalleryViewController *galleryView = [[GalleryViewController alloc] init];
        galleryView.resetsViewWhenPopped = YES;
        galleryView.initialMediaData = UIImageJPEGRepresentation(media, 1.0);
        galleryView.mediaLocalPath = path;
        
        appDelegate.viewIsDraggable = NO;
        [appDelegate.mainMenu disableCompositionLayerScrolling];
        
        if ( recipientName_alias.length > 0 )
        {
            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:recipientName_alias style:UIBarButtonItemStylePlain target:nil action:nil];
        }
        else
        {
            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:recipientName_first style:UIBarButtonItemStylePlain target:nil action:nil];
        }
        
        [self.navigationController pushViewController:galleryView animated:YES];
    }
}

- (void)showMapForLocation:(NSDictionary *)location
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([[location objectForKey:@"location_latitude"] floatValue], [[location objectForKey:@"location_longitude"] floatValue]);
    
    MapViewController *mapView = [[MapViewController alloc] init];
    mapView.locationToLoad = coordinate;
    mapView.resetsViewWhenPopped = YES;
    
    if ( [[location objectForKey:@"attachment_value"] isEqualToString:@"venue"] )
    {
        mapView.calloutTitle = [location objectForKey:@"venue_name"];
        mapView.calloutSubtitle = [location objectForKey:@"venue_country"];
    }
    else
    {
        NSData *base64Data_userThumbnail = [NSData dataWithBase64EncodedString:[location objectForKey:@"user_thumbnail"]];
        UIImage *userThumbnail = [UIImage imageWithData:base64Data_userThumbnail];
        
        mapView.thumbnail = userThumbnail;
    }
    
    appDelegate.mainMenu.windowCompositionLayer.contentSize = CGSizeMake(appDelegate.screenBounds.size.width * 2 - 40, appDelegate.screenBounds.size.height);
    [appDelegate.mainMenu.windowCompositionLayer setContentOffset:CGPointMake(280, 0) animated:NO];
    [appDelegate.mainMenu.messagesView resetView];
    
    appDelegate.mainMenu.windowCompositionLayer.scrollEnabled = NO;
    appDelegate.viewIsDraggable = NO;
    
    if ( recipientName_alias.length > 0 )
    {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:recipientName_alias style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    else
    {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:recipientName_first style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    
    [self.navigationController pushViewController:mapView animated:YES];
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
        [backButton setBackgroundImage:[UIImage imageNamed:@"chats_blue"] forState:UIControlStateNormal];
        
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            backButtonBadge.frame = CGRectMake(backButton.frame.size.width + 7 - width, backButtonBadge.frame.origin.y, width, backButtonBadge.frame.size.height);
            backButtonBadgeLabel.frame = CGRectMake(backButtonBadgeLabel.frame.origin.x, backButtonBadgeLabel.frame.origin.y, backButtonBadge.frame.size.width, backButtonBadge.frame.size.height);
            backButtonBadge.alpha = 0.0;
        } completion:^(BOOL finished){
            backButtonBadge.hidden = YES;
        }];
    }
    else
    {
        [backButton setBackgroundImage:[UIImage imageNamed:@"chats_blue_filled"] forState:UIControlStateNormal];
        
        backButtonBadge.hidden = NO;
        
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            backButtonBadge.frame = CGRectMake(backButton.frame.size.width + 7 - width, backButtonBadge.frame.origin.y, width, backButtonBadge.frame.size.height);
            backButtonBadgeLabel.frame = CGRectMake(backButtonBadgeLabel.frame.origin.x, backButtonBadgeLabel.frame.origin.y, backButtonBadge.frame.size.width, backButtonBadge.frame.size.height);
            backButtonBadge.alpha = 1.0;
        } completion:^(BOOL finished){
            
        }];
    }
}

#pragma mark -
#pragma mark Handle a UISwitch Flip

- (void)didToggleSwitch:(id)sender
{
    UISwitch *toggleSwitch = (UISwitch *)sender;
    
    if ( toggleSwitch.tag == 0 ) // Private Mode
    {
        if ( _inPrivateMode )
        {
            [self setPrivateMode:NO withServerSync:YES];
        }
        else
        {
            [self setPrivateMode:YES withServerSync:YES];
        }
    }
}

#pragma mark -
#pragma mark Attachment Options

- (void)showAttachmentOptions
{
    if ( isSendingMedia )
    {
        [self cancelMediaUpload];
    }
    else if ( !_attachmentsPanelIsShown )
    {
        UIShouldSlideDown = NO;
        shouldShowAttachmentsPanel = YES;
        
        [_messageBox becomeFirstResponder];
        [_messageBox resignFirstResponder];
        
        // Reset these values.
        UIShouldSlideDown = YES;
        shouldShowAttachmentsPanel = NO;
    }
    else // Panel is already shown. Dismiss it & show the keyboard.
    {
        [_messageBox becomeFirstResponder];
    }
}

- (void)showOptionsForTappedPhoneNumber:(NSString *)phoneNumber
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[appDelegate.contactManager formatPhoneNumberForDisplay:phoneNumber]
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:NSLocalizedString(@"OPTION_CALL_CONTACT", nil), NSLocalizedString(@"GENERIC_COPY", nil), nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.tag = 1;
    
    [actionSheet showFromRect:self.view.frame inView:appDelegate.window animated:YES];
}

- (void)media_UseLastPhotoTaken
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
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
                
                SHUserPresenceAudience audience = SHUserPresenceAudienceEveryone;
                
                if ( appDelegate.mainMenu.messagesView.inPrivateMode || !appDelegate.preference_Talking )
                {
                    audience = SHUserPresenceAudienceRecipient;
                }
                
                [appDelegate.presenceManager setPresence:SHUserPresenceSendingPhoto withTargetID:appDelegate.mainMenu.messagesView.recipientID forAudience:audience];
                
                [self beginMediaUploadWithMedia:selectedImage];
            }
        }];
    } failureBlock: ^(NSError *error){
        // Typically you should handle an error more gracefully than this.
        NSLog(@"No groups");
    }];
}

- (void)media_Camera
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    appDelegate.mainMenu.isPickingMedia = YES;
    
    SHUserPresenceAudience audience = SHUserPresenceAudienceEveryone;
    
    if ( appDelegate.mainMenu.messagesView.inPrivateMode || !appDelegate.preference_Talking )
    {
        audience = SHUserPresenceAudienceRecipient;
    }
    
    [appDelegate.presenceManager setPresence:SHUserPresenceSendingPhoto withTargetID:appDelegate.mainMenu.messagesView.recipientID forAudience:audience];
    
    [self resetView];
    [appDelegate.mainMenu showMediaPicker_Camera];
}

- (void)media_Library
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    appDelegate.mainMenu.isPickingMedia = YES;
    
    SHUserPresenceAudience audience = SHUserPresenceAudienceEveryone;
    
    if ( appDelegate.mainMenu.messagesView.inPrivateMode || !appDelegate.preference_Talking )
    {
        audience = SHUserPresenceAudienceRecipient;
    }
    
    [appDelegate.presenceManager setPresence:SHUserPresenceSendingPhoto withTargetID:appDelegate.mainMenu.messagesView.recipientID forAudience:audience];
    
    [self resetView];
    [appDelegate.mainMenu showMediaPicker_Library];
}

- (void)attachLocation
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    SHUserPresenceAudience audience = SHUserPresenceAudienceEveryone;
    
    if ( appDelegate.mainMenu.messagesView.inPrivateMode || !appDelegate.preference_Talking )
    {
        audience = SHUserPresenceAudienceRecipient;
    }
    
    [appDelegate.presenceManager setPresence:SHUserPresenceLocation withTargetID:appDelegate.mainMenu.messagesView.recipientID forAudience:audience];
    
    SHLocationPicker *locationPicker = [[SHLocationPicker alloc] init];
    locationPicker.delegate = self;
    
    SHOrientationNavigationController *navigationController = [[SHOrientationNavigationController alloc] initWithRootViewController:locationPicker];
    navigationController.autoRotates = NO;
    
    [appDelegate.mainMenu presentViewController:navigationController animated:YES completion:nil];
    
    locationPicker = nil;
    navigationController = nil;
}

#pragma mark -
#pragma mark Messages

- (void)fetchLatestMessageState
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for ( NSString *userID in _initialMessagesFetchedIDs )
        {
            
            if ( userID.intValue == _recipientID.intValue )
            {
                return;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [appDelegate.messageManager fetchLatestMessagesStateForUserID:_recipientID withIDInQueue:-1];
        });
    });
}

- (void)loadMessagesForRecipient
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [self currentUserPresenceDidChange];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            @synchronized( _threads )
            {
                __block int addedRowsHeight = 0;
                
                if ( batchNumber > 0 )
                {
                    int firstEntryType = [[[_threads objectAtIndex:0] objectForKey:@"entry_type"] intValue];
                    
                    if ( firstEntryType == 2 )
                    {
                        [_threads removeObjectAtIndex:0]; // Remove the date marker that would usually be the 1st element.
                    }
                }
                
                FMResultSet *s1;
                
                if ( _inAdHocMode )
                {
                    NSArray *originalParticipants = [_adHocTag allObjects];
                    NSString *originalParticipant_1 = [originalParticipants objectAtIndex:0];
                    NSString *originalParticipant_2 = [originalParticipants objectAtIndex:1];
                    
                    if ( batchNumber == 0 )
                    {
                        s1 = [db executeQuery:@"SELECT * FROM ("
                              @"SELECT * FROM sh_thread, sh_cloud "
                              @"INNER JOIN sh_message_dispatch "
                              @"ON sh_thread.thread_id = sh_message_dispatch.thread_id AND sh_thread.owner_id = sh_cloud.sh_user_id AND sh_thread.hidden = 0 AND sh_thread.temp = 1 AND ((sh_message_dispatch.sender_id = :original_user_1 AND sh_message_dispatch.recipient_id = :original_user_2) OR (sh_message_dispatch.sender_id = :original_user_2 AND sh_message_dispatch.recipient_id = :original_user_1)) "
                              @"ORDER BY sh_thread.timestamp_sent DESC LIMIT :batch_number, :batch_size) AS result "
                              @"ORDER BY result.timestamp_sent ASC"
                      withParameterDictionary:@{@"original_user_1": originalParticipant_1,
                                                @"original_user_2": originalParticipant_2,
                                                @"batch_size": [NSNumber numberWithInt:CONVERSATION_BATCH_SIZE],
                                                @"batch_number": [NSNumber numberWithInt:(batchNumber * CONVERSATION_BATCH_SIZE)]}];
                    }
                    else
                    {
                        s1 = [db executeQuery:@"SELECT * FROM sh_thread, sh_cloud "
                              @"INNER JOIN sh_message_dispatch "
                              @"ON sh_thread.thread_id = sh_message_dispatch.thread_id AND sh_thread.owner_id = sh_cloud.sh_user_id AND sh_thread.hidden = 0 AND sh_thread.temp = 1 AND ((sh_message_dispatch.sender_id = :original_user_1 AND sh_message_dispatch.recipient_id = :original_user_2) OR (sh_message_dispatch.sender_id = :original_user_2 AND sh_message_dispatch.recipient_id = :original_user_1)) "
                              @"ORDER BY sh_thread.timestamp_sent DESC LIMIT :batch_number, :batch_size"
                      withParameterDictionary:@{@"original_user_1": originalParticipant_1,
                                                @"original_user_2": originalParticipant_2,
                                                @"batch_size": [NSNumber numberWithInt:CONVERSATION_BATCH_SIZE],
                                                @"batch_number": [NSNumber numberWithInt:(batchNumber * CONVERSATION_BATCH_SIZE)]}];
                    }
                }
                else
                {
                    if ( batchNumber == 0 )
                    {
                        s1 = [db executeQuery:@"SELECT * FROM ("
                              @"SELECT * FROM sh_thread s1 "
                              @"WHERE ((s1.owner_id = :recipient_id OR s1.owner_id = :current_user_id) AND s1.thread_type NOT IN (1, 8)) "
                              @"OR thread_id IN "
                              @"(SELECT s2.thread_id FROM sh_thread s2 "
                              @"INNER JOIN sh_message_dispatch "
                              @"ON s2.thread_id = sh_message_dispatch.thread_id AND s2.hidden = 0 AND s2.temp = 0 AND ((sh_message_dispatch.sender_id = :current_user_id AND sh_message_dispatch.recipient_id = :recipient_id) OR (sh_message_dispatch.sender_id = :recipient_id AND sh_message_dispatch.recipient_id = :current_user_id))) "
                              @"ORDER BY s1.timestamp_sent DESC LIMIT :batch_number, :batch_size) AS result "
                              @"ORDER BY result.timestamp_sent ASC"
                      withParameterDictionary:@{@"recipient_id": _recipientID,
                                                @"current_user_id": [appDelegate.currentUser objectForKey:@"user_id"],
                                                @"batch_size": [NSNumber numberWithInt:CONVERSATION_BATCH_SIZE],
                                                @"batch_number": [NSNumber numberWithInt:(batchNumber * CONVERSATION_BATCH_SIZE)]}];
                    }
                    else
                    {
                        s1 = [db executeQuery:@"SELECT * FROM sh_thread s1 "
                              @"WHERE ((s1.owner_id = :recipient_id OR s1.owner_id = :current_user_id) AND s1.thread_type NOT IN (1, 8)) "
                              @"OR thread_id IN "
                              @"(SELECT s2.thread_id FROM sh_thread s2 "
                              @"INNER JOIN sh_message_dispatch "
                              @"ON s2.thread_id = sh_message_dispatch.thread_id AND s2.hidden = 0 AND s2.temp = 0 AND ((sh_message_dispatch.sender_id = :current_user_id AND sh_message_dispatch.recipient_id = :recipient_id) OR (sh_message_dispatch.sender_id = :recipient_id AND sh_message_dispatch.recipient_id = :current_user_id))) "
                              @"ORDER BY s1.timestamp_sent DESC LIMIT :batch_number, :batch_size"
                      withParameterDictionary:@{@"recipient_id": _recipientID,
                                                @"current_user_id": [appDelegate.currentUser objectForKey:@"user_id"],
                                                @"batch_size": [NSNumber numberWithInt:CONVERSATION_BATCH_SIZE],
                                                @"batch_number": [NSNumber numberWithInt:(batchNumber * CONVERSATION_BATCH_SIZE)]}];
                    }
                }
                
                int i = 0;
                
                // Read & store each thread's data.
                while ( [s1 next] )
                {
                    NSString *firstName;
                    NSString *lastName;
                    NSString *alias;
                    id DP;
                    id aliasDP;
                    
                    if ( _inAdHocMode )
                    {
                        firstName = [s1 stringForColumn:@"name_first"];
                        lastName = [s1 stringForColumn:@"name_last"];
                        alias = [s1 stringForColumn:@"alias"];
                        DP = [s1 dataForColumn:@"dp"];
                        aliasDP = [s1 dataForColumn:@"alias_dp"];
                    }
                    else
                    {
                        firstName = @"";
                        lastName = @"";
                        alias = @"";
                        DP = @"";
                        aliasDP = @"";
                    }
                    
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
                    NSString *mediaNotFound = @"0";
                    id mediaData = @"";
                    id mediaExtra = @"";
                    
                    if ( !alias )
                    {
                        alias = @"";
                    }
                    
                    if ( !DP )
                    {
                        DP = UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0);
                    }
                    
                    if ( [status_sent intValue] == SHThreadStatusSending )
                    {
                        status_sent = [NSString stringWithFormat:@"%d", SHThreadStatusSendingFailed];
                    }
                    
                    if ( [s1 stringForColumn:@"thread_id"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"thread_id"]] )
                    {
                        threadID = [s1 stringForColumn:@"thread_id"];
                    }
                    
                    if ( [s1 stringForColumn:@"thread_type"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"thread_type"]] )
                    {
                        threadType = [s1 stringForColumn:@"thread_type"];
                    }
                    
                    if ( [s1 stringForColumn:@"root_item_id"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"root_item_id"]] )
                    {
                        rootItemID = [s1 stringForColumn:@"root_item_id"];
                    }
                    
                    if ( [s1 stringForColumn:@"child_count"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"child_count"]] )
                    {
                        childCount = [s1 stringForColumn:@"child_count"];
                    }
                    
                    if ( [s1 stringForColumn:@"owner_id"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"owner_id"]] )
                    {
                        ownerID = [s1 stringForColumn:@"owner_id"];
                    }
                    
                    if ( [s1 stringForColumn:@"owner_type"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"owner_type"]] )
                    {
                        ownerType = [s1 stringForColumn:@"owner_type"];
                    }
                    
                    if ( [s1 stringForColumn:@"group_id"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"group_id"]] )
                    {
                        groupID = [s1 stringForColumn:@"group_id"];
                    }
                    
                    if ( [s1 stringForColumn:@"unread_message_count"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"unread_message_count"]] )
                    {
                        unreadMessageCount = [s1 stringForColumn:@"unread_message_count"];
                    }
                    
                    if ( [s1 stringForColumn:@"privacy"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"privacy"]] )
                    {
                        privacy = [s1 stringForColumn:@"privacy"];
                    }
                    
                    if ( [s1 stringForColumn:@"status_sent"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"status_sent"]] )
                    {
                        status_sent = [s1 stringForColumn:@"status_sent"];
                    }
                    
                    if ( [s1 stringForColumn:@"status_delivered"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"status_delivered"]] )
                    {
                        status_delivered = [s1 stringForColumn:@"status_delivered"];
                    }
                    
                    if ( [s1 stringForColumn:@"status_read"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"status_read"]] )
                    {
                        status_read = [s1 stringForColumn:@"status_read"];
                    }
                    
                    if ( [s1 stringForColumn:@"timestamp_sent"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"timestamp_sent"]] )
                    {
                        timestamp_sent = [s1 stringForColumn:@"timestamp_sent"];
                    }
                    
                    if ( [s1 stringForColumn:@"timestamp_delivered"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"timestamp_delivered"]] )
                    {
                        timestamp_delivered = [s1 stringForColumn:@"timestamp_delivered"];
                    }
                    
                    if ( [s1 stringForColumn:@"timestamp_read"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"timestamp_read"]] )
                    {
                        timestamp_read = [s1 stringForColumn:@"timestamp_read"];
                    }
                    
                    if ( [s1 stringForColumn:@"message"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"message"]] )
                    {
                        message = [s1 stringForColumn:@"message"];
                    }
                    
                    if ( [s1 stringForColumn:@"location_longitude"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"location_longitude"]] )
                    {
                        longitude = [s1 stringForColumn:@"location_longitude"];
                    }
                    
                    if ( [s1 stringForColumn:@"location_latitude"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"location_latitude"]] )
                    {
                        latitude = [s1 stringForColumn:@"location_latitude"];
                    }
                    
                    if ( [s1 stringForColumn:@"media_type"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"media_type"]] )
                    {
                        mediaType = [s1 stringForColumn:@"media_type"];
                    }
                    
                    if ( [s1 stringForColumn:@"media_file_size"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"media_file_size"]] )
                    {
                        mediaFileSize = [s1 stringForColumn:@"media_file_size"];
                    }
                    
                    if ( [s1 stringForColumn:@"media_local_path"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"media_local_path"]] )
                    {
                        mediaLocalPath = [s1 stringForColumn:@"media_local_path"];
                    }
                    
                    if ( [s1 stringForColumn:@"media_hash"] && ![[NSNull null] isEqual:[s1 stringForColumn:@"media_hash"]] )
                    {
                        mediaHash = [s1 stringForColumn:@"media_hash"];
                    }
                    
                    if ( [s1 dataForColumn:@"media_data"] && ![[NSNull null] isEqual:[s1 dataForColumn:@"media_data"]] )
                    {
                        mediaData = [s1 dataForColumn:@"media_data"];
                    }
                    
                    if ( [s1 dataForColumn:@"media_extra"] && ![[NSNull null] isEqual:[s1 dataForColumn:@"media_extra"]] )
                    {
                        mediaExtra = [s1 dataForColumn:@"media_extra"];
                        
                        NSDictionary *attachmentData = [NSJSONSerialization JSONObjectWithData:mediaExtra options:NSJSONReadingAllowFragments error:nil];
                        mediaExtra = attachmentData;
                        
                        if ( !mediaExtra )
                        {
                            mediaExtra = @"";
                        }
                    }
                    
                    NSMutableDictionary *messageData = [[NSMutableDictionary alloc] initWithObjects:@[firstName,
                                                                                                      lastName,
                                                                                                      alias,
                                                                                                      DP,
                                                                                                      aliasDP,
                                                                                                      entryType,
                                                                                                      threadID,
                                                                                                      threadType,
                                                                                                      rootItemID,
                                                                                                      childCount,
                                                                                                      ownerID,
                                                                                                      ownerType,
                                                                                                      groupID,
                                                                                                      unreadMessageCount,
                                                                                                      privacy,
                                                                                                      status_sent,
                                                                                                      status_delivered,
                                                                                                      status_read,
                                                                                                      timestamp_sent,
                                                                                                      timestamp_delivered,
                                                                                                      timestamp_read,
                                                                                                      message,
                                                                                                      longitude,
                                                                                                      latitude,
                                                                                                      mediaType,
                                                                                                      mediaFileSize,
                                                                                                      mediaLocalPath,
                                                                                                      mediaHash,
                                                                                                      mediaNotFound,
                                                                                                      mediaData,
                                                                                                      mediaExtra]
                                                                                            forKeys:@[@"name_first",
                                                                                                      @"name_last",
                                                                                                      @"alias",
                                                                                                      @"dp",
                                                                                                      @"alias_dp",
                                                                                                      @"entry_type",
                                                                                                      @"thread_id",
                                                                                                      @"thread_type",
                                                                                                      @"root_item_id",
                                                                                                      @"child_count",
                                                                                                      @"owner_id",
                                                                                                      @"owner_type",
                                                                                                      @"group_id",
                                                                                                      @"unread_message_count",
                                                                                                      @"privacy",
                                                                                                      @"status_sent",
                                                                                                      @"status_delivered",
                                                                                                      @"status_read",
                                                                                                      @"timestamp_sent",
                                                                                                      @"timestamp_delivered",
                                                                                                      @"timestamp_read",
                                                                                                      @"message",
                                                                                                      @"location_longitude",
                                                                                                      @"location_latitude",
                                                                                                      @"media_type",
                                                                                                      @"media_file_size",
                                                                                                      @"media_local_path",
                                                                                                      @"media_hash",
                                                                                                      @"media_not_found",
                                                                                                      @"media_data",
                                                                                                      @"media_extra"]];
                    
                    if ( mediaHash.length > 1 && mediaHash.intValue != -1 )
                    {
                        UIImage *media = [UIImage imageWithData:mediaData];
                        
                        if ( !media )
                        {
                            NSURL *mediaURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/userphotos/%@/photos/f_%@.jpg", SH_DOMAIN, ownerID, mediaHash]];
                            
                            NSURLRequest *request = [NSURLRequest requestWithURL:mediaURL];
                            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                UIImage *media = [UIImage imageWithData:data];
                                
                                if ( media )
                                {
                                    // Save the file locally.
                                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                    NSString *documentsPath = [paths objectAtIndex:0]; // Get the docs directory.
                                    NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", mediaHash]]; // Add the file name.
                                    [data writeToFile:filePath atomically:YES]; // Write the file.
                                    
                                    [db executeUpdate:@"UPDATE sh_thread "
                                                        @"SET media_data = :media_data, media_local_path = :media_local_path "
                                                        @"WHERE owner_id = :user_id AND thread_id = :thread_id"
                                            withParameterDictionary:@{@"user_id": ownerID,
                                                                      @"thread_id": threadID,
                                                                      @"media_data": data,
                                                                      @"media_local_path": filePath}];
                                    
                                    for ( int i = 0; i < _threads.count; i++ )
                                    {
                                        NSMutableDictionary *message = [_threads objectAtIndex:i];
                                        NSString *targetMediaHash = [message objectForKey:@"media_hash"];
                                        
                                        if ( [targetMediaHash isEqualToString:mediaHash] )
                                        {
                                            SHThreadCell *targetCell = (SHThreadCell *)[_conversationTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                                            
                                            UIImage *scaledImage = [UIImage imageWithData:data];
                                            float width = scaledImage.size.width;
                                            float height = scaledImage.size.height;
                                            float paddingFactor = height / 4;
                                            
                                            if ( height > width + paddingFactor ) // Portrait image.
                                            {
                                                if ( width > 320 ) // No bigger than this size.
                                                {
                                                    width = 320;
                                                }
                                            }
                                            else // Landscape image.
                                            {
                                                if ( width > 480 )
                                                {
                                                    width = 480;
                                                }
                                            }
                                            
                                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                                [message setObject:data forKey:@"media_data"];
                                                [message setObject:UIImageJPEGRepresentation([appDelegate imageWithImage:scaledImage scaledToWidth:width], 1.0) forKey:@"media_thumbnail"];
                                                [message setObject:filePath forKey:@"media_local_path"];
                                                
                                                [targetCell setMedia:scaledImage withThumbnail:[UIImage imageWithData:[message objectForKey:@"media_thumbnail"]] atPath:filePath];
                                                
                                                [_threads setObject:message atIndexedSubscript:i];
                                                [_conversationTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
                                            });
                                            
                                            break;
                                        }
                                    }
                                }
                                else
                                {
                                    for ( int i = 0; i < _threads.count; i++ )
                                    {
                                        NSMutableDictionary *message = [_threads objectAtIndex:i];
                                        NSString *targetMediaHash = [message objectForKey:@"media_hash"];
                                        
                                        if ( [targetMediaHash isEqualToString:mediaHash] )
                                        {
                                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                                SHThreadCell *targetCell = (SHThreadCell *)[_conversationTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                                                
                                                if ( [response respondsToSelector:@selector(statusCode)] )
                                                {
                                                    int statusCode = (int)[((NSHTTPURLResponse *)response) statusCode];
                                                    
                                                    if ( statusCode == 404 )
                                                    {
                                                        [message setObject:@"1" forKey:@"media_not_found"];
                                                        [_threads setObject:message atIndexedSubscript:i];
                                                        [targetCell showMediaNotFound];
                                                    }
                                                    else
                                                    {
                                                        [targetCell showMediaRedownloadButton];
                                                    }
                                                }
                                                else
                                                {
                                                    [targetCell showMediaRedownloadButton];
                                                }
                                            });
                                            
                                            break;
                                        }
                                    }
                                }
                            }];
                        }
                        else
                        {
                            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                            NSString *documentsPath = [paths objectAtIndex:0]; // Get the docs directory.
                            NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", mediaHash]]; // Add the file name.
                            
                            UIImage *scaledImage = [UIImage imageWithData:mediaData];
                            float width = scaledImage.size.width;
                            float height = scaledImage.size.height;
                            float paddingFactor = height / 4; // The height needs to be significantly greater than the width.
                            
                            if ( height > width + paddingFactor ) // Portrait image.
                            {
                                if ( width > 320 ) // No bigger than this size.
                                {
                                    width = 320;
                                }
                            }
                            else // Landscape image.
                            {
                                if ( width > 480 )
                                {
                                    width = 480;
                                }
                            }
                            
                            [messageData setObject:UIImageJPEGRepresentation([appDelegate imageWithImage:scaledImage scaledToWidth:width], 1.0) forKey:@"media_thumbnail"];
                            [messageData setObject:filePath forKey:@"media_local_path"];
                        }
                    }
                    
                    if ( i != 0 )
                    {
                        int index = 0; // Since in the case of batch != 0, the new element is always inserted at the top.
                        
                        if ( batchNumber == 0 )
                        {
                            index = i - 1;
                        }
                        
                        NSMutableDictionary *entry = [_threads objectAtIndex:index];
                        int entryType = [[entry objectForKey:@"entry_type"] intValue];
                        
                        if ( entryType == 1 )
                        {
                            NSDate *firstDate = [dateFormatter dateFromString:[entry objectForKey:@"timestamp_sent"]];
                            NSDate *secondDate = [dateFormatter dateFromString:timestamp_sent];
                            
                            NSDateComponents *componentsForFirstDate = [appDelegate.calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:firstDate];
                            NSDateComponents *componentsForSecondDate = [appDelegate.calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:secondDate];
                            
                            if ( componentsForFirstDate.year == componentsForSecondDate.year &&
                                componentsForFirstDate.month == componentsForSecondDate.month &&
                                componentsForFirstDate.day == componentsForSecondDate.day )
                            {
                                // On the same day. Nothing to do.
                                
                            }
                            else
                            {
                                /*
                                 *  We should always compare the timestamp of the current message with the one
                                 *  underneath it. Remember that the insertion sequence for the first batch that
                                 *  loads with the window is different from subsequent batches.
                                 */
                                if ( batchNumber == 0 )
                                {
                                    NSMutableDictionary *dateMarker = [[NSMutableDictionary alloc] initWithObjects:@[@"2",
                                                                                                                     timestamp_sent]
                                                                                                           forKeys:@[@"entry_type",
                                                                                                                     @"date"]];
                                    
                                    [_threads addObject:dateMarker];
                                }
                                else
                                {
                                    NSMutableDictionary *dateMarker = [[NSMutableDictionary alloc] initWithObjects:@[@"2",
                                                                                                                     [entry objectForKey:@"timestamp_sent"]]
                                                                                                           forKeys:@[@"entry_type",
                                                                                                                     @"date"]];
                                    
                                    [_threads insertObject:dateMarker atIndex:0];
                                }
                                
                                i++;
                            }
                        }
                    }
                    
                    i++;
                    
                    if ( batchNumber == 0 )
                    {
                        [_threads addObject:messageData];
                    }
                    else
                    {
                        [_threads insertObject:messageData atIndex:0];
                    }
                    
                    
                }
                
                [s1 close];
                
                NSMutableDictionary *firstEntry = [_threads objectAtIndex:0];
                int firstEntryType = [[firstEntry objectForKey:@"entry_type"] intValue];
                
                if ( firstEntryType != 2 )
                {
                    NSMutableDictionary *dateMarker = [[NSMutableDictionary alloc] initWithObjects:@[@"2",
                                                                                                     [firstEntry objectForKey:@"timestamp_sent"]]
                                                                                           forKeys:@[@"entry_type",
                                                                                                     @"date"]];
                    i++;
                    
                    [_threads insertObject:dateMarker atIndex:0];
                }
                
                if ( i < CONVERSATION_BATCH_SIZE )
                {
                    endOfConversation = YES;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [_conversationTable reloadData];
                    
                    if ( batchNumber == 0 )
                    {
                        shouldReloadTable = YES; // Reload the table again because sometimes the merit value isn't available by the time this runs.
                        
                        [self scrollViewToBottomForced:YES animated:YES];
                    }
                    else
                    {
                        for ( int j = 0; j < i; j++ )
                        {
                            addedRowsHeight += [self tableView:_conversationTable heightForRowAtIndexPath:[NSIndexPath indexPathForRow:j inSection:0]];
                        }
                        
                        addedRowsHeight -= 41; // Subtract this value to prevent an offset twitch.
                        
                        [_conversationTable setContentOffset:CGPointMake(0, addedRowsHeight)];
                    }
                    
                    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                        _conversationTable.alpha = 1.0;
                    } completion:^(BOOL finished){
                        long double delayInSeconds = 0.35;
                        
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            shouldLoadMessagesOnScroll = YES;
                        });
                    }];
                    
                    if ( timer_timestamps )
                    {
                        [timer_timestamps invalidate];
                        timer_timestamps = nil;
                    }
                    
                    timer_timestamps = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(updateTimestamps) userInfo:nil repeats:YES]; // Update every 1 min.
                });
            }
        }];
        
        if ( !_inAdHocMode && batchNumber == 0 )
        {
            [self markMessagesAsRead];
        }
    });
}

- (void)sendTextMessage
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSString *message = _messageBox.text;
    
    if ( message.length > MAX_MSG_LENGTH )
    {
        [appDelegate.strobeLight negativeStrobeLight];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"MESSAGES_ERROR_LENGTH", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil) otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    
    if ( _keyboardIsShown )
    {
        UIShouldSlideDown = NO;
        
        [_messageBox resignFirstResponder];
        [_messageBox becomeFirstResponder];
        
        UIShouldSlideDown = YES; // Reset this value.
    }
    else if ( _attachmentsPanelIsShown )
    {
        [_messageBox becomeFirstResponder]; // To reset the keyboard view.
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SHMediaType activeMediaType;
        NSString *activeMediaHash = @"";
        id activeMediaFile = nil;
        
        for ( int i = 0; i < processedMediaUploads.count; i++ ) // Check if we've got media ready for sending.
        {
            NSDictionary *processedUpload = [processedMediaUploads objectAtIndex:i];
            int processedUploadID = [[processedUpload objectForKey:@"user_id"] intValue];
            SHMediaType processedMediaType = [[processedUpload objectForKey:@"media_type"] intValue];
            NSString *processedMediaHash = [processedUpload objectForKey:@"hash"];
            NSData *targetMedia = [processedUpload objectForKey:@"media"];
            
            if ( processedUploadID == _recipientID.intValue )
            {
                activeMediaType = processedMediaType;
                activeMediaHash = processedMediaHash;
                activeMediaFile = targetMedia;
                
                [processedMediaUploads removeObjectAtIndex:i]; // Clear 'em out.
                
                break;
            }
        }
        
        if ( message.length > 0 || activeMediaFile )
        {
            __block NSString *threadID = @"-1";
            NSString *entryType = @"1";
            NSString *threadType = [NSString stringWithFormat:@"%d", SHThreadTypeMessage];
            NSString *rootItemID = @"-1";
            NSString *childCount = @"0";
            NSString *ownerID = [appDelegate.currentUser objectForKey:@"user_id"];
            NSString *ownerType = @"1";
            NSString *unreadMessageCount = @"0";
            NSString *groupID = @"-1";
            NSString *status_sent = [NSString stringWithFormat:@"%d", SHThreadStatusSending];
            NSString *status_delivered = @"0";
            NSString *status_read = @"0";
            NSString *timestamp_sent = [appDelegate.modelManager dateTodayString];
            NSString *timestamp_delivered = @"";
            NSString *timestamp_read = @"";
            NSString *mediaType = @"-1";
            NSString *mediaFileSize = @"-1";
            NSString *mediaLocalPath = @"-1";
            NSString *mediaHash = @"-1";
            NSString *mediaNotFound = @"0";
            id mediaData = @"-1";
            NSDictionary *mediaExtra = @{@"attachment_type": @"null"};
            NSString *longitude = [NSString stringWithFormat:@"%f", appDelegate.locationManager.currentLocation.longitude];
            NSString *latitude = [NSString stringWithFormat:@"%f", appDelegate.locationManager.currentLocation.latitude];
            NSString *privacy;
            SHUserPresenceAudience audience = SHUserPresenceAudienceEveryone;
            
            if ( _inPrivateMode )
            {
                privacy = [NSString stringWithFormat:@"%d", SHThreadPrivacyPrivate];
                audience = SHUserPresenceAudienceRecipient;
            }
            else
            {
                privacy = [NSString stringWithFormat:@"%d", SHThreadPrivacyPublic];
                
                if ( !appDelegate.preference_Talking )
                {
                    audience = SHUserPresenceAudienceRecipient;
                }
            }
            
            if ( appDelegate.locationManager.currentLocation.latitude == 9999 ) // When location fails.
            {
                longitude = @"";
                latitude = @"";
            }
            
            if ( activeMediaFile )
            {
                mediaType = [NSString stringWithFormat:@"%d", activeMediaType];
                mediaHash = activeMediaHash;
                mediaData = activeMediaFile;
                
                // Save the file locally.
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsPath = [paths objectAtIndex:0]; // Get the docs directory.
                mediaLocalPath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", mediaHash]]; // Add the file name.
                [mediaData writeToFile:mediaLocalPath atomically:YES]; // Write the file.
            }
            
            NSMutableDictionary *messageData = [[NSMutableDictionary alloc] initWithObjects:@[entryType,
                                                                                              threadID,
                                                                                              threadType,
                                                                                              rootItemID,
                                                                                              childCount,
                                                                                              ownerID,
                                                                                              ownerType,
                                                                                              _recipientID,
                                                                                              unreadMessageCount,
                                                                                              privacy,
                                                                                              groupID,
                                                                                              status_sent,
                                                                                              status_delivered,
                                                                                              status_read,
                                                                                              timestamp_sent,
                                                                                              timestamp_delivered,
                                                                                              timestamp_read,
                                                                                              message,
                                                                                              longitude,
                                                                                              latitude,
                                                                                              mediaType,
                                                                                              mediaFileSize,
                                                                                              mediaLocalPath,
                                                                                              mediaHash,
                                                                                              mediaNotFound,
                                                                                              mediaData,
                                                                                              mediaExtra]
                                                                                    forKeys:@[@"entry_type",
                                                                                              @"thread_id",
                                                                                              @"thread_type",
                                                                                              @"root_item_id",
                                                                                              @"child_count",
                                                                                              @"owner_id",
                                                                                              @"owner_type",
                                                                                              @"recipient_id",
                                                                                              @"unread_message_count",
                                                                                              @"privacy",
                                                                                              @"group_id",
                                                                                              @"status_sent",
                                                                                              @"status_delivered",
                                                                                              @"status_read",
                                                                                              @"timestamp_sent",
                                                                                              @"timestamp_delivered",
                                                                                              @"timestamp_read",
                                                                                              @"message",
                                                                                              @"location_longitude",
                                                                                              @"location_latitude",
                                                                                              @"media_type",
                                                                                              @"media_file_size",
                                                                                              @"media_local_path",
                                                                                              @"media_hash",
                                                                                              @"media_not_found",
                                                                                              @"media_data",
                                                                                              @"media_extra"]];
            
            NSData *mediaExtraData = [NSJSONSerialization dataWithJSONObject:mediaExtra options:NSJSONWritingPrettyPrinted error:nil];
            [messageData setObject:mediaExtraData forKey:@"media_extra"];
            
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
            [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                [db executeUpdate:@"INSERT INTO sh_thread "
                                    @"(thread_type, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                                    @"VALUES (:thread_type, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent, :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                        withParameterDictionary:messageData];
                
                // Get the insert ID & use it in the dispatch table.
                FMResultSet *s1 = [db executeQuery:@"SELECT thread_id FROM sh_thread ORDER BY timestamp_sent DESC LIMIT 1"
                           withParameterDictionary:nil];
                
                while ( [s1 next] )
                {
                    threadID = [s1 stringForColumnIndex:0];
                    [messageData setObject:threadID forKey:@"thread_id"];
                }
                
                [s1 close];
                
                [db executeUpdate:@"INSERT INTO sh_message_dispatch "
                                    @"(thread_id, sender_id, sender_type, recipient_id, timestamp) "
                                    @"VALUES (:thread_id, :owner_id, :owner_type, :recipient_id, :timestamp_sent)"
                        withParameterDictionary:messageData];
                
                if ( activeMediaFile )
                {
                    UIImage *scaledImage = [UIImage imageWithData:mediaData];
                    float width = scaledImage.size.width;
                    float height = scaledImage.size.height;
                    float paddingFactor = height / 4;
                    
                    if ( height > width + paddingFactor ) // Portrait image.
                    {
                        if ( width > 320 ) // No bigger than this size.
                        {
                            width = 320;
                        }
                    }
                    else // Landscape image.
                    {
                        if ( width > 480 )
                        {
                            width = 480;
                        }
                    }
                    
                    [messageData setObject:UIImageJPEGRepresentation([appDelegate imageWithImage:scaledImage scaledToWidth:width], 1.0) forKey:@"media_thumbnail"];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    _messageBox.textColor = [UIColor colorWithRed:59/255.0 green:89/255.0 blue:152/255.0 alpha:1.0];
                    
                    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                        sendButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-90));
                        attachButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90));
                    } completion:^(BOOL finished){
                        
                    }];
                    
                    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                        messageBoxBubble.frame = CGRectMake(appDelegate.screenBounds.size.width - messageBoxBubble.frame.size.width, messageBoxBubble.frame.origin.y, messageBoxBubble.frame.size.width, messageBoxBubble.frame.size.height);
                        attachButton.frame = CGRectMake(-25, attachButton.frame.origin.y, attachButton.frame.size.width, attachButton.frame.size.height);
                        sendButton.frame = CGRectMake(appDelegate.screenBounds.size.width - 5, sendButton.frame.origin.y, sendButton.frame.size.width, sendButton.frame.size.height);
                        attachButton.alpha = 0.0;
                        sendButton.alpha = 0.0;
                    } completion:^(BOOL finished){
                        [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                            messageBoxBubble.frame = CGRectMake(appDelegate.screenBounds.size.width - messageBoxBubble.frame.size.width - 10, messageBoxBubble.frame.origin.y, messageBoxBubble.frame.size.width, messageBoxBubble.frame.size.height);
                        } completion:^(BOOL finished){
                            [self sendMessage:messageData forAudience:audience];
                        }];
                    }];
                });
            }];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [_messageBox becomeFirstResponder];
            });
        }
    });
}

- (void)sendMessage:(NSMutableDictionary *)message forAudience:(SHUserPresenceAudience)audience
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.presenceManager setPresence:SHUserPresenceActivityStopped withTargetID:_recipientID forAudience:SHUserPresenceAudienceEveryone];
    [appDelegate.messageManager dispatchMessage:message forAudience:audience];
    
    if ( appDelegate.preference_Sounds ) // Play the sound effect.
    {
        [Sound playSoundEffect:12];
    }
    
    NSDictionary *mediaExtra = [NSJSONSerialization JSONObjectWithData:[message objectForKey:@"media_extra"] options:NSJSONReadingAllowFragments error:nil];
    [message setObject:mediaExtra forKey:@"media_extra"];
    
    @synchronized( _threads )
    {
        NSMutableDictionary *previousEntry = [_threads lastObject];
        int previousEntryType = [[previousEntry objectForKey:@"entry_type"] intValue];
        
        if ( previousEntryType == 1 )
        {
            NSString *timestamp_sent = [appDelegate.modelManager dateTodayString];
            NSDate *firstDate = [dateFormatter dateFromString:[previousEntry objectForKey:@"timestamp_sent"]];
            NSDate *secondDate = [dateFormatter dateFromString:timestamp_sent];
            
            NSDateComponents *componentsForFirstDate = [appDelegate.calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:firstDate];
            NSDateComponents *componentsForSecondDate = [appDelegate.calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:secondDate];
            
            if ( componentsForFirstDate.year == componentsForSecondDate.year &&
                componentsForFirstDate.month == componentsForSecondDate.month &&
                componentsForFirstDate.day == componentsForSecondDate.day )
            {
                // On the same day. Nothing to do.
                
            }
            else
            {
                NSMutableDictionary *dateMarker = [[NSMutableDictionary alloc] initWithObjects:@[@"2",
                                                                                                 timestamp_sent]
                                                                                       forKeys:@[@"entry_type",
                                                                                                 @"date"]];
                [_threads addObject:dateMarker];
            }
        }
        
        [_threads addObject:message];
        [_conversationTable reloadData];
        
        attachButton.alpha = 1.0;
        sendButton.alpha = 1.0;
        attachButton.frame = CGRectMake(5, attachButton.frame.origin.y, attachButton.frame.size.width, attachButton.frame.size.height);
        sendButton.frame = CGRectMake(appDelegate.screenBounds.size.width - 55, sendButton.frame.origin.y, sendButton.frame.size.width, sendButton.frame.size.height);
        sendButton.transform = CGAffineTransformIdentity;
        attachButton.transform = CGAffineTransformIdentity;
        _messageBox.textColor = [UIColor blackColor];
        _messageBox.text = @""; // Clear out the text box.
        
        if ( isSendingMedia )
        {
            [self resetMessagingInterface];
        }
        else
        {
            [self scrollViewToBottomForced:YES animated:YES];
        }
    }
}

- (void)deleteThreadAtIndexPath:(NSIndexPath *)indexPath deletionConfirmed:(BOOL)confirmed
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    NSDictionary *messageData = [_threads objectAtIndex:indexPath.row];
    int ownerID = [[messageData objectForKey:@"owner_id"] intValue];
    
    // If you're not the owner of a thread, you can delete your local copy, but not the server one.
    if ( ownerID != [[appDelegate.currentUser objectForKey:@"user_id"] intValue] )
    {
        [appDelegate.modelManager executeUpdate:@"UPDATE sh_thread "
                                                @"SET hidden = 1 "
                                                @"WHERE thread_id = :thread_id"
                        withParameterDictionary:@{@"thread_id": [messageData objectForKey:@"thread_id"]}];
        
        [appDelegate.modelManager executeUpdate:@"DELETE FROM sh_message_dispatch "
                                                @"WHERE thread_id = :thread_id"
                        withParameterDictionary:@{@"thread_id": [messageData objectForKey:@"thread_id"]}];
        
        confirmed = YES;
    }
    
    if ( confirmed )
    {
        @synchronized( _threads )
        {
            /*  Cleanup
             *  ==
             *  Entries containing media save a copy of the file to the local filesystem.
             */
            NSMutableDictionary *entry = [_threads objectAtIndex:indexPath.row];
            NSString *mediaHash = [entry objectForKey:@"media_hash"];
            
            if ( mediaHash.length > 1 && [mediaHash intValue] != -1 )
            {
                NSString *mediaLocalPath = [entry objectForKey:@"media_local_path"];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *error;
                
                if ( [fileManager fileExistsAtPath:mediaLocalPath] )
                {
                    if ( [fileManager removeItemAtPath:mediaLocalPath error:&error] )
                    {
                        NSLog(@"Deleted local media!");
                    }
                    else
                    {
                        NSLog(@"Failed delete local media: %@", error);
                    }
                }
            }
            
            [_conversationTable beginUpdates];
            
            [_threads removeObjectAtIndex:indexPath.row];
            [_conversationTable deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            BOOL clearFromAbove = NO;
            BOOL clearFromBelow = NO;
            
            NSMutableDictionary *previousEntry = [_threads objectAtIndex:indexPath.row - 1];
            int previousEntryType = [[previousEntry objectForKey:@"entry_type"] intValue];
            
            if ( previousEntryType == 2 ) // No messages above the current one.
            {
                clearFromAbove = YES;
            }
            
            if ( indexPath.row < _threads.count )
            {
                NSMutableDictionary *nextEntry = [_threads objectAtIndex:indexPath.row]; // Not +1 because at this point an entry has already been deleted!
                int nextEntryType = [[nextEntry objectForKey:@"entry_type"] intValue];
                
                if ( nextEntryType == 2 )
                {
                    clearFromBelow = YES;
                }
            }
            else
            {
                clearFromBelow = YES;
            }
            
            if ( clearFromAbove && clearFromBelow )
            {
                NSIndexPath *dateEntryIndexPath = [NSIndexPath indexPathForRow:(indexPath.row - 1) inSection:0];
                [_threads removeObjectAtIndex:dateEntryIndexPath.row];
                [_conversationTable deleteRowsAtIndexPaths:@[dateEntryIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            
            [_conversationTable endUpdates];
            
            long double delayInSeconds = 0.35;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if ( shouldReloadTable )
                {
                    [_conversationTable reloadData];
                    
                    shouldReloadTable = NO;
                }
                
                tableIsScrolling = NO;
            });
        }
    }
    else
    {
        [appDelegate.messageManager deleteThread:[messageData objectForKey:@"thread_id"] withIndexPath:indexPath];
    }
}

- (void)resendMessageAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    SHUserPresenceAudience audience = SHUserPresenceAudienceEveryone;
    SHThreadCell *targetCell = (SHThreadCell *)[_conversationTable cellForRowAtIndexPath:indexPath];
    NSMutableDictionary *thread = [_threads objectAtIndex:indexPath.row];
    
    [thread setObject:[NSString stringWithFormat:@"%d", SHThreadStatusSending] forKey:@"status_sent"];
    [_threads setObject:thread atIndexedSubscript:indexPath.row];
    
    if ( _inPrivateMode )
    {
        audience = SHUserPresenceAudienceRecipient;
    }
    else
    {
        if ( !appDelegate.preference_Talking )
        {
            audience = SHUserPresenceAudienceRecipient;
        }
    }
    
    [appDelegate.messageManager dispatchMessage:thread forAudience:audience];
    [targetCell updateThreadStatus:SHThreadStatusSending];
}

- (void)redownloadMediaFromSender:(NSString *)senderID atIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            NSMutableDictionary *messageData = [_threads objectAtIndex:indexPath.row];
            NSString *threadID = [messageData objectForKey:@"thread_id"];
            NSString *ownerID = [messageData objectForKey:@"owner_id"];
            NSString *mediaHash = [messageData objectForKey:@"media_hash"];
            
            NSURL *mediaURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/userphotos/%@/photos/f_%@.jpg", SH_DOMAIN, ownerID, mediaHash]];
            
            NSURLRequest *request = [NSURLRequest requestWithURL:mediaURL];
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                UIImage *media = [UIImage imageWithData:data];
                
                if ( media )
                {
                    // Save the file locally.
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *documentsPath = [paths objectAtIndex:0]; // Get the docs directory.
                    NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", mediaHash]]; // Add the file name.
                    [data writeToFile:filePath atomically:YES]; // Write the file.
                    
                    [db executeUpdate:@"UPDATE sh_thread "
                                        @"SET media_data = :media_data, media_local_path = :media_local_path "
                                        @"WHERE owner_id = :user_id AND thread_id = :thread_id"
                            withParameterDictionary:@{@"user_id": ownerID,
                                                      @"thread_id": threadID,
                                                      @"media_data": data,
                                                      @"media_local_path": filePath}];
                    
                    if ( senderID.intValue == _recipientID.intValue ) // Make sure we're still in the same conversation.
                    {
                        for ( int i = 0; i < _threads.count; i++ )
                        {
                            NSMutableDictionary *message = [_threads objectAtIndex:i];
                            NSString *targetMediaHash = [message objectForKey:@"media_hash"];
                            
                            if ( [targetMediaHash isEqualToString:mediaHash] )
                            {
                                SHThreadCell *targetCell = (SHThreadCell *)[_conversationTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                                
                                UIImage *scaledImage = [UIImage imageWithData:data];
                                float width = scaledImage.size.width;
                                float height = scaledImage.size.height;
                                float paddingFactor = height / 4;
                                
                                if ( height > width + paddingFactor ) // Portrait image.
                                {
                                    if ( width > 320 ) // No bigger than this size.
                                    {
                                        width = 320;
                                    }
                                }
                                else // Landscape image.
                                {
                                    if ( width > 480 )
                                    {
                                        width = 480;
                                    }
                                }
                                
                                dispatch_async(dispatch_get_main_queue(), ^(void){
                                    [message setObject:data forKey:@"media_data"];
                                    [message setObject:UIImageJPEGRepresentation([appDelegate imageWithImage:scaledImage scaledToWidth:width], 1.0) forKey:@"media_thumbnail"];
                                    [message setObject:filePath forKey:@"media_local_path"];
                                    
                                    [targetCell setMedia:scaledImage withThumbnail:[UIImage imageWithData:[message objectForKey:@"media_thumbnail"]] atPath:filePath];
                                    
                                    [_threads setObject:message atIndexedSubscript:i];
                                });
                                
                                break;
                            }
                        }
                    }
                }
                else
                {
                    if ( senderID.intValue == _recipientID.intValue ) // Make sure we're still in the same conversation.
                    {
                        for ( int i = 0; i < _threads.count; i++ )
                        {
                            NSMutableDictionary *message = [_threads objectAtIndex:i];
                            NSString *targetMediaHash = [message objectForKey:@"media_hash"];
                            
                            if ( [targetMediaHash isEqualToString:mediaHash] )
                            {
                                dispatch_async(dispatch_get_main_queue(), ^(void){
                                    SHThreadCell *targetCell = (SHThreadCell *)[_conversationTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                                    
                                    if ( [response respondsToSelector:@selector(statusCode)] )
                                    {
                                        int statusCode = (int)[((NSHTTPURLResponse *)response) statusCode];
                                        
                                        if ( statusCode == 404 )
                                        {
                                            [message setObject:@"1" forKey:@"media_not_found"];
                                            [_threads setObject:message atIndexedSubscript:i];
                                            [targetCell showMediaNotFound];
                                        }
                                        else
                                        {
                                            [targetCell showMediaRedownloadButton];
                                        }
                                    }
                                    else
                                    {
                                        [targetCell showMediaRedownloadButton];
                                    }
                                });
                                
                                break;
                            }
                        }
                    }
                }
            }];
        }];
    });
}

- (void)receivedMessage:(NSDictionary *)messageData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    @synchronized( _threads )
    {
        NSMutableDictionary *messageData_mutable = [messageData mutableCopy];
        NSString *threadID = [messageData_mutable objectForKey:@"thread_id"];
        NSString *ownerID = [messageData_mutable objectForKey:@"owner_id"];
        NSString *mediaHash = [messageData_mutable objectForKey:@"media_hash"];
        
        if ( mediaHash.length > 1 && mediaHash.intValue != -1 )
        {
            [messageData_mutable setObject:[[NSData alloc] init] forKey:@"media_data"]; // Prepare this for the fresh data. -1 causes crashes when checking image validity.
        }
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            if ( mediaHash.length > 1 && mediaHash.intValue != -1 )
            {
                NSURL *mediaURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/userphotos/%@/photos/f_%@.jpg", SH_DOMAIN, ownerID, mediaHash]];
                
                NSURLRequest *request = [NSURLRequest requestWithURL:mediaURL];
                [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                    UIImage *media = [UIImage imageWithData:data];
                    
                    if ( media )
                    {
                        // Save the file locally.
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *documentsPath = [paths objectAtIndex:0]; // Get the docs directory.
                        NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", mediaHash]]; // Add the file name.
                        [data writeToFile:filePath atomically:YES]; // Write the file.
                        
                        [db executeUpdate:@"UPDATE sh_thread "
                                            @"SET media_data = :media_data, media_local_path = :media_local_path "
                                            @"WHERE owner_id = :user_id AND thread_id = :thread_id"
                                withParameterDictionary:@{@"user_id": ownerID,
                                                          @"thread_id": threadID,
                                                          @"media_data": data,
                                                          @"media_local_path": filePath}];
                        
                        for ( int i = 0; i < _threads.count; i++ )
                        {
                            NSMutableDictionary *message = [_threads objectAtIndex:i];
                            NSString *targetMediaHash = [message objectForKey:@"media_hash"];
                            
                            if ( [targetMediaHash isEqualToString:mediaHash] )
                            {
                                SHThreadCell *targetCell = (SHThreadCell *)[_conversationTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                                
                                UIImage *scaledImage = [UIImage imageWithData:data];
                                float width = scaledImage.size.width;
                                float height = scaledImage.size.height;
                                float paddingFactor = height / 4;
                                
                                if ( height > width + paddingFactor ) // Portrait image.
                                {
                                    if ( width > 320 ) // No bigger than this size.
                                    {
                                        width = 320;
                                    }
                                }
                                else // Landscape image.
                                {
                                    if ( width > 480 )
                                    {
                                        width = 480;
                                    }
                                }
                                
                                dispatch_async(dispatch_get_main_queue(), ^(void){
                                    [message setObject:data forKey:@"media_data"];
                                    [message setObject:UIImageJPEGRepresentation([appDelegate imageWithImage:scaledImage scaledToWidth:width], 1.0) forKey:@"media_thumbnail"];
                                    [message setObject:filePath forKey:@"media_local_path"];
                                    
                                    [targetCell setMedia:scaledImage withThumbnail:[UIImage imageWithData:[message objectForKey:@"media_thumbnail"]] atPath:filePath];
                                    
                                    [_threads setObject:message atIndexedSubscript:i];
                                    [_conversationTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
                                });
                                
                                break;
                            }
                        }
                    }
                    else
                    {
                        for ( int i = 0; i < _threads.count; i++ )
                        {
                            NSMutableDictionary *message = [_threads objectAtIndex:i];
                            NSString *targetMediaHash = [message objectForKey:@"media_hash"];
                            
                            if ( [targetMediaHash isEqualToString:mediaHash] )
                            {
                                dispatch_async(dispatch_get_main_queue(), ^(void){
                                    SHThreadCell *targetCell = (SHThreadCell *)[_conversationTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                                    
                                    if ( [response respondsToSelector:@selector(statusCode)] )
                                    {
                                        int statusCode = (int)[((NSHTTPURLResponse *)response) statusCode];
                                        
                                        if ( statusCode == 404 )
                                        {
                                            [message setObject:@"1" forKey:@"media_not_found"];
                                            [_threads setObject:message atIndexedSubscript:i];
                                            [targetCell showMediaNotFound];
                                        }
                                        else
                                        {
                                            [targetCell showMediaRedownloadButton];
                                        }
                                    }
                                    else
                                    {
                                        [targetCell showMediaRedownloadButton];
                                    }
                                });
                                
                                break;
                            }
                        }
                    }
                }];
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            NSMutableDictionary *previousEntry = [_threads lastObject];
            int previousEntryType = [[previousEntry objectForKey:@"entry_type"] intValue];
            BOOL shouldScrollToBottom = YES;
            
            if ( previousEntryType == 1 )
            {
                NSString *timestamp_sent = [messageData_mutable objectForKey:@"timestamp_sent"];
                NSDate *firstDate = [dateFormatter dateFromString:[previousEntry objectForKey:@"timestamp_sent"]];
                NSDate *secondDate = [dateFormatter dateFromString:timestamp_sent];
                
                NSDateComponents *componentsForFirstDate = [appDelegate.calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:firstDate];
                NSDateComponents *componentsForSecondDate = [appDelegate.calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:secondDate];
                
                if ( componentsForFirstDate.year == componentsForSecondDate.year &&
                    componentsForFirstDate.month == componentsForSecondDate.month &&
                    componentsForFirstDate.day == componentsForSecondDate.day )
                {
                    // On the same day. Nothing to do.
                    
                }
                else
                {
                    NSMutableDictionary *dateMarker = [[NSMutableDictionary alloc] initWithObjects:@[@"2",
                                                                                                     timestamp_sent]
                                                                                           forKeys:@[@"entry_type",
                                                                                                     @"date"]];
                    [_threads addObject:dateMarker];
                }
            }
            
            if ( _conversationTable.contentSize.height > _conversationTable.frame.size.height &&
                _conversationTable.contentOffset.y < _conversationTable.contentSize.height - _conversationTable.frame.size.height - 200 )
            {
                shouldScrollToBottom = NO;
            }
            
            [_threads addObject:messageData_mutable];
            [_conversationTable reloadData];
            
            if ( shouldScrollToBottom )
            {
                [self scrollViewToBottomForced:YES animated:YES];
            }
        });
    }
}

- (void)receivedMessageBatch:(NSMutableArray *)messages
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    @synchronized( _threads )
    {
        for ( int i = 0; i < messages.count; i++ )
        {
            NSMutableDictionary *messageData_mutable = [[messages objectAtIndex:i] mutableCopy];
            NSString *threadID = [messageData_mutable objectForKey:@"thread_id"];
            NSString *ownerID = [messageData_mutable objectForKey:@"owner_id"];
            NSString *mediaHash = [messageData_mutable objectForKey:@"media_hash"];
            
            if ( mediaHash.length > 1 && [mediaHash intValue] != -1 )
            {
                [messageData_mutable setObject:[[NSData alloc] init] forKey:@"media_data"]; // Prepare this for the fresh data. -1 causes crashes when checking image validity.
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if ( i == 0 ) // Check if we entered a new day (first message only).
                {
                    NSMutableDictionary *previousEntry = [_threads lastObject];
                    int previousEntryType = [[previousEntry objectForKey:@"entry_type"] intValue];
                    
                    if ( previousEntryType == 1 )
                    {
                        NSString *timestamp_sent = [messageData_mutable objectForKey:@"timestamp_sent"];
                        NSDate *firstDate = [dateFormatter dateFromString:[previousEntry objectForKey:@"timestamp_sent"]];
                        NSDate *secondDate = [dateFormatter dateFromString:timestamp_sent];
                        
                        NSDateComponents *componentsForFirstDate = [appDelegate.calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:firstDate];
                        NSDateComponents *componentsForSecondDate = [appDelegate.calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:secondDate];
                        
                        if ( componentsForFirstDate.year == componentsForSecondDate.year &&
                            componentsForFirstDate.month == componentsForSecondDate.month &&
                            componentsForFirstDate.day == componentsForSecondDate.day )
                        {
                            // On the same day. Nothing to do.
                            
                        }
                        else
                        {
                            NSMutableDictionary *dateMarker = [[NSMutableDictionary alloc] initWithObjects:@[@"2",
                                                                                                             timestamp_sent]
                                                                                                   forKeys:@[@"entry_type",
                                                                                                             @"date"]];
                            [_threads addObject:dateMarker];
                        }
                    }
                }
                
                [_threads addObject:messageData_mutable];
                [_conversationTable reloadData];
                [self scrollViewToBottomForced:YES animated:YES];
            });
            
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
            [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                if ( mediaHash.length > 1 && [mediaHash intValue] != -1 )
                {
                    NSURL *mediaURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/userphotos/%@/photos/f_%@.jpg", SH_DOMAIN, ownerID, mediaHash]];
                    
                    NSURLRequest *request = [NSURLRequest requestWithURL:mediaURL];
                    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                        UIImage *media = [UIImage imageWithData:data];
                        
                        if ( media )
                        {
                            // Save the file locally.
                            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                            NSString *documentsPath = [paths objectAtIndex:0]; // Get the docs directory.
                            NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", mediaHash]]; // Add the file name.
                            [data writeToFile:filePath atomically:YES]; // Write the file.
                            
                            [db executeUpdate:@"UPDATE sh_thread "
                                                @"SET media_data = :media_data, media_local_path = :media_local_path "
                                                @"WHERE owner_id = :user_id AND thread_id = :thread_id"
                                    withParameterDictionary:@{@"user_id": ownerID,
                                                              @"thread_id": threadID,
                                                              @"media_data": data,
                                                              @"media_local_path": filePath}];
                            
                            for ( int i = 0; i < _threads.count; i++ )
                            {
                                NSMutableDictionary *message = [_threads objectAtIndex:i];
                                NSString *targetMediaHash = [message objectForKey:@"media_hash"];
                                
                                if ( [targetMediaHash isEqualToString:mediaHash] )
                                {
                                    SHThreadCell *targetCell = (SHThreadCell *)[_conversationTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                                    
                                    UIImage *scaledImage = [UIImage imageWithData:data];
                                    float width = scaledImage.size.width;
                                    float height = scaledImage.size.height;
                                    float paddingFactor = height / 4;
                                    
                                    if ( height > width + paddingFactor ) // Portrait image.
                                    {
                                        if ( width > 320 ) // No bigger than this size.
                                        {
                                            width = 320;
                                        }
                                    }
                                    else // Landscape image.
                                    {
                                        if ( width > 480 )
                                        {
                                            width = 480;
                                        }
                                    }
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^(void){
                                        [message setObject:data forKey:@"media_data"];
                                        [message setObject:UIImageJPEGRepresentation([appDelegate imageWithImage:scaledImage scaledToWidth:width], 1.0) forKey:@"media_thumbnail"];
                                        [message setObject:filePath forKey:@"media_local_path"];
                                        
                                        [targetCell setMedia:scaledImage withThumbnail:[UIImage imageWithData:[message objectForKey:@"media_thumbnail"]] atPath:filePath];
                                        
                                        [_threads setObject:message atIndexedSubscript:i];
                                        [_conversationTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
                                    });
                                    
                                    break;
                                }
                            }
                        }
                        else
                        {
                            for ( int i = 0; i < _threads.count; i++ )
                            {
                                NSMutableDictionary *message = [_threads objectAtIndex:i];
                                NSString *targetMediaHash = [message objectForKey:@"media_hash"];
                                
                                if ( [targetMediaHash isEqualToString:mediaHash] )
                                {
                                    dispatch_async(dispatch_get_main_queue(), ^(void){
                                        SHThreadCell *targetCell = (SHThreadCell *)[_conversationTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                                        
                                        if ( [response respondsToSelector:@selector(statusCode)] )
                                        {
                                            int statusCode = (int)[((NSHTTPURLResponse *)response) statusCode];
                                            
                                            if ( statusCode == 404 )
                                            {
                                                [message setObject:@"1" forKey:@"media_not_found"];
                                                [_threads setObject:message atIndexedSubscript:i];
                                                [targetCell showMediaNotFound];
                                            }
                                            else
                                            {
                                                [targetCell showMediaRedownloadButton];
                                            }
                                        }
                                        else
                                        {
                                            [targetCell showMediaRedownloadButton];
                                        }
                                    });
                                    
                                    break;
                                }
                            }
                        }
                    }];
                }
            }];
        }
    }
}

- (void)receivedStatusUpdate:(NSDictionary *)statusData fresh:(BOOL)fresh
{
    if ( fresh )
    {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [_threads addObject:statusData];
            [_conversationTable reloadData];
            [self scrollViewToBottomForced:YES animated:YES];
            
            if ( [_recipientID intValue] == [[statusData objectForKey:@"owner_id"] intValue] )
            {
                [self setRecipientStatus:[statusData objectForKey:@"message"]];
            }
        });
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDate *firstRowTimestamp;
            
            // Since here we're just comparing the age of 2 timestamps, there's no need to convert them from GMT.
            if ( [[[_threads firstObject] objectForKey:@"entry_type"] intValue] == 1 ) // Make sure it's not a date marker entry.
            {
                firstRowTimestamp = [dateFormatter dateFromString:[[_threads firstObject] objectForKey:@"timestamp_sent"]];
            }
            else
            {
                firstRowTimestamp = [dateFormatter dateFromString:[[_threads objectAtIndex:1] objectForKey:@"timestamp_sent"]];
            }
            
            NSDate *targetTimestamp = [dateFormatter dateFromString:[statusData objectForKey:@"timestamp_sent"]];
            NSDate *dateToday = [NSDate date];
            
            for ( int i = 0 ; i < _threads.count; i++ )
            {
                NSDictionary *thread = [_threads objectAtIndex:i];
                int threadID = [[thread objectForKey:@"thread_id"] intValue];
                
                // If the status already in conversation or the current target's older than the first row.
                if ( threadID == [[statusData objectForKey:@"thread_id"] intValue] || [dateToday timeIntervalSinceDate:targetTimestamp] > [dateToday timeIntervalSinceDate:firstRowTimestamp] )
                {
                    return;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [_threads addObject:statusData];
                [_conversationTable reloadData];
                [self scrollViewToBottomForced:YES animated:YES];
                
                if ( [_recipientID intValue] == [[statusData objectForKey:@"owner_id"] intValue] )
                {
                    [self setRecipientStatus:[statusData objectForKey:@"message"]];
                }
                
                if ( [_recipientID intValue] == [[statusData objectForKey:@"owner_id"] intValue] )
                {
                    [self setRecipientStatus:[statusData objectForKey:@"message"]];
                }
            });
        });
    }
}

- (void)didFetchMessageStateForCurrentRecipient:(NSMutableArray *)messages
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( int i = 0 ; i < messages.count; i++ )
        {
            NSMutableDictionary *thread = [messages objectAtIndex:i];
            int64_t threadID = [[thread objectForKey:@"thread_id"] intValue];
            int64_t ownerID = [[thread objectForKey:@"owner_id"] intValue];
            NSString *message = [thread objectForKey:@"message"];
            NSString *timestampSent = [thread objectForKey:@"timestamp_sent"];
            
            for ( int j = 0 ; j < _threads.count; j++ )
            {
                NSMutableDictionary *target = [_threads objectAtIndex:j];
                int64_t targetThreadID = [[target objectForKey:@"thread_id"] intValue];
                int64_t targetOwnerID = [[target objectForKey:@"owner_id"] intValue];
                NSString *targetMessage = [target objectForKey:@"message"];
                NSString *targetTimestampSent = [target objectForKey:@"timestamp_sent"];
                
                if ( threadID == targetThreadID ||
                    (ownerID == targetOwnerID && [message isEqualToString:targetMessage] && [timestampSent isEqualToString:targetTimestampSent]) )
                {
                    [target setObject:[thread objectForKey:@"thread_id"] forKey:@"thread_id"];
                    [target setObject:[thread objectForKey:@"status_sent"] forKey:@"status_sent"];
                    [target setObject:[thread objectForKey:@"status_delivered"] forKey:@"status_delivered"];
                    [target setObject:[thread objectForKey:@"status_read"] forKey:@"status_read"];
                    [target setObject:[thread objectForKey:@"timestamp_sent"] forKey:@"timestamp_sent"];
                    [target setObject:[thread objectForKey:@"timestamp_delivered"] forKey:@"timestamp_delivered"];
                    [target setObject:[thread objectForKey:@"timestamp_read"] forKey:@"timestamp_read"];
                    
                    [_threads setObject:target atIndexedSubscript:j];
                    
                    break;
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if ( tableIsScrolling )
            {
                shouldReloadTable = YES;
            }
            else
            {
                [_conversationTable reloadData];
            }
        });
    });
}

- (void)didFetchPresenceForCurrentRecipient:(NSDictionary *)presenceData
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self setRecipientPresence:presenceData withDB:nil];
    });
}

- (void)markMessagesAsRead
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    int currentUserID = [[appDelegate.currentUser objectForKey:@"user_id"] intValue];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_thread "
                                            @"INNER JOIN sh_message_dispatch "
                                            @"ON sh_thread.thread_id = sh_message_dispatch.thread_id AND sh_thread.hidden = 0 AND sh_thread.temp = 0 AND sh_thread.status_read = 0 AND sh_message_dispatch.sender_id = :recipient_id AND sh_message_dispatch.recipient_id = :current_user_id "
                                            @"ORDER BY sh_thread.timestamp_sent ASC"
                   withParameterDictionary:@{@"recipient_id": _recipientID,
                                             @"current_user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
        
        NSMutableArray *threadIDs = [NSMutableArray array];
        
        while ( [s1 next])
        {
            NSString *threadID = [s1 stringForColumn:@"thread_id"];
            int threadOwnerID = [[s1 stringForColumn:@"owner_id"] intValue];
            
            if ( threadOwnerID != currentUserID ) // You can only mark the other person's messages as read, not your own! Also, non-ad-hocs.
            {
                [threadIDs addObject:threadID];
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [appDelegate.messageManager acknowledgeReadForMessage:threadID toOwnerID:_recipientID];
                });
            }
        }
        
        [s1 close];
        
        if ( threadIDs.count > 0 )
        {
            [db executeUpdate:@"UPDATE sh_cloud "
                                @"SET unread_thread_count = 0 "
                                @"WHERE sh_user_id = :user_id"
                    withParameterDictionary:@{@"user_id": _recipientID}];
            
            [db executeUpdate:@"UPDATE sh_current_user "
                                @"SET unread_thread_count = unread_thread_count - 1 "
                    withParameterDictionary:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                int currentBadgeCount = (int)[[UIApplication sharedApplication] applicationIconBadgeNumber];
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:currentBadgeCount - 1];
                
                [appDelegate.currentUser setObject:[NSNumber numberWithInt:currentBadgeCount - 1] forKey:@"unread_thread_count"];
            });
        }
    }];
}

// These methods are not delegate methods. They're manually called by the Home Menu.
- (void)message:(NSDictionary *)messageData statusDidChange:(SHThreadStatus)status
{
    for ( int i = 0; i < _threads.count; i++ ) // We need to update the message's data in the conversation.
    {
        NSMutableDictionary *message = [_threads objectAtIndex:i];
        
        if ( status == SHThreadStatusSent )
        {
            int ownerID = [[messageData objectForKey:@"owner_id"] intValue];
            int targetOwnerID = [[message objectForKey:@"owner_id"] intValue];
            int threadID = [[messageData objectForKey:@"generated_id"] intValue];
            int generatedThreadID = [[message objectForKey:@"thread_id"] intValue];
            
            if ( ownerID == targetOwnerID && threadID == generatedThreadID )
            {
                [message setObject:[messageData objectForKey:@"thread_id"] forKey:@"thread_id"]; // Update with the new ID.
                [message setObject:[NSNumber numberWithInt:SHThreadStatusSent] forKey:@"status_sent"];
                [_threads setObject:message atIndexedSubscript:i];
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    SHThreadCell *targetCell = (SHThreadCell *)[_conversationTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                    
                    [targetCell updateThreadStatus:status];
                });
                
                break;
            }
        }
        else
        {
            int threadID = [[messageData objectForKey:@"thread_id"] intValue];
            int targetThreadID = [[message objectForKey:@"thread_id"] intValue];
            
            if ( threadID == targetThreadID )
            {
                switch ( status )
                {
                    case SHThreadStatusDelivered:
                        [message setObject:@"1" forKey:@"status_delivered"];
                        [message setObject:[messageData objectForKey:@"timestamp_delivered"] forKey:@"timestamp_delivered"];
                        
                        break;
                        
                    case SHThreadStatusRead:
                        [message setObject:@"1" forKey:@"status_read"];
                        [message setObject:[messageData objectForKey:@"timestamp_read"] forKey:@"timestamp_read"];
                        
                        break;
                        
                    case SHThreadStatusSending:
                        [message setObject:[NSNumber numberWithInt:SHThreadStatusSending] forKey:@"status_sent"];
                        
                        break;
                        
                    case SHThreadStatusSendingFailed:
                        [message setObject:[NSNumber numberWithInt:SHThreadStatusSendingFailed] forKey:@"status_sent"];
                        
                        break;
                        
                    default:
                        break;
                }
                
                [_threads setObject:message atIndexedSubscript:i];
                
                // Message status is also hidden when presence is hidden.
                if ( didGainPrivacyMerit )
                {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        SHThreadCell *targetCell = (SHThreadCell *)[_conversationTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                        
                        [targetCell updateThreadStatus:status];
                    });
                }
                
                break;
            }
        }
    }
}

- (void)beginMediaUploadWithMedia:(id)media
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight activateStrobeLight];
    
    [uploadActivityIndicator startAnimating];
    
    [sendButton setImage:nil forState:UIControlStateNormal];
    sendButton.enabled = NO;
    uploadActivityIndicator.hidden = NO;
    
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        uploadActivityIndicator.alpha = 1.0;
    } completion:^(BOOL finished){
        
    }];
    
    SHMediaType mediaType = SHMediaTypeNone;
    NSData *mediaData;
    NSString *recipient = _recipientID; // Make a copy of this ID in case the user switches to a different conversation.
    
    if ( [media isKindOfClass:[UIImage class]] )
    {
        mediaType = SHMediaTypePhoto;
        UIImage *image = (UIImage *)media;
        
        if ( !appDelegate.preference_HQUploads ) // Scale the image down.
        {
            float width = image.size.width;
            float height = image.size.height;
            float paddingFactor = height / 4;
            
            if ( height > width + paddingFactor ) // Portrait image.
            {
                if ( width > 320 ) // No bigger than this size.
                {
                    width = 320;
                }
            }
            else // Landscape image.
            {
                if ( width > 568 )
                {
                    width = 568;
                }
            }
            
            media = [appDelegate imageWithImage:media scaledToWidth:width];
        }
        
        mediaData = UIImageJPEGRepresentation(media, 0.6);
        
        [self updateMessagingInterfaceWithImage:image];
    }
    else
    {
        mediaType = SHMediaTypeMovie;
    }
    
    [activeMediaUploadRecipients addObject:@{@"user_id": recipient,
                                             @"media_type": [NSNumber numberWithInt:mediaType],
                                             @"media": mediaData}];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[[NSNumber numberWithInt:mediaType]]
                                                                          forKeys:@[@"media_type"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/mediaupload", SH_DOMAIN] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        if ( mediaType == SHMediaTypePhoto )
        {
            [formData appendPartWithFileData:mediaData name:@"mediaFile" fileName:@"mediaFile.jpg" mimeType:@"image/jpeg"];
        }
        else if ( mediaType == SHMediaTypeMovie )
        {
            //[formData setData:media withFileName:@"mediaFile" andContentType:@"image/jpeg" forKey:@"mediaFile"];
        }
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                [self didUploadMediaForRecipient:recipient withHash:[responseData objectForKey:@"response"]];
            }
        }
        else
        {
            [self resetMessagingInterface];
            [self showNetworkError];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self resetMessagingInterface];
        
        if ( error.code != 4 )
        {
            [self showNetworkError];
        }
        else
        {
            [appDelegate.strobeLight deactivateStrobeLight];
        }
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)cancelMediaUpload
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight activateStrobeLight];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager.operationQueue cancelAllOperations];
    
    __block NSString *hash = @"";
    __block int activeIndex = -1;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( int i = 0; i < processedMediaUploads.count; i++ )
        {
            NSDictionary *activeUpload = [processedMediaUploads objectAtIndex:i];
            int activeUploadID = [[activeUpload objectForKey:@"user_id"] intValue];
            
            if ( activeUploadID == _recipientID.intValue )
            {
                hash = [activeUpload objectForKey:@"hash"];
                activeIndex = i;
                
                break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if ( activeIndex != -1 )
            {
                NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[hash]
                                                                                      forKeys:@[@"media_hash"]];
                
                NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
                
                NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                             @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                             @"request": jsonString};
                
                [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/mediadelete", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                            [self resetMessagingInterface];
                            
                            [appDelegate.strobeLight deactivateStrobeLight];
                            [appDelegate.presenceManager setPresence:SHUserPresenceActivityStopped withTargetID:_recipientID forAudience:SHUserPresenceAudienceEveryone];
                            [processedMediaUploads removeObjectAtIndex:activeIndex];
                        }
                    }
                    else
                    {
                        sendButton.enabled = YES;
                        [sendButton setImage:[UIImage imageNamed:@"send"] forState:UIControlStateNormal];
                        
                        [self showNetworkError];
                    }
                    
                    NSLog(@"Response: %@", responseData);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    sendButton.enabled = YES;
                    [sendButton setImage:[UIImage imageNamed:@"send"] forState:UIControlStateNormal];
                    
                    [self showNetworkError];
                    
                    NSLog(@"Error: %@", operation.responseString);
                }];
            }
            else
            {
                [self resetMessagingInterface];
                [appDelegate.strobeLight deactivateStrobeLight];
            }
        });
    });
}

- (void)didUploadMediaForRecipient:(NSString *)recipient withHash:(NSString *)hash
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight deactivateStrobeLight];
    
    if ( _recipientID.intValue == recipient.intValue ) // Make sure the user hasn't switched to another conversation.
    {
        [sendButton setImage:[UIImage imageNamed:@"send"] forState:UIControlStateNormal];
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            uploadActivityIndicator.alpha = 0.0;
        } completion:^(BOOL finished){
            sendButton.enabled = YES;
            uploadActivityIndicator.hidden = YES;
            
            [uploadActivityIndicator stopAnimating];
        }];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( int i = 0; i < activeMediaUploadRecipients.count; i++ )
        {
            NSDictionary *activeUpload = [activeMediaUploadRecipients objectAtIndex:i];
            int activeUploadID = [[activeUpload objectForKey:@"user_id"] intValue];
            
            if ( activeUploadID == recipient.intValue )
            {
                NSMutableDictionary *activeUpload_mutable = [activeUpload mutableCopy];
                [activeUpload_mutable setObject:hash forKey:@"hash"];
                
                // Swap this person into the ready queue.
                [processedMediaUploads addObject:activeUpload_mutable];
                [activeMediaUploadRecipients removeObjectAtIndex:i];
                
                break;
            }
        }
    });
    
    [self sendTextMessage];
}

#pragma mark -
#pragma mark Presence

- (void)currentUserPresenceDidChange
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [self setRecipientPresence:nil withDB:nil]; // Reset to appear offline.
    
    if ( appDelegate.networkManager.networkState == SHNetworkStateConnected )
    {
        attachButton.enabled = YES;
        privacyToggle.enabled = YES;
    }
    else
    {
        privacyToggle.enabled = NO;
        
        if ( !_attachmentsPanelIsShown )
        {
            attachButton.enabled = NO;
        }
    }
    
    [self updateNetworkConnectionStatusLabel];
}

- (void)presenceDidChange:(SHUserPresence)presence time:(NSString *)timestamp forRecipientWithTargetID:(NSString *)presenceTargetID forAudience:(SHUserPresenceAudience)audience withDB:(FMDatabase *)db
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDictionary *presenceData = [NSDictionary dictionaryWithObjectsAndKeys:_recipientID, @"user_id",
                                  [NSNumber numberWithInt:presence], @"status",
                                  presenceTargetID, @"target_id",
                                  [NSNumber numberWithInt:audience], @"audience",
                                  timestamp, @"timestamp", nil];
    
    if ( db )
    {
        [db executeUpdate:@"UPDATE sh_user_online_status "
                            @"SET status = :status, target_id = :target_id, audience = :audience, timestamp = :timestamp "
                            @"WHERE user_id = :user_id"
                withParameterDictionary:presenceData];
    }
    else
    {
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [db executeUpdate:@"UPDATE sh_user_online_status "
                                @"SET status = :status, target_id = :target_id, audience = :audience, timestamp = :timestamp "
                                @"WHERE user_id = :user_id"
                    withParameterDictionary:presenceData];
        }];
    }
    
    [self setRecipientPresence:presenceData withDB:db];
}

#pragma mark -
#pragma mark UI

- (void)titleButtonHighlighted
{
    headerNameLabel.textColor = [UIColor grayColor];
    headerStatusLabel.textColor = [UIColor grayColor];
}

- (void)resetHeaderLabels
{
    if ( _inPrivateMode )
    {
        headerNameLabel.textColor = [UIColor whiteColor];
        headerStatusLabel.textColor = [UIColor whiteColor];
    }
    else
    {
        headerNameLabel.textColor = [UIColor blackColor];
        headerStatusLabel.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
    }
}

- (void)updateNetworkConnectionStatusLabel
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( appDelegate.networkManager.networkState == SHNetworkStateConnected )
    {
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            if ( !(IS_IOS7) )
            {
                connectionStatusLabel.frame = CGRectMake(0, -25 + ([UIApplication sharedApplication].statusBarFrame.size.height - 20), appDelegate.screenBounds.size.width, 25);
            }
            else
            {
                connectionStatusLabel.frame = CGRectMake(0, 19 + ([UIApplication sharedApplication].statusBarFrame.size.height - 20), appDelegate.screenBounds.size.width, 25);
            }
        } completion:^(BOOL finished){
            // Check once again at the end of the animation because the app might've disconnected.
            if ( appDelegate.networkManager.networkState != SHNetworkStateConnected )
            {
                connectionStatusLabel.hidden = NO;
                connectionStatusLabel.text = NSLocalizedString(@"NETWORK_CONNECTION_STATUS_CONNECTING", nil);
                
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    if ( !(IS_IOS7) )
                    {
                        connectionStatusLabel.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height - 20, appDelegate.screenBounds.size.width, 25);
                    }
                    else
                    {
                        connectionStatusLabel.frame = CGRectMake(0, 64 + ([UIApplication sharedApplication].statusBarFrame.size.height - 20), appDelegate.screenBounds.size.width, 25);
                    }
                } completion:^(BOOL finished){
                    int statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
                    
                    if ( [UIApplication sharedApplication].statusBarFrame.size.height < 20 )
                    {
                        statusBarHeight = 20;
                    }
                    
                    if ( !(IS_IOS7) )
                    {
                        connectionStatusLabel.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height - 20, appDelegate.screenBounds.size.width, 25);
                    }
                    else
                    {
                        connectionStatusLabel.frame = CGRectMake(0, 64 + (statusBarHeight - 20), appDelegate.screenBounds.size.width, 25);
                    }
                }];
            }
            else
            {
                connectionStatusLabel.hidden = YES;
            }
        }];
    }
    else
    {
        connectionStatusLabel.hidden = NO;
        connectionStatusLabel.text = NSLocalizedString(@"NETWORK_CONNECTION_STATUS_CONNECTING", nil);
        
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            if ( !(IS_IOS7) )
            {
                connectionStatusLabel.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height - 20, appDelegate.screenBounds.size.width, 25);
            }
            else
            {
                connectionStatusLabel.frame = CGRectMake(0, 64 + ([UIApplication sharedApplication].statusBarFrame.size.height - 20), appDelegate.screenBounds.size.width, 25);
            }
        } completion:^(BOOL finished){
            // Check once again at the end of the animation because the app might've connected.
            if ( appDelegate.networkManager.networkState == SHNetworkStateConnected )
            {
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    if ( !(IS_IOS7) )
                    {
                        connectionStatusLabel.frame = CGRectMake(0, -25 + ([UIApplication sharedApplication].statusBarFrame.size.height - 20), appDelegate.screenBounds.size.width, 25);
                    }
                    else
                    {
                        connectionStatusLabel.frame = CGRectMake(0, 19 + ([UIApplication sharedApplication].statusBarFrame.size.height - 20), appDelegate.screenBounds.size.width, 25);
                    }
                } completion:^(BOOL finished){
                    connectionStatusLabel.hidden = YES;
                }];
            }
        }];
    }
}

// Called when the UIKeyboardWillShowNotification is sent.
- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    keyboardAnimationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger animationCurve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    switch ( animationCurve )
    {
        case UIViewAnimationCurveEaseInOut:
        {
            keyboardAnimationCurve = UIViewAnimationOptionCurveEaseInOut;
            break;
        }
            
        case UIViewAnimationCurveEaseIn:
        {
            keyboardAnimationCurve = UIViewAnimationOptionCurveEaseIn;
            break;
        }
            
        case UIViewAnimationCurveEaseOut:
        {
            keyboardAnimationCurve = UIViewAnimationOptionCurveEaseOut;
            break;
        }
            
        case UIViewAnimationCurveLinear:
        {
            keyboardAnimationCurve = UIViewAnimationOptionCurveLinear;
            break;
        }
            
        default:
        {
            keyboardAnimationCurve = 7 << 16; // For iOS 7.
        }
    }
    
    [self slideUIUp];
    
    _keyboardIsShown = YES;
}

// Called when the UIKeyboardWillHideNotification is sent.
- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    keyboardAnimationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger animationCurve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    switch ( animationCurve )
    {
        case UIViewAnimationCurveEaseInOut:
        {
            keyboardAnimationCurve = UIViewAnimationOptionCurveEaseInOut;
            break;
        }
            
        case UIViewAnimationCurveEaseIn:
        {
            keyboardAnimationCurve = UIViewAnimationOptionCurveEaseIn;
            break;
        }
            
        case UIViewAnimationCurveEaseOut:
        {
            keyboardAnimationCurve = UIViewAnimationOptionCurveEaseOut;
            break;
        }
            
        case UIViewAnimationCurveLinear:
        {
            keyboardAnimationCurve = UIViewAnimationOptionCurveLinear;
            break;
        }
            
        default:
        {
            keyboardAnimationCurve = 7 << 16; // For iOS 7.
        }
    }
    
    [self slideUIDown];
    
    _keyboardIsShown = NO;
}

- (void)slideUIUp
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( !_attachmentsPanelIsShown ) // If the panel is already shown don't slide back up!
    {
        CGSize messageBoxPlaceholderTextSize = [NSLocalizedString(@"MESSAGES_MESSAGE_BOX_PLACEHOLDER", nil) sizeWithFont:[UIFont systemFontOfSize:16] constrainedToSize:CGSizeMake(211, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
        
        if ( _messageBox.text.length > 0 )
        {
            messageBoxPlaceholderTextSize = [_messageBox.text sizeWithFont:[UIFont systemFontOfSize:16] constrainedToSize:CGSizeMake(211, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
        }
        
        sendButton.hidden = NO;
        
        [UIView animateWithDuration:keyboardAnimationDuration delay:0 options:keyboardAnimationCurve animations:^{
            if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
            {
                attachmentsPanel.frame = CGRectMake(0, appDelegate.screenBounds.size.height - 64 - keyboardSize.height, attachmentsPanel.frame.size.width, keyboardSize.height);
                
                attachmentsScrollView.frame = CGRectMake(0, 0, attachmentsPanel.frame.size.width, attachmentsPanel.frame.size.height);
                attachmentsScrollView.contentSize = CGSizeMake(attachmentsPanel.frame.size.width + 2, attachmentsPanel.frame.size.height);
            }
            else
            {
                attachmentsPanel_toolbar.frame = CGRectMake(0, appDelegate.screenBounds.size.height - 64 - keyboardSize.height, attachmentsPanel_toolbar.frame.size.width, keyboardSize.height);
                
                attachmentsScrollView.frame = CGRectMake(0, 0, attachmentsPanel_toolbar.frame.size.width, attachmentsPanel_toolbar.frame.size.height);
                attachmentsScrollView.contentSize = CGSizeMake(attachmentsPanel_toolbar.frame.size.width + 2, attachmentsPanel_toolbar.frame.size.height);
            }
            
            _conversationTable.contentInset = UIEdgeInsetsMake(_conversationTable.contentInset.top, _conversationTable.contentInset.left, keyboardSize.height, _conversationTable.contentInset.right);
            _conversationTable.scrollIndicatorInsets = UIEdgeInsetsMake(_conversationTable.scrollIndicatorInsets.top, _conversationTable.scrollIndicatorInsets.left, keyboardSize.height, _conversationTable.scrollIndicatorInsets.right);
            
            sendButton.alpha = 1.0;
            messageBoxBubble.frame = CGRectMake(appDelegate.screenBounds.size.width - messageBoxPlaceholderTextSize.width - 100, messageBoxBubble.frame.origin.y, messageBoxBubble.frame.size.width, messageBoxBubble.frame.size.height);
            
            // Don't use the scrollViewToBottom method here. This content offsetting uses animated:NO.
            if ( _conversationTable.contentSize.height > _conversationTable.frame.size.height - _conversationTable.contentInset.bottom )
            {
                float difference = _conversationTable.contentSize.height - (_conversationTable.frame.size.height - _conversationTable.contentInset.bottom);
                
                [_conversationTable setContentOffset:CGPointMake(0, difference) animated:NO];
                
                long double delayInSeconds = 0.3;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    if ( shouldReloadTable )
                    {
                        [_conversationTable reloadData];
                        
                        shouldReloadTable = NO;
                    }
                    
                    tableIsScrolling = NO;
                });
            }
        } completion:^(BOOL finished){
            
        }];
    }
    
    if ( _attachmentsPanelIsShown )
    {
        [UIView animateWithDuration:0.13 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            if ( !(IS_IOS7) )
            {
                attachmentsPanel.alpha = 0.0; // Hide the attachments panel.
            }
            else
            {
                attachmentsPanel_toolbar.alpha = 0.0;
            }
        } completion:^(BOOL finished){
            if ( !(IS_IOS7) )
            {
                attachmentsPanel.hidden = YES;
            }
            else
            {
                attachmentsPanel_toolbar.hidden = YES;
            }
            
            _attachmentsPanelIsShown = NO;
        }];
        
        [UIView animateWithDuration:0.08 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            attachButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-15));
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.09 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                attachButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(5));
            } completion:^(BOOL finished){
                [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    attachButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(0));
                } completion:^(BOOL finished){
                    
                }];
            }];
        }];
    }
}

- (void)slideUIDown
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( UIShouldSlideDown )
    {
        CGSize messageBoxPlaceholderTextSize = [NSLocalizedString(@"MESSAGES_MESSAGE_BOX_PLACEHOLDER", nil) sizeWithFont:[UIFont systemFontOfSize:16] constrainedToSize:CGSizeMake(211, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
        
        if ( _messageBox.text.length > 0 )
        {
            messageBoxPlaceholderTextSize = [_messageBox.text sizeWithFont:[UIFont systemFontOfSize:16] constrainedToSize:CGSizeMake(211, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
        }
        
        [UIView animateWithDuration:keyboardAnimationDuration delay:0 options:keyboardAnimationCurve animations:^{
            if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
            {
                attachmentsPanel.frame = CGRectMake(0, appDelegate.screenBounds.size.height - 64, attachmentsPanel.frame.size.width, attachmentsPanel.frame.size.height);
                attachmentsPanel.alpha = 0.0; // 2nd safeguard to make the sure the panel gets hidden.
            }
            else
            {
                attachmentsPanel_toolbar.frame = CGRectMake(0, appDelegate.screenBounds.size.height - 64, attachmentsPanel_toolbar.frame.size.width, attachmentsPanel_toolbar.frame.size.height);
                attachmentsPanel_toolbar.alpha = 0.0;
            }
            
            _conversationTable.contentInset = UIEdgeInsetsMake(_conversationTable.contentInset.top, _conversationTable.contentInset.left, 0, _conversationTable.contentInset.right);
            _conversationTable.scrollIndicatorInsets = UIEdgeInsetsMake(_conversationTable.scrollIndicatorInsets.top, _conversationTable.scrollIndicatorInsets.left, 0, _conversationTable.scrollIndicatorInsets.right);
            
            if ( !isSendingMedia && _messageBox.text.length == 0 )
            {
                sendButton.alpha = 0.0;
                messageBoxBubble.frame = CGRectMake(appDelegate.screenBounds.size.width - messageBoxPlaceholderTextSize.width - 60, messageBoxBubble.frame.origin.y, messageBoxBubble.frame.size.width, messageBoxBubble.frame.size.height);
            }
        } completion:^(BOOL finished){
            attachmentsPanel.hidden = YES;
            _attachmentsPanelIsShown = NO;
            
            if ( !isSendingMedia )
            {
                sendButton.hidden = YES;
            }
            
            if ( shouldReloadTable )
            {
                [_conversationTable reloadData];
                
                shouldReloadTable = NO;
            }
            
            tableIsScrolling = NO;
        }];
        
        [UIView animateWithDuration:0.08 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            attachButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-15));
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.09 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                attachButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(5));
            } completion:^(BOOL finished){
                [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    attachButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(0));
                } completion:^(BOOL finished){
                    
                }];
            }];
        }];
    }
    else if ( shouldShowAttachmentsPanel ) // Show the attachments panel.
    {
        float targetHeight = 0.0;
        
        if ( !(IS_IOS7) )
        {
            targetHeight = attachmentsPanel.frame.size.height;
        }
        else
        {
            targetHeight = attachmentsPanel_toolbar.frame.size.height;
        }
        
        if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ) // If the device has a camera.
        {
            attachButton_camera.frame = CGRectMake(20, 20, 80, 50);
            attachButton_library.frame = CGRectMake(appDelegate.screenBounds.size.width / 2 - 40, 20, 80, 50);
            attachButton_lastPhoto.frame = CGRectMake(appDelegate.screenBounds.size.width - 100, 20, 80, 50);
            attachButton_location.frame = CGRectMake(20, 127, 80, 50);
            //attachButton_contact.frame = CGRectMake(122, 127, 80, 50);
            //attachButton_file.frame = CGRectMake(228, 127, 80, 50);
        }
        else
        {
            attachButton_library.frame = CGRectMake(20, 20, 80, 50);
            attachButton_lastPhoto.frame = CGRectMake(appDelegate.screenBounds.size.width / 2 - 40, 20, 80, 50);
            attachButton_location.frame = CGRectMake(appDelegate.screenBounds.size.width - 100, 20, 80, 50);
            //attachButton_contact.frame = CGRectMake(15, 127, 80, 50);
            //attachButton_file.frame = CGRectMake(122, 127, 80, 50);
        }
        
        CGRect labelFrame = CGRectMake(0, attachButton_camera.frame.size.height + 7, 80, 18);
        
        attachLabel_camera.frame = labelFrame;
        attachLabel_library.frame = labelFrame;
        attachLabel_lastPhoto.frame = labelFrame;
        attachLabel_location.frame = labelFrame;
        attachLabel_contact.frame = labelFrame;
        attachLabel_file.frame = labelFrame;
        
        // Now get a preview of the last photo taken.
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
                    lastPhotoTaken = [UIImage imageWithCGImage:[representation fullScreenImage]];
                    
                    CGImageRef imageRef = CGImageCreateWithImageInRect([lastPhotoTaken CGImage], CGRectMake(lastPhotoTaken.size.width / 2 - 160, lastPhotoTaken.size.height / 2 - 160, 340, 340));
                    lastPhotoTaken = [UIImage imageWithCGImage:imageRef];
                    CGImageRelease(imageRef);
                    
                    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, lastPhotoTaken.size.width, lastPhotoTaken.size.height)];
                    
                    // Create an image context containing the original UIImage.
                    UIGraphicsBeginImageContext(lastPhotoTaken.size);
                    
                    // Clip to the bezier path and clear that portion of the image.
                    CGContextRef context = UIGraphicsGetCurrentContext();
                    
                    CGContextAddPath(context, bezierPath.CGPath);
                    CGContextClip(context);
                    
                    // Draw here when the context is clipped.
                    [lastPhotoTaken drawAtPoint:CGPointZero];
                    
                    // Build a new UIImage from the image context.
                    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    lastPhotoTaken = newImage;
                    lastPhotoTakenPreview.image = lastPhotoTaken;
                }
            }];
        } failureBlock: ^(NSError *error){
            // Typically you should handle an error more gracefully than this.
            NSLog(@"No groups");
        }];
        
        if ( !(IS_IOS7) )
        {
            attachmentsPanel.hidden = NO;
        }
        else
        {
            attachmentsPanel_toolbar.hidden = NO;
        }
        
        [UIView animateWithDuration:0.08 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            attachButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(55));
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.09 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                attachButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(40));
            } completion:^(BOOL finished){
                [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    attachButton.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(45));
                } completion:^(BOOL finished){
                    
                }];
            }];
        }];
        
        [UIView animateWithDuration:keyboardAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            if ( !(IS_IOS7) )
            {
                attachmentsPanel.alpha = 1.0;
            }
            else
            {
                attachmentsPanel_toolbar.alpha = 1.0;
            }
        } completion:^(BOOL finished){
            _attachmentsPanelIsShown = YES;
        }];
    }
}

- (void)updateMessagingInterfaceWithImage:(UIImage *)image
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    isSendingMedia = YES;
    
    [self resetView];
    
    attachButton.transform = CGAffineTransformIdentity;
    [attachButton setTitle:@"" forState:UIControlStateNormal];
    [attachButton setImage:[UIImage imageNamed:@"trash"] forState:UIControlStateNormal];
    _messageBox.hidden = YES;
    
    float maxWidth = 216;
    
    CGImageRef imageRef = image.CGImage;
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    CGFloat scaleRatio = maxWidth / width;
    
    CGRect bounds = CGRectMake(0, 0, width, height);
    
    if ( width > maxWidth )
    {
        bounds.size.width = maxWidth;
        bounds.size.height = height * scaleRatio;
    }
    
    CGSize contentSize = CGSizeMake(bounds.size.width - 50, bounds.size.height - 19);
    
    UIImage *maskImage = [UIImage imageNamed:@"message_mask_right"];
    
    messageBoxBubbleImagePreview.frame = bounds;
    messageBoxBubbleImagePreview.image = image;
    messageBoxBubbleImagePreview.hidden = NO;
    
    CALayer *maskLayer = [CALayer layer];
    maskLayer.contents = (id)maskImage.CGImage;
    maskLayer.frame = messageBoxBubbleImagePreview.layer.frame;
    maskLayer.contentsScale = [UIScreen mainScreen].scale;
    maskLayer.contentsCenter = CGRectMake(11 / maskImage.size.width,
                                          14 / maskImage.size.height,
                                          1.0 / maskImage.size.width,
                                          1.0 / maskImage.size.height);
    
    messageBoxBubbleImagePreview.layer.mask = maskLayer;
    
    int x_bubble = appDelegate.screenBounds.size.width - contentSize.width - 100;
    
    [UIView animateWithDuration:0.15 delay:0 options:keyboardAnimationCurve animations:^{
        recipientStatusBubble.frame = CGRectMake(recipientStatusBubble.frame.origin.x, contentSize.height + 49, recipientStatusBubble.frame.size.width, recipientStatusBubble.frame.size.height);
        messageBoxBubble.frame = CGRectMake(x_bubble, messageBoxBubble.frame.origin.y, contentSize.width + 50, contentSize.height + 19);
        attachButton.frame = CGRectMake(MIN(5, x_bubble - attachButton.frame.size.width), contentSize.height + 37 - sendButton.frame.size.height, attachButton.frame.size.width, attachButton.frame.size.height); // Make sure the button moves away from the expanding message bubble.
        
        sendButton.frame = CGRectMake(sendButton.frame.origin.x, contentSize.height + 37 - sendButton.frame.size.height, sendButton.frame.size.width, sendButton.frame.size.height);
    } completion:^(BOOL finished){
        conversationTableFooter.frame = CGRectMake(0, 0, conversationTableFooter.frame.size.width, messageBoxBubble.frame.size.height + recipientStatusBubble.frame.size.height + 40);
        _conversationTable.tableFooterView = conversationTableFooter;
        
        [self scrollViewToBottomForced:YES animated:YES];
    }];
}

- (void)redrawViewForStatusBar:(CGRect)oldStatusBarFrame
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    connectionStatusLabel.frame = CGRectMake(connectionStatusLabel.frame.origin.x, 44 + [UIApplication sharedApplication].statusBarFrame.size.height, connectionStatusLabel.frame.size.width, connectionStatusLabel.frame.size.height);
    participantsPane.frame = CGRectMake(participantsPane.frame.origin.x, appDelegate.screenBounds.size.height - 104 - ([UIApplication sharedApplication].statusBarFrame.size.height - 20), participantsPane.frame.size.width, participantsPane.frame.size.height);
    
    if ( _keyboardIsShown )
    {
        _conversationTable.contentInset = UIEdgeInsetsMake(_conversationTable.contentInset.top, _conversationTable.contentInset.left, _conversationTable.contentInset.bottom + keyboardSize.height, _conversationTable.contentInset.right);
        _conversationTable.scrollIndicatorInsets = UIEdgeInsetsMake(_conversationTable.scrollIndicatorInsets.top, _conversationTable.scrollIndicatorInsets.left, _conversationTable.contentInset.bottom + keyboardSize.height, _conversationTable.scrollIndicatorInsets.right);
    }
    else
    {
        _conversationTable.contentInset = UIEdgeInsetsMake(_conversationTable.contentInset.top, _conversationTable.contentInset.left, 0, _conversationTable.contentInset.right);
        _conversationTable.scrollIndicatorInsets = UIEdgeInsetsMake(_conversationTable.scrollIndicatorInsets.top, _conversationTable.scrollIndicatorInsets.left, 0, _conversationTable.scrollIndicatorInsets.right);
    }
    
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        if ( appDelegate.networkManager.networkState == SHNetworkStateConnected )
        {
            connectionStatusLabel.frame = CGRectMake(connectionStatusLabel.frame.origin.x, -25 + ([UIApplication sharedApplication].statusBarFrame.size.height - 20), connectionStatusLabel.frame.size.width, connectionStatusLabel.frame.size.height);
        }
        else
        {
            connectionStatusLabel.frame = CGRectMake(_tableContainer.frame.origin.x, ([UIApplication sharedApplication].statusBarFrame.size.height - 20), connectionStatusLabel.frame.size.width, connectionStatusLabel.frame.size.height);
        }
        
        participantsPane.frame = CGRectMake(participantsPane.frame.origin.x, appDelegate.screenBounds.size.height - 114 - ([UIApplication sharedApplication].statusBarFrame.size.height - 20), participantsPane.frame.size.width, 50);
        
        //_tableContainer.frame = CGRectMake(_tableContainer.frame.origin.x, [UIApplication sharedApplication].statusBarFrame.size.height - 20, _tableContainer.frame.size.width, appDelegate.screenBounds.size.height - ([UIApplication sharedApplication].statusBarFrame.size.height - 20));
    }
    else
    {
        if ( appDelegate.networkManager.networkState == SHNetworkStateConnected )
        {
            connectionStatusLabel.frame = CGRectMake(connectionStatusLabel.frame.origin.x, 19 + ([UIApplication sharedApplication].statusBarFrame.size.height - 20), connectionStatusLabel.frame.size.width, connectionStatusLabel.frame.size.height);
        }
    }
}

- (void)resetView
{
    if ( _keyboardIsShown )
    {
        [_messageBox resignFirstResponder];
    }
    else if ( _attachmentsPanelIsShown )
    {
        [self slideUIDown];
    }
}

- (void)resetMessagingInterface
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    isSendingMedia = NO;
    
    sendButton.enabled = YES;
    [sendButton setImage:[UIImage imageNamed:@"send"] forState:UIControlStateNormal];
    [attachButton setTitle:@"+" forState:UIControlStateNormal];
    [attachButton setImage:nil forState:UIControlStateNormal];
    messageBoxBubbleImagePreview.image = nil;
    messageBoxBubbleImagePreview.hidden = YES;
    _messageBox.hidden = NO;
    
    CGSize messageBoxTextSize = [NSLocalizedString(@"MESSAGES_MESSAGE_BOX_PLACEHOLDER", nil) sizeWithFont:[UIFont systemFontOfSize:16] constrainedToSize:CGSizeMake(211, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    
    int x_bubble = appDelegate.screenBounds.size.width - messageBoxTextSize.width - 60;
    
    if ( _keyboardIsShown || _attachmentsPanelIsShown )
    {
        x_bubble = appDelegate.screenBounds.size.width - messageBoxTextSize.width - 100;
    }
    
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        recipientStatusBubble.frame = CGRectMake(recipientStatusBubble.frame.origin.x, _messageBox.frame.size.height + 32, recipientStatusBubble.frame.size.width, recipientStatusBubble.frame.size.height);
        messageBoxBubble.frame = CGRectMake(x_bubble, 10, messageBoxTextSize.width + 48, _messageBox.frame.size.height + 2);
        attachButton.frame = CGRectMake(MIN(5, x_bubble - attachButton.frame.size.width), 3, attachButton.frame.size.width, attachButton.frame.size.height); // Make sure the button moves away from the expanding message bubble.
        sendButton.frame = CGRectMake(sendButton.frame.origin.x, 3, sendButton.frame.size.width, sendButton.frame.size.height);
        uploadActivityIndicator.alpha = 0.0;
    } completion:^(BOOL finished){
        conversationTableFooter.frame = CGRectMake(0, 0, conversationTableFooter.frame.size.width, messageBoxBubble.frame.size.height + recipientStatusBubble.frame.size.height + 40);
        _conversationTable.tableFooterView = conversationTableFooter;
        
        uploadActivityIndicator.hidden = YES;
        [uploadActivityIndicator stopAnimating];
        
        [self scrollViewToBottomForced:YES animated:YES];
    }];
}

- (void)clearViewAnimated:(BOOL)animated
{
    endOfConversation = NO;
    didGainPrivacyMerit = NO;
    shouldLoadMessagesOnScroll = NO;
    batchNumber = 0;
    _recipientID = @"";
    headerNameLabel.text = @"";
    headerStatusLabel.text = @"";
    recipientStatusBubbleLabel.text = @""; // The presence displayed won't be updated if the text here hasn't changed!
    
    [self cancelTimestampUpdates];
    [self setPrivateMode:NO withServerSync:NO];
    
    if ( animated )
    {
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            _conversationTable.alpha = 0.0;
        } completion:^(BOOL finished){
            [_threads removeAllObjects];
            [_conversationTable reloadData];
        }];
    }
    else
    {
        _conversationTable.alpha = 0.0;
        [_threads removeAllObjects];
        [_conversationTable reloadData];
    }
    
    [self resetMessagingInterface];
}

- (void)scrollViewToBottomForced:(BOOL)forced animated:(BOOL)animated
{
    float difference = _conversationTable.contentSize.height - (_conversationTable.frame.size.height - _conversationTable.contentInset.bottom);
    
    // If it's not a forced scroll, then the view only scrolls to the bottom on content size change if it's already at the bottom.
    if ( !forced )
    {
        if ( _conversationTable.contentOffset.y <= difference && _conversationTable.contentOffset.y >= difference - 45 )
        {
            if ( _conversationTable.contentSize.height > _conversationTable.frame.size.height - _conversationTable.contentInset.bottom )
            {
                if ( !(IS_IOS7) )
                {
                    [_conversationTable setContentOffset:CGPointMake(0, difference) animated:animated];
                    
                    long double delayInSeconds = 0.3;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        if ( shouldReloadTable )
                        {
                            [_conversationTable reloadData];
                            
                            shouldReloadTable = NO;
                        }
                        
                        tableIsScrolling = NO;
                    });
                }
                else
                {
                    if ( animated )
                    {
                        [UIView animateWithDuration:0.3 delay:0 options:7 << 16 animations:^{
                            [_conversationTable setContentOffset:CGPointMake(0, difference)];
                        } completion:^(BOOL finished){
                            if ( shouldReloadTable )
                            {
                                [_conversationTable reloadData];
                                
                                shouldReloadTable = NO;
                            }
                            
                            tableIsScrolling = NO;
                        }];
                    }
                    else
                    {
                        [_conversationTable setContentOffset:CGPointMake(0, difference)];
                        tableIsScrolling = NO;
                    }
                }
            }
        }
        
        return;
    }
    
    if ( _conversationTable.contentSize.height > _conversationTable.frame.size.height - _conversationTable.contentInset.bottom )
    {
        if ( !(IS_IOS7) )
        {
            [_conversationTable setContentOffset:CGPointMake(0, difference) animated:animated];
            
            long double delayInSeconds = 0.3;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if ( shouldReloadTable )
                {
                    [_conversationTable reloadData];
                    
                    shouldReloadTable = NO;
                }
                
                tableIsScrolling = NO;
            });
        }
        else
        {
            if ( animated )
            {
                [UIView animateWithDuration:0.3 delay:0 options:7 << 16 animations:^{
                    [_conversationTable setContentOffset:CGPointMake(0, difference)];
                } completion:^(BOOL finished){
                    if ( shouldReloadTable )
                    {
                        [_conversationTable reloadData];
                        
                        shouldReloadTable = NO;
                    }
                    
                    tableIsScrolling = NO;
                }];
            }
            else
            {
                [_conversationTable setContentOffset:CGPointMake(0, difference)];
                tableIsScrolling = NO;
            }
        }
    }
}

- (void)setCurrentWallpaper:(UIImage *)theWallpaper
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    _wallpaper.image = theWallpaper;
    
    if ( theWallpaper )
    {
        if ( [appDelegate isDarkImage:theWallpaper] )
        {
            shouldUseLightTheme = YES;
        }
        else
        {
            shouldUseLightTheme = NO;
        }
    }
    else
    {
        shouldUseLightTheme = NO;
    }
    
    [_conversationTable reloadData];
}

#pragma mark -
#pragma mark Recipients

- (void)privacyDidChange:(SHThreadPrivacy)newPrivacy
{
    if ( newPrivacy == SHThreadPrivacyPrivate )
    {
        [self setPrivateMode:YES withServerSync:NO];
    }
    else if ( newPrivacy == SHThreadPrivacyPublic )
    {
        [self setPrivateMode:NO withServerSync:NO];
    }
}

- (void)setAdHocMode:(BOOL)adHocMode withOriginalRecipients:(NSSet *)originalRecipients
{
    if ( adHocMode )
    {
        _adHocTag = originalRecipients;
        
        headerStatusLabel.hidden = YES;
        conversationTableFooter.hidden = YES;
        attachButton.hidden = YES;
        sendButton.hidden = YES;
        _messageBox.hidden = YES;
        _recipientBubble.hidden = YES;
        
        headerNameLabel.frame = CGRectMake(headerNameLabel.frame.origin.x, 10, headerNameLabel.frame.size.width, headerNameLabel.frame.size.height);
        conversationTableFooter.frame = CGRectMake(0, 0, 1, 10); // Hide the footer (keep some of it as bottom padding).
        _conversationTable.tableFooterView = conversationTableFooter;
    }
    else
    {
        _adHocTag = nil;
        
        headerStatusLabel.hidden = NO;
        conversationTableFooter.hidden = NO;
        attachButton.hidden = NO;
        sendButton.hidden = NO;
        _messageBox.hidden = NO;
        _recipientBubble.hidden = NO;
        
        headerNameLabel.frame = CGRectMake(headerNameLabel.frame.origin.x, 5, headerNameLabel.frame.size.width, headerNameLabel.frame.size.height);
    }
    
    _inAdHocMode = adHocMode;
}

- (void)setPrivateMode:(BOOL)privateMode withServerSync:(BOOL)shouldSync
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( privateMode )
    {
        if ( shouldSync )
        {
            [appDelegate.messageManager updateThreadPrivacy:SHThreadPrivacyPrivate forConversation:_recipientID];
        }
        
        if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
        {
            if ( appDelegate.activeWindow == SHAppWindowTypeMessages &&
                self.navigationController.viewControllers.count < 2 ) // Main Window is active.
            {
                [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav_bar_legacy_dark"] forBarMetrics:UIBarMetricsDefault];
                self.navigationController.navigationBar.tintColor = [UIColor blackColor];
                self.navigationController.navigationBar.shadowImage = [UIImage new];
            }
        }
        else
        {
            _messageBox.internalTextView.keyboardAppearance = UIKeyboardAppearanceDark;
            
            if ( appDelegate.activeWindow == SHAppWindowTypeMessages &&
                self.navigationController.viewControllers.count < 2 )
            {
                if ( !appDelegate.mainMenu.presentedViewController ) // In case the status update view happened to be presented over the current chat.
                {
                    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
                }
                
                self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
                
                [appDelegate.mainWindowNavigationController.navigationBar setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor]}];
            }
        }
        
        // Newer devices have warmer color hues.
        NSSet *devicesWithOlderHues = [NSSet setWithObjects:@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"13", @"14", @"15", @"16", @"18", @"19", @"20", @"21", @"22", @"23", @"24", @"25", @"26", @"27", @"28", @"29", @"30", @"31", @"32", nil];
        NSString *currentDevice = [UIDeviceHardware platformNumericString];
        
        if ( [devicesWithOlderHues containsObject:currentDevice] )
        {
            appDelegate.mainMenu.mainWindowNipple.image = [UIImage imageNamed:@"main_window_nipple_dark_4s"];
        }
        else
        {
            appDelegate.mainMenu.mainWindowNipple.image = [UIImage imageNamed:@"main_window_nipple_dark_5"];
        }
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            headerNameLabel.textColor = [UIColor whiteColor];
            headerStatusLabel.textColor = [UIColor whiteColor];
        } completion:^(BOOL finished){
            
        }];
    }
    else
    {
        if ( shouldSync )
        {
            [appDelegate.messageManager updateThreadPrivacy:SHThreadPrivacyPublic forConversation:_recipientID];
        }
        
        if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
        {
            if ( appDelegate.activeWindow == SHAppWindowTypeMessages &&
                self.navigationController.viewControllers.count < 2 ) // Main Window is active
            {
                [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav_bar_legacy_white"] forBarMetrics:UIBarMetricsDefault];
                self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:224/255.0 green:224/255.0 blue:224/255.0 alpha:1.0];
                self.navigationController.navigationBar.shadowImage = [UIImage imageNamed:@"nav_bar_shadow_line"];
            }
        }
        else
        {
            
            _messageBox.internalTextView.keyboardAppearance = UIKeyboardAppearanceDefault;
            
            if ( appDelegate.activeWindow == SHAppWindowTypeMessages &&
                self.navigationController.viewControllers.count < 2 ) // Main Window is active
            {
                if ( appDelegate.mainMenu.windowCompositionLayer.contentOffset.x >= 320 )
                {
                    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
                }
                
                self.navigationController.navigationBar.tintColor = nil;
                self.navigationController.navigationBar.barTintColor = nil;
                
                [appDelegate.mainWindowNavigationController.navigationBar setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor blackColor]}];
            }
        }
        
        appDelegate.mainMenu.mainWindowNipple.image = [UIImage imageNamed:@"main_window_nipple"];
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            headerNameLabel.textColor = [UIColor blackColor];
            headerStatusLabel.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
        } completion:^(BOOL finished){
            
        }];
    }
    
    [privacyToggle setOn:privateMode];
    _inPrivateMode = privateMode;
    
    appDelegate.mainWindowNavigationController.inPrivateMode = privateMode;
}

- (void)addParticipant
{
    SHRecipientPickerViewController *recipientPicker = [[SHRecipientPickerViewController alloc] init];
    SHOrientationNavigationController *navigationController = [[SHOrientationNavigationController alloc] initWithRootViewController:recipientPicker];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)setRecipientDataForUser:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    showsPhoneNumber = NO; // Reset this.
    
    if ( !didPlayTutorial_Privacy )
    {
        [self playPrivacyTutorial];
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"SHBDTutorialPrivacy"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        didPlayTutorial_Privacy = YES;
    }
    
    if ( appDelegate.preference_ReturnKeyToSend )
    {
        _messageBox.returnKeyType = UIReturnKeySend;
        _messageBox.enablesReturnKeyAutomatically = YES;
        sendButton.alpha = 0.0;
        sendButton.hidden = YES;
    }
    else
    {
        _messageBox.returnKeyType = UIReturnKeyDefault;
        _messageBox.enablesReturnKeyAutomatically = NO;
        sendButton.alpha = 0.0;
        sendButton.hidden = NO;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inDatabase:^(FMDatabase *db) {
            if ( _inAdHocMode )
            {
                privacyToggle.enabled = NO; // Can't edit privacy for ad hoc convos.
                
                NSMutableArray *originalParticipantData = [NSMutableArray array];
                
                for ( NSString *participantID in _adHocTag )
                {
                    FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :user_id"
                               withParameterDictionary:@{@"user_id": participantID}];
                    
                    // Read & store each contact's data.
                    while ( [s1 next] )
                    {
                        NSMutableDictionary *data = [NSMutableDictionary dictionary];
                        
                        [data setObject:[s1 stringForColumn:@"name_first"] forKey:@"name_first"];
                        [data setObject:[s1 stringForColumn:@"name_last"] forKey:@"name_last"];
                        [data setObject:[s1 stringForColumn:@"alias"] forKey:@"alias"];
                        
                        [originalParticipantData addObject:data];
                    }
                    
                    [s1 close];
                }
                
                NSMutableDictionary *participant_1 = [originalParticipantData objectAtIndex:0];
                NSMutableDictionary *participant_2 = [originalParticipantData objectAtIndex:1];
                NSString *participantName_1 = [participant_1 objectForKey:@"alias"];
                NSString *participantName_2 = [participant_2 objectForKey:@"alias"];
                
                if ( participantName_1.length == 0 )
                {
                    participantName_1 = [participant_1 objectForKey:@"name_first"];
                }
                
                if ( participantName_2.length == 0 )
                {
                    participantName_2 = [participant_2 objectForKey:@"name_first"];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [self setRecipientName:[NSString stringWithFormat:@"%@ + %@", participantName_1, participantName_2]];
                });
            }
            else
            {
                _recipientID = userID;
                
                // Getting the recipient's data happens on the main thread. We need a semaphore to wait for it.
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    _recipientDataChunk = [appDelegate.contactManager infoForUser:_recipientID];
                    
                    if ( appDelegate.networkManager.networkState == SHNetworkStateConnected )
                    {
                        privacyToggle.enabled = YES;
                    }
                    else
                    {
                        privacyToggle.enabled = NO;
                    }
                    
                    dispatch_semaphore_signal(semaphore);
                });
                
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                
                // Before showing the recipient's presence, check if the current user reached the required message threshold with them.
                int64_t messageCount_CurrentUser = [[_recipientDataChunk objectForKey:@"total_messages_sent"] intValue];
                int64_t messageCount_Recipient = [[_recipientDataChunk objectForKey:@"total_messages_received"] intValue];
                
                if ( messageCount_CurrentUser > MERIT_MESSAGE_THRESHOLD && messageCount_Recipient > MERIT_MESSAGE_THRESHOLD )
                {
                    didGainPrivacyMerit = YES;
                }
                else
                {
                    didGainPrivacyMerit = NO;
                }
                
                recipientName_first = [_recipientDataChunk objectForKey:@"name_first"];
                recipientName_last = [_recipientDataChunk objectForKey:@"name_last"];
                recipientName_alias = [_recipientDataChunk objectForKey:@"alias"];
                NSString *fullName = recipientName_alias;
                
                [appDelegate.mainMenu.activeRecipientBubble setMetadata:_recipientDataChunk];
                
                if ( recipientName_alias.length == 0 )
                {
                    fullName = [NSString stringWithFormat:@"%@ %@", recipientName_first, recipientName_last];
                }
                
                __block UIImage *currentDP = [UIImage imageWithData:[_recipientDataChunk objectForKey:@"alias_dp"]];
                
                if ( !currentDP )
                {
                    currentDP = [UIImage imageWithData:[_recipientDataChunk objectForKey:@"dp"]];
                }
                
                FMResultSet *s1 = [db executeQuery:@"SELECT message FROM sh_thread WHERE thread_id = :last_status_id"
                           withParameterDictionary:@{@"last_status_id": [_recipientDataChunk objectForKey:@"last_status_id"]}];
                
                NSString *lastStatus = @"";
                
                while ( [s1 next] )
                {
                    lastStatus = [s1 stringForColumnIndex:0];
                }
                
                [s1 close];
                
                BOOL private = NO;
                
                s1 = [db executeQuery:@"SELECT COUNT(*) FROM sh_private_conversations WHERE user_id = :user_id"
                            withParameterDictionary:@{@"user_id": _recipientID}];
                
                while ( [s1 next] )
                {
                    int count = [s1 intForColumnIndex:0];
                    
                    if ( count > 0 )
                    {
                        private = YES;
                    }
                }
                
                [s1 close];
                
                [self setRecipientPresence:nil withDB:db];
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    // We need to re-create a small version of the photo.
                    UIImageView *preview = [[UIImageView alloc] initWithImage:currentDP];
                    preview.frame = CGRectMake(0, 0, 100, 100);
                    
                    // Next, we basically take a screenshot of it again.
                    UIGraphicsBeginImageContext(preview.bounds.size);
                    [preview.layer renderInContext:UIGraphicsGetCurrentContext()];
                    currentDP = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    
                    [self setRecipientName:fullName];
                    [self setRecipientStatus:lastStatus];
                    [_recipientBubble setImage:currentDP];
                    [self setPrivateMode:private withServerSync:NO];
                    [self fetchLatestMessageState];
                    
                    [appDelegate.mainMenu.activeRecipientBubble setImage:currentDP];
                    
                    if ( recipientName_alias.length > 0 )
                    {
                        [appDelegate.mainMenu.activeRecipientBubble setLabelText:recipientName_alias withFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:MIN_SECONDARY_FONT_SIZE]];
                    }
                    else
                    {
                        [appDelegate.mainMenu.activeRecipientBubble setLabelText:recipientName_first withFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:MIN_SECONDARY_FONT_SIZE]];
                    }
                });
                
                BOOL foundActiveUpload = NO;
                
                for ( NSDictionary *activeUpload in activeMediaUploadRecipients ) // Still uploading...
                {
                    int activeUploadID = [[activeUpload objectForKey:@"user_id"] intValue];
                    SHMediaType mediaType = [[activeUpload objectForKey:@"media_type"] intValue];
                    NSData *media = [activeUpload objectForKey:@"media"];
                    
                    if ( activeUploadID == _recipientID.intValue )
                    {
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            sendButton.enabled = NO;
                            
                            if ( mediaType == SHMediaTypePhoto )
                            {
                                [uploadActivityIndicator startAnimating];
                                
                                [sendButton setImage:nil forState:UIControlStateNormal];
                                sendButton.enabled = NO;
                                uploadActivityIndicator.hidden = NO;
                                
                                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                                    uploadActivityIndicator.alpha = 1.0;
                                } completion:^(BOOL finished){
                                    
                                }];
                                
                                [self updateMessagingInterfaceWithImage:[UIImage imageWithData:media]];
                            }
                        });
                        
                        foundActiveUpload = YES;
                        
                        break;
                    }
                }
                
                if ( !foundActiveUpload )
                {
                    for ( NSDictionary *processedUpload in processedMediaUploads ) // Check completed uploads.
                    {
                        int activeUploadID = [[processedUpload objectForKey:@"user_id"] intValue];
                        SHMediaType mediaType = [[processedUpload objectForKey:@"media_type"] intValue];
                        NSData *media = [processedUpload objectForKey:@"media"];
                        
                        if ( activeUploadID == _recipientID.intValue )
                        {
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                sendButton.enabled = YES;
                                
                                if ( mediaType == SHMediaTypePhoto )
                                {
                                    [self updateMessagingInterfaceWithImage:[UIImage imageWithData:media]];
                                }
                            });
                            
                            break;
                        }
                    }
                }
            }
        }];
    });
}

- (void)setRecipientPresence:(NSDictionary *)presenceData withDB:(FMDatabase *)db
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( db )
    {
        SHUserPresence presence;
        BOOL didLoadPresence = YES; // When the app first loads & still hasn't connected.
        BOOL shouldDisplayBubbleTypingIndicator = NO;
        int targetID = -1;
        SHUserPresenceAudience audience = SHUserPresenceAudienceEveryone;
        int currentUserID = [[appDelegate.currentUser objectForKey:@"user_id"] intValue];
        NSString *presenceString;
        NSString *userName = recipientName_first;
        
        if ( recipientName_alias.length > 0 )
        {
            userName = recipientName_alias; // Alias has higher priority.
        }
        
        if ( presenceData ) // Fresh data.
        {
            presence = [[presenceData objectForKey:@"status"] intValue];
            targetID = [[presenceData objectForKey:@"target_id"] intValue];
            audience = [[presenceData objectForKey:@"audience"] intValue];
            
            if ( [[presenceData objectForKey:@"timestamp"] isKindOfClass:[NSDate class]] )
            {
                presenceTimestampDate = [presenceData objectForKey:@"timestamp"];
            }
            else
            {
                presenceTimestampDate = [dateFormatter dateFromString:[presenceData objectForKey:@"timestamp"]];
            }
        }
        else // Pull it from local storage.
        {
            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_user_online_status WHERE user_id = :recipient_id"
                       withParameterDictionary:@{@"recipient_id": _recipientID}];
            
            NSString *timestampString = @"";
            
            while ( [s1 next] )
            {
                presence = [s1 intForColumn:@"status"];
                targetID = [s1 intForColumn:@"target_id"];
                audience = [s1 intForColumn:@"audience"];
                timestampString = [s1 stringForColumn:@"timestamp"];
            }
            
            [s1 close];
            
            if ( timestampString.length == 0 )
            {
                didLoadPresence = NO;
                presenceString = @"…";
            }
            else
            {
                presenceTimestampDate = [dateFormatter dateFromString:timestampString];
            }
        }
        
        if ( didLoadPresence )
        {
            presenceTimestampString = [appDelegate relativeTimefromDate:presenceTimestampDate shortened:NO condensed:NO];
            recipientCurrentPresence = presence;
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [appDelegate.mainMenu.activeRecipientBubble setPresence:recipientCurrentPresence animated:YES];
            });
            
            switch ( presence )
            {
                case SHUserPresenceOnline:
                {
                    presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                    break;
                }
                    
                case SHUserPresenceOnlineMasked:
                {
                    presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                    break;
                }
                    
                case SHUserPresenceAway:
                {
                    presenceString = [NSString stringWithFormat:@"%@ is away.", userName];
                    break;
                }
                    
                case SHUserPresenceOffline:
                {
                    if ( appDelegate.preference_LastSeen ) // You can only see this part if the preference is turned on.
                    {
                         presenceString = [NSString stringWithFormat:@"%@ was last seen %@.", userName, presenceTimestampString];
                    }
                    else
                    {
                        presenceString = [NSString stringWithFormat:@"%@ is offline.", userName];
                    }
                    
                    break;
                }
                    
                case SHUserPresenceOfflineMasked:
                {
                    presenceString = [NSString stringWithFormat:@"%@ is offline.", userName];
                    break;
                }
                    
                case SHUserPresenceTyping:
                {
                    if ( targetID == currentUserID )
                    {
                        presenceString = [NSString stringWithFormat:@"💭 %@ is typing…", userName];
                        
                        if ( _conversationTable.contentSize.height > _conversationTable.frame.size.height &&
                            _conversationTable.contentOffset.y < _conversationTable.contentSize.height - _conversationTable.frame.size.height - 50 )
                        {
                            shouldDisplayBubbleTypingIndicator = YES;
                        }
                    }
                    else if ( appDelegate.preference_Talking ) // You can only see this part if the preference is turned on.
                    {
                        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                   withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                        
                        NSString *targetName = @"";
                        NSString *targetAlias = @"";
                        
                        // Check if the target's a contact.
                        while ( [s1 next] )
                        {
                            targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                            targetAlias = [s1 stringForColumn:@"alias"];
                        }
                        
                        [s1 close];
                        
                        if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient ) // Target is not a contact or audience is restricted.
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                        }
                    }
                    else
                    {
                        presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                    }
                    
                    break;
                }
                    
                case SHUserPresenceActivityStopped:
                {
                    presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                    break;
                }
                    
                case SHUserPresenceSendingPhoto:
                {
                    if ( targetID == currentUserID )
                    {
                        presenceString = [NSString stringWithFormat:@"📷 %@ is sending a photo…", userName];
                    }
                    else if ( appDelegate.preference_Talking )
                    {
                        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                   withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                        
                        NSString *targetName = @"";
                        NSString *targetAlias = @"";
                        
                        // Check if the target's a contact.
                        while ( [s1 next] )
                        {
                            targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                            targetAlias = [s1 stringForColumn:@"alias"];
                        }
                        
                        [s1 close];
                        
                        if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient )
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                        }
                    }
                    else
                    {
                        presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                    }
                    
                    break;
                }
                    
                case SHUserPresenceSendingVideo:
                {
                    if ( targetID == currentUserID )
                    {
                        presenceString = [NSString stringWithFormat:@"📹 %@ is recording a video…", userName];
                    }
                    else if ( appDelegate.preference_Talking )
                    {
                        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                   withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                        
                        NSString *targetName = @"";
                        NSString *targetAlias = @"";
                        
                        // Check if the target's a contact.
                        while ( [s1 next] )
                        {
                            targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                            targetAlias = [s1 stringForColumn:@"alias"];
                        }
                        
                        [s1 close];
                        
                        if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient )
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                        }
                    }
                    else
                    {
                        presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                    }
                    
                    break;
                }
                    
                case SHUserPresenceAudio:
                {
                    if ( targetID == currentUserID )
                    {
                        presenceString = [NSString stringWithFormat:@"🎤 %@ is recording audio…", userName];
                    }
                    else if ( appDelegate.preference_Talking )
                    {
                        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                   withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                        
                        NSString *targetName = @"";
                        NSString *targetAlias = @"";
                        
                        // Check if the target's a contact.
                        while ( [s1 next] )
                        {
                            targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                            targetAlias = [s1 stringForColumn:@"alias"];
                        }
                        
                        [s1 close];
                        
                        if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient )
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                        }
                    }
                    else
                    {
                        presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                    }
                    
                    break;
                }
                    
                case SHUserPresenceLocation:
                {
                    if ( targetID == currentUserID )
                    {
                        presenceString = [NSString stringWithFormat:@"📍 %@ is sending a location…", userName];
                    }
                    else if ( appDelegate.preference_Talking )
                    {
                        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                   withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                        
                        NSString *targetName = @"";
                        NSString *targetAlias = @"";
                        
                        // Check if the target's a contact.
                        while ( [s1 next] )
                        {
                            targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                            targetAlias = [s1 stringForColumn:@"alias"];
                        }
                        
                        [s1 close];
                        
                        if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient )
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                        }
                    }
                    else
                    {
                        presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                    }
                    
                    break;
                }
                    
                case SHUserPresenceContact:
                {
                    if ( targetID == currentUserID )
                    {
                        presenceString = [NSString stringWithFormat:@"👤 %@ is sending a contact…", userName];
                    }
                    else if ( appDelegate.preference_Talking )
                    {
                        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                   withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                        
                        NSString *targetName = @"";
                        NSString *targetAlias = @"";
                        
                        // Check if the target's a contact.
                        while ( [s1 next] )
                        {
                            targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                            targetAlias = [s1 stringForColumn:@"alias"];
                        }
                        
                        [s1 close];
                        
                        if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient )
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                        }
                    }
                    else
                    {
                        presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                    }
                    
                    break;
                }
                    
                case SHUserPresenceFile:
                {
                    if ( targetID == currentUserID )
                    {
                        presenceString = [NSString stringWithFormat:@"📦 %@ is sending a file…", userName];
                    }
                    else if ( appDelegate.preference_Talking )
                    {
                        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                   withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                        
                        NSString *targetName = @"";
                        NSString *targetAlias = @"";
                        
                        // Check if the target's a contact.
                        while ( [s1 next] )
                        {
                            targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                            targetAlias = [s1 stringForColumn:@"alias"];
                        }
                        
                        [s1 close];
                        
                        if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient )
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                        }
                    }
                    else
                    {
                        presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                    }
                    
                    break;
                }
                    
                case SHUserPresenceCheckingLink:
                {
                    if ( targetID == currentUserID )
                    {
                        presenceString = [NSString stringWithFormat:@"👀 %@ is checking out a link that was sent…", userName];
                    }
                    else if ( appDelegate.preference_Talking )
                    {
                        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                   withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                        
                        NSString *targetName = @"";
                        NSString *targetAlias = @"";
                        
                        // Check if the target's a contact.
                        while ( [s1 next] )
                        {
                            targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                            targetAlias = [s1 stringForColumn:@"alias"];
                        }
                        
                        [s1 close];
                        
                        if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient )
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                        }
                    }
                    else
                    {
                        presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                    }
                    
                    break;
                }
                    
                default:
                    break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if ( ![presenceString isEqualToString:recipientStatusBubbleLabel.text] ) // Don't bother updating the UI if the timestamp is too old & no difference will be noticed.
            {
                CGSize textSize_presence = [presenceString sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:13] constrainedToSize:CGSizeMake(250, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
                
                [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                    recipientStatusBubble.frame = CGRectMake(10, messageBoxBubble.frame.size.height + 30, textSize_presence.width + 30, MAX(textSize_presence.height + 24, 40.456001));
                } completion:^(BOOL finished){
                    
                }];
                
                [UIView animateWithDuration:0.075 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    recipientStatusBubbleLabel.frame = CGRectMake(15.5, 10, textSize_presence.width, textSize_presence.height);
                    recipientStatusBubbleLabel.alpha = 0.0;
                } completion:^(BOOL finished){
                    recipientStatusBubbleLabel.text = presenceString;
                    
                    [UIView animateWithDuration:0.075 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                        recipientStatusBubbleLabel.alpha = 1.0;
                    } completion:^(BOOL finished){
                        
                    }];
                }];
                
                if ( shouldDisplayBubbleTypingIndicator )
                {
                    [_recipientBubble showTypingIndicatorFromDirection:SHChatBubbleTypingIndicatorDirectionRight];
                }
                else
                {
                    if ( _recipientBubble.isShowingTypingIndicator )
                    {
                        [_recipientBubble hideTypingIndicator];
                    }
                }
                
                conversationTableFooter.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, messageBoxBubble.frame.size.height + recipientStatusBubble.frame.size.height + 40);
                _conversationTable.tableFooterView = conversationTableFooter;
                
                [self scrollViewToBottomForced:NO animated:YES];
            }
            
            [_recipientBubble setPresence:presence animated:YES];
        });
    }
    else
    {
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            SHUserPresence presence;
            BOOL didLoadPresence = YES; // When the app first loads & still hasn't connected.
            BOOL shouldDisplayBubbleTypingIndicator = NO;
            int targetID = -1;
            SHUserPresenceAudience audience = SHUserPresenceAudienceEveryone;
            int currentUserID = [[appDelegate.currentUser objectForKey:@"user_id"] intValue];
            NSString *presenceString;
            NSString *userName = recipientName_first;
            
            if ( recipientName_alias.length > 0 )
            {
                userName = recipientName_alias; // Alias has higher priority.
            }
            
            if ( presenceData ) // Fresh data.
            {
                presence = [[presenceData objectForKey:@"status"] intValue];
                targetID = [[presenceData objectForKey:@"target_id"] intValue];
                audience = [[presenceData objectForKey:@"audience"] intValue];
                
                if ( [[presenceData objectForKey:@"timestamp"] isKindOfClass:[NSDate class]] )
                {
                    presenceTimestampDate = [presenceData objectForKey:@"timestamp"];
                }
                else
                {
                    presenceTimestampDate = [dateFormatter dateFromString:[presenceData objectForKey:@"timestamp"]];
                }
            }
            else // Pull it from local storage.
            {
                FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_user_online_status WHERE user_id = :recipient_id"
                           withParameterDictionary:@{@"recipient_id": _recipientID}];
                
                NSString *timestampString = @"";
                
                while ( [s1 next] )
                {
                    presence = [s1 intForColumn:@"status"];
                    targetID = [s1 intForColumn:@"target_id"];
                    audience = [s1 intForColumn:@"audience"];
                    timestampString = [s1 stringForColumn:@"timestamp"];
                }
                
                [s1 close];
                
                if ( timestampString.length == 0 )
                {
                    didLoadPresence = NO;
                    presenceString = @"…";
                }
                else
                {
                    presenceTimestampDate = [dateFormatter dateFromString:timestampString];
                }
            }
            
            if ( didLoadPresence )
            {
                presenceTimestampString = [appDelegate relativeTimefromDate:presenceTimestampDate shortened:NO condensed:NO];
                recipientCurrentPresence = presence;
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [appDelegate.mainMenu.activeRecipientBubble setPresence:recipientCurrentPresence animated:YES];
                });
                
                switch ( presence )
                {
                    case SHUserPresenceOnline:
                    {
                        presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                        break;
                    }
                        
                    case SHUserPresenceOnlineMasked:
                    {
                        presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                        break;
                    }
                        
                    case SHUserPresenceAway:
                    {
                        presenceString = [NSString stringWithFormat:@"%@ is away.", userName];
                        break;
                    }
                        
                    case SHUserPresenceOffline:
                    {
                        if ( appDelegate.preference_LastSeen ) // You can only see this part if the preference is turned on.
                        {
                            presenceString = [NSString stringWithFormat:@"%@ was last seen %@.", userName, presenceTimestampString];
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"%@ is offline.", userName];
                        }
                        
                        break;
                    }
                        
                    case SHUserPresenceOfflineMasked:
                    {
                        presenceString = [NSString stringWithFormat:@"%@ is offline.", userName];
                        break;
                    }
                        
                    case SHUserPresenceTyping:
                    {
                        if ( targetID == currentUserID )
                        {
                            presenceString = [NSString stringWithFormat:@"💭 %@ is typing…", userName];
                            
                            if ( _conversationTable.contentSize.height > _conversationTable.frame.size.height &&
                                _conversationTable.contentOffset.y < _conversationTable.contentSize.height - _conversationTable.frame.size.height - 50 )
                            {
                                shouldDisplayBubbleTypingIndicator = YES;
                            }
                        }
                        else if ( appDelegate.preference_Talking ) // You can only see this part if the preference is turned on.
                        {
                            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                       withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                            
                            NSString *targetName = @"";
                            NSString *targetAlias = @"";
                            
                            // Check if the target's a contact.
                            while ( [s1 next] )
                            {
                                targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                                targetAlias = [s1 stringForColumn:@"alias"];
                            }
                            
                            [s1 close];
                            
                            if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient ) // Target is not a contact or audience is restricted.
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                            }
                            else
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                            }
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                        }
                        
                        break;
                    }
                        
                    case SHUserPresenceActivityStopped:
                    {
                        presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                        break;
                    }
                        
                    case SHUserPresenceSendingPhoto:
                    {
                        if ( targetID == currentUserID )
                        {
                            presenceString = [NSString stringWithFormat:@"📷 %@ is sending a photo…", userName];
                        }
                        else if ( appDelegate.preference_Talking )
                        {
                            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                       withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                            
                            NSString *targetName = @"";
                            NSString *targetAlias = @"";
                            
                            // Check if the target's a contact.
                            while ( [s1 next] )
                            {
                                targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                                targetAlias = [s1 stringForColumn:@"alias"];
                            }
                            
                            [s1 close];
                            
                            if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient )
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                            }
                            else
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                            }
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                        }
                        
                        break;
                    }
                        
                    case SHUserPresenceSendingVideo:
                    {
                        if ( targetID == currentUserID )
                        {
                            presenceString = [NSString stringWithFormat:@"📹 %@ is recording a video…", userName];
                        }
                        else if ( appDelegate.preference_Talking )
                        {
                            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                       withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                            
                            NSString *targetName = @"";
                            NSString *targetAlias = @"";
                            
                            // Check if the target's a contact.
                            while ( [s1 next] )
                            {
                                targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                                targetAlias = [s1 stringForColumn:@"alias"];
                            }
                            
                            [s1 close];
                            
                            if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient )
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                            }
                            else
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                            }
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                        }
                        
                        break;
                    }
                        
                    case SHUserPresenceAudio:
                    {
                        if ( targetID == currentUserID )
                        {
                            presenceString = [NSString stringWithFormat:@"🎤 %@ is recording audio…", userName];
                        }
                        else if ( appDelegate.preference_Talking )
                        {
                            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                       withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                            
                            NSString *targetName = @"";
                            NSString *targetAlias = @"";
                            
                            // Check if the target's a contact.
                            while ( [s1 next] )
                            {
                                targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                                targetAlias = [s1 stringForColumn:@"alias"];
                            }
                            
                            [s1 close];
                            
                            if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient )
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                            }
                            else
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                            }
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                        }
                        
                        break;
                    }
                        
                    case SHUserPresenceLocation:
                    {
                        if ( targetID == currentUserID )
                        {
                            presenceString = [NSString stringWithFormat:@"📍 %@ is sending a location…", userName];
                        }
                        else if ( appDelegate.preference_Talking )
                        {
                            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                       withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                            
                            NSString *targetName = @"";
                            NSString *targetAlias = @"";
                            
                            // Check if the target's a contact.
                            while ( [s1 next] )
                            {
                                targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                                targetAlias = [s1 stringForColumn:@"alias"];
                            }
                            
                            [s1 close];
                            
                            if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient )
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                            }
                            else
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                            }
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                        }
                        
                        break;
                    }
                        
                    case SHUserPresenceContact:
                    {
                        if ( targetID == currentUserID )
                        {
                            presenceString = [NSString stringWithFormat:@"👤 %@ is sending a contact…", userName];
                        }
                        else if ( appDelegate.preference_Talking )
                        {
                            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                       withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                            
                            NSString *targetName = @"";
                            NSString *targetAlias = @"";
                            
                            // Check if the target's a contact.
                            while ( [s1 next] )
                            {
                                targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                                targetAlias = [s1 stringForColumn:@"alias"];
                            }
                            
                            [s1 close];
                            
                            if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient )
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                            }
                            else
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                            }
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                        }
                        
                        break;
                    }
                        
                    case SHUserPresenceFile:
                    {
                        if ( targetID == currentUserID )
                        {
                            presenceString = [NSString stringWithFormat:@"📦 %@ is sending a file…", userName];
                        }
                        else if ( appDelegate.preference_Talking )
                        {
                            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                       withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                            
                            NSString *targetName = @"";
                            NSString *targetAlias = @"";
                            
                            // Check if the target's a contact.
                            while ( [s1 next] )
                            {
                                targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                                targetAlias = [s1 stringForColumn:@"alias"];
                            }
                            
                            [s1 close];
                            
                            if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient )
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                            }
                            else
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                            }
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                        }
                        
                        break;
                    }
                        
                    case SHUserPresenceCheckingLink:
                    {
                        if ( targetID == currentUserID )
                        {
                            presenceString = [NSString stringWithFormat:@"👀 %@ is checking out a link that was sent…", userName];
                        }
                        else if ( appDelegate.preference_Talking )
                        {
                            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :target_id"
                                       withParameterDictionary:@{@"target_id": [NSNumber numberWithInt:targetID]}];
                            
                            NSString *targetName = @"";
                            NSString *targetAlias = @"";
                            
                            // Check if the target's a contact.
                            while ( [s1 next] )
                            {
                                targetName = [NSString stringWithFormat:@"%@ %@", [s1 stringForColumn:@"name_first"], [s1 stringForColumn:@"name_last"]];
                                targetAlias = [s1 stringForColumn:@"alias"];
                            }
                            
                            [s1 close];
                            
                            if ( targetName.length == 0 || audience == SHUserPresenceAudienceRecipient )
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to somebody…", userName];
                            }
                            else
                            {
                                presenceString = [NSString stringWithFormat:@"💬 %@ is talking to %@…", userName, targetAlias.length > 0 ? targetAlias : targetName]; // Priority to the alias.
                            }
                        }
                        else
                        {
                            presenceString = [NSString stringWithFormat:@"%@ is online.", userName];
                        }
                        
                        break;
                    }
                        
                    default:
                        break;
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if ( ![presenceString isEqualToString:recipientStatusBubbleLabel.text] ) // Don't bother updating the UI if the timestamp is too old & no difference will be noticed.
                {
                    CGSize textSize_presence = [presenceString sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:13] constrainedToSize:CGSizeMake(250, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
                    
                    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                        recipientStatusBubble.frame = CGRectMake(10, messageBoxBubble.frame.size.height + 30, textSize_presence.width + 30, MAX(textSize_presence.height + 24, 40.456001));
                    } completion:^(BOOL finished){
                        
                    }];
                    
                    [UIView animateWithDuration:0.075 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                        recipientStatusBubbleLabel.frame = CGRectMake(15.5, 10, textSize_presence.width, textSize_presence.height);
                        recipientStatusBubbleLabel.alpha = 0.0;
                    } completion:^(BOOL finished){
                        recipientStatusBubbleLabel.text = presenceString;
                        
                        [UIView animateWithDuration:0.075 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                            recipientStatusBubbleLabel.alpha = 1.0;
                        } completion:^(BOOL finished){
                            
                        }];
                    }];
                    
                    if ( shouldDisplayBubbleTypingIndicator )
                    {
                        [_recipientBubble showTypingIndicatorFromDirection:SHChatBubbleTypingIndicatorDirectionRight];
                    }
                    else
                    {
                        if ( _recipientBubble.isShowingTypingIndicator )
                        {
                            [_recipientBubble hideTypingIndicator];
                        }
                    }
                    
                    conversationTableFooter.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, messageBoxBubble.frame.size.height + recipientStatusBubble.frame.size.height + 40);
                    _conversationTable.tableFooterView = conversationTableFooter;
                    
                    [self scrollViewToBottomForced:NO animated:YES];
                }
                
                [_recipientBubble setPresence:presence animated:YES];
            });
        }];
    }
}

- (void)setRecipientName:(NSString *)name
{
    headerNameLabel.text = name;
}

- (void)setRecipientStatus:(NSString *)status
{
    headerStatusLabel.text = status;
}

- (void)showProfileForRecipient
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [self resetHeaderLabels];
    
    SHProfileViewController *profileView = [[SHProfileViewController alloc] init];
    profileView.ownerID = _recipientID;
    
    appDelegate.mainMenu.activeRecipientBubble.hidden = YES;
    appDelegate.mainMenu.windowCompositionLayer.contentSize = CGSizeMake(appDelegate.screenBounds.size.width * 2 - 40, appDelegate.screenBounds.size.height);
    
    profileView.ownerDataChunk = [appDelegate.contactManager infoForUser:_recipientID];
    
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        appDelegate.mainMenu.mainWindowContainer.alpha = 0.0;
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.05 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            appDelegate.mainMenu.mainWindowContainer.alpha = 1.0;
        } completion:^(BOOL finished){
            
        }];
    }];
    
    appDelegate.mainMenu.windowCompositionLayer.scrollEnabled = NO;
    appDelegate.mainMenu.wallpaper.alpha = 1.0;
    appDelegate.viewIsDraggable = NO;
    [appDelegate.mainMenu resumeWallpaperAnimation];
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController pushViewController:profileView animated:YES];
}

- (void)showDPOverlay
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSString *DPHash = [_recipientDataChunk objectForKey:@"dp_hash"];
    
    if ( DPHash.length == 0 ) // Don't show the overlay for people with no pics.
    {
        return;
    }
    
    [self resetView];
    
    UIView *overlay = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.9];
    overlay.opaque = YES;
    overlay.userInteractionEnabled = YES;
    overlay.alpha = 0.0;
    overlay.tag = 777;
    
    UIImageView *preview = [[UIImageView alloc] initWithFrame:CGRectMake(overlay.frame.size.width - 53, -53, _recipientBubble.frame.size.width, _recipientBubble.frame.size.height)];
    preview.contentMode = UIViewContentModeScaleAspectFit;
    preview.opaque = YES;
    preview.tag = 7771;
    
    UIButton *dismissOverlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [dismissOverlayButton setImage:[UIImage imageNamed:@"back_white"] forState:UIControlStateNormal];
    [dismissOverlayButton addTarget:self action:@selector(dismissDPOverlay) forControlEvents:UIControlEventTouchUpInside];
    dismissOverlayButton.frame = CGRectMake(17, overlay.frame.size.height - 53, 32, 32);
    dismissOverlayButton.showsTouchWhenHighlighted = YES;
    
    UIButton *saveDPButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [saveDPButton setImage:[UIImage imageNamed:@"save_white"] forState:UIControlStateNormal];
    [saveDPButton addTarget:self action:@selector(exportDP) forControlEvents:UIControlEventTouchUpInside];
    saveDPButton.frame = CGRectMake(overlay.frame.size.width - 45, overlay.frame.size.height - 53, 32, 32);
    saveDPButton.showsTouchWhenHighlighted = YES;
    
    UIImage *currentDP = [UIImage imageWithData:[_recipientDataChunk objectForKey:@"alias_dp"]];
    
    if ( !currentDP )
    {
        currentDP = [UIImage imageWithData:[_recipientDataChunk objectForKey:@"dp"]];
    }
    
    preview.image = currentDP;
    [overlay addSubview:preview];
    [overlay addSubview:dismissOverlayButton];
    [overlay addSubview:saveDPButton];
    [self.view addSubview:overlay];
    
    if ( (IS_IOS7) )
    {
        [appDelegate registerPrallaxEffectForView:dismissOverlayButton depth:PARALLAX_DEPTH_HEAVY];
        [appDelegate registerPrallaxEffectForView:saveDPButton depth:PARALLAX_DEPTH_HEAVY];
    }
    
    appDelegate.mainMenu.windowCompositionLayer.scrollEnabled = NO;
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
    
    appDelegate.mainMenu.windowCompositionLayer.scrollEnabled = YES;
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionNavigationBar];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        overlay.alpha = 0.0;
        preview.transform = CGAffineTransformMakeScale(2.0, 2.0);
    } completion:^(BOOL finished){
        [overlay removeFromSuperview];
    }];
}

- (void)exportDP
{
    UIImage *currentDP = [UIImage imageWithData:[_recipientDataChunk objectForKey:@"alias_dp"]];
    
    if ( !currentDP )
    {
        currentDP = [UIImage imageWithData:[_recipientDataChunk objectForKey:@"dp"]];
    }
    
    NSArray *activityItems = @[currentDP];
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    [self.navigationController presentViewController:activityController animated:YES completion:nil];
}

#pragma mark -
#pragma mark Realtime Timestamps

- (void)updateTimestamps
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ( appDelegate.preference_RelativeTime )
        {
            NSArray *visibleCells = [_conversationTable visibleCells];
            
            for ( int i = 0; i < visibleCells.count; i++ )
            {
                SHThreadCell *targetCell = (SHThreadCell *)[visibleCells objectAtIndex:i];
                NSIndexPath *indexPath = [_conversationTable indexPathForCell:targetCell];
                NSMutableDictionary *entry = [_threads objectAtIndex:indexPath.row];
                int entryType = [[entry objectForKey:@"entry_type"] intValue];
                
                if ( entryType == 1 )
                {
                    NSString *timestampSentString = [entry objectForKey:@"timestamp_sent"];
                    SHThreadStatus status = [[entry objectForKey:@"status_sent"] intValue];
                    BOOL messageDidDeliver = [[entry objectForKey:@"status_delivered"] boolValue];
                    BOOL messageWasRead = [[entry objectForKey:@"status_read"] boolValue];
                    
                    if ( messageWasRead )
                    {
                        status = SHThreadStatusRead;
                    }
                    else if ( messageDidDeliver )
                    {
                        status = SHThreadStatusDelivered;
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [targetCell updateTimestampWithTime:timestampSentString messageStatus:status];
                    });
                }
            }
        }
        
        if ( recipientCurrentPresence == SHUserPresenceOffline && appDelegate.preference_LastSeen && !_inAdHocMode ) // Don't accidentally show last seen time if the preference is disabled!
        {
            NSString *userName = recipientName_first;
            
            if ( recipientName_alias.length > 0 )
            {
                userName = recipientName_alias; // Alias has higher priority.
            }
            
            presenceTimestampString = [appDelegate relativeTimefromDate:presenceTimestampDate shortened:NO condensed:NO];
            NSString *presenceString = [NSString stringWithFormat:@"%@ was last seen %@.", userName, presenceTimestampString];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if ( ![presenceString isEqualToString:recipientStatusBubbleLabel.text] ) // Don't bother updating the presence UI if the timestamp is too old & no difference will be noticed.
                {
                    CGSize textSize_presence = [presenceString sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:13] constrainedToSize:CGSizeMake(250, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
                    
                    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                        recipientStatusBubble.frame = CGRectMake(10, messageBoxBubble.frame.size.height + 30, textSize_presence.width + 30, MAX(textSize_presence.height + 24, 40.456001));
                    } completion:^(BOOL finished){
                        
                    }];
                    
                    [UIView animateWithDuration:0.075 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                        recipientStatusBubbleLabel.frame = CGRectMake(15.5, 10, textSize_presence.width, textSize_presence.height);
                    } completion:^(BOOL finished){
                        recipientStatusBubbleLabel.text = presenceString;
                    }];
                    
                    conversationTableFooter.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, messageBoxBubble.frame.size.height + recipientStatusBubble.frame.size.height + 40);
                    _conversationTable.tableFooterView = conversationTableFooter;
                    
                    [self scrollViewToBottomForced:NO animated:YES];
                }
            });
        }
    });
}

- (void)cancelTimestampUpdates
{
    [timer_timestamps invalidate];
    timer_timestamps = nil;
}

- (void)resumeTimestampUpdates
{
    if ( timer_timestamps )
    {
        [timer_timestamps invalidate];
        timer_timestamps = nil;
    }
    
    [self updateTimestamps];
    
    timer_timestamps = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(updateTimestamps) userInfo:nil repeats:YES]; // Update every 1 min.
}

- (void)showExactLastSeenTime
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( recipientCurrentPresence == SHUserPresenceOffline && appDelegate.preference_LastSeen && !isShowingExactLastSeenTime ) // Don't accidentally show last seen time if the preference is disabled!
    {
        isShowingExactLastSeenTime = YES;
        
        NSString *userName = recipientName_first;
        
        if ( recipientName_alias.length > 0 )
        {
            userName = recipientName_alias; // Alias has higher priority.
        }
        
        NSDateComponents *targetDateComponents = [appDelegate.calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:presenceTimestampDate];
        NSInteger targetHour = [targetDateComponents hour];
        NSInteger targetMinute = [targetDateComponents minute];
        NSString *timePeriod = @"am";
        
        if ( targetHour > 12 ) // Convert back to 12-hour format for display purposes.
        {
            targetHour -= 12;
            timePeriod = @"pm";
        }
        
        if ( targetHour == 12 ) // This needs its own fix for the case of 12 pm.
        {
            timePeriod = @"pm";
        }
        
        if ( targetHour == 0 )
        {
            targetHour = 12;
            timePeriod = @"am";
        }
        
        NSString *presenceString = [NSString stringWithFormat:@"%@ was last seen at %d:%02d %@.", userName, (int)targetHour, (int)targetMinute, timePeriod];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            CGSize textSize_presence = [presenceString sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:13] constrainedToSize:CGSizeMake(250, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
            
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                recipientStatusBubble.frame = CGRectMake(10, messageBoxBubble.frame.size.height + 30, textSize_presence.width + 30, MAX(textSize_presence.height + 24, 40.456001));
            } completion:^(BOOL finished){
                
            }];
            
            [UIView animateWithDuration:0.075 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                recipientStatusBubbleLabel.frame = CGRectMake(15.5, 10, textSize_presence.width, textSize_presence.height);
            } completion:^(BOOL finished){
                recipientStatusBubbleLabel.text = presenceString;
            }];
            
            conversationTableFooter.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, messageBoxBubble.frame.size.height + recipientStatusBubble.frame.size.height + 40);
            _conversationTable.tableFooterView = conversationTableFooter;
            
            [self scrollViewToBottomForced:NO animated:YES];
        });
    }
    else
    {
        isShowingExactLastSeenTime = NO;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self setRecipientPresence:nil withDB:nil];
        });
    }
}

#pragma mark -
#pragma mark Typing Updates

- (void)inspectCurrentlyTypedText
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( [currentlyTypedText isEqualToString:_messageBox.text] ) // Stopped typing.
    {
        [appDelegate.presenceManager setPresence:SHUserPresenceActivityStopped withTargetID:_recipientID forAudience:SHUserPresenceAudienceEveryone];
        [timer_typing invalidate];
        timer_typing = nil;
    }
    
    currentlyTypedText = _messageBox.text;
}

- (void)cancelTypingUpdates
{
    if ( timer_typing )
    {
        [timer_typing invalidate];
        timer_typing = nil;
    }
}

#pragma mark -
#pragma mark Tutorials

- (void)playPrivacyTutorial
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *overlay = [[UIView alloc] init];
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.85];
    overlay.opaque = YES;
    overlay.userInteractionEnabled = YES;
    overlay.alpha = 0.0;
    
    if ( !(IS_IOS7) )
    {
        overlay.frame = _conversationTable.frame;
    }
    else
    {
        overlay.frame = appDelegate.screenBounds;
    }
    
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 100, 260, 150)];
    descriptionLabel.backgroundColor = [UIColor clearColor];
    descriptionLabel.numberOfLines = 0;
    descriptionLabel.textColor = [UIColor whiteColor];
    descriptionLabel.text = NSLocalizedString(@"TUTORIAL_MESSAGE_PRIVACY", nil);
    descriptionLabel.opaque = YES;
    
    UIImageView *arrow = [[UIImageView alloc] initWithFrame:CGRectMake((overlay.frame.size.width / 2) - 10, 265, 20, 20)];
    arrow.image = [UIImage imageNamed:@"rounded_arrow_gray"];
    arrow.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
    arrow.opaque = YES;
    
    [overlay addSubview:descriptionLabel];
    [overlay addSubview:arrow];
    [self.view addSubview:overlay];
    
    [UIView animateWithDuration:0.15 delay:0.4 options:UIViewAnimationOptionCurveLinear animations:^{
        overlay.alpha = 1.0;
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.25 delay:1.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            arrow.frame = CGRectMake((overlay.frame.size.width / 2) - 50, arrow.frame.origin.y, arrow.frame.size.width, arrow.frame.size.height);
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                arrow.frame = CGRectMake((overlay.frame.size.width / 2) - 10, arrow.frame.origin.y, arrow.frame.size.width, arrow.frame.size.height);
            } completion:^(BOOL finished){
                [UIView animateWithDuration:0.15 delay:3 options:UIViewAnimationOptionCurveEaseIn animations:^{
                    overlay.alpha = 0.0;
                } completion:^(BOOL finished){
                    [overlay removeFromSuperview];
                }];
            }];
        }];
    }];
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
#pragma mark SHChatBubbleDelegate methods.

// Forward these to the chat cloud delegate.
- (void)didSelectBubble:(SHChatBubble *)bubble
{
    [self showDPOverlay];
}

- (void)didTapAndHoldBubble:(SHChatBubble *)bubble
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    for ( NSMutableDictionary *phoneNumberPack in [_recipientDataChunk objectForKey:@"phone_numbers"] )
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
    
    UIActionSheet *actionSheet;
    
    if ( showsPhoneNumber )
    {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                    destructiveButtonTitle:NSLocalizedString(@"OPTION_BLOCK_CONTACT", nil)
                                         otherButtonTitles:NSLocalizedString(@"OPTION_CALL_CONTACT", nil), NSLocalizedString(@"OPTION_VIEW_PROFILE", nil), nil];
    }
    else
    {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                    destructiveButtonTitle:NSLocalizedString(@"OPTION_BLOCK_CONTACT", nil)
                                         otherButtonTitles:NSLocalizedString(@"OPTION_VIEW_PROFILE", nil), nil];
    }
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.tag = 0;
    
    [actionSheet showFromRect:self.view.frame inView:appDelegate.window animated:YES];
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods.

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ( scrollView.tag == 7 ) // Conversation table.
    {
        tableIsScrolling = NO;
        
        if ( shouldReloadTable )
        {
            [_conversationTable reloadData];
            
            shouldReloadTable = NO;
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ( scrollView.tag == 7 ) // Conversation table.
    {
        tableIsScrolling = YES;
        
        if ( scrollView.contentOffset.y <= 0 && shouldLoadMessagesOnScroll && !endOfConversation )
        {
            shouldLoadMessagesOnScroll = NO;
            batchNumber++;
            
            [self loadMessagesForRecipient];
        }
    }
}

#pragma mark -
#pragma mark UITableViewDataSource methods.

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _threads.count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor clearColor];
    cell.backgroundView = [UIView new];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"ThreadCell";
    threadCell = (SHThreadCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if ( threadCell == nil )
    {
        threadCell = [[SHThreadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        threadCell.selectionStyle = UITableViewCellSelectionStyleNone;
        threadCell.frame = CGRectZero;
    }
    
    if ( shouldUseLightTheme )
    {
        threadCell.isLightTheme = YES;
    }
    else
    {
        threadCell.isLightTheme = NO;
    }
    
    if ( _inAdHocMode )
    {
        threadCell.showsDP = YES;
    }
    else
    {
        threadCell.showsDP = NO;
    }
    
    if ( didGainPrivacyMerit )
    {
        threadCell.showsMessageStatus = YES;
    }
    else
    {
        threadCell.showsMessageStatus = NO;
    }
    
    if ( indexPath.row < _threads.count )
    {
        [threadCell populateCellWithData:[_threads objectAtIndex:indexPath.row]];
    }
    
    return threadCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *entry = [_threads objectAtIndex:indexPath.row];
    int entryType = [[entry objectForKey:@"entry_type"] intValue];
    SHThreadType threadType = [[entry objectForKey:@"thread_type"] intValue];
    
    if ( entryType == 1 )
    {
        NSString *messageText = [entry objectForKey:@"message"];
        NSString *mediaHash = [entry objectForKey:@"media_hash"];
        NSData *mediaData = [entry objectForKey:@"media_data"];
        
        if ( mediaHash.length > 1 && [mediaHash intValue] != -1 )
        {
            UIImage *media = [UIImage imageWithData:mediaData];
            
            if ( !media )
            {
                return 149;
            }
            else
            {
                UIImage *thumbnail = [UIImage imageWithData:[entry objectForKey:@"media_thumbnail"]];
                
                float maxWidth = 216;
                
                CGImageRef imageRef = thumbnail.CGImage;
                CGFloat width = CGImageGetWidth(imageRef);
                CGFloat height = CGImageGetHeight(imageRef);
                CGFloat scaleRatio = maxWidth / width;
                
                CGRect bounds = CGRectMake(0, 0, width, height);
                
                if ( width > maxWidth )
                {
                    bounds.size.width = maxWidth;
                    bounds.size.height = height * scaleRatio;
                }
                
                return bounds.size.height + 29; // Account for the height of the message status label.
            }
        }
        else if ( threadType == SHThreadTypeMessageLocation )
        {
            return 241;
        }
        else
        {
            CGSize textSize_messageText = [messageText sizeWithFont:[UIFont systemFontOfSize:16] constrainedToSize:CGSizeMake(216, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
            
            if ( _inAdHocMode )
            {
                return 65 + textSize_messageText.height;
            }
            else
            {
                return 45 + textSize_messageText.height;
            }
        }
    }
    else
    {
        return 44;
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark -
#pragma mark SHGrowingTextViewDelegate methods.

- (void)growingTextViewDidChange:(SHGrowingTextView *)growingTextView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    CGSize messageBoxTextSize = [NSLocalizedString(@"MESSAGES_MESSAGE_BOX_PLACEHOLDER", nil) sizeWithFont:[UIFont systemFontOfSize:16] constrainedToSize:CGSizeMake(211, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    
    if ( _messageBox.text.length > 0 )
    {
        messageBoxTextSize = [_messageBox.text sizeWithFont:[UIFont systemFontOfSize:16] constrainedToSize:CGSizeMake(211, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    }
    
    int x_bubble = appDelegate.screenBounds.size.width - messageBoxTextSize.width - 100;
    
    [UIView animateWithDuration:0.08 delay:0 options:keyboardAnimationCurve animations:^{
        messageBoxBubble.frame = CGRectMake(x_bubble, 10, messageBoxTextSize.width + 48, _messageBox.frame.size.height + 2);
        attachButton.frame = CGRectMake(MIN(5, x_bubble - attachButton.frame.size.width), attachButton.frame.origin.y, attachButton.frame.size.width, attachButton.frame.size.height); // Make sure the button moves away from the expanding message bubble.
    } completion:^(BOOL finished){
        [self scrollViewToBottomForced:YES animated:YES];
    }];
}

- (BOOL)growingTextView:(SHGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // We need to observe the user's typing and synchronize it with the server.
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    currentlyTypedText = _messageBox.text;
    
    if ( !timer_typing )
    {
        SHUserPresenceAudience audience = SHUserPresenceAudienceEveryone;
        
        if ( _inPrivateMode || !appDelegate.preference_Talking )
        {
            audience = SHUserPresenceAudienceRecipient;
        }
        
        [appDelegate.presenceManager setPresence:SHUserPresenceTyping withTargetID:_recipientID forAudience:audience];
        
        timer_typing = [NSTimer scheduledTimerWithTimeInterval:AVG_KEYSTROKE_TIME target:self selector:@selector(inspectCurrentlyTypedText) userInfo:nil repeats:YES];
    }
    
    if ( appDelegate.preference_ReturnKeyToSend )
    {
        if ( [text isEqualToString:@"\n"] )
        {
            [self sendTextMessage];
            
            return NO;
        }
    }
    
    return YES;
}

- (void)growingTextView:(SHGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float difference = (growingTextView.frame.size.height - height);
    
    conversationTableFooter.frame = CGRectMake(0, 0, conversationTableFooter.frame.size.width, conversationTableFooter.frame.size.height - difference);
    _conversationTable.tableFooterView = conversationTableFooter;
    
    [UIView animateWithDuration:0.08 delay:0 options:keyboardAnimationCurve animations:^{
        sendButton.frame = CGRectMake(sendButton.frame.origin.x, sendButton.frame.origin.y - difference, sendButton.frame.size.width, sendButton.frame.size.height);
        attachButton.frame = CGRectMake(attachButton.frame.origin.x, attachButton.frame.origin.y - difference, attachButton.frame.size.width, attachButton.frame.size.height);
        uploadActivityIndicator.frame = CGRectMake(uploadActivityIndicator.frame.origin.x, uploadActivityIndicator.frame.origin.y - difference, uploadActivityIndicator.frame.size.width, uploadActivityIndicator.frame.size.height);
        recipientStatusBubble.frame = CGRectMake(recipientStatusBubble.frame.origin.x, recipientStatusBubble.frame.origin.y - difference, recipientStatusBubble.frame.size.width, recipientStatusBubble.frame.size.height);
    } completion:^(BOOL finished){
        [self scrollViewToBottomForced:YES animated:YES];
    }];
}

- (void)growingTextViewDidBeginEditing:(SHGrowingTextView *)growingTextView
{
    // Scroll to the bottom.
    [self scrollViewToBottomForced:YES animated:YES];
}

#pragma mark -
#pragma mark SHLocationPickerDelegate methods

- (void)locationPickerDidPickVenue:(NSDictionary *)venue
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( _inPrivateMode )
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    }
    else
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }
    
    [self resetView];
    
    if ( venue )
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *detectedCountry = [[[venue objectForKey:@"location"] objectForKey:@"cc"] lowercaseString];
            
            for ( int i = 0; i < appDelegate.contactManager.countryList.count; i++ )
            {
                NSDictionary *country = [appDelegate.contactManager.countryList objectAtIndex:i];
                NSString *countryCode = [[country objectForKey:@"country_code"] lowercaseString];
                
                if ( [countryCode isEqualToString:detectedCountry] )
                {
                    detectedCountry = [country objectForKey:@"name"];
                    
                    break;
                }
            }
            
            __block NSString *threadID = @"-1";
            NSString *entryType = @"1";
            NSString *threadType = [NSString stringWithFormat:@"%d", SHThreadTypeMessageLocation];
            NSString *rootItemID = @"-1";
            NSString *childCount = @"0";
            NSString *ownerID = [appDelegate.currentUser objectForKey:@"user_id"];
            NSString *ownerType = @"1";
            NSString *unreadMessageCount = @"0";
            NSString *groupID = @"-1";
            NSString *status_sent = [NSString stringWithFormat:@"%d", SHThreadStatusSending];
            NSString *status_delivered = @"0";
            NSString *status_read = @"0";
            NSString *timestamp_sent = [appDelegate.modelManager dateTodayString];
            NSString *timestamp_delivered = @"";
            NSString *timestamp_read = @"";
            NSString *message = @"location.";
            NSString *mediaType = @"-1";
            NSString *mediaFileSize = @"-1";
            NSString *mediaLocalPath = @"-1";
            NSString *mediaHash = @"-1";
            id mediaData = @"-1";
            NSMutableDictionary *mediaExtra = [@{@"attachment_type": @"location",
                                                 @"attachment_value": @"venue",
                                                 @"attachment": @{@"venue_name": [venue objectForKey:@"name"],
                                                                  @"venue_id": [venue objectForKey:@"id"],
                                                                  @"venue_country": detectedCountry}} mutableCopy];
            NSString *longitude = [[venue objectForKey:@"location"] objectForKey:@"lng"];
            NSString *latitude = [[venue objectForKey:@"location"] objectForKey:@"lat"];
            NSString *privacy;
            SHUserPresenceAudience audience = SHUserPresenceAudienceEveryone;
            
            if ( _inPrivateMode )
            {
                privacy = [NSString stringWithFormat:@"%d", SHThreadPrivacyPrivate];
                audience = SHUserPresenceAudienceRecipient;
            }
            else
            {
                privacy = [NSString stringWithFormat:@"%d", SHThreadPrivacyPublic];
                
                if ( !appDelegate.preference_Talking )
                {
                    audience = SHUserPresenceAudienceRecipient;
                }
            }
            
            NSMutableDictionary *messageData = [[NSMutableDictionary alloc] initWithObjects:@[entryType,
                                                                                              threadID,
                                                                                              threadType,
                                                                                              rootItemID,
                                                                                              childCount,
                                                                                              ownerID,
                                                                                              ownerType,
                                                                                              _recipientID,
                                                                                              unreadMessageCount,
                                                                                              privacy,
                                                                                              groupID,
                                                                                              status_sent,
                                                                                              status_delivered,
                                                                                              status_read,
                                                                                              timestamp_sent,
                                                                                              timestamp_delivered,
                                                                                              timestamp_read,
                                                                                              message,
                                                                                              longitude,
                                                                                              latitude,
                                                                                              mediaType,
                                                                                              mediaFileSize,
                                                                                              mediaLocalPath,
                                                                                              mediaHash,
                                                                                              mediaData,
                                                                                              mediaExtra]
                                                                                    forKeys:@[@"entry_type",
                                                                                              @"thread_id",
                                                                                              @"thread_type",
                                                                                              @"root_item_id",
                                                                                              @"child_count",
                                                                                              @"owner_id",
                                                                                              @"owner_type",
                                                                                              @"recipient_id",
                                                                                              @"unread_message_count",
                                                                                              @"privacy",
                                                                                              @"group_id",
                                                                                              @"status_sent",
                                                                                              @"status_delivered",
                                                                                              @"status_read",
                                                                                              @"timestamp_sent",
                                                                                              @"timestamp_delivered",
                                                                                              @"timestamp_read",
                                                                                              @"message",
                                                                                              @"location_longitude",
                                                                                              @"location_latitude",
                                                                                              @"media_type",
                                                                                              @"media_file_size",
                                                                                              @"media_local_path",
                                                                                              @"media_hash",
                                                                                              @"media_data",
                                                                                              @"media_extra"]];
            
            NSData *data = [NSJSONSerialization dataWithJSONObject:mediaExtra options:NSJSONWritingPrettyPrinted error:nil];
            [messageData setObject:data forKey:@"media_extra"];
            
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
            [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                [db executeUpdate:@"INSERT INTO sh_thread "
                                    @"(thread_type, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                                    @"VALUES (:thread_type, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent, :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                        withParameterDictionary:messageData];
                
                // Get the insert ID & use it in the dispatch table.
                FMResultSet *s1 = [db executeQuery:@"SELECT thread_id FROM sh_thread ORDER BY timestamp_sent DESC LIMIT 1"
                           withParameterDictionary:nil];
                
                while ( [s1 next] )
                {
                    threadID = [s1 stringForColumnIndex:0];
                    [messageData setObject:threadID forKey:@"thread_id"];
                }
                
                [s1 close];
                
                [db executeUpdate:@"INSERT INTO sh_message_dispatch "
                                    @"(thread_id, sender_id, sender_type, recipient_id, timestamp) "
                                    @"VALUES (:thread_id, :owner_id, :owner_type, :recipient_id, :timestamp_sent)"
                        withParameterDictionary:messageData];
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [self sendMessage:messageData forAudience:audience];
                });
            }];
        });
    }
}

- (void)locationPickerDidPickCurrentLocation
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( _inPrivateMode )
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    }
    else
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }
    
    [self resetView];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block NSString *threadID = @"-1";
        NSString *entryType = @"1";
        NSString *threadType = [NSString stringWithFormat:@"%d", SHThreadTypeMessageLocation];
        NSString *rootItemID = @"-1";
        NSString *childCount = @"0";
        NSString *ownerID = [appDelegate.currentUser objectForKey:@"user_id"];
        NSString *ownerType = @"1";
        NSString *unreadMessageCount = @"0";
        NSString *groupID = @"-1";
        NSString *status_sent = [NSString stringWithFormat:@"%d", SHThreadStatusSending];
        NSString *status_delivered = @"0";
        NSString *status_read = @"0";
        NSString *timestamp_sent = [appDelegate.modelManager dateTodayString];
        NSString *timestamp_delivered = @"";
        NSString *timestamp_read = @"";
        NSString *message = @"location.";
        NSString *mediaType = @"-1";
        NSString *mediaFileSize = @"-1";
        NSString *mediaLocalPath = @"-1";
        NSString *mediaHash = @"-1";
        id mediaData = @"-1";
        NSMutableDictionary *mediaExtra = [@{@"attachment_type": @"location",
                                             @"attachment_value": @"current_location"} mutableCopy];
        NSString *longitude = [NSString stringWithFormat:@"%f", appDelegate.locationManager.currentLocation.longitude];
        NSString *latitude = [NSString stringWithFormat:@"%f", appDelegate.locationManager.currentLocation.latitude];
        NSString *privacy;
        SHUserPresenceAudience audience = SHUserPresenceAudienceEveryone;
        
        if ( _inPrivateMode )
        {
            privacy = [NSString stringWithFormat:@"%d", SHThreadPrivacyPrivate];
            audience = SHUserPresenceAudienceRecipient;
        }
        else
        {
            privacy = [NSString stringWithFormat:@"%d", SHThreadPrivacyPublic];
            
            if ( !appDelegate.preference_Talking )
            {
                audience = SHUserPresenceAudienceRecipient;
            }
        }
        
        if ( appDelegate.locationManager.currentLocation.latitude == 9999 ) // When location fails.
        {
            longitude = @"";
            latitude = @"";
        }
        
        NSMutableDictionary *messageData = [[NSMutableDictionary alloc] initWithObjects:@[entryType,
                                                                                          threadID,
                                                                                          threadType,
                                                                                          rootItemID,
                                                                                          childCount,
                                                                                          ownerID,
                                                                                          ownerType,
                                                                                          _recipientID,
                                                                                          unreadMessageCount,
                                                                                          privacy,
                                                                                          groupID,
                                                                                          status_sent,
                                                                                          status_delivered,
                                                                                          status_read,
                                                                                          timestamp_sent,
                                                                                          timestamp_delivered,
                                                                                          timestamp_read,
                                                                                          message,
                                                                                          longitude,
                                                                                          latitude,
                                                                                          mediaType,
                                                                                          mediaFileSize,
                                                                                          mediaLocalPath,
                                                                                          mediaHash,
                                                                                          mediaData,
                                                                                          mediaExtra]
                                                                                forKeys:@[@"entry_type",
                                                                                          @"thread_id",
                                                                                          @"thread_type",
                                                                                          @"root_item_id",
                                                                                          @"child_count",
                                                                                          @"owner_id",
                                                                                          @"owner_type",
                                                                                          @"recipient_id",
                                                                                          @"unread_message_count",
                                                                                          @"privacy",
                                                                                          @"group_id",
                                                                                          @"status_sent",
                                                                                          @"status_delivered",
                                                                                          @"status_read",
                                                                                          @"timestamp_sent",
                                                                                          @"timestamp_delivered",
                                                                                          @"timestamp_read",
                                                                                          @"message",
                                                                                          @"location_longitude",
                                                                                          @"location_latitude",
                                                                                          @"media_type",
                                                                                          @"media_file_size",
                                                                                          @"media_local_path",
                                                                                          @"media_hash",
                                                                                          @"media_data",
                                                                                          @"media_extra"]];
        
        NSString *base64_userThumbnail = [[appDelegate.currentUser objectForKey:@"dp"] base64Encoding];
        
        NSDictionary *attachmentData = @{@"user_thumbnail": base64_userThumbnail};
        [mediaExtra setObject:attachmentData forKey:@"attachment"];
        NSData *data = [NSJSONSerialization dataWithJSONObject:mediaExtra options:NSJSONWritingPrettyPrinted error:nil];
        [messageData setObject:data forKey:@"media_extra"];
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [db executeUpdate:@"INSERT INTO sh_thread "
                                @"(thread_type, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                                @"VALUES (:thread_type, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent, :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                    withParameterDictionary:messageData];
            
            // Get the insert ID & use it in the dispatch table.
            FMResultSet *s1 = [db executeQuery:@"SELECT thread_id FROM sh_thread ORDER BY timestamp_sent DESC LIMIT 1"
                       withParameterDictionary:nil];
            
            while ( [s1 next] )
            {
                threadID = [s1 stringForColumnIndex:0];
                [messageData setObject:threadID forKey:@"thread_id"];
            }
            
            [s1 close];
            
            [db executeUpdate:@"INSERT INTO sh_message_dispatch "
                                @"(thread_id, sender_id, sender_type, recipient_id, timestamp) "
                                @"VALUES (:thread_id, :owner_id, :owner_type, :recipient_id, :timestamp_sent)"
                    withParameterDictionary:messageData];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self sendMessage:messageData forAudience:audience];
            });
        }];
    });
}

- (void)locationPickerDidCancel
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( _inPrivateMode )
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    }
    else
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }
    
    [appDelegate.presenceManager setPresence:SHUserPresenceActivityStopped withTargetID:_recipientID forAudience:SHUserPresenceAudienceEveryone];
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( actionSheet.tag == 0 ) // Recipient options.
    {
        if ( buttonIndex == 0 ) // Block.
        {
            [appDelegate.contactManager blockContact:_recipientID];
            
            [appDelegate.mainMenu showMainWindowSide];
            [appDelegate.mainMenu closeCurrentChat];
        }
        else if ( buttonIndex == 1 ) // Call/Show profile
        {
            if ( showsPhoneNumber )
            {
                UIDevice *device = [UIDevice currentDevice];
                
                if ([[device model] isEqualToString:@"iPhone"] )
                {
                    // For now, we're just going to use the first phone number in the array.
                    NSDictionary *firstPhoneNumber = [[_recipientDataChunk objectForKey:@"phone_numbers"] firstObject];
                    NSString *phoneNumber = [NSString stringWithFormat:@"+%@%@%@", [firstPhoneNumber objectForKey:@"country_calling_code"], [firstPhoneNumber objectForKey:@"prefix"], [firstPhoneNumber objectForKey:@"phone_number"]];
                    
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
            else
            {
                [self showProfileForRecipient];
            }
        }
        else if ( buttonIndex == 2 ) // Profile
        {
            if ( showsPhoneNumber )
            {
                [self showProfileForRecipient];
            }
        }
    }
    else if ( actionSheet.tag == 1 ) // Phone number options.
    {
        if ( buttonIndex == 0 ) // Call
        {
            UIDevice *device = [UIDevice currentDevice];
            
            if ([[device model] isEqualToString:@"iPhone"] )
            {
                NSString *phoneNumber = actionSheet.title;
                NSCharacterSet *notAllowedChars = [[NSCharacterSet characterSetWithCharactersInString:@"+1234567890"] invertedSet];
                phoneNumber = [[phoneNumber componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
                phoneNumber = [phoneNumber stringByTrimmingLeadingWhitespace];  // Needs to be a URL, so no spaces.
                
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", phoneNumber]]];
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
        else if ( buttonIndex == 1 ) // Copy
        {
            [[UIPasteboard generalPasteboard] setString:actionSheet.title];
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
}

@end
