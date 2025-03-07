//
//  AppDelegate.m
//  Scapes
//
//  Created by Ali Razzouk on 31/7/13.
//  Copyright (c) 2013 Scapehouse. All rights reserved.
//

#import "AppDelegate.h"

#import "AFNetworkActivityIndicatorManager.h"
#import "Base64.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "SettingsViewController_License.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _screenBounds = [[UIScreen mainScreen] bounds];
    
    _currentUser = [[NSMutableDictionary alloc] init];
    
    // Let the device know we want to receive push notifications.
    if ( [[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)] )
    {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    else
    {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    }
    
    // Override point for customization after application launch.
    _window = [[UIWindow alloc] initWithFrame:_screenBounds];
    _window.backgroundColor = [UIColor whiteColor];
    [_window makeKeyAndVisible];
    
    _modelManager = [[SHModelManager alloc] init];
    _networkManager = [[SHNetworkManager alloc] init];
    
    [self refreshCurrentUserData];
    
    _mainMenu = [[MainMenuViewController alloc] init];
    _mainMenu.wantsFullScreenLayout = YES; // To reclaim the 20px taken up by the status bar.
    _loginWindow.wantsFullScreenLayout = YES;
    
    _mainWindowNavigationController = [[SHOrientationNavigationController alloc] initWithRootViewController:_mainMenu.messagesView];
    
    _window.backgroundColor = [UIColor blackColor];
    _window.rootViewController = _mainMenu;
    
    _strobeLight = [[SHStrobeLight alloc] init];
    [_strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
    
    [_window addSubview:_strobeLight];
    
    // Automatically start and stop the network activity indicator in the status bar.
    [AFNetworkActivityIndicatorManager sharedManager].enabled = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _passcodeWindow = [[SHPasscodeViewController alloc] init];
        
        _calendar = [NSCalendar currentCalendar];
        [_calendar setTimeZone:[NSTimeZone localTimeZone]];
        
        _device_token = @"";
        
        // Initialize the Keychain items.
        _credsKeychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"SHBD_CREDS" accessGroup:nil];
        _passcodeKeychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"SHBD_PASSCODE" accessGroup:nil];
        
        [_credsKeychainItem setObject:@"SHBD_CREDS" forKey: (__bridge id)kSecAttrService];
        [_passcodeKeychainItem setObject:@"SHBD_PASSCODE" forKey: (__bridge id)kSecAttrService];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        
        if ( [userDefaults stringForKey:@"SHBDRunCount"] )
        {
            _SHToken = [_credsKeychainItem objectForKey:(__bridge id)(kSecValueData)];
            [_currentUser setObject:_SHToken forKey:@"access_token"];
            
            _preference_UseAddressBook = [[userDefaults stringForKey:@"SHBDUseAddressBook"] boolValue];
            _preference_UseBluetooth = [[userDefaults stringForKey:@"SHBDUseBluetooth"] boolValue];
            _preference_RelativeTime = [[userDefaults stringForKey:@"SHBDRelativeTime"] boolValue];
            _preference_AutosaveMedia = [[userDefaults stringForKey:@"SHBDAutosaveMedia"] boolValue];
            _preference_HQUploads = [[userDefaults stringForKey:@"SHBDHQUploads"] boolValue];
            _preference_Sounds = [[userDefaults stringForKey:@"SHBDVibrate"] boolValue];
            _preference_Vibrate = [[userDefaults stringForKey:@"SHBDSounds"] boolValue];
            _preference_LastSeen = [[userDefaults stringForKey:@"SHBDLastSeen"] boolValue];
            _preference_Talking = [[userDefaults stringForKey:@"SHBDTalking"] boolValue];
            _preference_ReturnKeyToSend = [[userDefaults stringForKey:@"SHBDReturnKeyToSend"] boolValue];
            
            int runCount = [[userDefaults stringForKey:@"SHBDRunCount"] intValue] + 1; // Increment the run count.
            [userDefaults setObject:[NSNumber numberWithInt:runCount] forKey:@"SHBDRunCount"];
            
            if ( runCount == REVIEW_NAG_THRESHOLD )
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    UIAlertView *rateAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GENERIC_RATE_TITLE", nil)
                                                                        message:NSLocalizedString(@"GENERIC_RATE_MESSAGE", nil)
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"GENERIC_RATE_DISMISS", nil)
                                                              otherButtonTitles:NSLocalizedString(@"GENERIC_RATE_CONFIRM", nil), nil];
                    rateAlert.tag = 0;
                    [rateAlert show];
                });
            }
        }
        else
        {
            NSString *staleToken = [_credsKeychainItem objectForKey:(__bridge id)(kSecValueData)];
            
            if ( staleToken && staleToken.length > 0 )
            {
                [_loginWindow purgeStaleToken:staleToken]; // Clear out any old creds from the Keychain.
            }
            
            [userDefaults setObject:@"0" forKey:@"SHBDRunCount"];
            
            // Store default settings values.
            [userDefaults setObject:@"YES" forKey:@"SHBDUseAddressBook"];
            [userDefaults setObject:@"YES" forKey:@"SHBDUseBluetooth"];
            [userDefaults setObject:@"NO" forKey:@"SHBDRelativeTime"];
            [userDefaults setObject:@"YES" forKey:@"SHBDAutosaveMedia"];
            [userDefaults setObject:@"YES" forKey:@"SHBDHQUploads"];
            [userDefaults setObject:@"YES" forKey:@"SHBDVibrate"];
            [userDefaults setObject:@"YES" forKey:@"SHBDSounds"];
            [userDefaults setObject:@"YES" forKey:@"SHBDLastSeen"];
            [userDefaults setObject:@"YES" forKey:@"SHBDTalking"];
            [userDefaults setObject:@"NO" forKey:@"SHBDReturnKeyToSend"];
            [userDefaults setObject:[NSNumber numberWithInt:SHLicenseTrial] forKey:@"SHBDLicenseType"];
            [userDefaults setObject:@"NO" forKey:@"SHBDTutorialPrivacy"];
            
            [userDefaults synchronize];
            
            _preference_UseAddressBook = YES;
            _preference_UseBluetooth = YES;
            _preference_RelativeTime = NO;
            _preference_AutosaveMedia = YES;
            _preference_HQUploads = YES;
            _preference_Sounds = YES;
            _preference_Vibrate = YES;
            _preference_LastSeen = YES;
            _preference_Talking = YES;
            _preference_ReturnKeyToSend = NO;
        }
        
        _viewIsDraggable = YES;
        _appIsLocked = NO;
        
        _contactManager = [[SHContactManager alloc] init];
        _licenseManager = [SHLicenseManager sharedInstance];
        _locationManager = [[SHLocationManager alloc] init];
        _peerManager = [[SHPeerManager alloc] init];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            _messageManager = [[SHMessageManager alloc] init];
            _messageManager.delegate = _mainMenu;
            
            _presenceManager = [[SHPresenceManager alloc] init];
            _presenceManager.delegate = _mainMenu;
            
            [_contactManager fetchCountryList];
            
            if ( _SHToken.length == 0 ) // No token. Show login.
            {
                _loginWindow = [[LoginViewController alloc] init];
                
                _loginWindowNavigationController = [[SHOrientationNavigationController alloc] initWithRootViewController:_loginWindow];
                _loginWindowNavigationController.autoRotates = NO;
                
                [_mainMenu stopWallpaperAnimation]; // Save power.
                [_mainMenu presentViewController:_loginWindowNavigationController animated:NO completion:nil];
            }
            else
            {
                [_mainMenu setup];
                
                [self checkLicenseStatus];
                [_networkManager connect];
                
                // Check if the user has a passcode enabled.
                [_passcodeWindow checkTimeout];
                
                // Check if the app was launched via a push notif.
                NSDictionary *remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
                
                if ( remoteNotification )
                {
                    long double delayInSeconds = 1.0;
                    
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [self handlePushNotification:remoteNotification withApplicationState:UIApplicationStateBackground];
                    });
                }
            }
        });
    });
    
    return YES;
}

