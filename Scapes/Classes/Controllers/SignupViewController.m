//
//  RegistrationViewController.m
//  Scapes
//
//  Created by MachOSX on 8/24/13.
//
//

#import "SignupViewController.h"

#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>


#import "AFHTTPRequestOperationManager.h"
#import "UIDeviceHardware.h"

@implementation SignupViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        welcomes = [[NSArray alloc] initWithObjects:@"Welcome",
                    @"أهلاً و سهلاً",
                    @"خوش آمدید",
                    @"Bienvenu",
                    @"Willkommen",
                    @"Hoşgeldin",
                    @"स्वागत",
                    @"Maligayang Pagdating",
                    @"Bienvenido",
                    @"Benvenuti",
                    @"欢迎",
                    @"ようこそ",
                    @"어서오세요",
                    @"υποδοχή",
                    @"Добро пожаловать",
                    @"Witać",
                    @"Welkom",
                    @"Karibu",
                    @"01010111011001010110110001100011011011110110110101100101", nil];
        
        wallpaperShouldAnimate = YES;
        wallpaperIsAnimatingRight = NO;
        wallpaperDidChange_dawn = NO;
        wallpaperDidChange_day = NO;
        wallpaperDidChange_dusk = NO;
        wallpaperDidChange_night = NO;
        nextWelcomeLabelIndex = 1; // Because it starts at 0.
        
        selectedImage = nil;
    }
    
    return self;
}

