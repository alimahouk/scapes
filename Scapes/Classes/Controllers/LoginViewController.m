//
//  LoginViewController.m
//  Scapes
//
//  Created by MachOSX on 8/23/13.
//
//

#import "LoginViewController.h"

#import "AFHTTPRequestOperationManager.h"
#import "UIDeviceHardware.h"

@implementation LoginViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        waitingForCountryList = NO;
        isAwaitingVerification = NO;
        locationUpdateFailed = NO;
        
        countryCodes = [[NSArray alloc] initWithObjects:@"", nil];
        countryNames = [[NSArray alloc] initWithObjects:@"", nil];
        
        detectedCountry = @"";
        countryCallingCode = @"93"; // The first country in the list, Afghanistan.
        prefix = @"";
        phoneNumber = @"";
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor whiteColor];
    
    roof = [[UIImageView alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width / 2 - 23, 121, 46, 35)];
    roof.image = [UIImage imageNamed:@"roof_small_gray"];
    roof.opaque = YES;
    
    phoneIcon = [[UIImageView alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width / 2 - 12, 194, 19, 53)];
    phoneIcon.image = [UIImage imageNamed:@"iphone_small_gray"];
    phoneIcon.opaque = YES;
    
    spotlight = [[UIImageView alloc] initWithFrame:CGRectMake(40, appDelegate.screenBounds.size.height / 2 + 25, 27, 19)];
    spotlight.image = [UIImage imageNamed:@"spotlight"];
    spotlight.opaque = YES;
    
    countryCodeList = [[UITableView alloc] initWithFrame:CGRectMake(0, appDelegate.screenBounds.size.height / 2 - 95, appDelegate.screenBounds.size.width, 210)];
    countryCodeList.backgroundColor = [UIColor clearColor];
    countryCodeList.separatorStyle = UITableViewCellSeparatorStyleNone;
    countryCodeList.showsVerticalScrollIndicator = NO;
    countryCodeList.delegate = self;
    countryCodeList.dataSource = self;
    countryCodeList.opaque = YES;
    countryCodeList.alpha = 0.0;
    countryCodeList.hidden = YES;
    countryCodeList.tag = 1;
    
    phoneNumberField = [[UITextField alloc] initWithFrame:CGRectMake(82, appDelegate.screenBounds.size.height / 2, appDelegate.screenBounds.size.width - 115, 25)];
    phoneNumberField.delegate = self;
    phoneNumberField.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:23];
    phoneNumberField.textColor = [UIColor blackColor];
    phoneNumberField.keyboardType = UIKeyboardTypeNumberPad;
    phoneNumberField.placeholder = NSLocalizedString(@"LOGIN_PHONE_FIELD_PLACEHOLDER", nil);
    
    countryCodeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [countryCodeButton setTitle:[NSString stringWithFormat:@"+%@", countryCallingCode] forState:UIControlStateNormal];
    [countryCodeButton setTitleColor:[UIColor colorWithRed:144/255.0 green:143/255.0 blue:149/255.0 alpha:1.0] forState:UIControlStateNormal];
    [countryCodeButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [countryCodeButton addTarget:self action:@selector(showCountryCodeList) forControlEvents:UIControlEventTouchUpInside];
    countryCodeButton.backgroundColor = [UIColor clearColor];
    countryCodeButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Ultralight" size:23];
    countryCodeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    countryCodeButton.frame = CGRectMake(0, appDelegate.screenBounds.size.height / 2, 75, 25);
    countryCodeButton.enabled = NO;
    
    doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    doneButton.backgroundColor = [UIColor clearColor];
    doneButton.frame = CGRectMake(appDelegate.screenBounds.size.width - 40, appDelegate.screenBounds.size.height / 2, 20, 20);
    doneButton.alpha = 0.0;
    doneButton.hidden = YES;
    [doneButton setBackgroundImage:[UIImage imageNamed:@"rounded_arrow_gray"] forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *SHSignature = [[UILabel alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width - 120, appDelegate.screenBounds.size.height - 34, 100, 14)];
    SHSignature.backgroundColor = [UIColor clearColor];
    SHSignature.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
    SHSignature.textColor = [UIColor colorWithRed:144/255.0 green:143/255.0 blue:149/255.0 alpha:1.0];
    SHSignature.textAlignment = NSTextAlignmentRight;
    SHSignature.text = NSLocalizedString(@"SH_SIGNATURE", nil);
    
    UIColor *outerColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    UIColor *innerColor = [UIColor colorWithWhite:1.0 alpha:0.0];
    
    // Adding transparency to the top & bottom of the country list.
    maskLayer_CountryCodeList = [CAGradientLayer layer];
    maskLayer_CountryCodeList.colors = [NSArray arrayWithObjects:(__bridge id)innerColor.CGColor, (__bridge id)innerColor.CGColor, (__bridge id)outerColor.CGColor, (__bridge id)outerColor.CGColor, (__bridge id)innerColor.CGColor, nil];
    maskLayer_CountryCodeList.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0],
                                    [NSNumber numberWithFloat:0.06],
                                    [NSNumber numberWithFloat:0.2],
                                    [NSNumber numberWithFloat:0.8],
                                    [NSNumber numberWithFloat:1.0], nil];
    
    maskLayer_CountryCodeList.bounds = CGRectMake(0, 0, countryCodeList.frame.size.width, countryCodeList.frame.size.height);
    maskLayer_CountryCodeList.position = CGPointMake(0, countryCodeList.contentOffset.y);
    maskLayer_CountryCodeList.anchorPoint = CGPointZero;
    countryCodeList.layer.mask = maskLayer_CountryCodeList;
    
    // http://stackoverflow.com/questions/3940615/find-current-country-from-iphone-device
    
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        phoneNumberField.frame = CGRectMake(82, 266, 218, 28);
        
        countryCodeButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:23];
    }
    
    [contentView addSubview:roof];
    [contentView addSubview:phoneIcon];
    [contentView addSubview:countryCodeList];
    [contentView addSubview:spotlight];
    [contentView addSubview:phoneNumberField];
    [contentView addSubview:countryCodeButton];
    [contentView addSubview:doneButton];
    [contentView addSubview:SHSignature];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    appDelegate.contactManager.delegate = self;
    appDelegate.locationManager.delegate = self;
    [appDelegate.mainMenu hideMainWindowSide];
    
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    appDelegate.locationManager.delegate = nil;
    
    [super viewDidDisappear:animated];
}

