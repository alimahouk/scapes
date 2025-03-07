//
//  LoginViewController.h
//  Scapes
//
//  Created by MachOSX on 8/23/13.
//
//

#import "MBProgressHUD.h"
#import "SHContactManager.h"
#import "SHLocationManager.h"
#import "SHPasscodeViewController.h"
#import "SignupViewController.h"

@interface LoginViewController : UIViewController <MBProgressHUDDelegate, SHContactManagerDelegate, SHLocationManagerDelegate, SHPasscodeViewDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIAlertViewDelegate>
{
    SignupViewController *signupView;
    MBProgressHUD *HUD;
    UIImageView *roof;
    UIImageView *phoneIcon;
    UIImageView *spotlight;
    UITableView *countryCodeList;
    UITextField *phoneNumberField;
    UIButton *countryCodeButton;
    UIButton *doneButton;
    CAGradientLayer *maskLayer_CountryCodeList;
    NSDictionary *responseData;
    NSArray *countryCodes;
    NSArray *countryNames;
    NSIndexPath *activeIndexPath;
    NSString *detectedCountry;
    NSString *countryCallingCode;
    NSString *prefix;
    NSString *phoneNumber;
    NSString *verificationCode;
    float timezoneoffset;
    BOOL waitingForCountryList;
    BOOL isAwaitingVerification;
    BOOL locationUpdateFailed;
}

- (void)sendVerificationCode;
- (void)confirmNumber;
- (void)login;
- (void)parseLoginResponse:(NSDictionary *)response;
- (void)purgeStaleToken:(NSString *)staleToken;
- (void)showVerificationUI;

- (void)showCountryCodeList;
- (void)dismissCountryCodeList;
- (void)getCurrentCountry;

- (void)showNetworkError;

@end