#pragma mark -
#pragma mark Delegate static functions.
// Return a shared delegate.
+ (AppDelegate *)sharedDelegate
{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)refreshCurrentUserData
{
    _currentUser = [_modelManager refreshCurrentUserData];
    _SHToken = [_currentUser objectForKey:@"access_token"];
    _SHTokenID = [_currentUser objectForKey:@"access_token_id"];
}

- (void)checkLicenseStatus
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_licenseManager requestProductsWithCompletionHandler:^(BOOL success, NSArray *products){
            if ( success )
            {
                _IAPurchases = products;
            }
        }];
    });
}

- (void)disableApp
{
    SettingsViewController_License *licenseView = [[SettingsViewController_License alloc] init];
    licenseView.showsExpiryMessage = YES;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:licenseView];
    
    _appIsLocked = YES;
    
    [_networkManager disconnect];
    [_mainMenu presentViewController:navigationController animated:YES completion:nil];
}

- (void)lockdownApp
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"critical update required!" message:@"You're using an unsupported version of Nightboard! Some things might not work properly anymore. Go to the App Store & update to the latest version." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    
    [alert show];
    [_networkManager disconnect];
}

- (void)logout
{
    [_loginWindow purgeStaleToken:_SHToken];
    [_networkManager disconnect];
    [_contactManager updateContactCount];
    
    if ( !_loginWindowNavigationController )
    {
        _loginWindow = [[LoginViewController alloc] init];
        
        _loginWindowNavigationController = [[SHOrientationNavigationController alloc] initWithRootViewController:_loginWindow];
        _loginWindowNavigationController.autoRotates = NO;
    }
    
    // We need a slight delay here.
    long double delayInSeconds = 0.7;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [_modelManager resetDB];
        
        _SHToken = @"";
        _currentUser = nil;
        
        [_mainMenu showMainWindowSide];
        [_mainMenu presentViewController:_loginWindowNavigationController animated:NO completion:nil];
        [_mainMenu stopWallpaperAnimation]; // Save power.
        
        _mainWindowNavigationController.viewControllers = @[_mainMenu.messagesView];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for ( SHChatBubble *bubble in _mainMenu.contactCloud.cloudBubbles )
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [bubble removeFromSuperview];
                });
            }
            
            [_mainMenu.SHMiniFeedEntries removeAllObjects];
            [_mainMenu.contactCloud.cloudBubbles removeAllObjects];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                _mainMenu.contactCloud.headerLabel.text = @"0 contacts";
                [_mainMenu.SHMiniFeed reloadData];
            });
        });
    });
}