- (void)sendVerificationCode
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight activateStrobeLight];
    
    phoneNumber = phoneNumberField.text;
    
    // Only numeric characters are allowed.
    NSCharacterSet *notAllowedChars = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890"] invertedSet];
    phoneNumber = [[phoneNumber componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
    phoneNumber = [phoneNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    phoneNumber = [NSString stringWithFormat:@"+%@%@", countryCallingCode, phoneNumber];
    NSDictionary *phoneNumberPack = [appDelegate.contactManager formatPhoneNumber:phoneNumber mobileOnly:YES];
    
    if ( [phoneNumberField.text isEqualToString:@"801009002"] || [phoneNumberField.text isEqualToString:@"801009003"] )
    {
        [appDelegate.strobeLight deactivateStrobeLight];
        [self showVerificationUI];
        
        return;
    }
    else if ( !phoneNumberPack )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOGIN_ERROR_PHONE_NUMBER", nil)
                                                        message:NSLocalizedString(@"LOGIN_ERROR_DESCRIPTION_PHONE_NUMBER", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
        [appDelegate.strobeLight negativeStrobeLight];
        
        return;
    }
    
    prefix = [phoneNumberPack objectForKey:@"prefix"];
    phoneNumber = [phoneNumberPack objectForKey:@"phone_number"];
    
    [phoneNumberField resignFirstResponder];
    
    // Disable the fields.
    phoneNumberField.enabled = NO;
    doneButton.enabled = NO;
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    [NSTimeZone resetSystemTimeZone];
    timezoneoffset = ([[NSTimeZone systemTimeZone] secondsFromGMT] / 3600.0);
    
    int digit_1 = arc4random_uniform(9) + 1;
    int digit_2 = arc4random_uniform(9);
    int digit_3 = arc4random_uniform(9);
    int digit_4 = arc4random_uniform(9);
    int digit_5 = arc4random_uniform(9);
    verificationCode = [NSString stringWithFormat:@"%d%d%d%d%d", digit_1, digit_2, digit_3, digit_4, digit_5];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[countryCallingCode,
                                                                                    prefix,
                                                                                    phoneNumber,
                                                                                    verificationCode]
                                                                          forKeys:@[@"country_calling_code",
                                                                                    @"prefix",
                                                                                    @"phone_number",
                                                                                    @"code"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:INIT_TOKEN];
    
    NSDictionary *parameters = @{@"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/sms/send", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:INIT_TOKEN];
        responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        [HUD hide:YES];
        phoneNumberField.enabled = YES;
        doneButton.enabled = YES;
        
        if ( responseData )
        {
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            if ( errorCode == 0 )
            {
                [appDelegate.strobeLight deactivateStrobeLight];
                [self showVerificationUI];
            }
            else
            {
                [appDelegate.strobeLight negativeStrobeLight];
            }
        }
        else // Some error occurred...
        {
            // Re-enable the fields.
            phoneNumberField.enabled = YES;
            doneButton.enabled = YES;
            
            [self showNetworkError];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Re-enable the fields.
        phoneNumberField.enabled = YES;
        doneButton.enabled = YES;
        
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)confirmNumber
{
    NSString *displayString = phoneNumberField.text;
    
    // Only numeric characters are allowed.
    NSCharacterSet *notAllowedChars = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890"] invertedSet];
    displayString = [[displayString componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
    displayString = [displayString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    displayString = [NSString stringWithFormat:@"+%@%@", countryCallingCode, displayString];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:displayString
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                          otherButtonTitles:NSLocalizedString(@"GENERIC_CONFIRM", nil), nil];
    alert.tag = 0;
    [alert show];
}

- (void)login
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    int enteredVerificationCode = phoneNumberField.text.intValue;
    int actualVerificationCode = verificationCode.intValue;
    BOOL cheating = NO;
    
    // Comment this part out during development to avoid sending SMSs!
    if ( !isAwaitingVerification )
    {
        [self confirmNumber];
        
        return;
    }
    else
    {
        if ( enteredVerificationCode != actualVerificationCode )
        {
            if ( enteredVerificationCode == 801009002 || enteredVerificationCode == 801009003 ) // Cheat code.
            {
                cheating = YES;
            }
            else
            {
                [appDelegate.strobeLight negativeStrobeLight];
                
                HUD = [[MBProgressHUD alloc] initWithView:self.view];
                [self.view addSubview:HUD];
                
                HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cross_white"]];
                
                // Set custom view mode.
                HUD.mode = MBProgressHUDModeCustomView;
                HUD.dimBackground = YES;
                HUD.delegate = self;
                HUD.labelText = NSLocalizedString(@"LOGIN_ERROR_VERIFICATION", nil);
                
                [HUD show:YES];
                [HUD hide:YES afterDelay:2.5];
                
                return;
            }
        }
    }
    
    if ( cheating )
    {
        countryCallingCode = @"971";
        prefix = @"50";
        
        if ( enteredVerificationCode == 801009002 )
        {
            phoneNumber = @"3442703";
        }
        else
        {
            phoneNumber = @"0000000";
        }
        
        [NSTimeZone resetSystemTimeZone];
        timezoneoffset = ([[NSTimeZone systemTimeZone] secondsFromGMT] / 3600.0);
    }
    
    // Disable the fields.
    phoneNumberField.enabled = NO;
    doneButton.enabled = NO;
    
    [appDelegate.strobeLight activateStrobeLight];
    
    [phoneNumberField resignFirstResponder];
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    if ( !appDelegate.contactManager.countryListDidDownload )
    {
        waitingForCountryList = YES;
        
        [appDelegate.contactManager fetchCountryList]; // Now, wait till the delegate method gets called.
        
        return;
    }
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[countryCallingCode,
                                                                                    prefix,
                                                                                    phoneNumber,
                                                                                    [[NSLocale preferredLanguages] objectAtIndex:0],
                                                                                    [NSNumber numberWithFloat:timezoneoffset],
                                                                                    @"ios",
                                                                                    [[UIDevice currentDevice] systemVersion],
                                                                                    [[UIDevice currentDevice] name],
                                                                                    [UIDeviceHardware platformNumericString],
                                                                                    appDelegate.device_token]
                                                                            forKeys:@[@"country_calling_code",
                                                                                    @"prefix",
                                                                                    @"phone_number",
                                                                                    @"locale",
                                                                                    @"timezone",
                                                                                    @"os_name",
                                                                                    @"os_version",
                                                                                    @"device_name",
                                                                                    @"device_type",
                                                                                    @"device_token"]];
    if ( cheating )
    {
        [dataChunk setObject:@"1" forKey:@"cheat"];
    }
    else
    {
        [dataChunk setObject:@"0" forKey:@"cheat"];
    }
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:INIT_TOKEN];
    
    NSDictionary *parameters = @{@"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/login", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:INIT_TOKEN];
        responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        if ( responseData )
        {
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            appDelegate.contactManager.delegate = appDelegate.mainMenu;
            
            if ( errorCode == 0 ) // User has an account. Take them in.
            {
                NSDictionary *userData = [[responseData objectForKey:@"response"] objectForKey:@"user_data"];
                
                // First we check if the user's account is passcode-protected. If yes, display an authentication prompt.
                if ( [userData objectForKey:@"passcodes"] )
                {
                    NSArray *passcodes = [userData objectForKey:@"passcodes"];
                    
                    [appDelegate.passcodeWindow setMode:SHPasscodeWindowModeAuthenticate];
                    appDelegate.passcodeWindow.delegate = self;
                    
                    [self.navigationController presentViewController:appDelegate.passcodeWindow animated:YES completion:nil];
                    [appDelegate.passcodeWindow testAgainstCases:passcodes];
                }
                else
                {
                    [self parseLoginResponse:[responseData objectForKey:@"response"]];
                }
            }
            else
            {
                if ( errorCode == 404 ) // No account found. Create one.
                {
                    if ( !signupView )
                    {
                        signupView = [[SignupViewController alloc] init];
                    }
                    
                    signupView.countryCallingCode = countryCallingCode;
                    signupView.prefix = prefix;
                    signupView.phoneNumber = phoneNumber;
                    signupView.timezone = timezoneoffset;
                    [self.navigationController pushViewController:signupView animated:YES];
                    [appDelegate.strobeLight deactivateStrobeLight];
                }
                else
                {
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
                        HUD.labelText = NSLocalizedString(@"GENERIC_HUD_NETWORK_RESPONSE_ERROR", nil);
                        
                        [HUD show:YES];
                        [HUD hide:YES afterDelay:3];
                        
                        [appDelegate.strobeLight negativeStrobeLight];
                        
                        // Re-enable the fields.
                        phoneNumberField.enabled = YES;
                        doneButton.enabled = YES;
                    });
                }
            }
        }
        else // Some error occurred...
        {
            // Re-enable the fields.
            phoneNumberField.enabled = YES;
            doneButton.enabled = YES;
            
            [self showNetworkError];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Re-enable the fields.
        phoneNumberField.enabled = YES;
        doneButton.enabled = YES;
        
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)parseLoginResponse:(NSDictionary *)response
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDictionary *userData = [[responseData objectForKey:@"response"] objectForKey:@"user_data"];
    
    appDelegate.SHToken = [[responseData objectForKey:@"response"] objectForKey:@"SHToken"];
    appDelegate.SHTokenID = [[responseData objectForKey:@"response"] objectForKey:@"SHToken_id"];
    
    appDelegate.contactManager.delegate = appDelegate.mainMenu;
    
    // Save the token in the Keychain.
    [appDelegate.credsKeychainItem setObject:appDelegate.SHToken forKey:(__bridge id)(kSecValueData)];
    
    // Save the token ID in the shared defaults.
    [[NSUserDefaults standardUserDefaults] setObject:appDelegate.SHTokenID forKey:@"SHSilphScope"];
    
    [appDelegate.modelManager saveCurrentUserData:userData];
    [appDelegate.locationManager resumeLocationUpdates];
    
    if ( appDelegate.currentUser.count == 0 )
    {
        NSString *userID = [NSString stringWithFormat:@"%@", [userData objectForKey:@"user_id"]];
        
        [appDelegate.currentUser setObject:userID forKey:@"user_id"]; // Set this right away for any concurrent operations that might need it.
    }
    
    [HUD hide:YES];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"LOGIN_ADDRESS_BOOK_SCAN_TITLE", nil), [userData objectForKey:@"name_first"]]
                                                    message:NSLocalizedString(@"LOGIN_ADDRESS_BOOK_SCAN_MESSAGE", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"LOGIN_ADDRESS_BOOK_SCAN_CANCEL", nil)
                                          otherButtonTitles:NSLocalizedString(@"LOGIN_ADDRESS_BOOK_SCAN_CONFIRM", nil), nil];
    alert.tag = 1;
    [alert show];
    
    [appDelegate.peerManager startScanning];
    [appDelegate.peerManager startAdvertising];
}

