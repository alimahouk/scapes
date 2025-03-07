//
//  SHPasscodeViewController.m
//  Scapes
//
//  Created by MachOSX on 11/13/13.
//
//

#import <Audiotoolbox/AudioToolbox.h>
#import "SHPasscodeViewController.h"

@implementation SHPasscodeViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        lockupDelays = @[@"1",
                         @"6",
                         @"21",
                         @"81",
                         @"141"];
    }
    
    return self;
}

- (void)loadView
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    UIView *contentView = [[UIView alloc] initWithFrame:screenBounds];
    contentView.backgroundColor = [UIColor whiteColor];
    
    passcodeField = [[UITextField alloc] init];
    passcodeField.secureTextEntry = YES;
    passcodeField.keyboardType = UIKeyboardTypeNumberPad;
    passcodeField.delegate = self;
    
    headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 280, 21)];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textColor = [UIColor blackColor];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE];
    headerLabel.opaque = YES;
    
    lockTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, screenBounds.size.height - 155, 280, 35)];
    lockTimeLabel.backgroundColor = [UIColor clearColor];
    lockTimeLabel.textColor = [UIColor blackColor];
    lockTimeLabel.textAlignment = NSTextAlignmentCenter;
    lockTimeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:32];
    lockTimeLabel.opaque = YES;
    lockTimeLabel.alpha = 0.0;
    lockTimeLabel.hidden = YES;
    
    lockTimeDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, screenBounds.size.height - 190, 280, 21)];
    lockTimeDescriptionLabel.backgroundColor = [UIColor clearColor];
    lockTimeDescriptionLabel.textColor = [UIColor blackColor];
    lockTimeDescriptionLabel.textAlignment = NSTextAlignmentCenter;
    lockTimeDescriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE];
    lockTimeDescriptionLabel.opaque = YES;
    lockTimeDescriptionLabel.text = NSLocalizedString(@"PASSCODE_DELAY_DESCRIPTION", nil);
    lockTimeDescriptionLabel.alpha = 0.0;
    lockTimeDescriptionLabel.hidden = YES;
    
    dotContainer = [[UIView alloc] initWithFrame:CGRectMake(104, 150, 150, 22)];
    
    dot_1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    dot_1.image = [UIImage imageNamed:@"passcode_dot"];
    dot_1.opaque = YES;
    
    dot_2 = [[UIImageView alloc] initWithFrame:CGRectMake(30, 0, 22, 22)];
    dot_2.image = [UIImage imageNamed:@"passcode_dot"];
    dot_2.opaque = YES;
    
    dot_3 = [[UIImageView alloc] initWithFrame:CGRectMake(60, 0, 22, 22)];
    dot_3.image = [UIImage imageNamed:@"passcode_dot"];
    dot_3.opaque = YES;
    
    dot_4 = [[UIImageView alloc] initWithFrame:CGRectMake(90, 0, 22, 22)];
    dot_4.image = [UIImage imageNamed:@"passcode_dot"];
    dot_4.opaque = YES;
    
    dotFill_1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    dotFill_1.image = [UIImage imageNamed:@"passcode_dot_filled"];
    dotFill_1.opaque = YES;
    dotFill_1.alpha = 0.0;
    
    dotFill_2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    dotFill_2.image = [UIImage imageNamed:@"passcode_dot_filled"];
    dotFill_2.opaque = YES;
    dotFill_2.alpha = 0.0;
    
    dotFill_3 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    dotFill_3.image = [UIImage imageNamed:@"passcode_dot_filled"];
    dotFill_3.opaque = YES;
    dotFill_3.alpha = 0.0;
    
    dotFill_4 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    dotFill_4.image = [UIImage imageNamed:@"passcode_dot_filled"];
    dotFill_4.opaque = YES;
    dotFill_4.alpha = 0.0;
    
    dismissWindowButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [dismissWindowButton setTitle:NSLocalizedString(@"GENERIC_CANCEL", nil) forState:UIControlStateNormal];
    [dismissWindowButton setTitleColor:[UIColor colorWithWhite:0.0 alpha:0.7] forState:UIControlStateNormal];
    [dismissWindowButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [dismissWindowButton addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchUpInside];
    dismissWindowButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE];
    dismissWindowButton.frame = CGRectMake(0, 30, 68, 30);
    
    forgotPasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [forgotPasswordButton setTitle:@"?" forState:UIControlStateNormal];
    [forgotPasswordButton setTitleColor:[UIColor colorWithWhite:0.0 alpha:0.7] forState:UIControlStateNormal];
    forgotPasswordButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE];
    forgotPasswordButton.frame = CGRectMake(screenBounds.size.width / 2 - 20, dotContainer.frame.origin.y + dotContainer.frame.size.height + 60, 40, 40);
    forgotPasswordButton.showsTouchWhenHighlighted = YES;
    forgotPasswordButton.alpha = 0.0;
    forgotPasswordButton.hidden = YES;
    
    [contentView addSubview:passcodeField];
    [contentView addSubview:headerLabel];
    [contentView addSubview:dotContainer];
    [contentView addSubview:dismissWindowButton];
    [contentView addSubview:forgotPasswordButton];
    [contentView addSubview:lockTimeLabel];
    [contentView addSubview:lockTimeDescriptionLabel];
    [dotContainer addSubview:dot_1];
    [dotContainer addSubview:dot_2];
    [dotContainer addSubview:dot_3];
    [dotContainer addSubview:dot_4];
    [dot_1 addSubview:dotFill_1];
    [dot_2 addSubview:dotFill_2];
    [dot_3 addSubview:dotFill_3];
    [dot_4 addSubview:dotFill_4];
    
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
    [passcodeField becomeFirstResponder];
    
    // Read how many unsuccessful passcode attempts were previously made.
    NSString *attempts = [[NSUserDefaults standardUserDefaults] stringForKey:@"SHPasscodeAttempts"];
    
    if ( attempts.length > 0 )
    {
        attemptCount = attempts.intValue;
    }
    else
    {
        attemptCount = 0;
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:attemptCount] forKey:@"SHPasscodeAttempts"]; // Save the number of attempts.
    }
    
    // Check if a passcode delay was previously set.
    NSString *passcodeDelay = [[NSUserDefaults standardUserDefaults] stringForKey:@"SHPasscodeDelayTime"];
    
    if ( passcodeDelay.length > 0 )
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        
        unlockTime = [dateFormatter dateFromString:passcodeDelay];
        
        [self lockUIAsResume:YES];
    }
    
    // Reset these.
    _authenticationPassed = NO;
    isAuthenticating = NO;
    isConfirmingPasscode = NO;
    isTestingAgainstCases = NO;
    
    // Customize the UI based on the window mode.
    switch ( windowMode )
    {
        case SHPasscodeWindowModeAuthenticate:
        {
            headerLabel.text = NSLocalizedString(@"PASSCODE_TITLE_MAIN", nil);
            currentPasscode = [appDelegate.passcodeKeychainItem objectForKey:(__bridge id)(kSecValueData)];
            
            dismissWindowButton.hidden = YES;
            break;
        }
            
        case SHPasscodeWindowModeDismissableAuthenticate:
        {
            headerLabel.text = NSLocalizedString(@"PASSCODE_TITLE_MAIN", nil);
            currentPasscode = [appDelegate.passcodeKeychainItem objectForKey:(__bridge id)(kSecValueData)];
            
            dismissWindowButton.hidden = NO;
            break;
        }
            
        case SHPasscodeWindowModeFreshPasscode:
        {
            headerLabel.text = NSLocalizedString(@"PASSCODE_TITLE_NEW", nil);
            
            dismissWindowButton.hidden = NO;
            break;
        }
            
        case SHPasscodeWindowModeChangePasscode:
        {
            headerLabel.text = NSLocalizedString(@"PASSCODE_TITLE_OLD", nil);
            currentPasscode = [appDelegate.passcodeKeychainItem objectForKey:(__bridge id)(kSecValueData)];
            
            dismissWindowButton.hidden = NO;
            break;
        }
            
        default:
            break;
    }
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Reset everything here.
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight restoreOldPosition];
    
    forgotPasswordButton.alpha = 0.0;
    forgotPasswordButton.hidden = YES;
    
    dotFill_1.alpha = 0.0;
    dotFill_2.alpha = 0.0;
    dotFill_3.alpha = 0.0;
    dotFill_4.alpha = 0.0;
    passcodeField.text = @"";
    
    attemptCount = 0;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:attemptCount] forKey:@"SHPasscodeAttempts"];
    
    [super viewWillDisappear:animated];
}