- (BOOL)isDeviceLanguageRTL
{
    return ( [NSLocale characterDirectionForLanguage:[[NSLocale preferredLanguages] objectAtIndex:0]] == NSLocaleLanguageDirectionRightToLeft );
}

#pragma mark -
#pragma mark Image Manipulation

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling.
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image.
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage.
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToWidth:(float)i_width
{
    UIImageOrientation imageOrientation = image.imageOrientation;
    
    CGImageRef imageRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    CGFloat scaleRatio = i_width / width;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    
    if ( width > i_width )
    {
        bounds.size.width = i_width;
        bounds.size.height = height * scaleRatio;
    }
    
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGFloat boundHeight;
    UIImageOrientation orient = imageOrientation;
    
    switch( orient )
    {
            
        case UIImageOrientationUp: // EXIF = 1
            transform = CGAffineTransformIdentity;
            
            break;
            
        case UIImageOrientationUpMirrored: // EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            
            break;
            
        case UIImageOrientationDown: // EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            
            break;
            
        case UIImageOrientationDownMirrored: // EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            
            break;
            
        case UIImageOrientationLeftMirrored: // EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            
            break;
            
        case UIImageOrientationLeft: // EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            
            break;
            
        case UIImageOrientationRightMirrored: // EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            
            break;
            
        case UIImageOrientationRight: // EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation!"];
    }
    
    UIGraphicsBeginImageContextWithOptions(bounds.size, YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    if ( orient == UIImageOrientationRight || orient == UIImageOrientationLeft )
    {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else
    {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imageRef);
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
    
    // Old code.
    /*
    float oldWidth = image.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = image.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    CGSize newSize = CGSizeMake(newWidth, newHeight);
    
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling.
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image.
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage.
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;*/
}

// Convert the image's fill color to the passed in color.
- (UIImage *)imageFilledWith:(UIColor *)color using:(UIImage *)startImage
{
    // Create the proper sized rect
    CGRect imageRect = CGRectMake(0, 0, CGImageGetWidth(startImage.CGImage), CGImageGetHeight(startImage.CGImage));
    
    // Create a new bitmap context
    CGContextRef context = CGBitmapContextCreate(NULL, imageRect.size.width, imageRect.size.height, 8, 0, CGImageGetColorSpace(startImage.CGImage), kCGImageAlphaPremultipliedLast);
    
    // Use the passed in image as a clipping mask
    CGContextClipToMask(context, imageRect, startImage.CGImage);
    // Set the fill color
    CGContextSetFillColorWithColor(context, color.CGColor);
    // Fill with color
    CGContextFillRect(context, imageRect);
    
    // Generate a new image
    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newCGImage scale:startImage.scale orientation:startImage.imageOrientation];
    
    // Cleanup
    CGContextRelease(context);
    CGImageRelease(newCGImage);
    
    return newImage;
}

- (UIImage *)maskImage:(UIImage *)image withMask:(UIImage *)mask
{
    CGImageRef imageReference = image.CGImage;
    CGImageRef maskReference = mask.CGImage;
    
    CGImageRef imageMask = CGImageMaskCreate(CGImageGetWidth(maskReference),
                                             CGImageGetHeight(maskReference),
                                             CGImageGetBitsPerComponent(maskReference),
                                             CGImageGetBitsPerPixel(maskReference),
                                             CGImageGetBytesPerRow(maskReference),
                                             CGImageGetDataProvider(maskReference),
                                             NULL, // Decode is null.
                                             YES // Should interpolate.
                                             );
    
    CGImageRef maskedReference = CGImageCreateWithMask(imageReference, imageMask);
    CGImageRelease(imageMask);
    
    UIImage *maskedImage = [UIImage imageWithCGImage:maskedReference];
    CGImageRelease(maskedReference);
    
    return maskedImage;
}

- (BOOL)isDarkImage:(UIImage *)inputImage
{
    BOOL isDark = FALSE;
    
    CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(inputImage.CGImage));
    const UInt8 *pixels = CFDataGetBytePtr(imageData);
    
    int darkPixels = 0;
    
    int length = (int)CFDataGetLength(imageData);
    int const darkPixelThreshold = (inputImage.size.width*inputImage.size.height) * 0.45;
    
    for ( int i = 0; i < length; i += 4 )
    {
        int r = pixels[i];
        int g = pixels[i + 1];
        int b = pixels[i + 2];
        
        // Luminance calculation gives more weight to R & B for human eyes.
        float luminance = (0.299 * r + 0.587 * g + 0.114 * b);
        
        if ( luminance < 150 )
        {
            darkPixels++;
        }
    }
    
    if ( darkPixels >= darkPixelThreshold )
    {
        isDark = YES;
    }
    
    CFRelease(imageData);
    
    return isDark;
}

