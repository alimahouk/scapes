//
//  SettingsViewController_Account.m
//  Scapes
//
//  Created by MachOSX on 9/23/13.
//
//

#import "SettingsViewController_Account.h"
#import "SettingsViewController_License.h"
#import "SettingsViewController_Passcode.h"
#import "SHRecipientPickerViewController.h"

@implementation SettingsViewController_Account

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        NSArray *arrTemp1 = [[NSArray alloc]
                             initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_LICENSE", nil), /*NSLocalizedString(@"SETTINGS_OPTION_CHANGE_NUMBER", nil),*/ nil];
        NSArray *arrTemp2 = [[NSArray alloc]
                             initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_PASSCODE", nil), NSLocalizedString(@"SETTINGS_OPTION_BLOCKLIST", nil), nil];
        NSArray *arrTemp3 = [[NSArray alloc]
                             initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_HIDDEN_CONTACTS", nil), nil];
        NSArray *arrTemp4 = [[NSArray alloc]
                             initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_LOGOUT", nil), nil];
        NSDictionary *temp = [[NSDictionary alloc]
                             initWithObjectsAndKeys:arrTemp1, @"1", arrTemp2,
                             @"2", arrTemp3, @"3", nil];
        
        tableContents = temp;
        sortedKeys = [[tableContents allKeys] sortedArrayUsingSelector:@selector(compare:)];
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
    
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        settingsTableView.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - 64);
    }
    
    [contentView addSubview:settingsTableView];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    [self setTitle:NSLocalizedString(@"SETTINGS_TITLE_ACCOUNT", nil)];
    
    // Gestures.
    // A lil' easter egg. Swipe to the right to go back!
    viewSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goBack)];
    [viewSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [settingsTableView addGestureRecognizer:viewSwipeRecognizer];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionNavigationBar];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [super viewWillAppear:animated];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
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
    
	if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // Set the accessory type.
	}
    
    cell.textLabel.text = [listData objectAtIndex:indexPath.row];
    
    // Customization. Hide the accessory for the buttons that don't push new view controllers:
    // # Logout
    if ( indexPath.section == 0 && indexPath.row == 0 )
    {
        UIImageView *licenseStatusIcon = [[UIImageView alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width - 85, -2, 45, 45)];
        UIImage *licenseStatusIconImage;
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        SHLicense licenseType = [[userDefaults stringForKey:@"SHBDLicenseType"] intValue];
        
        if ( licenseType != SHLicenseTrial )
        {
            licenseStatusIconImage = [UIImage imageNamed:@"check_small_green"];
        }
        else
        {
            licenseStatusIconImage = [UIImage imageNamed:@"warning_small_blue"];
        }
        
        licenseStatusIcon.image = licenseStatusIconImage;
        licenseStatusIcon.highlightedImage = [appDelegate imageFilledWith:[UIColor whiteColor] using:licenseStatusIconImage];
        
        [cell.contentView addSubview:licenseStatusIcon];
    }
    else
    {
        if ( (indexPath.section == 3 && indexPath.row == 0) )
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
	if ( indexPath.section == 0 && indexPath.row == 0 ) // Scapes License
    {
        SettingsViewController_License *licenseView = [[SettingsViewController_License alloc] init];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SETTINGS_TITLE_ACCOUNT", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
        [self.navigationController pushViewController:licenseView animated:YES];
    }
    else if ( indexPath.section == 0 && indexPath.row == 1 ) // Change Phone Numbers
    {
        
    }
    else if ( indexPath.section == 1 && indexPath.row == 0 ) // Passcode Lock
    {
        SettingsViewController_Passcode *passcodeSettingsView = [[SettingsViewController_Passcode alloc] init];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SETTINGS_TITLE_ACCOUNT", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
        [self.navigationController pushViewController:passcodeSettingsView animated:YES];
    }
    else if ( indexPath.section == 1 && indexPath.row == 1 ) // Blocklist
    {
        SHRecipientPickerViewController *recipientPicker = [[SHRecipientPickerViewController alloc] initInMode:SHRecipientPickerModeBlocked];
        
        [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [self.navigationController pushViewController:recipientPicker animated:YES];
    }
    else if ( indexPath.section == 2 && indexPath.row == 0 ) // Removed Contacts
    {
        SHRecipientPickerViewController *recipientPicker = [[SHRecipientPickerViewController alloc] initInMode:SHRecipientPickerModeHidden];
        
        [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [self.navigationController pushViewController:recipientPicker animated:YES];
    }
    else if ( indexPath.section == 3 && indexPath.row == 0 ) // Logout
    {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                                   destructiveButtonTitle:NSLocalizedString(@"SETTINGS_OPTION_LOG_OUT", nil)
                                                        otherButtonTitles:nil];
        actionSheet.tag = 0;
        [actionSheet showFromRect:self.view.frame inView:appDelegate.window animated:YES];
    }
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( actionSheet.tag == 0 ) // Logout
    {
        if ( buttonIndex == 0 )
        {
            [self.navigationController popToRootViewControllerAnimated:YES];
            [appDelegate logout];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