- (void)dismissView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)shakeWithReset:(BOOL)reset
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight negativeStrobeLight];
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); // Vibrate.
    passcodeField.text = @"";
    newPasscode = @"";
    
    if ( reset ) // This condition takes place only if the user is changing the passcode, not adding a fresh one.
    {
        if ( windowMode == SHPasscodeWindowModeChangePasscode )
        {
            headerLabel.text = NSLocalizedString(@"PASSCODE_TITLE_OLD", nil);
        }
        else
        {
            headerLabel.text = NSLocalizedString(@"PASSCODE_TITLE_MAIN", nil);
        }
        
        forgotPasswordButton.hidden = NO;
        
        if (++attemptCount >= 6)
        {
            [self lockUIAsResume:NO];
        }
    }
    else
    {
        headerLabel.text = NSLocalizedString(@"PASSCODE_TITLE_CONFIRM_ERROR", nil);
    }
    
    // Save the number of attempts. This gets around the intruder restarting the app to reset the count.
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:attemptCount] forKey:@"SHPasscodeAttempts"];
    
    [UIView animateWithDuration:0.07 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        dotContainer.frame = CGRectMake(dotContainer.frame.origin.x - 30, dotContainer.frame.origin.y, dotContainer.frame.size.width, dotContainer.frame.size.height);
        dotFill_1.alpha = 0.0;
        dotFill_2.alpha = 0.0;
        dotFill_3.alpha = 0.0;
        dotFill_4.alpha = 0.0;
        
        if ( reset )
        {
            forgotPasswordButton.alpha = 1.0;
        }
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.07 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            dotContainer.frame = CGRectMake(dotContainer.frame.origin.x + 50, dotContainer.frame.origin.y, dotContainer.frame.size.width, dotContainer.frame.size.height);
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.07 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                dotContainer.frame = CGRectMake(dotContainer.frame.origin.x - 35, dotContainer.frame.origin.y, dotContainer.frame.size.width, dotContainer.frame.size.height);
            } completion:^(BOOL finished){
                [UIView animateWithDuration:0.07 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    dotContainer.frame = CGRectMake(dotContainer.frame.origin.x + 20, dotContainer.frame.origin.y, dotContainer.frame.size.width, dotContainer.frame.size.height);
                } completion:^(BOOL finished){
                    [UIView animateWithDuration:0.07 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                        dotContainer.frame = CGRectMake(dotContainer.frame.origin.x - 5, dotContainer.frame.origin.y, dotContainer.frame.size.width, dotContainer.frame.size.height);
                    } completion:^(BOOL finished){
                        
                    }];
                }];
            }];
        }];
    }];
}

