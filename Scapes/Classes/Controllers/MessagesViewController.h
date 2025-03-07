//
//  MessagesViewController.h
//  Scapes
//
//  Created by MachOSX on 8/3/13.
//
//

#import "MBProgressHUD.h"
#import "SHChatBubble.h"
#import "SHGrowingTextView.h"
#import "SHLocationPicker.h"
#import "SHMessageManager.h"
#import "SHPresenceManager.h"
#import "SHRecipientPickerViewController.h"
#import "SHThreadCell.h"

@interface MessagesViewController : UIViewController <MBProgressHUDDelegate, SHChatBubbleDelegate, SHLocationPickerDelegate, SHRecipientPickerDelegate, SHGrowingTextViewDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>
{
    MBProgressHUD *HUD;
    UIView *hood;
    UIView *attachmentsPanel;
    UIView *conversationTableFooter;
    UIScrollView *attachmentsScrollView;
    UIScrollView *participantsPane;
    UIToolbar *attachmentsPanel_toolbar;
    UIActivityIndicatorView *uploadActivityIndicator;
    UIImageView *messageBoxBubble;
    UIImageView *messageBoxBubbleImagePreview;
    UIImageView *backButtonBadge;
    UIImageView *lastPhotoTakenPreview;
    UIBarButtonItem *leftButtonItem;
    UIButton *backButton;
    UIButton *sendButton;
    UIButton *recipientStatusBubble;
    UIButton *attachButton;
    UIButton *attachButton_camera;
    UIButton *attachButton_library;
    UIButton *attachButton_lastPhoto;
    UIButton *attachButton_location;
    UIButton *attachButton_contact;
    UIButton *attachButton_file;
    UIButton *widgetButton;
    UIButton *addParticipantButton;
    UILabel *backButtonBadgeLabel;
    UILabel *connectionStatusLabel;
    UILabel *headerNameLabel;
    UILabel *headerStatusLabel;
    UILabel *recipientStatusBubbleLabel;
    UILabel *attachLabel_camera;
    UILabel *attachLabel_library;
    UILabel *attachLabel_lastPhoto;
    UILabel *attachLabel_location;
    UILabel *attachLabel_contact;
    UILabel *attachLabel_file;
    UILabel *privacyToggleLabel;
    UISwitch *privacyToggle;
    SHThreadCell *threadCell;
    UIImage *lastPhotoTaken;
    CGSize keyboardSize;
    CGFloat keyboardAnimationDuration;
    UIViewAnimationOptions keyboardAnimationCurve;
    NSMutableArray *participants;
    NSString *recipientName_first;
    NSString *recipientName_last;
    NSString *recipientName_alias;
    NSMutableArray *activeMediaUploadRecipients; // If a media upload occurs, this holds the ID of the original recipient.
    NSMutableArray *processedMediaUploads;
    NSDateFormatter *dateFormatter;
    NSTimer *timer_timestamps;
    NSTimer *timer_typing;
    NSString *currentlyTypedText;
    SHUserPresence recipientCurrentPresence;
    NSString *presenceTimestampString;
    NSDate *presenceTimestampDate;
    int batchNumber;
    BOOL showsPhoneNumber;
    BOOL isShowingExactLastSeenTime;
    BOOL didPlayTutorial_Privacy;
    BOOL didGainPrivacyMerit;
    BOOL endOfConversation;
    BOOL tableIsScrolling;
    BOOL shouldReloadTable;
    BOOL isSendingMedia;
    BOOL UIShouldSlideDown;
    BOOL shouldLoadMessagesOnScroll;
    BOOL shouldShowAttachmentsPanel;
    BOOL shouldUseLightTheme;
    BOOL canSendAcknowledgement;
    BOOL didAnimateAcknowledgementIcon;
}

@property (nonatomic) UIView *tableContainer;
@property (nonatomic) UIImageView *wallpaper;
@property (nonatomic) UIImageView *tableSideShadow;
@property (nonatomic) UITableView *conversationTable;
@property (nonatomic) SHChatBubble *recipientBubble;
@property (nonatomic) SHGrowingTextView *messageBox;
@property (nonatomic) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic) NSMutableDictionary *recipientDataChunk;
@property (nonatomic) NSMutableArray *initialMessagesFetchedIDs;
@property (nonatomic) NSMutableArray *threads;
@property (nonatomic) NSString *recipientID;
@property (nonatomic) NSSet *adHocTag;
@property (nonatomic) BOOL keyboardIsShown;
@property (nonatomic) BOOL attachmentsPanelIsShown;
@property (nonatomic) BOOL inAdHocMode;
@property (nonatomic) BOOL inPrivateMode;

