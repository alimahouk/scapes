//
//  MainMenuViewController.h
//  Scapes
//
//  Created by MachOSX on 8/3/13.
//
//

#import <AddressBook/AddressBook.h>

#import "SHContactCloud.h"
#import "SHContactManager.h"
#import "SHMessageManager.h"
#import "SHMiniFeedCell.h"
#import "SHPresenceManager.h"
#import "MBProgressHUD.h"
#import "MessagesViewController.h"

@interface MainMenuViewController : UIViewController <MBProgressHUDDelegate, SHContactManagerDelegate, SHPresenceManagerDelegate, SHMessageManagerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate, SHContactCloudDelegate, SHChatBubbleDelegate, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, UITextFieldDelegate>
{
    UIImagePickerController *photoPicker;
    MBProgressHUD *HUD;
    UIButton *searchCancelButton;
    UIButton *settingsButton;
    UIButton *inviteButton;
    SHChatBubble *activeBubble; // When the user taps & holds one.
    UILabel *contactCloudInfoLabel;
    CAGradientLayer *maskLayer_ContactCloud;
    CAGradientLayer *maskLayer_MiniFeed;
    UIRefreshControl *SHMiniFeedrefreshControl;
    SHMiniFeedCell *miniFeedCell;
    UITableViewCell *miniFeedLoadMoreCell;
    UITextField *searchBox;
    UITapGestureRecognizer *gesture_mainWindowTap;
    NSIndexPath *activeMiniFeedIndexPath; // When the user taps & holds one.
    ABAddressBookRef addressBook;
    NSTimer *timer_timeOfDayCheck;
    NSTimer *timer_miniFeedRefresh;
    NSTimer *timer_miniFeedRefreshResume;
    NSArray *randomQuotes;
    NSString *wallpaperImageName;
    CGPoint activeRecipientBubblePanCoordinate;
    BOOL wallpaperShouldAnimate;
    BOOL wallpaperIsAnimatingRight;
    BOOL wallpaperDidChange_dawn;
    BOOL wallpaperDidChange_day;
    BOOL wallpaperDidChange_dusk;
    BOOL wallpaperDidChange_night;
    BOOL isShowingSearchInterface;
    BOOL isShowingNewPeerNotification;
    BOOL miniFeedRefreshDidFailOnScroll;
    BOOL endOfMiniFeed;
    BOOL userDidGrantAddressBookAccess;
    int currentUnreadBadgeCycle;
    int batchNumber;
}

@property (nonatomic) MessagesViewController *messagesView;
@property (nonatomic) SHProfileViewController *profileView;
@property (nonatomic) UIView *mainWindowContainer;
@property (nonatomic) UIView *SHMiniFeedContainer;
@property (nonatomic) UIImageView *wallpaper;
@property (nonatomic) UIImageView *mainWindowNipple;
@property (nonatomic) UITableView *SHMiniFeed;
@property (nonatomic) UIScrollView *windowCompositionLayer;
@property (nonatomic) UIButton *searchButton;
@property (nonatomic) UIButton *createBoardButton;
@property (nonatomic) UIButton *refreshButton;
@property (nonatomic) UIButton *cloudCenterButton;
@property (nonatomic) UIButton *unreadBadgeButton;
@property (nonatomic) SHContactCloud *contactCloud;
@property (nonatomic) SHChatBubble *activeRecipientBubble; // The currently active conversation.
@property (nonatomic) NSMutableArray *SHMiniFeedEntries;
@property (nonatomic) NSMutableArray *unreadThreadBubbles;
@property (nonatomic) BOOL wallpaperIsAnimating;
@property (nonatomic) BOOL didDownloadInitialFeed;
@property (nonatomic) BOOL miniFeedDidFinishDownloading;
@property (nonatomic) BOOL mediaPickerSourceIsCamera;
@property (nonatomic) BOOL isRenamingContact;
@property (nonatomic) BOOL isPickingAliasDP;
@property (nonatomic) BOOL isPickingDP;
@property (nonatomic) BOOL isPickingMedia;

- (void)setup;

// Live Wallpaper
- (void)startWallpaperAnimation;
- (void)resumeWallpaperAnimation;
- (void)stopWallpaperAnimation;
- (void)startTimeOfDayCheck;
- (void)pauseTimeOfDayCheck;
- (void)checkTimeOfDay;

- (void)enableCompositionLayerScrolling;
- (void)disableCompositionLayerScrolling;
- (void)dismissWindow;
- (void)hideMainWindowSide;
- (void)showMainWindowSide;
- (void)pushWindow:(SHAppWindowType)windowType;
- (void)restoreCurrentProfileBubble;
- (void)showUserProfile;
- (void)showBoardForID:(NSString *)boardID;
- (void)showBoardCreator;

// CHat Cloud
- (void)showRenamingInterfaceForBubble:(SHChatBubble *)bubble;
- (void)dismissRenamingInterface;
- (void)showSearchInterface;
- (void)dismissSearchInterface;
- (void)showChatCloudCenterJumpButton;
- (void)dismissChatCloudCenterJumpButton;
- (void)jumpToChatCloudCenter;
- (void)confirmContactDeletion;
- (void)confirmHistoryDeletion;
- (void)searchChatCloudForQuery:(NSString *)query;
- (void)showEmptyCloud;
- (void)updateUnreadBadge:(int)count;
- (void)addBubbleToUnreadQueue:(SHChatBubble *)bubble;
- (void)removeBubbleWithUserIDFromUnreadQueue:(NSString *)userID;
- (void)cycleUnreadThreads;
- (void)slideUIForWindow;

- (void)showInvitationOptions;
- (void)showNewPeerNotification;

- (void)loadConversationForUser:(NSString *)userID;

// Media Picker
- (void)showMediaPicker_Camera;
- (void)showMediaPicker_Library;
- (void)dismissMediaPicker;

// Contacts & Boards
- (void)loadCloud;
- (void)refreshContacts;
- (void)refreshCloud;
- (void)removeBoard:(NSString *)boardID;
- (void)hideContact:(NSString *)userID;

// Mini Feed
- (void)scrollToTopOfMiniFeed;
- (void)downloadMiniFeed;
- (void)refreshMiniFeed;
- (void)beginMiniFeedRefreshCycle;
- (void)pauseMiniFeedRefreshCycle;
- (void)resumeMiniFeedRefreshCycle;
- (void)deleteFeedStatus;
- (void)muteUpdatesForUser:(NSString *)userID;

// For listening to keystrokes on any UITextField.
- (void)textFieldDidChange:(id)sender;

// Gesture handling.
- (void)userDidTapAndHoldProfileButton:(UILongPressGestureRecognizer *)longPress;
- (void)userDidTapAndHoldMiniFeedRow:(UILongPressGestureRecognizer *)longPress;
- (void)userDidDragActiveRecipientBubble:(UIPanGestureRecognizer *)drag;

- (void)closeCurrentChat;

- (void)setMaxMinZoomScalesForChatCloudBounds;

@end