- (UIColor *)colorForCode:(SHPostColor)code
{
    switch ( code )
    {
        case SHPostColorWhite:
            return [UIColor whiteColor];
            
        case SHPostColorRed:
            return [UIColor colorWithRed:255/255.0 green:138/255.0 blue:138/255.0 alpha:1.0];
            
        case SHPostColorGreen:
            return [UIColor colorWithRed:189/255.0 green:255/255.0 blue:138/255.0 alpha:1.0];
            
        case SHPostColorBlue:
            return [UIColor colorWithRed:189/255.0 green:236/255.0 blue:255/255.0 alpha:1.0];
            
        case SHPostColorPink:
            return [UIColor colorWithRed:255/255.0 green:214/255.0 blue:239/255.0 alpha:1.0];
            
        case SHPostColorYellow:
            return [UIColor colorWithRed:255/255.0 green:243/255.0 blue:112/255.0 alpha:1.0];
        default:
            return [UIColor whiteColor];
            break;
    }
}

#pragma mark -
#pragma mark Time

- (NSString *)relativeTimefromDate:(NSDate *)targetDate shortened:(BOOL)shortened condensed:(BOOL)condensed
{
    NSDate *currentTime = [NSDate date];
    
    NSDateComponents *targetDateComponents = [_calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:targetDate];
    NSInteger targetHour = [targetDateComponents hour];
    NSInteger targetMinute = [targetDateComponents minute];
    NSString *timePeriod = @"am";
    
    if ( targetHour > 12 ) // Convert back to 12-hour format for display purposes.
    {
        targetHour -= 12;
        timePeriod = @"pm";
    }
    
    if ( targetHour == 12 ) // This needs its own fix for the case of 12 pm.
    {
        timePeriod = @"pm";
    }
    
    if ( targetHour == 0 )
    {
        targetHour = 12;
        timePeriod = @"am";
    }
    
    int timeElapsed = [targetDate timeIntervalSinceDate:currentTime] * -1; // In seconds.
    int minute = 60;
    int hour = 60 * 60;
    int day = 60 * 60 * 24;
    int month = 60 * 60 * 24 * 30;
    
    if ( timeElapsed < 1 * minute )
    {
        if ( shortened )
        {
            return @"now";
        }
        
        return @"just now";
    }
    
    if ( timeElapsed < 2 * minute )
    {
        if ( condensed )
        {
            return @"1m ago";
        }
        
        return @"a minute ago";
    }
    
    if ( timeElapsed < 45 * minute )
    {
        if ( shortened )
        {
            return [NSString stringWithFormat:@"%dm ago", (int)floor(timeElapsed / minute)];
        }
        
        return [NSString stringWithFormat:@"%d minutes ago", (int)floor(timeElapsed / minute)];
    }
    
    if ( timeElapsed < 90 * minute - 30 )
    {
        if ( condensed )
        {
            return @"1h ago";
        }
        
        return @"an hour ago";
    }
    
    if ( timeElapsed < 90 * minute - 15 )
    {
        if ( condensed )
        {
            return @"1h ago";
        }
        
        return @"an hour & a half ago";
    }
    
    if ( timeElapsed < 24 * hour )
    {
        int hours = (int)ceil(timeElapsed / hour);
        
        if ( shortened )
        {
            return [NSString stringWithFormat:@"%dh ago", hours];
        }
        
        return [NSString stringWithFormat:@"%d hour%@ ago", hours, hours == 1 ? @"" : @"s"];
    }
    
    if ( timeElapsed < 36 * hour ) // Makes less sense to use exactly 48 hours.
    {
        if ( condensed )
        {
            return @"1d ago.";
        }
        
        return [NSString stringWithFormat:@"yesterday, %d:%02d %@", (int)targetHour, (int)targetMinute, timePeriod];
    }
    
    if ( timeElapsed < 30 * day )
    {
        int days = (int)floor(timeElapsed / day);
        
        if ( condensed )
        {
            return [NSString stringWithFormat:@"%dd ago", days];
        }
        
        if ( shortened )
        {
            return [NSString stringWithFormat:@"%dd ago, %d:%02d %@", days, (int)targetHour, (int)targetMinute, timePeriod];
        }
        
        return [NSString stringWithFormat:@"%d day%@ ago, %d:%02d %@", days, days == 1 ? @"" : @"s", (int)targetHour, (int)targetMinute, timePeriod];
    }
    
    if ( timeElapsed < 12 * month )
    {
        int months = floor(timeElapsed / day / 30);
        
        if ( condensed )
        {
            return [NSString stringWithFormat:@"%dmo ago", months];
        }
        
        if ( shortened )
        {
            return [NSString stringWithFormat:@"%dmo ago, %d:%02d %@", months, (int)targetHour, (int)targetMinute, timePeriod];
        }
        
        return [NSString stringWithFormat:@"%d month%@ ago, %d:%02d %@", months, months == 1 ? @"" : @"s", (int)targetHour, (int)targetMinute, timePeriod];
    }
    else
    {
        int years = floor(timeElapsed / day / 365);
        
        if ( condensed )
        {
            return [NSString stringWithFormat:@"%dy ago", years];
        }
        
        if ( shortened )
        {
            return [NSString stringWithFormat:@"%dy ago, %d:%02d %@", years, (int)targetHour, (int)targetMinute, timePeriod];
        }
        
        return [NSString stringWithFormat:@"%d year%@ ago, %d:%02d %@", years, years == 1 ? @"" : @"s", (int)targetHour, (int)targetMinute, timePeriod];
    }
}