- (void)lockUIAsResume:(BOOL)resume
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    // Waiting time varies depending on the number of past failed attempts.
    int delay = 0;
    
    if ( !resume ) // Freshly-locked UI.
    {
        if ( attemptCount >= 11 )
        {
            delay = [[lockupDelays objectAtIndex:4] intValue];
        }
        else
        {
            delay = [[lockupDelays objectAtIndex:attemptCount - 5] intValue];
        }
        
        delay *= 60; // Convert to seconds.
        
        NSDate *timeNow = [NSDate date];
        unlockTime = [timeNow dateByAddingTimeInterval:delay];
        
        // Note: the date must be saved as an NSString, not an NSDate.
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        
        // Save the delay. This gets around the intruder restarting the app to reset the it.
        [[NSUserDefaults standardUserDefaults] setObject:[dateFormatter stringFromDate:unlockTime] forKey:@"SHPasscodeDelayTime"];
    }
    else // We're resuming a lock.
    {
        delay = [unlockTime timeIntervalSinceReferenceDate];
    }
    
    timer_UILock = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(unlockUI) userInfo:nil repeats:NO];
    timer_UILockLabel = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(updateLockTimeLabel) userInfo:nil repeats:YES];
    
    lockTimeLabel.hidden = NO;
    lockTimeDescriptionLabel.hidden = NO;
    [UIView animateWithDuration:0.07 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        lockTimeLabel.frame = CGRectMake(20, screenBounds.size.height - 165, 280, 28);
        lockTimeDescriptionLabel.frame = CGRectMake(20, screenBounds.size.height - 200, 280, 28);
        lockTimeLabel.alpha = 1.0;
        lockTimeDescriptionLabel.alpha = 1.0;
    } completion:^(BOOL finished){
        
    }];
    
    dismissWindowButton.enabled = NO;
    [passcodeField resignFirstResponder];
    [self updateLockTimeLabel];
}