- (void)loadView
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    UIView *contentView = [[UIView alloc] initWithFrame:screenBounds];
    contentView.backgroundColor = [UIColor blackColor];
    
    [self.navigationItem setHidesBackButton:YES]; // You can't go back beyond this point.
    
    doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"GENERIC_DONE", nil) style:UIBarButtonItemStyleDone target:self action:@selector(createAccount)];
    self.navigationItem.rightBarButtonItem = doneButton;
    doneButton.enabled = NO;
    
    photoPicker = [[UIImagePickerController alloc] init];
    photoPicker.mediaTypes = @[(NSString *)kUTTypeImage];
    photoPicker.allowsEditing = YES;
    photoPicker.delegate = self;
    
    wallpaper = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 750, 568)];
    wallpaper.backgroundColor = [UIColor blackColor];
    wallpaper.opaque = YES;
    
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 175, 44)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:MAIN_FONT_SIZE];
    titleLabel.minimumScaleFactor = 8.0 / MAIN_FONT_SIZE;
    titleLabel.numberOfLines = 1;
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = [welcomes objectAtIndex:0];
    
    self.navigationItem.titleView = titleLabel;
    
    welcomeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 175, 280, 65)];
    welcomeLabel.backgroundColor = [UIColor clearColor];
    welcomeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:MAIN_FONT_SIZE];
    welcomeLabel.numberOfLines = 0;
    welcomeLabel.textColor = [UIColor whiteColor];
    welcomeLabel.text = NSLocalizedString(@"SIGNUP_WELCOME", nil);
    
    firstNameFieldBG = [[UIImageView alloc] initWithFrame:CGRectMake(20, 340, 280, 35)];
    firstNameFieldBG.image = [[UIImage imageNamed:@"button_round_white_transparent"] stretchableImageWithLeftCapWidth:18 topCapHeight:18];
    firstNameFieldBG.userInteractionEnabled = YES;
    
    lastNameFieldBG = [[UIImageView alloc] initWithFrame:CGRectMake(20, 385, 280, 35)];
    lastNameFieldBG.image = [[UIImage imageNamed:@"button_round_white_transparent"] stretchableImageWithLeftCapWidth:18 topCapHeight:18];
    lastNameFieldBG.userInteractionEnabled = YES;
    
    firstNameField = [[UITextField alloc] initWithFrame:CGRectMake(13, 6, firstNameFieldBG.frame.size.width - 13, 24)];
    firstNameField.textColor  = [UIColor whiteColor];
    firstNameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    firstNameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    firstNameField.returnKeyType = UIReturnKeyNext;
    firstNameField.tag = 0;
    firstNameField.delegate = self;
    
    lastNameField = [[UITextField alloc] initWithFrame:CGRectMake(13, 6, lastNameFieldBG.frame.size.width - 13, 24)];
    lastNameField.textColor  = [UIColor whiteColor];
    lastNameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    lastNameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    lastNameField.returnKeyType = UIReturnKeyDone;
    lastNameField.enablesReturnKeyAutomatically = YES;
    lastNameField.tag = 1;
    lastNameField.delegate = self;
    
    firstNameFieldPlaceholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(13, 6, firstNameFieldBG.frame.size.width - 11, 24)];
    firstNameFieldPlaceholderLabel.backgroundColor = [UIColor clearColor];
    firstNameFieldPlaceholderLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:MAIN_FONT_SIZE];
    firstNameFieldPlaceholderLabel.numberOfLines = 1;
    firstNameFieldPlaceholderLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    firstNameFieldPlaceholderLabel.text = NSLocalizedString(@"SIGNUP_PLACEHOLDER_FIRST_NAME", nil);
    
    lastNameFieldPlaceholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(13, 6, lastNameFieldBG.frame.size.width - 11, 24)];
    lastNameFieldPlaceholderLabel.backgroundColor = [UIColor clearColor];
    lastNameFieldPlaceholderLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:MAIN_FONT_SIZE];
    lastNameFieldPlaceholderLabel.numberOfLines = 1;
    lastNameFieldPlaceholderLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    lastNameFieldPlaceholderLabel.text = NSLocalizedString(@"SIGNUP_PLACEHOLDER_LAST_NAME", nil);
    
    DPPreview = [[SHChatBubble alloc] initWithFrame:CGRectMake(120, 80, CHAT_CLOUD_BUBBLE_SIZE, CHAT_CLOUD_BUBBLE_SIZE) withMiniModeEnabled:NO];
    DPPreview.delegate = self;
    
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav_bar_legacy_white"] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0];
        self.navigationController.navigationBar.shadowImage = [UIImage imageNamed:@"nav_bar_shadow_line"];
        
        titleLabel.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.shadowColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        
        DPPreview.frame = CGRectMake(120, 20, CHAT_CLOUD_BUBBLE_SIZE, CHAT_CLOUD_BUBBLE_SIZE);
        
        welcomeLabel.frame = CGRectMake(20, 115, 280, 65);
        
        firstNameFieldBG.frame = CGRectMake(20, 245, 280, 33);
        lastNameFieldBG.frame = CGRectMake(20, 290, 280, 33);
    }
    
    [firstNameFieldBG addSubview:firstNameFieldPlaceholderLabel];
    [firstNameFieldBG addSubview:firstNameField];
    [lastNameFieldBG addSubview:lastNameFieldPlaceholderLabel];
    [lastNameFieldBG addSubview:lastNameField];
    [contentView addSubview:wallpaper];
    [contentView addSubview:DPPreview];
    [contentView addSubview:welcomeLabel];
    [contentView addSubview:firstNameFieldBG];
    [contentView addSubview:lastNameFieldBG];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [DPPreview setImage:[UIImage imageNamed:@"user_placeholder"]];
    
    [self checkTimeOfDay];
    [self startWallpaperAnimation];
    
    timer_timeOfDayCheck = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(checkTimeOfDay) userInfo:nil repeats:YES]; // Run this every 1 minute.
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // See if the user saved their own number in their address book & grab their thumbnail & name.
        ABRecordRef newUser = (__bridge ABRecordRef)([appDelegate.contactManager addressBookInfoForNumber:_phoneNumber withCountryCallingCode:_countryCallingCode prefix:_prefix]);
        NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(newUser, kABPersonFirstNameProperty));
        NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(newUser, kABPersonLastNameProperty));
        
        if ( ABPersonHasImageData(newUser) )
        {
            NSData *data = (__bridge_transfer NSData *)ABPersonCopyImageDataWithFormat(newUser, kABPersonImageFormatThumbnail);
            
            selectedImage = [UIImage imageWithData:data];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [DPPreview setImage:selectedImage];
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if ( firstName.length > 0 )
            {
                firstNameField.text = firstName;
                firstNameFieldPlaceholderLabel.hidden = YES;
            }
            
            if ( lastName.length > 0 )
            {
                lastNameField.text = lastName;
                lastNameFieldPlaceholderLabel.hidden = YES;
            }
            
            if ( firstName.length > 0 && lastName.length > 0 )
            {
                doneButton.enabled = YES;
            }
        });
    });
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionNavigationBar];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    timer_welcomeTitle = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(changeWelcomeTitle) userInfo:nil repeats:YES]; // Start the timer.
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
    
    [timer_welcomeTitle invalidate]; // Cancel the timer.
    timer_welcomeTitle = nil;
    
    [super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark Live Wallpaper

- (void)startWallpaperAnimation
{
    // Keep the animation slow & mellow.
    [UIView animateWithDuration:0.05 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        if ( wallpaperIsAnimatingRight )
        {
            if ( wallpaper.frame.origin.x < 0 )
            {
                wallpaper.frame = CGRectMake(wallpaper.frame.origin.x + 1, wallpaper.frame.origin.y, wallpaper.frame.size.width, wallpaper.frame.size.height);
            }
            else
            {
                wallpaperIsAnimatingRight = NO; // Go left now.
            }
        }
        else // Animating left.
        {
            if ( wallpaper.frame.origin.x > 320 - wallpaper.frame.size.width )
            {
                wallpaper.frame = CGRectMake(wallpaper.frame.origin.x - 1, wallpaper.frame.origin.y, wallpaper.frame.size.width, wallpaper.frame.size.height);
            }
            else
            {
                wallpaperIsAnimatingRight = YES; // Go right now.
            }
        }
    } completion:^(BOOL finished){
        if ( wallpaperShouldAnimate )
        {
            [self startWallpaperAnimation];
        }
    }];
}

