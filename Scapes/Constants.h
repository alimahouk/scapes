//
//  Constants.h
//  Scapes
//
//  Created by Ali Razzouk on 31/7/13.
//  Copyright (c) 2013 Scapehouse. All rights reserved.
//

#ifndef SHConstants_h
#define SHConstants_h

/*  --------------------------------------------
    ---------- Runtime Environment -------------
    --------------------------------------------
 */

#define SH_DEVELOPMENT_ENVIRONMENT      NO
#define IS_IOS7                         kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_6_1

/*  ---------------------------------------------
    ------------------- API ---------------------
    ---------------------------------------------
 */

#define SH_DOMAIN                               @"scapehouse.com" // scapehouse.dlinkddns.com:2703
#define SH_PORT                                 5222 // Old: 4244
#define SH_PORT_SANDBOX                         5157
#define DB_TEMPLATE_NAME                        @"default_template.sqlite"
#define INIT_TOKEN                              @"54f01568a9e6d50e9190a1e21b1800445585d427"
#define SH_UUID                                 @"51234a40-aead-11e4-891b-0002a5d5c51b"
#define MAX_POST_LENGTH                         4000
#define MAX_MSG_LENGTH                          4000
#define MAX_BIO_LENGTH                          140
#define MAX_STATUS_UPDATE_LENGTH                140
#define MAX_DEFAULT_PASSCODE_ATTEMPTS           6
#define NETWORK_CONNECTION_ATTEMPT_TIMEOUT      5
#define NETWORK_CONNECTION_TIMEOUT              7   // Seconds.
#define MESSAGE_TIMEOUT                         7   // Seconds.
#define FEED_BATCH_SIZE                         15
#define MERIT_MESSAGE_THRESHOLD                 15
#define REVIEW_NAG_THRESHOLD                    20
#define CONVERSATION_BATCH_SIZE                 20
#define DEFAULT_WALLPAPER                       @"chat_wallpaper_8.jpg"

/*  ---------------------------------------------
    ---------- Application Interface ------------
    ---------------------------------------------
 */

#define RADIANS_TO_DEGREES(radians)             ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle)               ((angle) / 180.0 * M_PI)

// Fonts
#define MAIN_FONT_SIZE                          18
#define MIN_MAIN_FONT_SIZE                      15
#define SECONDARY_FONT_SIZE                     12
#define MIN_SECONDARY_FONT_SIZE                 10

// Chat Cloud
#define CHAT_CLOUD_BUBBLE_SIZE                  80
#define CHAT_CLOUD_BUBBLE_SIZE_MINI             36
#define CHAT_CLOUD_BUBBLE_PADDING               10
#define WEIGHT_VIEWS                            0.1
#define WEIGHT_MESSAGES_SENT                    0.3
#define WEIGHT_MESSAGES_RECEIVED                0.2
#define WEIGHT_MEDIA_SENT                       0.6
#define WEIGHT_MEDIA_RECEIVED                   0.4
#define PARALLAX_DEPTH_HEAVY                    15.0
#define PARALLAX_DEPTH_LIGHT                    8.0
#define PREVIEW_BUBBLE_DURATION                 5.0

#define MEDIA_GALLERY_PREVIEW_SIZE              105

// Messages View
#define MESSAGE_BOX_MAX_HEIGHT                  150
#define AVG_KEYSTROKE_TIME                      1.2

typedef enum {
    SHStrobeLightPositionFullScreen = 1,
    SHStrobeLightPositionStatusBar,
    SHStrobeLightPositionNavigationBar
} SHStrobeLightPosition;

typedef enum {
    SHAppWindowTypeMessages = 1,
    SHAppWindowTypeProfile
} SHAppWindowType;

typedef enum {
    SHChatBubbleTypeUser = 1,
    SHChatBubbleTypeBoard
} SHChatBubbleType;

typedef enum {
    SHPasscodeWindowModeAuthenticate = 1,
    SHPasscodeWindowModeDismissableAuthenticate,
    SHPasscodeWindowModeFreshPasscode,
    SHPasscodeWindowModeChangePasscode
} SHPasscodeWindowMode;

typedef enum {
    SHNetworkStateConnected = 1,
    SHNetworkStateConnecting,
    SHNetworkStateOffline
} SHNetworkState;

typedef enum {
    SHPeerRangeNear = 1,
    SHPeerRangeFar,
    SHPeerRangeImmediate,
    SHPeerRangeUnknown
} SHPeerRange;