- (void)purgeStaleToken:(NSString *)staleToken
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDictionary *parameters = @{@"stale_token": staleToken,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/purgestaletoken", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        if ( errorCode == 0 )
        {
            [appDelegate.credsKeychainItem resetKeychainItem]; // Clear out the creds from the Keychain.
            [appDelegate.passcodeKeychainItem resetKeychainItem]; // Remove any old passcode.
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)showVerificationUI
{
    isAwaitingVerification = YES;
    
    countryCodeButton.hidden = YES;
    spotlight.hidden = YES;
    phoneNumberField.frame = CGRectMake(20, phoneNumberField.frame.origin.y, 280, phoneNumberField.frame.size.height);
    phoneNumberField.placeholder = NSLocalizedString(@"LOGIN_VERIFICATION_PLACEHOLDER", nil);
    phoneNumberField.text = @"";
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOGIN_VERIFICATION_SENT", nil)
                                                    message:NSLocalizedString(@"LOGIN_VERIFICATION_DESCRIPTION", nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
    [phoneNumberField becomeFirstResponder];
}

- (void)showCountryCodeList
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( !appDelegate.contactManager.countryListDidDownload )
    {
        [appDelegate.contactManager fetchCountryList]; // Now, wait till the delegate method gets called.
        
        return;
    }
    
    countryCodeList.hidden = NO;
    
    [phoneNumberField resignFirstResponder];
    
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        countryCodeList.alpha = 1.0;
        countryCodeButton.alpha = 0.0;
        phoneNumberField.alpha = 0.0;
        phoneIcon.alpha = 0.0;
    } completion:^(BOOL finished){
        countryCodeButton.hidden = YES;
        phoneNumberField.hidden = YES;
        phoneIcon.hidden = YES;
    }];
}