- (void)stopWallpaperAnimation
{
    wallpaperShouldAnimate = NO;
}

#pragma mark -
#pragma mark Check the time of the day to set the wallpaper accordingly.

- (void)checkTimeOfDay
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSDate *now = [NSDate date];
    NSDateComponents *components = [appDelegate.calendar components:NSHourCalendarUnit fromDate:now];
    
    if ( components.hour >= 6 && components.hour < 8 && !wallpaperDidChange_dawn )        // Dawn.
    {
        wallpaperImageName = @"wallpaper_dawn_1";
        wallpaperDidChange_dawn = YES;
        wallpaperDidChange_night = NO;
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            wallpaper.alpha = 0.0;
        } completion:^(BOOL finished){
            wallpaper.image = [UIImage imageNamed:wallpaperImageName];
            
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                wallpaper.alpha = 1.0;
            } completion:^(BOOL finished){
                
            }];
        }];
    }
    else if ( components.hour >= 8 && components.hour <= 16 && !wallpaperDidChange_day )  // Day.
    {
        wallpaperImageName = @"wallpaper_day_1";
        wallpaperDidChange_dawn = NO;
        wallpaperDidChange_day = YES;
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            wallpaper.alpha = 0.0;
        } completion:^(BOOL finished){
            wallpaper.image = [UIImage imageNamed:wallpaperImageName];
            
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                wallpaper.alpha = 1.0;
            } completion:^(BOOL finished){
                
            }];
        }];
    }
    else if ( components.hour >= 17 && components.hour <= 19 && !wallpaperDidChange_dusk ) // Dusk.
    {
        wallpaperImageName = @"wallpaper_dusk_1";
        wallpaperDidChange_day = NO;
        wallpaperDidChange_dusk = YES;
        // Each one resets the one before it.
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            wallpaper.alpha = 0.0;
        } completion:^(BOOL finished){
            wallpaper.image = [UIImage imageNamed:wallpaperImageName];
            
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                wallpaper.alpha = 1.0;
            } completion:^(BOOL finished){
                
            }];
        }];
    }
    else if ( (components.hour >= 20 || components.hour <= 5) && !wallpaperDidChange_night ) // Night.
    {
        // Since we use different images here, the selection is random.
        NSInteger randomChoice = arc4random_uniform(3);
        
        switch ( randomChoice )
        {
            case 0:
                wallpaperImageName = @"wallpaper_night_1";
                break;
                
            case 1:
                wallpaperImageName = @"wallpaper_night_2";
                break;
                
            case 2:
                wallpaperImageName = @"wallpaper_night_3";
                break;
                
            default:
                break;
        }
        
        wallpaperDidChange_dusk = NO;
        wallpaperDidChange_night = YES;
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            wallpaper.alpha = 0.0;
        } completion:^(BOOL finished){
            wallpaper.image = [UIImage imageNamed:wallpaperImageName];
            
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                wallpaper.alpha = 1.0;
            } completion:^(BOOL finished){
                
            }];
        }];
    }
}

#pragma mark -
#pragma mark Title View Welcome Animation