typedef enum {
    SHChatBubbleOrientationLowerRightBelow = 0,
    SHChatBubbleOrientationLowerRight,
    SHChatBubbleOrientationLowerRightDiagonal,
    SHChatBubbleOrientationLowerLeftBelow,
    SHChatBubbleOrientationLowerLeft,
    SHChatBubbleOrientationLowerLeftDiagonal,
    SHChatBubbleOrientationUpperRightAbove,
    SHChatBubbleOrientationUpperRight,
    SHChatBubbleOrientationUpperRightDiagonal,
    SHChatBubbleOrientationUpperLeftAbove,
    SHChatBubbleOrientationUpperLeft,
    SHChatBubbleOrientationUpperLeftDiagonal
} SHChatBubbleOrientation;

typedef enum {
    SHThreadTypeMessageRemoteUser = 1,
    SHThreadTypeMessageCurrentUser,
    SHThreadTypeStatusRemoteUser,
    SHThreadTypeStatusCurrentUser
} SHThreadClass;

typedef enum {
    SHUserTypeRemoteUser = 1,
    SHUserTypeCurrentUser,
    SHUserTypeBot,
} SHUserType;

typedef enum {
    SHMediaTypePhoto = 1,
    SHMediaTypeMovie,
    SHMediaTypeNone
} SHMediaType;

typedef enum {
    SHChatBubbleTypingIndicatorDirectionRight = 1,
    SHChatBubbleTypingIndicatorDirectionLeft
} SHChatBubbleTypingIndicatorDirection;

typedef enum {
    SHUserPresenceOffline = 1,
    SHUserPresenceOnline,
    SHUserPresenceOnlineMasked,
    SHUserPresenceAway,
    SHUserPresenceTyping,
    SHUserPresenceActivityStopped,
    SHUserPresenceSendingPhoto,
    SHUserPresenceSendingVideo,
    SHUserPresenceAudio,
    SHUserPresenceLocation,
    SHUserPresenceContact,
    SHUserPresenceFile,
    SHUserPresenceCheckingLink,
    SHUserPresenceOfflineMasked,
} SHUserPresence;

typedef enum {
    SHUserPresenceAudienceEveryone = 1,
    SHUserPresenceAudienceRecipient,
    SHUserPresenceAudienceContacts
} SHUserPresenceAudience;

typedef enum {
    SHThreadTypeMessage = 1,
    SHThreadTypeStatusText,
    SHThreadTypeStatusLocation,
    SHThreadTypeStatusSong,
    SHThreadTypeStatusDP,
    SHThreadTypeStatusProfileChange,
    SHThreadTypeStatusJoin,
    SHThreadTypeMessageLocation
} SHThreadType;

typedef enum {
    SHThreadStatusSent = 1,
    SHThreadStatusSending,
    SHThreadStatusDelivered,
    SHThreadStatusRead,
    SHThreadStatusSendingFailed,
    SHThreadStatusDeleted
} SHThreadStatus;

typedef enum {
    SHThreadOwnerUser = 1,
    SHThreadOwnerBot
} SHThreadOwner;

typedef enum {
    SHThreadPrivacyPrivate = 1,
    SHThreadPrivacyPublic
} SHThreadPrivacy;

typedef enum {
    SHPrivacySettingPublic = 1,
    SHPrivacySettingPrivate
} SHPrivacySetting;

typedef enum {
    SHPostColorWhite = 1,
    SHPostColorRed,
    SHPostColorGreen,
    SHPostColorBlue,
    SHPostColorPink,
    SHPostColorYellow
} SHPostColor;

typedef enum {
    SHRecipientPickerModeBoardRequests = 1,
    SHRecipientPickerModeBoardMembers,
    SHRecipientPickerModeFollowing,
    SHRecipientPickerModeFollowers,
    SHRecipientPickerModeRecipients,
    SHRecipientPickerModeHidden,
    SHRecipientPickerModeBlocked,
    SHRecipientPickerModeAddByUsername
} SHRecipientPickerMode;

typedef enum {
    SHProfileViewModeViewing = 1,
    SHProfileViewModeAcceptRequest
} SHProfileViewMode;

typedef enum {
    SHLicenseTrial = 1,
    SHLicenseAnnual,
    SHLicenseLifetime
} SHLicense;

typedef void (^RequestProductsCompletionHandler)(BOOL success, NSArray * products);

#endif