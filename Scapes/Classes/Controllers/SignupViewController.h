//
//  RegistrationViewController.h
//  Scapes
//
//  Created by MachOSX on 8/24/13.
//
//

#import "MBProgressHUD.h"
#import "SHChatBubble.h"

@interface SignupViewController : UIViewController <MBProgressHUDDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, SHChatBubbleDelegate, UITextFieldDelegate, UIActionSheetDelegate>
{
    MBProgressHUD *HUD;
    UIImagePickerController *photoPicker;
    UIBarButtonItem *doneButton;
    UIImageView *wallpaper;
    UIImageView *firstNameFieldBG;
    UIImageView *lastNameFieldBG;
    UILabel *titleLabel;
    UILabel *welcomeLabel;
    UILabel *firstNameFieldPlaceholderLabel;
    UILabel *lastNameFieldPlaceholderLabel;
    UITextField *firstNameField;
    UITextField *lastNameField;
    SHChatBubble *DPPreview;
    NSArray *welcomes;
    UIImage *selectedImage;
    NSTimer *timer_timeOfDayCheck;
    NSTimer *timer_welcomeTitle;
    NSString *wallpaperImageName;
    NSString *userID; // The newly-created user ID.
    BOOL wallpaperShouldAnimate;
    BOOL wallpaperIsAnimatingRight;
    BOOL wallpaperDidChange_dawn;
    BOOL wallpaperDidChange_day;
    BOOL wallpaperDidChange_dusk;
    BOOL wallpaperDidChange_night;
    int nextWelcomeLabelIndex;
}

@property (nonatomic) NSString *countryID;
@property (nonatomic) NSString *countryCallingCode;
@property (nonatomic) NSString *prefix;
@property (nonatomic) NSString *phoneNumber;
@property (nonatomic) float timezone;

// Live Wallpaper
- (void)startWallpaperAnimation;
- (void)stopWallpaperAnimation;
- (void)checkTimeOfDay;

// Title View Welcome Animation
- (void)changeWelcomeTitle;

// Account Creation
- (void)createAccount;

// DP Options
- (void)showDPOptions;
- (void)DP_Camera;
- (void)DP_Library;
- (void)DP_UseLastPhotoTaken;

- (void)showNetworkError;

@end