- (void)dismissCountryCodeList
{
    countryCodeButton.hidden = NO;
    phoneNumberField.hidden = NO;
    phoneIcon.hidden = NO;
    
    [countryCodeButton setTitle:[NSString stringWithFormat:@"+%@", countryCallingCode] forState:UIControlStateNormal];
    
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        countryCodeList.alpha = 0.0;
        countryCodeButton.alpha = 1.0;
        phoneNumberField.alpha = 1.0;
        phoneIcon.alpha = 1.0;
    } completion:^(BOOL finished){
        countryCodeList.hidden = YES;
    }];
    
    [phoneNumberField becomeFirstResponder];
}

- (void)getCurrentCountry
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( locationUpdateFailed )
    {
        if ( appDelegate.contactManager.countryList.count > 0 )
        {
            // Fallback. Pick the first country in the list.
            NSDictionary *firstCountry = [appDelegate.contactManager.countryList firstObject];
            
            detectedCountry = [firstCountry objectForKey:@"name"];
            countryCallingCode = [firstCountry objectForKey:@"calling_code"];
            [countryCodeButton setTitle:[NSString stringWithFormat:@"+%@", countryCallingCode] forState:UIControlStateNormal];
        }
    }
    else
    {
        // Geocoding block.
        [appDelegate.locationManager.geoCoder reverseGeocodeLocation:appDelegate.locationManager.locationManager.location completionHandler:
         ^(NSArray *placemarks, NSError *error) {
             // Get nearby address.
             CLPlacemark *placemark = [placemarks objectAtIndex:0];
             
             // Save the country.
             detectedCountry = placemark.country;
             
             if ( appDelegate.contactManager.countryList.count > 0 )
             {
                 for ( int i = 0; i < appDelegate.contactManager.countryList.count; i++ )
                 {
                     NSDictionary *country = [appDelegate.contactManager.countryList objectAtIndex:i];
                     NSString *countryName = [[country objectForKey:@"name"] lowercaseString];
                     
                     if ( [countryName isEqualToString:[detectedCountry lowercaseString]] )
                     {
                         countryCallingCode = [country objectForKey:@"calling_code"];
                         [countryCodeButton setTitle:[NSString stringWithFormat:@"+%@", countryCallingCode] forState:UIControlStateNormal];
                         
                         [countryCodeList scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                         
                         break;
                     }
                 }
             }
        }];
    }
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
#pragma mark SHContactManagerDelegate methods.

- (void)contactManagerDidFetchCountryList
{
    countryCodeButton.enabled = YES;
    [countryCodeList reloadData];
    
    if ( detectedCountry.length == 0 )
    {
        [self getCurrentCountry];
    }
    
    if ( waitingForCountryList )
    {
        [self login];
        waitingForCountryList = NO;
    }
}

- (void)contactManagerRequestDidFailWithError:(NSError *)error
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( !appDelegate.contactManager.countryListDidDownload )
    {
        [appDelegate.contactManager fetchCountryList]; // Now, wait till the delegate method gets called.
    }
    
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
        
        [appDelegate.strobeLight negativeStrobeLight];
        
        // Re-enable the fields.
        phoneNumberField.enabled = YES;
        doneButton.enabled = YES;
        
        NSLog(@"%@", error);
    });
}