- (void)changeWelcomeTitle
{
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        titleLabel.alpha = 0.0;
    } completion:^(BOOL finished){
        titleLabel.text = [welcomes objectAtIndex:nextWelcomeLabelIndex];
        
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            titleLabel.alpha = 1.0;
        } completion:^(BOOL finished){
            if ( nextWelcomeLabelIndex == welcomes.count - 1 )
            {
                nextWelcomeLabelIndex = 0;
            }
            else
            {
                nextWelcomeLabelIndex++;
            }
        }];
    }];
}

#pragma mark -
#pragma mark Account Creation

- (void)createAccount
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight activateStrobeLight];
    
    NSString *firstName = firstNameField.text;
    NSString *lastName = lastNameField.text;
    firstName = [firstName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    lastName = [lastName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ( firstName.length > 30 )
    {
        [appDelegate.strobeLight negativeStrobeLight];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GENERIC_TITLE_ERROR", nil)
                                                        message:NSLocalizedString(@"SIGNUP_ERROR_LENGTH_FIRST_NAME", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil)
                                              otherButtonTitles:nil];        
        [alert show];
        return;
    }
    
    if ( lastName.length > 30 )
    {
        [appDelegate.strobeLight negativeStrobeLight];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GENERIC_TITLE_ERROR", nil)
                                                        message:NSLocalizedString(@"SIGNUP_ERROR_LENGTH_LAST_NAME", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    NSData *imageData = nil;
    
    if ( selectedImage )
    {
        imageData = UIImageJPEGRepresentation(selectedImage, 1.0);
    }
    
    [firstNameField resignFirstResponder];
    [lastNameField resignFirstResponder];
    
    // Disable the fields.
    firstNameField.enabled = NO;
    lastNameField.enabled = NO;
    DPPreview.enabled = NO;
    doneButton.enabled = NO;
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[firstName,
                                                                                    lastName,
                                                                                    _countryID,
                                                                                    _countryCallingCode,
                                                                                    _prefix,
                                                                                    _phoneNumber,
                                                                                    [[NSLocale preferredLanguages] objectAtIndex:0],
                                                                                    [NSNumber numberWithFloat:_timezone],
                                                                                    @"ios",
                                                                                    [[UIDevice currentDevice] systemVersion],
                                                                                    [[UIDevice currentDevice] name],
                                                                                    [UIDeviceHardware platformNumericString],
                                                                                    appDelegate.device_token]
                                                                          forKeys:@[@"name_first",
                                                                                    @"name_last",
                                                                                    @"country_id",
                                                                                    @"country_calling_code",
                                                                                    @"prefix",
                                                                                    @"phone_number",
                                                                                    @"locale",
                                                                                    @"timezone",
                                                                                    @"os_name",
                                                                                    @"os_version",
                                                                                    @"device_name",
                                                                                    @"device_type",
                                                                                    @"device_token"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:INIT_TOKEN];
    
    NSDictionary *parameters = @{@"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/signup", SH_DOMAIN] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        if ( selectedImage )
        {
            [formData appendPartWithFileData:imageData name:@"image_file" fileName:@"image_file.jpg" mimeType:@"image/jpeg"];
        }
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:INIT_TOKEN];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        [HUD hide:YES];
        
        if ( errorCode == 0 ) // Success!
        {
            NSDictionary *response = [responseData objectForKey:@"response"];
            NSDictionary *userData = [response objectForKey:@"user_data"];
            userID = [NSString stringWithFormat:@"%@", [response objectForKey:@"userID"]];
            appDelegate.SHToken = [response objectForKey:@"SHToken"];
            appDelegate.SHTokenID = [response objectForKey:@"SHToken_id"];
            UIImage *chatWallpaper = [UIImage imageNamed:DEFAULT_WALLPAPER];
            
            /*NSString *timeNow = [appDelegate.modelManager dateTodayString];
            
            userID = [NSString stringWithFormat:@"%@", [[responseData objectForKey:@"response"] objectForKey:@"userID"]];
            appDelegate.SHToken = [[responseData objectForKey:@"response"] objectForKey:@"SHToken"];
            appDelegate.SHTokenID = [[responseData objectForKey:@"response"] objectForKey:@"SHToken_id"];
            
            NSString *alias = @"";
            NSString *userHandle = @"";
            NSString *imageData_alias = @""; // Insert this as a blank string since the user can't have an alias DP for themselves.
            NSString *email = @"";
            NSString *gender = @"";
            NSString *birthday = @"";
            NSString *location_country = @"";
            NSString *location_state = @"";
            NSString *location_city = @"";
            NSString *website = @"";
            NSString *bio = @"";
            NSString *facebookHandle = @"";
            NSString *twitterHandle = @"";
            NSString *instagramHandle = @"";
            NSString *joinDate = [[responseData objectForKey:@"response"] objectForKey:@"join_date"];
            NSString *lastStatusID = [[responseData objectForKey:@"response"] objectForKey:@"last_status_id"];
            NSString *DPHash = [[responseData objectForKey:@"response"] objectForKey:@"DP_hash"];
            id DP; // id since it might be null.
            
            if ( selectedImage )
            {
                DP = imageData;
            }
            else
            {
                DP = @"";
                DPHash = @"";
            }
            
            // Save the token in the Keychain.
            [appDelegate.credsKeychainItem setObject:appDelegate.SHToken forKey:(__bridge id)(kSecValueData)];
            
            // Save the token ID in the shared defaults.
            [[NSUserDefaults standardUserDefaults] setObject:appDelegate.SHTokenID forKey:@"SHSilphScope"];
            
            NSDictionary *argsDict_currentUser = [NSDictionary dictionaryWithObjectsAndKeys:userID, @"user_id",
                                                  firstName, @"name_first",
                                                  lastName, @"name_last",
                                                  alias, @"alias",
                                                  userHandle, @"user_handle",
                                                  DPHash, @"dp_hash",
                                                  DP, @"dp",
                                                  imageData_alias, @"alias_dp",
                                                  UIImageJPEGRepresentation(chatWallpaper, 1.0), @"chat_wallpaper",
                                                  lastStatusID, @"last_status_id",
                                                  email, @"email_address",
                                                  gender, @"gender",
                                                  birthday, @"birthday",
                                                  location_country, @"location_country",
                                                  location_state, @"location_state",
                                                  location_city, @"location_city",
                                                  website, @"website",
                                                  bio, @"bio",
                                                  facebookHandle, @"facebook_id",
                                                  twitterHandle, @"twitter_id",
                                                  instagramHandle, @"instagram_id",
                                                  joinDate, @"join_date",
                                                  @"0", @"total_messages_sent",
                                                  @"0", @"total_messages_received",
                                                  @"0", @"view_count",
                                                  @"0", @"coordinate_x",
                                                  @"0", @"coordinate_y",
                                                  @"0.0", @"rank_score", nil];
            
            [appDelegate.modelManager executeUpdate:@"INSERT INTO sh_current_user "
             @"(user_id, name_first, name_last, user_handle, dp_hash, dp, chat_wallpaper, email_address, gender, birthday, location_country, location_state, location_city, website, bio, facebook_id, twitter_id, instagram_id, join_date, last_status_id, total_messages_sent, total_messages_received) "
             @"VALUES (:user_id, :name_first, :name_last, :user_handle, :dp_hash, :dp, :chat_wallpaper, :email_address, :gender, :birthday, :location_country, :location_state, :location_city, :website, :bio, :facebook_id, :twitter_id, :instagram_id, :join_date, :last_status_id, :total_messages_sent, :total_messages_received)"
                            withParameterDictionary:argsDict_currentUser];
            
            [appDelegate.modelManager executeUpdate:@"INSERT INTO sh_cloud "
             @"(sh_user_id, name_first, name_last, alias, user_handle, dp_hash, dp, alias_dp, last_status_id, email_address, gender, birthday, location_country, location_state, location_city, website, bio, facebook_id, twitter_id, instagram_id, total_messages_sent, total_messages_received, view_count, coordinate_x, coordinate_y, rank_score) "
             @"VALUES (:user_id, :name_first, :name_last, :alias, :user_handle, :dp_hash, :dp, :alias_dp, :last_status_id, :email_address, :gender, :birthday, :location_country, :location_state, :location_city, :website, :bio, :facebook_id, :twitter_id, :instagram_id, :total_messages_sent, :total_messages_received, :view_count, :coordinate_x, :coordinate_y, :rank_score)"
                            withParameterDictionary:argsDict_currentUser];
            
            NSDictionary *argsDict_phoneNumber = [NSDictionary dictionaryWithObjectsAndKeys:_countryCallingCode, @"country_calling_code",
                                                  _prefix, @"prefix",
                                                  _phoneNumber, @"phone_number",
                                                  [appDelegate.modelManager dateTodayString], @"timestamp",
                                                  userID, @"sh_user_id", nil]; // raw_contact_id & phone_label are generated later.
            
            [appDelegate.modelManager executeUpdate:@"INSERT INTO sh_phone_numbers "
             @"(country_calling_code, prefix, phone_number, timestamp, sh_user_id) "
             @"VALUES (:country_calling_code, :prefix, :phone_number, :timestamp, :sh_user_id)"
                            withParameterDictionary:argsDict_phoneNumber];
            
            // Save presence for the current user.
            [appDelegate.modelManager executeUpdate:@"INSERT INTO sh_user_online_status "
             @"(user_id, status, target_id, audience, timestamp) "
             @"VALUES (:user_id, 1, :presence_target, :audience, :timestamp)"
                            withParameterDictionary:@{@"user_id": userID,
                                                      @"presence_target": @"",
                                                      @"audience": [NSNumber numberWithInt:SHUserPresenceAudienceEveryone],
                                                      @"timestamp": timeNow}];
            
            [appDelegate refreshCurrentUserData];
            [appDelegate.locationManager resumeLocationUpdates];
            [appDelegate.networkManager connect];
            [appDelegate.mainMenu refreshContacts];
            [appDelegate.mainMenu.messagesView setCurrentWallpaper:chatWallpaper]; // Set the default wallpaper in the window.
            [appDelegate.strobeLight affirmativeStrobeLight];
            
            [self dismissViewControllerAnimated:YES completion:^{
                [appDelegate.mainMenu resumeWallpaperAnimation];
                [appDelegate showMainWindowSide];
            }];*/
            
            // Save the token in the Keychain.
            [appDelegate.credsKeychainItem setObject:appDelegate.SHToken forKey:(__bridge id)(kSecValueData)];
            
            // Save the token ID in the shared defaults.
            [[NSUserDefaults standardUserDefaults] setObject:appDelegate.SHTokenID forKey:@"SHSilphScope"];
            
            [appDelegate.modelManager saveCurrentUserData:userData];
            [appDelegate.locationManager resumeLocationUpdates];
            [appDelegate.networkManager connect];
            [appDelegate.mainMenu refreshContacts];
            [appDelegate.mainMenu.messagesView setCurrentWallpaper:chatWallpaper]; // Set the default wallpaper in the window.
            [appDelegate.strobeLight affirmativeStrobeLight];
            
            appDelegate.contactManager.delegate = appDelegate.mainMenu;
            
            [appDelegate.peerManager startScanning];
            [appDelegate.peerManager startAdvertising];
            
            [appDelegate.mainMenu showEmptyCloud];
            
            [self dismissViewControllerAnimated:YES completion:^{
                [appDelegate.mainMenu resumeWallpaperAnimation];
            }];
        }
        else if ( errorCode == 500 )
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@":(" message:NSLocalizedString(@"SIGNUP_ERROR_SIGNUP_HALT", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil) otherButtonTitles:nil];
            [alert show];
            
            [appDelegate.strobeLight negativeStrobeLight];
            
            // Re-enable the fields.
            firstNameField.enabled = YES;
            lastNameField.enabled = YES;
            DPPreview.enabled = YES;
            doneButton.enabled = YES;
            
            [firstNameField becomeFirstResponder];
        }
        else
        {
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
                firstNameField.enabled = YES;
                lastNameField.enabled = YES;
                DPPreview.enabled = YES;
                doneButton.enabled = YES;
                
                [firstNameField becomeFirstResponder];
            });
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Re-enable the fields.
        firstNameField.enabled = YES;
        lastNameField.enabled = YES;
        DPPreview.enabled = YES;
        doneButton.enabled = YES;
        
        [firstNameField becomeFirstResponder];
        
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