- (NSString *)dayForTime:(NSDate *)targetDate relative:(BOOL)relative condensed:(BOOL)condensed
{
    if ( relative )
    {
        NSDate *dateToday = [NSDate date];
        
        NSDateComponents *dateTodayComponents = [_calendar components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:dateToday];
        NSInteger dayToday = dateTodayComponents.day;
        NSInteger monthToday = dateTodayComponents.month;
        NSInteger yearToday = dateTodayComponents.year;
        
        NSDateComponents *targetDateComponents = [_calendar components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:targetDate];
        NSInteger day = targetDateComponents.day;
        NSInteger month = targetDateComponents.month;
        NSInteger year = targetDateComponents.year;
        
        if ( day == dayToday && month == monthToday && year == yearToday )
        {
            return @"today";
        }
        else if ( day == dayToday - 1 && (month == monthToday || month == monthToday - 1) && year == yearToday ) // Account for the previous day being the last day of the previous month.
        {
            return @"yesterday";
        }
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    
    if ( condensed )
    {
        [dateFormatter setDateFormat:@"ccc, d MMM, yyyy"];
    }
    else
    {
        [dateFormatter setDateFormat:@"cccc, d MMMM, yyyy"];
    }
    
    return [dateFormatter stringFromDate:targetDate];
}

#pragma mark -
#pragma mark Cryptography

- (NSString *)encryptedJSONStringForDataChunk:(NSDictionary *)dataChunk withKey:(NSString *)key
{
    NSMutableData *jsonData = [[NSJSONSerialization dataWithJSONObject:dataChunk options:kNilOptions error:nil] mutableCopy];
    
    // Encrypt the payload.
    NSError *error;
    NSData *encryptedData = [RNEncryptor encryptData:jsonData
                                        withSettings:kRNCryptorAES256Settings
                                            password:key
                                               error:&error];
    
    NSMutableDictionary *finalChunk = [[NSMutableDictionary alloc] initWithObjects:@[[encryptedData base64Encoding]]
                                                                           forKeys:@[@"payload"]];
    
    jsonData = [[NSJSONSerialization dataWithJSONObject:finalChunk options:kNilOptions error:nil] mutableCopy];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return jsonString;
}

- (NSString *)decryptedJSONStringForEncryptedString:(NSString *)encryptedString withKey:(NSString *)key
{
    NSData *data = [NSData dataWithBase64EncodedString:encryptedString];
    
    NSError *error;
    NSData *decryptedData = [RNDecryptor decryptData:data
                                        withPassword:key
                                               error:&error];
    
    NSString *plaintext = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    
    return plaintext;
}

#pragma mark -
#pragma mark Parallax Motion Effects

- (void)registerPrallaxEffectForView:(UIView *)aView depth:(CGFloat)depth
{
	UIInterpolatingMotionEffect *effectX;
	UIInterpolatingMotionEffect *effectY;
    effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
	
	
	effectX.maximumRelativeValue = @(depth);
	effectX.minimumRelativeValue = @(-depth);
	effectY.maximumRelativeValue = @(depth);
	effectY.minimumRelativeValue = @(-depth);
	
	[aView addMotionEffect:effectX];
	[aView addMotionEffect:effectY];
}

- (void)registerPrallaxEffectForBackground:(UIView *)aView depth:(CGFloat)depth
{
	UIInterpolatingMotionEffect *effectX;
	UIInterpolatingMotionEffect *effectY;
    effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
	
	
	effectX.maximumRelativeValue = @(-depth);
	effectX.minimumRelativeValue = @(depth);
	effectY.maximumRelativeValue = @(-depth);
	effectY.minimumRelativeValue = @(depth);
	
	[aView addMotionEffect:effectX];
	[aView addMotionEffect:effectY];
}

- (void)unregisterPrallaxEffectForView:(UIView *)aView
{
    aView.motionEffects = nil;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    if ( _SHToken.length > 0 )
    {
        [_presenceManager setAway];
        
        [_mainMenu.messagesView.initialMessagesFetchedIDs removeAllObjects]; // Clear this out so message state gets refreshed when the user returns to the app.
        [_mainMenu pauseTimeOfDayCheck];
        [_mainMenu stopWallpaperAnimation]; // Save power.
        [_mainMenu pauseMiniFeedRefreshCycle];
        [_locationManager pauseLocationUpdates];
        [_messageManager clearMessageQueue];
        [_messageManager pauseUnreadMessageCheckTimer];
        [_mainMenu.messagesView cancelTypingUpdates];
        [_mainMenu.messagesView cancelTimestampUpdates];
        
        // Check if the user has a passcode enabled.
        NSString *passcode = [_passcodeKeychainItem objectForKey:(__bridge id)(kSecValueData)];
        
        if ( passcode.length > 0 )
        {
            if ( ![_mainMenu.presentedViewController isKindOfClass:[SHPasscodeViewController class]] ) // Check if the passcode window is on-screen.
            {
                [_passcodeWindow resetTimeout];
            }
        }
        
        // Hide the camera UI if it's visible (memory issues).
        if ( _mainMenu.mediaPickerSourceIsCamera )
        {
            [_mainMenu dismissMediaPicker];
        }
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if ( _SHToken.length > 0 )
    {
        [self refreshCurrentUserData];
        [_mainMenu startTimeOfDayCheck];
        
        if ( !_mainMenu.wallpaperIsAnimating )
        {
            [_mainMenu resumeWallpaperAnimation];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_contactManager refreshMagicNumbersWithDB:nil callback:NO]; // Runs every 24 hours.
        });
        
        if ( !_networkManager.masterServerSocket.isConnected )
        {
            _networkManager.networkState = SHNetworkStateOffline;
        }
        
        if ( _preference_LastSeen )
        {
            [_presenceManager setPresence:SHUserPresenceOnline withTargetID:@"-1" forAudience:SHUserPresenceAudienceEveryone];
        }
        else
        {
            [_presenceManager setPresence:SHUserPresenceOnlineMasked withTargetID:@"-1" forAudience:SHUserPresenceAudienceEveryone];
        }
        
        [_presenceManager refreshPresenceForAll];
        [_locationManager resumeLocationUpdates];
        
        // Check if the user has a passcode enabled.
        [_passcodeWindow checkTimeout];
        [_mainMenu.messagesView resumeTimestampUpdates];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    if ( _SHToken.length > 0 )
    {
        [_networkManager disconnect];
    }
}

- (void)application:(UIApplication *)application didChangeStatusBarFrame:(CGRect)oldStatusBarFrame
{
    if ( _strobeLight.position != SHStrobeLightPositionFullScreen )
    {
        _strobeLight.position = _strobeLight.position; // Causes it to redraw itself in the right position.
    }
    
    if ( oldStatusBarFrame.size.height > 20 ) // Returning to the normal 20px status bar.
    {
        if ( (IS_IOS7) )
        {
            _mainMenu.mainWindowContainer.frame = CGRectMake(_mainMenu.mainWindowContainer.frame.origin.x, 0, _screenBounds.size.width, _screenBounds.size.height);
        }
    }
    
    [_mainMenu.messagesView redrawViewForStatusBar:oldStatusBarFrame];
}

#pragma mark -
#pragma mark Push Notifications

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    _device_token = [[deviceToken description] stringByReplacingOccurrencesOfString:@"<" withString:@""];
    _device_token = [_device_token stringByReplacingOccurrencesOfString:@">" withString:@""];
    _device_token = [_device_token stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    //UIAlertView *test = [[UIAlertView alloc] initWithTitle:@"" message:_device_token delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
    //[test show];
    
    [_contactManager downloadLatestCurrentUserData]; // Contact refresh happens inside this method once it completes.
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	NSLog(@"Failed to get device token, error: %@", error);
    _device_token = @"";
    
    [_contactManager downloadLatestCurrentUserData];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if ( userInfo )
    {
        [self handlePushNotification:userInfo withApplicationState:application.applicationState];
    }
}

#pragma mark -
#pragma mark Background Tasks

- (void)beginBackgroundUpdateTask
{
    _BGTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundUpdateTask];
    }];
}