#pragma mark -
#pragma mark SHPasscodeViewDelegate methods.

- (void)passcodeViewDidAuthenticate
{
    [self parseLoginResponse:[responseData objectForKey:@"response"]];
}

- (void)textFieldDidChange:(id)sender
{
    UITextField *textField = (UITextField *)sender;
    
    NSString *number = textField.text;
    
    if ( number.length > 3 )
    {
        doneButton.hidden = NO;
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            doneButton.alpha = 1.0;
        } completion:^(BOOL finished){
            
        }];
    }
    else
    {
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            doneButton.alpha = 0.0;
        } completion:^(BOOL finished){
            doneButton.hidden = YES;
        }];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource methods.

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
	
	return appDelegate.contactManager.countryList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    static NSString *cellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    UILabel *countryCodeLabel;
    UILabel *countryNameLabel;
    
	if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.opaque = YES;
        
        countryCodeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 75, cell.frame.size.height)];
        countryCodeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Ultralight" size:23];
        countryCodeLabel.textColor = [UIColor colorWithRed:144/255.0 green:143/255.0 blue:149/255.0 alpha:1.0];
        countryCodeLabel.textAlignment = NSTextAlignmentRight;
        countryCodeLabel.tag = 7;
        
        countryNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 0, 270, cell.frame.size.height)];
        countryNameLabel.backgroundColor = [UIColor clearColor];
        countryNameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:23];
        countryNameLabel.textColor = [UIColor blackColor];
        countryNameLabel.tag = 8;
        
        if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
        {
            countryCodeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:23];
        }
        
        [cell.contentView addSubview:countryCodeLabel];
        [cell.contentView addSubview:countryNameLabel];
	}
    
    countryCodeLabel = (UILabel *)[cell.contentView viewWithTag:7];
    countryNameLabel = (UILabel *)[cell.contentView viewWithTag:8];
    
    NSDictionary *country = [appDelegate.contactManager.countryList objectAtIndex:indexPath.row];
    
    countryCodeLabel.text = [NSString stringWithFormat:@"+%@", [country objectForKey:@"calling_code"]];
    countryNameLabel.text = [country objectForKey:@"name"];
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( tableView.tag == 1 ) // Country code list.
    {
        NSDictionary *country = [appDelegate.contactManager.countryList objectAtIndex:indexPath.row];
        countryCallingCode = [country objectForKey:@"calling_code"];
        
        [self dismissCountryCodeList];
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
    
    activeIndexPath = indexPath;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)centerTable
{
    NSIndexPath *pathForCenterCell = [countryCodeList indexPathForRowAtPoint:CGPointMake(CGRectGetMidX(countryCodeList.bounds), CGRectGetMidY(countryCodeList.bounds))];
    
    [countryCodeList scrollToRowAtIndexPath:pathForCenterCell atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods.

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    // If decelerating, let scrollViewDidEndDecelerating: handle it.
    if ( !decelerate )
    {
        [self centerTable];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self centerTable];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    if ( scrollView.tag == 1 ) // Country code list.
    {
        maskLayer_CountryCodeList.position = CGPointMake(0, scrollView.contentOffset.y);
    }
    
    [CATransaction commit];
}

#pragma mark -
#pragma mark SHLocationManagerDelegate methods.

- (void)locationManagerDidUpdateLocation
{
    locationUpdateFailed = NO;
    
    [self getCurrentCountry];
}

- (void)locationManagerUpdateDidFail
{
    locationUpdateFailed = YES;
    NSLog(@"Location update failed.");
    
    [self getCurrentCountry];
}

#pragma mark -
#pragma mark UITextFieldDelegate methods.

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( appDelegate.screenBounds.size.height <= 480 ) // Older iPhones.
    {
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.view.frame = CGRectMake(0, -80, self.view.frame.size.width, self.view.frame.size.height);
        } completion:^(BOOL finished){
            
        }];
    }
    
    // Monitor keystrokes.
    [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( appDelegate.screenBounds.size.height <= 480 )
    {
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        } completion:^(BOOL finished){
            
        }];
    }
    
    [textField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods.

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( alertView.tag == 0 )
    {
        if (buttonIndex == 1) // Confirm number.
        {
            [self sendVerificationCode];
        }
    }
    else if ( alertView.tag == 1 )
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        if ( buttonIndex == 0 ) // No import.
        {
            appDelegate.preference_UseAddressBook = NO;
            [userDefaults setObject:@"NO" forKey:@"SHBDUseAddressBook"];
        }
        else if (buttonIndex == 1) // Import contacts.
        {
            appDelegate.preference_UseAddressBook = YES;
            [userDefaults setObject:@"YES" forKey:@"SHBDUseAddressBook"];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [appDelegate.mainMenu refreshContacts];
        });
        
        [self dismissViewControllerAnimated:YES completion:^{
            [appDelegate.mainMenu resumeWallpaperAnimation];
            [appDelegate.mainMenu showMainWindowSide];
            
            phoneNumberField.text = @""; // Clear this out.
            
            // Re-enable the fields.
            phoneNumberField.enabled = YES;
            doneButton.enabled = YES;
            doneButton.hidden = YES;
            doneButton.alpha = 0.0;
        }];
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
