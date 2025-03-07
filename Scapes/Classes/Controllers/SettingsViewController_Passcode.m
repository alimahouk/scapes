//
//  SettingsViewController_Passcode.m
//  Scapes
//
//  Created by MachOSX on 11/13/13.
//
//

#import "SettingsViewController_Passcode.h"

#import "AFHTTPRequestOperationManager.h"
#import "SettingsViewController_PasscodeTimeout.h"
#import "SHPasscodeViewController.h"

@implementation SettingsViewController_Passcode

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        isRemovingPasscode = NO;
        
        currentPasscode = [appDelegate.passcodeKeychainItem objectForKey:(__bridge id)(kSecValueData)];
        NSDictionary *temp;
        
        if ( currentPasscode.length > 0 )
        {
            NSArray *arrTemp1 = [[NSArray alloc]
                                 initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_CHANGE_PASSCODE", nil), NSLocalizedString(@"SETTINGS_OPTION_DELETE_PASSCODE", nil), nil];
            NSArray *arrTemp2 = [[NSArray alloc]
                                 initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_REQUIRE_PASSCODE", nil), nil];
            temp = [[NSDictionary alloc]
                   initWithObjectsAndKeys:arrTemp1, @"1", arrTemp2,
                   @"2", nil];
        }
        else // No exisiting passcode.
        {
            NSArray *arrTemp1 = [[NSArray alloc]
                                 initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_NEW_PASSCODE", nil), nil];
            temp = [[NSDictionary alloc]
                   initWithObjectsAndKeys:arrTemp1, @"1", nil];
        }
        
        
        tableContents = temp;
        sortedKeys = [[tableContents allKeys] sortedArrayUsingSelector:@selector(compare:)];
    }
    
    return self;
}

- (void)loadView
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    UIView *contentView = [[UIView alloc] initWithFrame:screenBounds];
    contentView.backgroundColor = [UIColor whiteColor];
    
    settingsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height) style:UITableViewStyleGrouped];
    settingsTableView.delegate = self;
    settingsTableView.dataSource = self;
    settingsTableView.backgroundView = nil; // Fix for iOS 6+.
    settingsTableView.backgroundColor = [UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0];
    
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        settingsTableView.frame = CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height - 64);
    }
    
    [contentView addSubview:settingsTableView];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    [self setTitle:NSLocalizedString(@"SETTINGS_TITLE_PASSCODE", nil)];
    
    // Gestures.
    // A lil' easter egg. Swipe to the right to go back!
    viewSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goBack)];
    [viewSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [settingsTableView addGestureRecognizer:viewSwipeRecognizer];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [settingsTableView reloadData];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if ( viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count - 2] == self ) // View is disappearing because a new view controller was pushed onto the stack.
    {
        
    }
    else if ( [viewControllers indexOfObject:self] == NSNotFound ) // View is disappearing because it was popped from the stack.
    {
        appDelegate.passcodeWindow.delegate = nil;
    }
    
    [super viewWillDisappear:animated];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Password Checks