- (void)unlockUI
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    [timer_UILock invalidate];
    [timer_UILockLabel invalidate];
    timer_UILock = nil;
    timer_UILockLabel = nil;
    unlockTime = nil;
    
    [UIView animateWithDuration:0.07 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        lockTimeLabel.frame = CGRectMake(20, screenBounds.size.height - 155, 280, 28);
        lockTimeDescriptionLabel.frame = CGRectMake(20, screenBounds.size.height - 190, 280, 28);
        lockTimeLabel.alpha = 0.0;
        lockTimeDescriptionLabel.alpha = 0.0;
    } completion:^(BOOL finished){
        lockTimeLabel.hidden = YES;
        lockTimeDescriptionLabel.hidden = YES;
    }];
    
    dismissWindowButton.enabled = YES;
    [passcodeField becomeFirstResponder];
}

- (void)updateLockTimeLabel
{
    NSDate *date = [NSDate date];
    
    int currentSeconds = [date timeIntervalSinceReferenceDate];
    int unlockTimeSeconds = [unlockTime timeIntervalSinceReferenceDate];
    
    int timeLeftInSeconds = unlockTimeSeconds - currentSeconds;
    
    if ( timeLeftInSeconds < 0 ) // The delay time has already elapsed.
    {
        [self unlockUI];
    }
    else
    {
        int timeLeftInMinutes = (timeLeftInSeconds + 59) / 60;
        
        NSString *displayString;
        
        if ( timeLeftInMinutes == 1 )
        {
            displayString = NSLocalizedString(@"PASSCODE_DELAY_TIME_1_MIN", nil);
        }
        else
        {
            displayString = [NSString stringWithFormat:NSLocalizedString(@"PASSCODE_DELAY_TIME", nil), timeLeftInMinutes];
        }
        
        lockTimeLabel.text = displayString;
    }
}

- (void)presentNewPasswordPrompt
{
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        headerLabel.frame = CGRectMake(-headerLabel.frame.size.width, headerLabel.frame.origin.y, headerLabel.frame.size.width, headerLabel.frame.size.height);
        dotContainer.frame = CGRectMake(-dotContainer.frame.size.width, dotContainer.frame.origin.y, dotContainer.frame.size.width, dotContainer.frame.size.height);
    } completion:^(BOOL finished){
        headerLabel.text = NSLocalizedString(@"PASSCODE_TITLE_NEW", nil);
        headerLabel.frame = CGRectMake(320, headerLabel.frame.origin.y, headerLabel.frame.size.width, headerLabel.frame.size.height);
        dotContainer.frame = CGRectMake(320, dotContainer.frame.origin.y, dotContainer.frame.size.width, dotContainer.frame.size.height);
        
        dotFill_1.alpha = 0.0;
        dotFill_2.alpha = 0.0;
        dotFill_3.alpha = 0.0;
        dotFill_4.alpha = 0.0;
        passcodeField.text = @"";
        
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            headerLabel.frame = CGRectMake(0, headerLabel.frame.origin.y, headerLabel.frame.size.width, headerLabel.frame.size.height);
            dotContainer.frame = CGRectMake(84, 150, 150, 22);
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                headerLabel.frame = CGRectMake(20, headerLabel.frame.origin.y, headerLabel.frame.size.width, headerLabel.frame.size.height);
                dotContainer.frame = CGRectMake(104, 150, 150, 22);
            } completion:^(BOOL finished){
                
            }];
        }];
    }];
}

- (void)presentConfirmationPrompt
{
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        headerLabel.frame = CGRectMake(-headerLabel.frame.size.width, headerLabel.frame.origin.y, headerLabel.frame.size.width, headerLabel.frame.size.height);
        dotContainer.frame = CGRectMake(-dotContainer.frame.size.width, dotContainer.frame.origin.y, dotContainer.frame.size.width, dotContainer.frame.size.height);
    } completion:^(BOOL finished){
        headerLabel.text = NSLocalizedString(@"PASSCODE_TITLE_CONFIRM", nil);
        headerLabel.frame = CGRectMake(320, headerLabel.frame.origin.y, headerLabel.frame.size.width, headerLabel.frame.size.height);
        dotContainer.frame = CGRectMake(320, dotContainer.frame.origin.y, dotContainer.frame.size.width, dotContainer.frame.size.height);
        
        dotFill_1.alpha = 0.0;
        dotFill_2.alpha = 0.0;
        dotFill_3.alpha = 0.0;
        dotFill_4.alpha = 0.0;
        passcodeField.text = @"";
        
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            headerLabel.frame = CGRectMake(0, headerLabel.frame.origin.y, headerLabel.frame.size.width, headerLabel.frame.size.height);
            dotContainer.frame = CGRectMake(84, 150, 150, 22);
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                headerLabel.frame = CGRectMake(20, headerLabel.frame.origin.y, headerLabel.frame.size.width, headerLabel.frame.size.height);
                dotContainer.frame = CGRectMake(104, 150, 150, 22);
            } completion:^(BOOL finished){
                
            }];
        }];
    }];
}

