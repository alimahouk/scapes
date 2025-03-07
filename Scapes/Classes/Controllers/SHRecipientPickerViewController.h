//
//  SHRecipientPickerViewController.h
//  Nightboard
//
//  Created by MachOSX on 11/18/13.
//
//

#import "SHChatBubble.h"
#import "SHContactCloud.h"
#import "SHContactManager.h"
#import "SHProfileViewController.h"

@class SHRecipientPicker;

@protocol SHRecipientPickerDelegate<NSObject>
@optional

- (void)recipientPickerDidSelectRecipient:(NSMutableDictionary *)recipient;

@end

@interface SHRecipientPickerViewController : UIViewController <MBProgressHUDDelegate, SHContactCloudDelegate, UIScrollViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UITextFieldDelegate>
{
    MBProgressHUD *HUD;
    UIImagePickerController *photoPicker;
    UIView *usernamePanel;
    UIImageView *usernameFieldBG;
    UIButton *dismissViewButton;
    UIButton *searchCancelButton;
    SHChatBubble *DPPreview;
    SHChatBubble *activeBubble; // When the user taps & holds one.
    UITextField *searchBox;
    UITextField *usernameField;
    UILabel *contactCloudInfoLabel;
    UILabel *atSignLabel;
    CAGradientLayer *maskLayer_contactCloud;
    NSTimer *timer_timeOfDayCheck;
    NSString *wallpaperImageName;
    BOOL wallpaperIsAnimating;
    BOOL wallpaperShouldAnimate;
    BOOL wallpaperIsAnimatingRight;
    BOOL wallpaperDidChange_dawn;
    BOOL wallpaperDidChange_day;
    BOOL wallpaperDidChange_dusk;
    BOOL wallpaperDidChange_night;
    BOOL isShowingSearchInterface;
}

@property (nonatomic, weak) id <SHRecipientPickerDelegate> delegate;
@property (nonatomic) SHOrientationNavigationController *mainWindowNavigationController;
@property (nonatomic) SHProfileViewController *profileView;
@property (nonatomic) SHContactCloud *contactCloud;
@property (nonatomic) UIView *mainWindowContainer;
@property (nonatomic) UIImageView *windowSideShadow;
@property (nonatomic) UIScrollView *windowCompositionLayer;
@property (nonatomic) UIImageView *wallpaper;
@property (nonatomic) UIButton *searchButton;
@property (nonatomic) UIButton *cloudCenterButton;
@property (nonatomic) NSString *userID;
@property (nonatomic) NSString *boardID;
@property (nonatomic) SHRecipientPickerMode mode;
@property (nonatomic) SHAppWindowType activeWindow;
@property (nonatomic) BOOL wallpaperIsAnimating;
@property (nonatomic) BOOL shouldEnterFullscreen;
@property (nonatomic) BOOL isFullscreen;
@property (nonatomic) BOOL mediaPickerSourceIsCamera;
@property (nonatomic) BOOL isPickingAliasDP;
@property (nonatomic) BOOL isPickingDP;
@property (nonatomic) BOOL showsBackButton;

- (id)initInMode:(SHRecipientPickerMode)mode;

- (void)dismissView;

// Live Wallpaper
- (void)startWallpaperAnimation;
- (void)resumeWallpaperAnimation;
- (void)stopWallpaperAnimation;
- (void)startTimeOfDayCheck;
- (void)pauseTimeOfDayCheck;
- (void)checkTimeOfDay;

- (void)dismissWindow;
- (void)pushWindow:(SHAppWindowType)window;
- (void)restoreCurrentProfileBubble;
- (void)showUserProfile;

// CHat Cloud
- (void)showSearchInterface;
- (void)dismissSearchInterface;
- (void)showChatCloudCenterJumpButton;
- (void)dismissChatCloudCenterJumpButton;
- (void)jumpToChatCloudCenter;
- (void)searchChatCloudForQuery:(NSString *)query;
- (void)showEmptyCloud;

// Contacts & Boards
- (void)loadCloud;
- (void)removeBubbleForUser:(NSString *)userID;

- (void)loadRequests;
- (void)processRequests:(NSArray *)requests;

- (void)loadBoardMembers;
- (void)processBoardMembers:(NSArray *)members;

- (void)loadFollowing;
- (void)loadFollowers;
- (void)processPeople:(NSArray *)people;

- (void)confirmContactAddition;

// For listening to keystrokes on any UITextField.
- (void)textFieldDidChange:(id)sender;

- (void)setMaxMinZoomScalesForChatCloudBounds;

- (void)showNetworkError;

@end
