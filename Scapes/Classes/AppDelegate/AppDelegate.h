//
//  AppDelegate.h
//  Scapes
//
//  Created by Ali Razzouk on 31/7/13.
//  Copyright (c) 2013 Scapehouse. All rights reserved.
//

#import "SHOrientationNavigationController.h"
#import "LoginViewController.h"
#import "SHPasscodeViewController.h"
#import "MainMenuViewController.h"
#import "SHContactManager.h"
#import "SHLicenseManager.h"
#import "SHLocationManager.h"
#import "SHMessageManager.h"
#import "SHModelManager.h"
#import "SHNetworkManager.h"
#import "SHPeerManager.h"
#import "SHPresenceManager.h"
#import "SHStrobeLight.h"
#import "KeychainItemWrapper.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>
{
    
}

@property (nonatomic) UIBackgroundTaskIdentifier BGTask;
@property (nonatomic, strong) SHContactManager *contactManager;
@property (nonatomic, strong) SHLicenseManager *licenseManager;
@property (nonatomic, strong) SHLocationManager *locationManager;
@property (nonatomic, strong) SHMessageManager *messageManager;
@property (nonatomic, strong) SHModelManager *modelManager;
@property (nonatomic, strong) SHNetworkManager *networkManager;
@property (strong, nonatomic) SHPeerManager *peerManager;
@property (nonatomic, strong) SHPresenceManager *presenceManager;
@property (nonatomic) CGRect screenBounds;
@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) SHStrobeLight *strobeLight;
@property (nonatomic, strong) LoginViewController *loginWindow;
@property (nonatomic, strong) SHPasscodeViewController *passcodeWindow;
@property (nonatomic, strong) MainMenuViewController *mainMenu;
@property (nonatomic, strong) SHOrientationNavigationController *loginWindowNavigationController;
@property (nonatomic, strong) SHOrientationNavigationController *mainWindowNavigationController;
@property (nonatomic, strong) KeychainItemWrapper *credsKeychainItem;
@property (nonatomic, strong) KeychainItemWrapper *passcodeKeychainItem;
@property (nonatomic, strong) NSString *device_token;
@property (nonatomic, strong) NSString *SHToken;
@property (nonatomic, strong) NSString *SHTokenID;
@property (nonatomic, strong) NSMutableDictionary *currentUser;
@property (nonatomic, strong) NSArray *IAPurchases;
@property (nonatomic) SHAppWindowType activeWindow;
@property (nonatomic) BOOL viewIsDraggable;
@property (nonatomic) BOOL appIsLocked;
@property (nonatomic) BOOL preference_UseAddressBook;
@property (nonatomic) BOOL preference_UseBluetooth;
@property (nonatomic) BOOL preference_RelativeTime;
@property (nonatomic) BOOL preference_AutosaveMedia;
@property (nonatomic) BOOL preference_HQUploads;
@property (nonatomic) BOOL preference_Sounds;
@property (nonatomic) BOOL preference_Vibrate;
@property (nonatomic) BOOL preference_LastSeen;
@property (nonatomic) BOOL preference_Talking;
@property (nonatomic) BOOL preference_ReturnKeyToSend;

+ (AppDelegate *)sharedDelegate;
- (void)refreshCurrentUserData;
- (void)checkLicenseStatus;
- (void)disableApp;
- (void)lockdownApp;
- (void)logout;

// For checking the currently selected system language.
- (BOOL)isDeviceLanguageRTL;

// Image Manipulation.
- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
- (UIImage *)imageWithImage:(UIImage *)image scaledToWidth:(float)i_width;
- (UIImage *)imageFilledWith:(UIColor *)color using:(UIImage *)startImage;
- (UIImage *)maskImage:(UIImage *)image withMask:(UIImage *)mask;
- (BOOL)isDarkImage:(UIImage *)inputImage;

- (UIColor *)colorForCode:(SHPostColor)code;

// Time.
- (NSString *)relativeTimefromDate:(NSDate *)targetDate shortened:(BOOL)shortened condensed:(BOOL)condensed;
- (NSString *)dayForTime:(NSDate *)targetDate relative:(BOOL)relative condensed:(BOOL)condensed;

// Cryptography
- (NSString *)encryptedJSONStringForDataChunk:(NSDictionary *)dataChunk withKey:(NSString *)key;
- (NSString *)decryptedJSONStringForEncryptedString:(NSString *)encryptedString withKey:(NSString *)key;

// Parallax.
- (void)registerPrallaxEffectForView:(UIView *)aView depth:(CGFloat)depth;
- (void)registerPrallaxEffectForBackground:(UIView *)aView depth:(CGFloat)depth;
- (void)unregisterPrallaxEffectForView:(UIView *)aView;

// Background Tasks.
- (void)beginBackgroundUpdateTask;
- (void)endBackgroundUpdateTask;

// Push Notifications.
- (void)handlePushNotification:(NSDictionary *)notification withApplicationState:(UIApplicationState)applicationState;

@end