- (void)testAgainstCases:(NSArray *)cases
{
    passcodeTestCases = cases;
    isTestingAgainstCases = YES;
}

- (void)setMode:(SHPasscodeWindowMode)theWindowMode
{
    windowMode = theWindowMode;
}

- (void)textFieldDidChange:(id)sender
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UITextField *textField = (UITextField *)sender;
    
    NSString *pin = textField.text;
    
    // Only numberic characters are allowed.
    NSCharacterSet *notAllowedChars = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890"] invertedSet];
    pin = [[pin componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
    pin = [pin stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    switch ( pin.length )
    {
        case 0:
        {
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                dotFill_1.alpha = 0.0;
            } completion:^(BOOL finished){
                
            }];
            
            break;
        }
            
        case 1:
        {
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                dotFill_1.alpha = 1.0;
                dotFill_2.alpha = 0.0;
            } completion:^(BOOL finished){
                
            }];
            
            break;
        }
          
        case 2:
        {
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                dotFill_2.alpha = 1.0;
                dotFill_3.alpha = 0.0;
            } completion:^(BOOL finished){
                
            }];
            
            break;
        }
            
        case 3:
        {
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                dotFill_3.alpha = 1.0;
                dotFill_4.alpha = 0.0;
            } completion:^(BOOL finished){
                
            }];
            
            break;
        }
            
        case 4:
        {
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                dotFill_4.alpha = 1.0;
            } completion:^(BOOL finished){
                
                switch ( windowMode )
                {
                    case SHPasscodeWindowModeAuthenticate:
                    {
                        if ( !isAuthenticating )
                        {
                            if ( isTestingAgainstCases )
                            {
                                for ( NSString *testCase in passcodeTestCases )
                                {
                                    if ( [pin isEqualToString:testCase] )
                                    {
                                        isAuthenticating = YES;
                                        
                                        [self dismissView];
                                        [self passcodeViewDidAuthenticate];
                                        
                                        return;
                                    }
                                }
                                
                                [self shakeWithReset:NO];
                            }
                            else
                            {
                                if ( [pin isEqualToString:currentPasscode] )
                                {
                                    isAuthenticating = YES;
                                    
                                    [self dismissView];
                                    [appDelegate.strobeLight affirmativeStrobeLight];
                                    [self passcodeViewDidAuthenticate];
                                }
                                else
                                {
                                    [self shakeWithReset:YES];
                                }
                            }
                            
                        }
                        
                        break;
                    }
                        
                    case SHPasscodeWindowModeDismissableAuthenticate:
                    {
                        if ( !isAuthenticating )
                        {
                            if ( [pin isEqualToString:currentPasscode] )
                            {
                                isAuthenticating = YES;
                                
                                [self dismissView];
                                [appDelegate.strobeLight affirmativeStrobeLight];
                                [self passcodeViewDidAuthenticate];
                            }
                            else
                            {
                                [self shakeWithReset:YES];
                            }
                        }
                        
                        break;
                    }
                        
                    case SHPasscodeWindowModeFreshPasscode:
                    {
                        if ( !isConfirmingPasscode )
                        {
                            isConfirmingPasscode = YES;
                            newPasscode = pin;
                            
                            [self presentConfirmationPrompt];
                        }
                        else // Confirmation.
                        {
                            if ( [pin isEqualToString:newPasscode] )
                            {
                                // Save the passcode in the Keychain.
                                [appDelegate.passcodeKeychainItem setObject:newPasscode forKey:(__bridge id)(kSecValueData)];
                                
                                // Save the default timeout value.
                                [[NSUserDefaults standardUserDefaults] setObject:@"5" forKey:@"SHBDPasscodeTimeout"];
                                
                                [self passcodeViewDidAcceptNewPasscode];
                                [self dismissView];
                            }
                            else
                            {
                                isConfirmingPasscode = NO;
                                [self shakeWithReset:NO];
                            }
                        }
                        
                        break;
                    }
                        
                    case SHPasscodeWindowModeChangePasscode:
                    {
                        if ( !isAuthenticating )
                        {
                            if ( [pin isEqualToString:currentPasscode] )
                            {
                                isAuthenticating = YES;
                                
                                [self presentNewPasswordPrompt];
                            }
                            else
                            {
                                [self shakeWithReset:YES];
                            }
                        }
                        else if ( !isConfirmingPasscode )
                        {
                            isConfirmingPasscode = YES;
                            newPasscode = pin;
                            
                            [self presentConfirmationPrompt];
                        }
                        else // Confirmation.
                        {
                            if ( [pin isEqualToString:newPasscode] )
                            {
                                [self passcodeViewShouldChangeToNewPasscode:newPasscode];
                                [self dismissView];
                                [appDelegate.strobeLight affirmativeStrobeLight];
                            }
                            else
                            {
                                isAuthenticating = NO;
                                isConfirmingPasscode = NO;
                                [self shakeWithReset:NO];
                            }
                        }
                        break;
                    }
                        
                    default:
                        break;
                }
            }];
            
            break;
        }
            
        default:
            break;
    }
}