- (void)checkForPassword
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:@"SHUserHasPassword"];
    
    if ( password.length > 0 ) // User already has a password set. Allow them to create a passcode.
    {
        [appDelegate.passcodeWindow setMode:SHPasscodeWindowModeFreshPasscode];
        appDelegate.passcodeWindow.delegate = self;
        
        [self.navigationController presentViewController:appDelegate.passcodeWindow animated:YES completion:nil];
    }
    else
    {
        [appDelegate.strobeLight activateStrobeLight];
        
        // Show the HUD.
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        
        HUD.customView = [[UIImageView alloc] init];
        HUD.mode = MBProgressHUDModeIndeterminate;
        HUD.dimBackground = YES;
        HUD.delegate = self;
        [HUD show:YES];
        
        NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                     @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]};
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/checkforpassword", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSString *response = operation.responseString;
            
            if ( [response hasPrefix:@"while(1);"] )
            {
                response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
            }
            
            response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
            NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
            
            [HUD hide:YES];
            
            if ( responseData )
            {
                int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
                
                if ( errorCode == 0 ) // User already has a password set. Allow them to create a passcode.
                {
                    [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"SHUserHasPassword"];
                    
                    [appDelegate.strobeLight deactivateStrobeLight];
                    
                    [appDelegate.passcodeWindow setMode:SHPasscodeWindowModeFreshPasscode];
                    appDelegate.passcodeWindow.delegate = self;
                    
                    [self.navigationController presentViewController:appDelegate.passcodeWindow animated:YES completion:nil];
                }
                else if ( errorCode == 404 ) // No password. Ask the user to create one.
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                    message:NSLocalizedString(@"SETTINGS_DESCRIPTION_PASSCODE_PASSWORD", nil)
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                                          otherButtonTitles:NSLocalizedString(@"GENERIC_DONE", nil), nil];
                    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                    [alert show];
                    
                    [appDelegate.strobeLight deactivateStrobeLight];
                }
                else
                {
                    [self showNetworkError];
                }
            }
            else // Some error occurred...
            {
                [self showNetworkError];
            }
            
            NSLog(@"Response: %@", responseData);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self showNetworkError];
            
            NSLog(@"Error: %@", operation.responseString);
        }];
    }
}