#pragma mark -
#pragma mark DP Options

- (void)showDPOptions
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    UIActionSheet *actionSheet;
    
    if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ) // If the device has a camera.
    {
        if ( !selectedImage )
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"SIGNUP_DP_SHEET_TITLE", nil)
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"GENERIC_PHOTO_CAMERA_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LIBRARY_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LAST_TAKEN", nil), nil];
        }
        else
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"SIGNUP_DP_SHEET_TITLE", nil)
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                        destructiveButtonTitle:NSLocalizedString(@"GENERIC_PHOTO_REMOVE", nil)
                                             otherButtonTitles:NSLocalizedString(@"GENERIC_PHOTO_CAMERA_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LIBRARY_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LAST_TAKEN", nil), nil];
        }
    }
    else
    {
        if ( !selectedImage )
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"SIGNUP_DP_SHEET_TITLE", nil)
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"GENERIC_PHOTO_LIBRARY_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LAST_TAKEN", nil), nil];
        }
        else
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"SIGNUP_DP_SHEET_TITLE", nil)
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                        destructiveButtonTitle:NSLocalizedString(@"GENERIC_PHOTO_REMOVE", nil)
                                             otherButtonTitles:NSLocalizedString(@"GENERIC_PHOTO_LIBRARY_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LAST_TAKEN", nil), nil];
        }
    }
    
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.tag = 0;
    
    [actionSheet showFromRect:CGRectMake(0, screenBounds.size.height - 44, screenBounds.size.width, 44) inView:self.view animated:YES];
}