- (void)checkTimeout
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Check if the user has a passcode enabled.
        NSString *passcode = [appDelegate.passcodeKeychainItem objectForKey:(__bridge id)(kSecValueData)];
        
        if ( passcode.length > 0 )
        {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
            
            NSString *lastUnlock = [appDelegate.currentUser objectForKey:@"last_passcode_unlock"];
            NSDate *lastUnlockTime;
            
            NSDate *dateToday = [NSDate date];
            lastUnlockTime = [dateFormatter dateFromString:lastUnlock];
            
            int passcodeTimeout = [[[NSUserDefaults standardUserDefaults] stringForKey:@"SHBDPasscodeTimeout"] intValue] * 60; // Value is originally in minutes.
            
            if ( passcodeTimeout == 0 || [dateToday timeIntervalSinceDate:lastUnlockTime] >= passcodeTimeout ) // Timeout's passed.
            {
                // First check to make sure the window's not already on-screen.
                BOOL modalPresent = (BOOL)(appDelegate.mainMenu.presentedViewController);
                
                if ( !modalPresent )
                {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [self setMode:SHPasscodeWindowModeAuthenticate];
                        [appDelegate.mainMenu presentViewController:self animated:YES completion:nil];
                    });
                }
            }
        }
    });
}

- (void)resetTimeout
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    // Reset the timer.
    NSString *timeNow = [appDelegate.modelManager dateTodayString];
    
    [appDelegate.modelManager executeUpdate:@"UPDATE sh_current_user SET last_passcode_unlock = :last_passcode_unlock"
                    withParameterDictionary:@{@"last_passcode_unlock": timeNow}];
    
    [appDelegate.currentUser setObject:timeNow forKey:@"last_passcode_unlock"];
}

#pragma mark -
#pragma mark UITextFieldDelegate methods.

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Monitor keystrokes.
    [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

#pragma mark -
#pragma mark SHPasscodeViewDelegate methods.

- (void)passcodeViewDidAuthenticate
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    attemptCount = 0;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:attemptCount] forKey:@"SHPasscodeAttempts"]; // Reset the number of attempts.
    
    NSString *timeNow = [appDelegate.modelManager dateTodayString];
    
    [appDelegate.currentUser setObject:timeNow forKey:@"last_passcode_unlock"];
    
    [appDelegate.modelManager executeUpdate:@"UPDATE sh_current_user SET last_passcode_unlock = :last_passcode_unlock"
                    withParameterDictionary:@{@"last_passcode_unlock": timeNow}];
    
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"SHPasscodeDelayTime"]; // Clear this out.
    
    if ( [_delegate respondsToSelector:@selector(passcodeViewDidAuthenticate)] )
    {
        [_delegate passcodeViewDidAuthenticate];
    }
}

- (void)passcodeViewDidAcceptNewPasscode
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSString *timeNow = [appDelegate.modelManager dateTodayString];
    
    [appDelegate.modelManager executeUpdate:@"UPDATE sh_current_user SET last_passcode_unlock = :last_passcode_unlock"
                    withParameterDictionary:@{@"last_passcode_unlock": timeNow}];
    
    if ( [_delegate respondsToSelector:@selector(passcodeViewDidAcceptNewPasscode)] )
    {
        [_delegate passcodeViewDidAcceptNewPasscode];
    }
}

- (void)passcodeViewShouldChangeToNewPasscode:(NSString *)passcode
{
    if ( [_delegate respondsToSelector:@selector(passcodeViewShouldChangeToNewPasscode:)] )
    {
        [_delegate passcodeViewShouldChangeToNewPasscode:passcode];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