- (void)endBackgroundUpdateTask
{
    [[UIApplication sharedApplication] endBackgroundTask:_BGTask];
    _BGTask = UIBackgroundTaskInvalid;
}

#pragma mark -
#pragma mark Push Notifications

- (void)handlePushNotification:(NSDictionary *)notification withApplicationState:(UIApplicationState)applicationState
{
    NSString *notificationType = [notification objectForKey:@"type"];
    
    if ( [notificationType isEqualToString:@"join"] ) // New contact joined.
    {
        NSString *userID = [notification objectForKey:@"user_id"];
        
        [_contactManager addUser:userID];
    }
    else if ( [notificationType isEqualToString:@"new_follower"] ) // New contact added the user.
    {
        NSString *userID = [notification objectForKey:@"user_id"];
        
        _mainMenu.profileView.ownerID = userID;
        [_mainMenu.profileView loadInfoOverNetwork];
    }
    else if ( [notificationType isEqualToString:@"board_request"] )
    {
        NSString *boardID = [notification objectForKey:@"board_id"];
        
        [_mainMenu showBoardForID:boardID];
    }
    
    if ( applicationState == UIApplicationStateActive ) // App was already in the foreground.
    {
        
    }
    else // App was just brought from background to foreground.
    {
        if ( [notificationType isEqualToString:@"notif_IM"] ) // New contact joined.
        {
            NSString *senderID = [notification objectForKey:@"sender_id"];
            //int64_t groupID = [[notification objectForKey:@"group_id"] intValue];
            //SHUserType senderType = [[notification objectForKey:@"sender_type"] intValue];
            
            [_mainWindowNavigationController popToRootViewControllerAnimated:NO];
            
            if ( _mainMenu.messagesView.recipientID.intValue != senderID.intValue )
            {
                [_mainMenu loadConversationForUser:senderID];
            }
        }
    }
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods.

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ( alertView.tag == 0 ) // Rate app alert.
    {
        if (buttonIndex == 1)
        {
            NSURL *url = [NSURL URLWithString:@"https://itunes.apple.com/us/app/scapes-messenger/id737271884?ls=1&mt=8"];
            
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

@end