- (void)enterLandscapeFullscreen;
- (void)exitLandscapeFullscreen;
- (void)presentMainMenu;
- (void)showWebBrowserForURL:(NSString *)URL reportEndOfActivity:(BOOL)shouldReportEndOfActivity;
- (void)showGalleryForMedia:(id)media atPath:(NSString *)path;
- (void)showMapForLocation:(NSDictionary *)location;
- (void)updateMenuButtonBadgeCount:(int)count;

- (void)didToggleSwitch:(id)sender;

// Attachments.
- (void)showAttachmentOptions;
- (void)showOptionsForTappedPhoneNumber:(NSString *)phoneNumber;
- (void)media_UseLastPhotoTaken;
- (void)media_Camera;
- (void)media_Library;
- (void)attachLocation;

// Messages.
- (void)fetchLatestMessageState;
- (void)loadMessagesForRecipient;
- (void)sendTextMessage;
- (void)sendMessage:(NSMutableDictionary *)message forAudience:(SHUserPresenceAudience)audience;
- (void)deleteThreadAtIndexPath:(NSIndexPath *)indexPath deletionConfirmed:(BOOL)confirmed;
- (void)resendMessageAtIndexPath:(NSIndexPath *)indexPath;
- (void)redownloadMediaFromSender:(NSString *)senderID atIndexPath:(NSIndexPath *)indexPath;
- (void)receivedMessage:(NSDictionary *)messageData;
- (void)receivedMessageBatch:(NSMutableArray *)messages;
- (void)receivedStatusUpdate:(NSDictionary *)statusData fresh:(BOOL)fresh;
- (void)didFetchMessageStateForCurrentRecipient:(NSMutableArray *)messages;
- (void)didFetchPresenceForCurrentRecipient:(NSDictionary *)presenceData;
- (void)markMessagesAsRead;
- (void)message:(NSDictionary *)messageData statusDidChange:(SHThreadStatus)status;
- (void)beginMediaUploadWithMedia:(id)media;
- (void)cancelMediaUpload;
- (void)didUploadMediaForRecipient:(NSString *)recipient withHash:(NSString *)hash;

// Presence.
- (void)currentUserPresenceDidChange;
- (void)presenceDidChange:(SHUserPresence)presence time:(NSString *)timestamp forRecipientWithTargetID:(NSString *)presenceTargetID forAudience:(SHUserPresenceAudience)audience withDB:(FMDatabase *)db;

// UI.
- (void)titleButtonHighlighted;
- (void)resetHeaderLabels;
- (void)updateNetworkConnectionStatusLabel;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillBeHidden:(NSNotification *)notification;
- (void)slideUIUp;
- (void)slideUIDown;
- (void)updateMessagingInterfaceWithImage:(UIImage *)image;
- (void)redrawViewForStatusBar:(CGRect)oldStatusBarFrame;
- (void)resetView;
- (void)resetMessagingInterface;
- (void)clearViewAnimated:(BOOL)animated;
- (void)scrollViewToBottomForced:(BOOL)forced animated:(BOOL)animated;
- (void)setCurrentWallpaper:(UIImage *)theWallpaper;

// Recipients.
- (void)addParticipant;
- (void)privacyDidChange:(SHThreadPrivacy)newPrivacy;
- (void)setAdHocMode:(BOOL)adHocMode withOriginalRecipients:(NSSet *)originalRecipients;
- (void)setPrivateMode:(BOOL)privateMode withServerSync:(BOOL)shouldSync;
- (void)setRecipientDataForUser:(NSString *)userID;
- (void)setRecipientPresence:(NSDictionary *)presenceData withDB:(FMDatabase *)db;
- (void)setRecipientName:(NSString *)name;
- (void)setRecipientStatus:(NSString *)status;
- (void)showProfileForRecipient;
- (void)showDPOverlay;
- (void)dismissDPOverlay;
- (void)exportDP;

// Realtime timestamps.
- (void)updateTimestamps;
- (void)cancelTimestampUpdates;
- (void)resumeTimestampUpdates;

- (void)showExactLastSeenTime;

- (void)inspectCurrentlyTypedText;
- (void)cancelTypingUpdates;

// Tutorials.
- (void)playPrivacyTutorial;

- (void)showNetworkError;

@end
