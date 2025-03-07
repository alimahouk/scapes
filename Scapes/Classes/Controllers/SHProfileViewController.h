//
//  SHProfileViewController.h.h
//  Nightboard
//
//  Created by MachOSX on 8/20/13.
//
//

#import "MBProgressHUD.h"
#import "SHChatBubble.h"
#import "SHMessageManager.h"
#import "SHPresenceManager.h"

@interface SHProfileViewController : UIViewController <MBProgressHUDDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SHChatBubbleDelegate, UIActionSheetDelegate>
{
    MBProgressHUD *HUD;
    UIView *detail_location;
    UIView *detail_sex;
    UIView *detail_age;
    UIView *panel_1;
    UIView *panel_2;
    UIView *panel_3;
    UIView *mediaCollectionViewBG;
    UICollectionView *mediaCollectionView;
    UIImageView *backButtonBadge;
    UIImageView *windowSideline_left;
    UIImageView *statusBubbleTrail_1;
    UIImageView *statusBubbleTrail_2;
    UIImageView *detailLine_1;
    UIImageView *detailLine_2;
    UIImageView *detailLine_3;
    UIImageView *phoneIcon;
    UIImageView *panel_1_horizontalSeparator_1;
    UIImageView *panel_1_horizontalSeparator_2;
    UIImageView *panel_1_verticalSeparator_1;
    UIImageView *panel_1_verticalSeparator_2;
    UIImageView *panel_2_horizontalSeparator_1;
    UIImageView *panel_2_horizontalSeparator_2;
    UIImageView *panel_3_horizontalSeparator_1;
    UIImageView *panel_3_horizontalSeparator_2;
    UIImageView *panel_3_horizontalSeparator_3;
    SHChatBubble *userBubble;
    UIButton *backButton;
    UIButton *settingsButton;
    UIButton *statusBubble;
    UIButton *addUserButton;
    UIButton *declineUserButton;
    UIButton *followersButton;
    UIButton *followingButton;
    UIButton *phoneNumberButton;
    UIButton *addressBookInfoButton;
    UIButton *instagramButton;
    UIButton *twitterButton;
    UIButton *facebookButton;
    UIButton *websiteButton;
    UILabel *backButtonBadgeLabel;
    UILabel *statusLabel;
    UILabel *detailLabel_locationDescription;
    UILabel *detailLabel_location;
    UILabel *detailLabel_sex;
    UILabel *detailLabel_age;
    UILabel *usernameLabel;
    UILabel *lastSeenLabel;
    UILabel *statLabel_following;
    UILabel *statLabel_followers;
    UILabel *descriptionLabel_following;
    UILabel *descriptionLabel_followers;
    UILabel *statLabel_contacts;
    UILabel *statLabel_messagesSent;
    UILabel *statLabel_messagesReceived;
    UILabel *descriptionLabel_contacts;
    UILabel *descriptionLabel_messagesSent;
    UILabel *descriptionLabel_messagesReceived;
    UILabel *bioLabel;
    UILabel *joinDateLabel;
    UILabel *noMediaLabel;
    UILabel *mediaCountLabel;
    UISegmentedControl *mediaSenderControl;
    NSMutableArray *mediaCollection_Received;
    NSMutableArray *mediaCollection_Sent;
    NSMutableArray *activeMediaArray;
    UIImage *newSelectedDP;
    NSString *username;
    NSString *gender;
    NSString *age;
    NSString *location;
    NSString *bio;
    NSString *email;
    NSString *phoneNumber;
    NSString *rawPhoneNumber;
    NSString *website;
    NSString *facebookHandle;
    NSString *twitterHandle;
    NSString *instagramHandle;
    NSString *joinDate;
    NSDateFormatter *dateFormatter;
    CAGradientLayer *maskLayer_mainView;
    NSInteger activeMediaSegmentedControlIndex;
    BOOL viewDidLoad;
    BOOL isCurrentUser;
    long followingCount;
    long followerCount;
}

@property (nonatomic) id callbackView;
@property (nonatomic) SHProfileViewMode mode;
@property (nonatomic) UIView *upperPane;
@property (nonatomic) UIScrollView *mainView;
@property (nonatomic) UIImageView *BG;
@property (nonatomic) NSMutableDictionary *ownerDataChunk;
@property (nonatomic) NSString *ownerID;
@property (nonatomic) BOOL shouldRefreshInfo;

- (void)refreshViewWithDP:(BOOL)refreshDP;
- (void)updateStats;
- (void)updateNetworkStatus;
- (void)updateMenuButtonBadgeCount:(int)count;
- (void)presentMainMenu;
- (void)goBack;
- (void)presentSettings;
- (void)loadMediaFromUser:(SHUserType)userType reloadView:(BOOL)reloadView;
- (void)calculateMediaBrowserHeightAndScrollToVisible:(BOOL)visible;
- (void)showStatusOptions;
- (void)showAddressBookInfo;
- (void)showGalleryForMedia:(id)media atPath:(NSString *)path;
- (void)showMapForLocation:(NSDictionary *)mediaLocation;
- (void)addUser;
- (void)removeUser;
- (void)acceptUserRequest;
- (void)presentFollowing;
- (void)presentFollowers;
- (void)emailUser;
- (void)callPhoneNumber;
- (void)gotoWebsite;
- (void)gotoSocialProfile:(id)sender;
- (NSInteger)ageFromDate:(NSString *)dateString;

- (void)mediaSenderTypeChanged:(id)sender;

- (void)showDPOptions;
- (void)DP_UseLastPhotoTaken;
- (void)uploadDP;
- (void)removeCurrentDP;
- (void)copyCurrentStatus;
- (void)showDPOverlay;
- (void)dismissDPOverlay;
- (void)saveDP;

// Gestures.
- (void)didLongPressStatus:(UILongPressGestureRecognizer *)longPress;

- (void)currentUserPresenceDidChange;
- (void)mediaPickerDidFinishPickingDP:(UIImage *)newDP;

- (void)loadInfoOverNetwork;
- (void)didAddUser;
- (void)didRemoveUser;

- (void)lastOperationFailedWithError:(NSError *)error;
- (void)showNetworkError;

@end
