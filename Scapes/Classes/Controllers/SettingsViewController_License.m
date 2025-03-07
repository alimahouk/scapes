//
//  SettingsViewController_License.m
//  Scapes
//
//  Created by MachOSX on 4/1/14.
//
//

#import "SettingsViewController_License.h"

#import "AFHTTPRequestOperationManager.h"

@implementation SettingsViewController_License

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        _showsExpiryMessage = NO;
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor whiteColor];
    
    settingsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height) style:UITableViewStyleGrouped];
    settingsTableView.delegate = self;
    settingsTableView.dataSource = self;
    settingsTableView.backgroundView = nil; // Fix for iOS 6+.
    settingsTableView.backgroundColor = [UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0];
    
    NSString *displayName = [[NSString stringWithFormat:@"%@ %@", [appDelegate.currentUser objectForKey:@"name_first"], [appDelegate.currentUser objectForKey:@"name_last"]] uppercaseString];
    
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 280, 15)];
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.opaque = YES;
    nameLabel.textColor = [UIColor colorWithRed:76/255.0 green:86/255.0 blue:108/255.0 alpha:1.0];
    nameLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    nameLabel.shadowOffset = CGSizeMake(0, 1);
    nameLabel.font = [UIFont systemFontOfSize:MIN_MAIN_FONT_SIZE];
    nameLabel.text = displayName;
    
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 40)];
    tableHeaderView.opaque = YES;
    settingsTableView.tableHeaderView = tableHeaderView;
    
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        settingsTableView.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - 64);
    }
    
    [tableHeaderView addSubview:nameLabel];
    [contentView addSubview:settingsTableView];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [self setTitle:NSLocalizedString(@"SETTINGS_TITLE_LICENSE", nil)];
    
    // Gestures.
    // A lil' easter egg. Swipe to the right to go back!
    viewSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goBack)];
    [viewSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:viewSwipeRecognizer];
    
    licenseType = [[[NSUserDefaults standardUserDefaults] stringForKey:@"SHBDLicenseType"] intValue];
    
    NSArray *arrTemp1 = [[NSArray alloc]
                         initWithArray:[appDelegate.currentUser objectForKey:@"phone_numbers"] copyItems:YES];
    NSArray *arrTemp2 = [[NSArray alloc]
                         initWithObjects:NSLocalizedString(@"SETTINGS_DESCRIPTION_LICENSE_LABEL", nil), nil];
    NSArray *arrTemp3 = [[NSArray alloc]
                         initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_LICENSE_BUY", nil), nil];
    NSDictionary *temp = [[NSDictionary alloc]
                          initWithObjectsAndKeys:arrTemp1, @"1", arrTemp2,
                          @"2", arrTemp3, @"3", nil];
    
    if ( licenseType != SHLicenseTrial && !_showsExpiryMessage )
    {
        temp = [[NSDictionary alloc]
                initWithObjectsAndKeys:arrTemp1, @"1", arrTemp2,
                @"2", nil];
    }
    
    tableContents = temp;
    sortedKeys = [[tableContents allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    appDelegate.licenseManager.delegate = self;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    if ( _showsExpiryMessage )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:NSLocalizedString(@"SETTINGS_DESCRIPTION_LICENSE_EXPIRY", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil) otherButtonTitles:nil];
        [alert show];
    }
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    appDelegate.licenseManager.delegate = nil;
    
    if ( _showsExpiryMessage )
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent
                                                    animated:YES];
    }
    
    [super viewWillDisappear:animated];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)registerPurchase
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[[NSNumber numberWithInt:SHLicenseAnnual]]
                                                                          forKeys:@[@"license_type"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/purchaselisenceannaual", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                [appDelegate.strobeLight affirmativeStrobeLight];
                
                // We need a slight delay here.
                long double delayInSeconds = 0.45;
                
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    HUD = [[MBProgressHUD alloc] initWithView:self.view];
                    [self.view addSubview:HUD];
                    
                    HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_white"]];
                    
                    // Set custom view mode.
                    HUD.mode = MBProgressHUDModeCustomView;
                    HUD.dimBackground = YES;
                    HUD.delegate = self;
                    
                    [HUD show:YES];
                    [HUD hide:YES afterDelay:2];
                });
                
                NSArray *arrTemp1 = [[NSArray alloc]
                                     initWithArray:[appDelegate.currentUser objectForKey:@"phone_numbers"] copyItems:YES];
                NSArray *arrTemp2 = [[NSArray alloc]
                                     initWithObjects:NSLocalizedString(@"SETTINGS_DESCRIPTION_LICENSE_LABEL", nil), nil];
                NSDictionary *temp = [[NSDictionary alloc]
                                      initWithObjectsAndKeys:arrTemp1, @"1", arrTemp2,
                                      @"2", nil];
                
                tableContents = temp;
                sortedKeys = [[tableContents allKeys] sortedArrayUsingSelector:@selector(compare:)];
                licenseType = [[[NSUserDefaults standardUserDefaults] stringForKey:@"SHBDLicenseType"] intValue];
                [settingsTableView reloadData];
                
                if ( appDelegate.appIsLocked )
                {
                    [appDelegate.networkManager connect];
                    
                    appDelegate.appIsLocked = NO;
                    
                    // We need a slight delay here.
                    delayInSeconds = 1.0;
                    
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [self dismissViewControllerAnimated:YES completion:nil];
                    });
                }
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
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    static NSString *cellIdentifier = @"CellIdentifier";
    NSArray *listData =[tableContents objectForKey:[sortedKeys objectAtIndex:indexPath.section]];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    UILabel *accessoryLabel;
    
	if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.textLabel.backgroundColor = [UIColor clearColor];
        
        accessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(155, 0, 150, cell.frame.size.height)];
        accessoryLabel.backgroundColor = [UIColor clearColor];
        accessoryLabel.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
        accessoryLabel.textAlignment = NSTextAlignmentRight;
        accessoryLabel.tag = 7;
        
        if ( !(IS_IOS7) )
        {
            accessoryLabel.frame = CGRectMake(135, 0, accessoryLabel.frame.size.width, cell.frame.size.height);
        }
        
        [cell.contentView addSubview:accessoryLabel];
	}
    
    accessoryLabel = (UILabel *)[cell.contentView viewWithTag:7];
    
    if ( indexPath.section == 0 )
    {
        NSDictionary *phoneNumberPack = [listData objectAtIndex:indexPath.row];
        NSString *preparedPhoneNumber = [NSString stringWithFormat:@"+%@%@%@", [phoneNumberPack objectForKey:@"country_calling_code"], [phoneNumberPack objectForKey:@"prefix"], [phoneNumberPack objectForKey:@"phone_number"]];
        NSString *phoneNumber = [appDelegate.contactManager formatPhoneNumberForDisplay:preparedPhoneNumber];
        
        cell.textLabel.text = phoneNumber;
    }
    else
    {
        if ( indexPath.section == 2 && (IS_IOS7) )
        {
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor = [UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0];
        }
        else
        {
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.textLabel.textColor = [UIColor blackColor];
        }
        
        if ( indexPath.section == 1 )
        {
            switch ( licenseType )
            {
                case SHLicenseTrial:
                    accessoryLabel.text = NSLocalizedString(@"SETTINGS_DESCRIPTION_LICENSE_TYPE_TRIAL", nil);
                    break;
                    
                case SHLicenseAnnual:
                    accessoryLabel.text = NSLocalizedString(@"SETTINGS_DESCRIPTION_LICENSE_TYPE_ANNUAL", nil);
                    break;
                    
                case SHLicenseLifetime:
                    accessoryLabel.text = NSLocalizedString(@"SETTINGS_DESCRIPTION_LICENSE_TYPE_LIFETIME", nil);
                    break;
                    
                default:
                    break;
            }
        }
        else
        {
            accessoryLabel.text = @"";
        }
        
        cell.textLabel.text = [listData objectAtIndex:indexPath.row];
    }
    
    if ( indexPath.section == 2 )
    {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else
    {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( indexPath.section == 2 && indexPath.row == 0 ) // Buy Subscription
    {
        [appDelegate.strobeLight activateStrobeLight];
        [appDelegate.licenseManager buyProduct];
    }
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark LicenseManagerDelegate methods

- (void)licenseManagerDidMakePurchase
{
    [self registerPurchase];
}

- (void)licenseManagerPurchaseFailed
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cross_white"]];
    
    // Set custom view mode.
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    
    [HUD show:YES];
    [HUD hide:YES afterDelay:3];
    
    [appDelegate.strobeLight negativeStrobeLight];
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