- (void)DP_Camera
{
    photoPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    photoPicker.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:photoPicker animated:YES completion:NULL];
}

- (void)DP_Library
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:photoPicker animated:YES completion:NULL];
}

- (void)DP_UseLastPhotoTaken
{
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
                selectedImage = [UIImage imageWithCGImage:[representation fullScreenImage]];
                
                CGImageRef imageRef = CGImageCreateWithImageInRect([selectedImage CGImage], CGRectMake(selectedImage.size.width / 2 - 160, selectedImage.size.height / 2 - 160, 320, 320));
                selectedImage = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
                
                UIImageView *preview = [[UIImageView alloc] initWithImage:selectedImage];
                preview.frame = CGRectMake(0, 0, 320, 320);
                
                // Next, we basically take a screenshot of it again.
                UIGraphicsBeginImageContext(preview.bounds.size);
                [preview.layer renderInContext:UIGraphicsGetCurrentContext()];
                UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                [DPPreview setImage:thumbnail];
            }
        }];
    } failureBlock: ^(NSError *error){
        // Typically you should handle an error more gracefully than this.
        NSLog(@"No groups");
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
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
    [self startWallpaperAnimation];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    [self startWallpaperAnimation];
    
    selectedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
    container.clipsToBounds = YES;
    
    UIImageView *preview = [[UIImageView alloc] initWithImage:selectedImage];
    preview.contentMode = UIViewContentModeScaleAspectFill;
    preview.frame = CGRectMake(0, 0, 320, 320);
    
    // Center the preview inside the container.
    float oldWidth = selectedImage.size.width;
    float scaleFactor = container.frame.size.width / oldWidth;
    
    float newHeight = selectedImage.size.height * scaleFactor;
    
    if ( newHeight > container.frame.size.height )
    {
        int delta = fabs(newHeight - container.frame.size.height);
        preview.frame = CGRectMake(0, -delta / 2, preview.frame.size.width, preview.frame.size.height);
    }
    else
    {
        preview.frame = CGRectMake(0, 0, preview.frame.size.width, preview.frame.size.height);
    }
    
    [container addSubview:preview];
    
    // Next, we basically take a screenshot of it again.
    UIGraphicsBeginImageContext(container.bounds.size);
    [container.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [DPPreview setImage:thumbnail];
    
    if ( firstNameField.text.length == 0 )
    {
        [firstNameField becomeFirstResponder];
    }
    else if ( lastNameField.text.length == 0 )
    {
        [lastNameField becomeFirstResponder];
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

#pragma mark -
#pragma mark SHChatBubbleDelegate methods.

// Forward these to the chat cloud delegate.
- (void)didSelectBubble:(SHChatBubble *)bubble
{
    [self showDPOptions];
}

#pragma mark -
#pragma mark UITextFieldDelegate methods.

- (void)textFieldDidChange:(id)sender
{
    UITextField *textField = (UITextField *)sender;
    NSString *text = textField.text;
    
    if ( textField.tag == 0 )   // First name.
    {
        if ( text.length > 0 )
        {
            firstNameFieldPlaceholderLabel.hidden = YES;
        }
        else
        {
            firstNameFieldPlaceholderLabel.hidden = NO;
        }
    }
    else                        // Last name.
    {
        if ( text.length > 0 )
        {
            lastNameFieldPlaceholderLabel.hidden = YES;
        }
        else
        {
            lastNameFieldPlaceholderLabel.hidden = NO;
        }
    }
    
    if ( firstNameField.text.length > 0 && lastNameField.text.length > 0 )
    {
        doneButton.enabled = YES;
    }
    else
    {
        doneButton.enabled = NO;
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            welcomeLabel.alpha = 0.0;
            welcomeLabel.frame = CGRectMake(welcomeLabel.frame.origin.x, welcomeLabel.frame.origin.y - 5, welcomeLabel.frame.size.width, welcomeLabel.frame.size.height);
            firstNameFieldBG.frame = CGRectMake(20, 115, 280, 33);
            lastNameFieldBG.frame = CGRectMake(20, 160, 280, 33);
        } completion:^(BOOL finished){
            welcomeLabel.hidden = YES;
        }];
    }
    else
    {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            welcomeLabel.alpha = 0.0;
            welcomeLabel.frame = CGRectMake(welcomeLabel.frame.origin.x, welcomeLabel.frame.origin.y - 5, welcomeLabel.frame.size.width, welcomeLabel.frame.size.height);
            firstNameFieldBG.frame = CGRectMake(20, 175, 280, 33);
            lastNameFieldBG.frame = CGRectMake(20, 220, 280, 33);
        } completion:^(BOOL finished){
            welcomeLabel.hidden = YES;
        }];
    }
    
    
    // Monitor keystrokes.
    [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ( textField.tag == 0 )   // First name.
    {
        [lastNameField becomeFirstResponder];
    }
    else                        // Last name.
    {
        if ( firstNameField.text.length > 0 && lastNameField.text.length > 0 )
        {
            [self createAccount];
        }
        else if ( firstNameField.text.length == 0 )
        {
            [firstNameField becomeFirstResponder];
        }
    }
    
    return NO;
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( actionSheet.tag == 0 ) // DP options.
    {
        if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ) // If the device has a camera.
        {
            if ( !selectedImage )
            {
                if ( buttonIndex == 0 )      // Camera.
                {
                    [self DP_Camera];
                }
                else if ( buttonIndex == 1 ) // Library.
                {
                    [self DP_Library];
                }
                else if ( buttonIndex == 2 ) // Last photo taken.
                {
                    [self DP_UseLastPhotoTaken];
                }
            }
            else
            {
                if ( buttonIndex == 0 )      // Remove photo.
                {
                    UIImageView *preview = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"user_placeholder"]];
                    preview.frame = CGRectMake(0, 0, 100, 100);
                    
                    // Next, we basically take a screenshot of it again.
                    UIGraphicsBeginImageContext(preview.bounds.size);
                    [preview.layer renderInContext:UIGraphicsGetCurrentContext()];
                    UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    
                    [DPPreview setImage:thumbnail];
                    
                    selectedImage = nil;
                }
                else if ( buttonIndex == 1 ) // Camera.
                {
                    [self DP_Camera];
                }
                else if ( buttonIndex == 2 ) // Library.
                {
                    [self DP_Library];
                }
                else if ( buttonIndex == 3 ) // Last photo taken.
                {
                    [self DP_UseLastPhotoTaken];
                }
            }
        }
        else
        {
            if ( !selectedImage )
            {
                if ( buttonIndex == 0 ) // Library.
                {
                    [self DP_Library];
                }
                else if ( buttonIndex == 1 ) // Last photo taken.
                {
                    [self DP_UseLastPhotoTaken];
                }
            }
            else
            {
                if ( buttonIndex == 0 )      // Remove photo.
                {
                    UIImageView *preview = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"user_placeholder"]];
                    preview.frame = CGRectMake(0, 0, 100, 100);
                    
                    // Next, we basically take a screenshot of it again.
                    UIGraphicsBeginImageContext(preview.bounds.size);
                    [preview.layer renderInContext:UIGraphicsGetCurrentContext()];
                    UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    
                    [DPPreview setImage:thumbnail];
                    
                    selectedImage = nil;
                }
                else if ( buttonIndex == 1 ) // Library.
                {
                    [self DP_Library];
                }
                else if ( buttonIndex == 2 ) // Last photo taken.
                {
                    [self DP_UseLastPhotoTaken];
                }
            }
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