- (void)createPassword:(NSString *)password
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight activateStrobeLight];
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[password]
                                                                          forKeys:@[@"password"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/setpassword", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        [HUD hide:YES];
        
        if ( responseData )
        {
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            if ( errorCode == 0 )
            {
                [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"SHUserHasPassword"];
                
                [appDelegate.strobeLight deactivateStrobeLight];
                
                [appDelegate.passcodeWindow setMode:SHPasscodeWindowModeFreshPasscode];
                appDelegate.passcodeWindow.delegate = self;
                
                [self.navigationController presentViewController:appDelegate.passcodeWindow animated:YES completion:nil];
            }
            else
            {
                [self showNetworkError];
            }
        }
        else // Some error occurred...
        {
            [self showNetworkError];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

#pragma mark -
#pragma mark Password Checks

- (void)createPasscode
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSString *newPasscode = [appDelegate.passcodeKeychainItem objectForKey:(__bridge id)(kSecValueData)];
    
    [appDelegate.strobeLight activateStrobeLight];
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[newPasscode]
                                                                          forKeys:@[@"passcode"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/addpasscode", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        [HUD hide:YES];
        
        if ( responseData )
        {
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            if ( errorCode == 0 )
            {
                currentPasscode = newPasscode;
                
                // The passcode's already saved in the Keychain at this point.
                NSArray *arrTemp1 = [[NSArray alloc]
                                     initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_CHANGE_PASSCODE", nil), NSLocalizedString(@"SETTINGS_OPTION_DELETE_PASSCODE", nil), nil];
                NSArray *arrTemp2 = [[NSArray alloc]
                                     initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_REQUIRE_PASSCODE", nil), nil];
                NSDictionary *temp = [[NSDictionary alloc]
                                      initWithObjectsAndKeys:arrTemp1, @"1", arrTemp2,
                                      @"2", nil];
                
                tableContents = temp;
                sortedKeys = [[tableContents allKeys] sortedArrayUsingSelector:@selector(compare:)];
                
                [settingsTableView reloadData];
                
                [appDelegate.strobeLight affirmativeStrobeLight];
            }
            else
            {
                [appDelegate.passcodeKeychainItem resetKeychainItem]; // Remove the new passcode.
                
                NSArray *arrTemp1 = [[NSArray alloc]
                                     initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_NEW_PASSCODE", nil), nil];
                NSDictionary *temp = [[NSDictionary alloc]
                                      initWithObjectsAndKeys:arrTemp1, @"1", nil];
                
                tableContents = temp;
                sortedKeys = [[tableContents allKeys] sortedArrayUsingSelector:@selector(compare:)];
                
                [settingsTableView reloadData];
                
                [self showNetworkError];
            }
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [appDelegate.passcodeKeychainItem resetKeychainItem]; // Remove the new passcode.
        
        NSArray *arrTemp1 = [[NSArray alloc]
                             initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_NEW_PASSCODE", nil), nil];
        NSDictionary *temp = [[NSDictionary alloc]
                              initWithObjectsAndKeys:arrTemp1, @"1", nil];
        
        tableContents = temp;
        sortedKeys = [[tableContents allKeys] sortedArrayUsingSelector:@selector(compare:)];
        
        [settingsTableView reloadData];
        
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)removePasscode
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSString *passcode = [appDelegate.passcodeKeychainItem objectForKey:(__bridge id)(kSecValueData)];
    
    [appDelegate.strobeLight activateStrobeLight];
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[passcode]
                                                                          forKeys:@[@"passcode"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/removepasscode", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        if ( responseData )
        {
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            if ( errorCode == 0 )
            {
                currentPasscode = @"";
                
                [appDelegate.passcodeKeychainItem resetKeychainItem]; // Remove the new passcode.
                [appDelegate.passcodeKeychainItem resetKeychainItem]; // For some reason, doing it once is not enough.
                
                NSArray *arrTemp1 = [[NSArray alloc]
                                     initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_NEW_PASSCODE", nil), nil];
                NSDictionary *temp = [[NSDictionary alloc]
                                      initWithObjectsAndKeys:arrTemp1, @"1", nil];
                
                tableContents = temp;
                sortedKeys = [[tableContents allKeys] sortedArrayUsingSelector:@selector(compare:)];
                
                [settingsTableView reloadData];
                
                [appDelegate.strobeLight deactivateStrobeLight];
            }
            else
            {
                [self showNetworkError];
            }
        }
        else // Some error occurred...
        {
            [self showNetworkError];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
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
#pragma mark UITableViewDataSource methods.

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return sortedKeys.count;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
	NSArray *listData = [tableContents objectForKey:[sortedKeys objectAtIndex:section]];
    
	return listData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"CellIdentifier";
    
    NSArray *listData = [tableContents objectForKey:[sortedKeys objectAtIndex:indexPath.section]];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    UILabel *accessoryLabel;
    
	if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // Set the accessory type.
        cell.textLabel.backgroundColor = [UIColor clearColor];
        
        accessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(180, 0, 100, cell.frame.size.height)];
        accessoryLabel.backgroundColor = [UIColor clearColor];
        accessoryLabel.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
        accessoryLabel.textAlignment = NSTextAlignmentRight;
        accessoryLabel.tag = 7;
        accessoryLabel.hidden = YES;
        
        if ( !(IS_IOS7) )
        {
            accessoryLabel.frame = CGRectMake(160, 0, accessoryLabel.frame.size.width, cell.frame.size.height);
        }
        
        [cell.contentView addSubview:accessoryLabel];
	}
    
    cell.textLabel.text = [listData objectAtIndex:indexPath.row];
    
    // Customization. Hide the accessory for the buttons that don't push new view controllers.
    if ( indexPath.section == 0 )
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        if ( (IS_IOS7) )
        {
            cell.textLabel.textColor = [UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0];
        }
    }
    else
    {
        cell.textLabel.textColor = [UIColor blackColor];
        accessoryLabel = (UILabel *)[cell.contentView viewWithTag:7];
        accessoryLabel.hidden = NO;
        
        int passcodeTimeout = [[[NSUserDefaults standardUserDefaults] stringForKey:@"SHBDPasscodeTimeout"] intValue];
        
        switch ( passcodeTimeout )
        {
            case 0:
            {
                accessoryLabel.text = NSLocalizedString(@"SETTINGS_DESCRIPTION_PASSCODE_TIMEOUT_IMMEDIATE", nil);
                break;
            }
                
            case 1:
            {
                accessoryLabel.text = NSLocalizedString(@"SETTINGS_DESCRIPTION_PASSCODE_TIMEOUT_1_MIN", nil);
                break;
            }
            
            case 3:
            {
                accessoryLabel.text = NSLocalizedString(@"SETTINGS_DESCRIPTION_PASSCODE_TIMEOUT_3_MINS", nil);
                break;
            }
                
            case 5:
            {
                accessoryLabel.text = NSLocalizedString(@"SETTINGS_DESCRIPTION_PASSCODE_TIMEOUT_5_MINS", nil);
                break;
            }
                
            case 10:
            {
                accessoryLabel.text = NSLocalizedString(@"SETTINGS_DESCRIPTION_PASSCODE_TIMEOUT_10_MINS", nil);
                break;
            }
                
            case 15:
            {
                accessoryLabel.text = NSLocalizedString(@"SETTINGS_DESCRIPTION_PASSCODE_TIMEOUT_15_MINS", nil);
                break;
            }
                
            default:
                break;
        }
    }
    
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        cell.textLabel.highlightedTextColor = [UIColor whiteColor];
    }
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
	if ( indexPath.section == 0 && indexPath.row == 0 ) // Add/Change Passcode
    {
        if ( currentPasscode.length > 0 ) // Change Passcode
        {
            [appDelegate.passcodeWindow setMode:SHPasscodeWindowModeChangePasscode];
            appDelegate.passcodeWindow.delegate = self;
            
            [self.navigationController presentViewController:appDelegate.passcodeWindow animated:YES completion:nil];
        }
        else // Add Passcode
        {
            [self checkForPassword];
        }
    }
    else if ( indexPath.section == 0 && indexPath.row == 1 ) // Remove Passcode
    {
        [appDelegate.passcodeWindow setMode:SHPasscodeWindowModeDismissableAuthenticate];
        appDelegate.passcodeWindow.delegate = self;
        isRemovingPasscode = YES;
        
        [self.navigationController presentViewController:appDelegate.passcodeWindow animated:YES completion:nil];
    }
    else if ( indexPath.section == 1 && indexPath.row == 0 ) // Require After
    {
        SettingsViewController_PasscodeTimeout *passcodeTimeoutView = [[SettingsViewController_PasscodeTimeout alloc] init];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SETTINGS_TITLE_PASSCODE", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
        [self.navigationController pushViewController:passcodeTimeoutView animated:YES];
    }
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark SHPasscodeViewDelegate methods.

- (void)passcodeViewDidAuthenticate
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( isRemovingPasscode ) // User just removed their passcode.
    {
        [self removePasscode];
    }
    
    isRemovingPasscode = NO;
    appDelegate.passcodeWindow.delegate = nil;
}

- (void)passcodeViewDidAcceptNewPasscode
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [self createPasscode];
    
    appDelegate.passcodeWindow.delegate = nil;
}

- (void)passcodeViewShouldChangeToNewPasscode:(NSString *)passcode
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight activateStrobeLight];
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[passcode]
                                                                          forKeys:@[@"passcode"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/changepasscode", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        if ( responseData )
        {
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            if ( errorCode == 0 )
            {
                currentPasscode = passcode;
                
                NSString *timeNow = [appDelegate.modelManager dateTodayString];
                
                [appDelegate.modelManager executeUpdate:@"UPDATE sh_current_user SET last_passcode_unlock = :last_passcode_unlock"
                                withParameterDictionary:@{@"last_passcode_unlock": timeNow}];
                
                // Save the passcode in the Keychain.
                [appDelegate.passcodeKeychainItem setObject:passcode forKey:(__bridge id)(kSecValueData)];
                
                [appDelegate.strobeLight affirmativeStrobeLight];
            }
            else
            {
                [self showNetworkError];
            }
        }
        else // Some error occurred...
        {
            [self showNetworkError];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods.

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex != alertView.cancelButtonIndex )
    {
        NSString *newPassword = [alertView textFieldAtIndex:0].text;
        newPassword = [newPassword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ( newPassword.length < 8 )
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:NSLocalizedString(@"SETTINGS_DESCRIPTION_PASSCODE_PASSWORD_MIN_LENGTH", nil)
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"GENERIC_DONE", nil)
                                                  otherButtonTitles:nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert show];
        }
        else if ( newPassword.length > 44 )
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:NSLocalizedString(@"SETTINGS_DESCRIPTION_PASSCODE_PASSWORD_MAX_LENGTH", nil)
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"GENERIC_DONE", nil)
                                                  otherButtonTitles:nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert show];
        }
        else
        {
            [self createPassword:newPassword];
        }
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
