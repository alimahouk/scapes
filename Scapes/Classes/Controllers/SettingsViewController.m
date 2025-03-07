//
//  SettingsViewController.m
//  Scapes
//
//  Created by MachOSX on 9/11/13.
//
//

#import "SettingsViewController.h"
#import "SettingsViewController_Account.h"
#import "SettingsViewController_Profile.h"
#import "SettingsViewController_Messages.h"
#import "SettingsViewController_Corporate.h"
#import "SHRecipientPickerViewController.h"

@implementation SettingsViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        NSArray *arrTemp1 = [[NSArray alloc]
                             initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_INVITE", nil), nil];
        NSArray *arrTemp2 = [[NSArray alloc]
                             initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_ACCOUNT", nil), NSLocalizedString(@"SETTINGS_OPTION_PROFILE", nil), NSLocalizedString(@"SETTINGS_OPTION_MESSAGES", nil), nil];
        NSArray *arrTemp3 = [[NSArray alloc]
                             initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_ADDRESS_BOOK", nil), NSLocalizedString(@"SETTINGS_OPTION_BLUETOOTH", nil), NSLocalizedString(@"SETTINGS_OPTION_ADD_USERNAME", nil), nil];
        NSArray *arrTemp4 = [[NSArray alloc]
                             initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_PRIVACY", nil), NSLocalizedString(@"SETTINGS_OPTION_TOS", nil), nil];
        NSDictionary *temp = [[NSDictionary alloc]
                             initWithObjectsAndKeys:arrTemp1, @"1", arrTemp2,
                             @"2", arrTemp3, @"3", arrTemp4, @"4", nil];
        
        tableContents = temp;
        sortedKeys =[[tableContents allKeys] sortedArrayUsingSelector:@selector(compare:)];
        
        shouldDisplayAddressBookMessage = NO;
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor whiteColor];
    
    UIImageView *roof = [[UIImageView alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width / 2 - 23, -41, 46, 36)];
    roof.image = [UIImage imageNamed:@"roof_small_blue"];
    roof.opaque = YES;
    
    settingsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height) style:UITableViewStyleGrouped];
    settingsTableView.delegate = self;
    settingsTableView.dataSource = self;
    settingsTableView.backgroundView = nil; // Fix for iOS 6+.
    settingsTableView.backgroundColor = [UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0];
    
    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, settingsTableView.frame.size.width, 44)];
    settingsTableView.tableFooterView = tableFooterView;
    
    UILabel *copyright = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, appDelegate.screenBounds.size.width - 40, 14)];
    copyright.backgroundColor = [UIColor clearColor];
    copyright.opaque = YES;
    copyright.textColor = [UIColor colorWithRed:76/255.0 green:86/255.0 blue:108/255.0 alpha:1.0];
    copyright.font = [UIFont fontWithName:@"Georgia" size:SECONDARY_FONT_SIZE];
    copyright.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    copyright.shadowOffset = CGSizeMake(0, 1);
    copyright.numberOfLines = 1;
    copyright.textAlignment = NSTextAlignmentCenter;
    
    NSDate *date = [NSDate date];
    NSDateComponents *dateComponents = [appDelegate.calendar components:NSYearCalendarUnit fromDate:date];
    copyright.text = [NSString stringWithFormat:@"© %d Scapehouse. be original.", (int)dateComponents.year];
    
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        settingsTableView.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - 64);
    }
    
    [tableFooterView addSubview:copyright];
    [settingsTableView addSubview:roof];
    [contentView addSubview:settingsTableView];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    [self setTitle:NSLocalizedString(@"SETTINGS_TITLE_MAIN", nil)];
    
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
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    // We need to keep an updated reference to the new preference values.
    // It's better than reading them from the disk every time.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    appDelegate.preference_UseAddressBook = [[userDefaults stringForKey:@"SHBDUseAddressBook"] boolValue];
    appDelegate.preference_UseBluetooth = [[userDefaults stringForKey:@"SHBDUseBluetooth"] boolValue];
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if ( viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count - 2] == self ) // View is disappearing because a new view controller was pushed onto the stack.
    {
        
    }
    else if ( [viewControllers indexOfObject:self] == NSNotFound ) // View is disappearing because it was popped from the stack.
    {
        [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        
        appDelegate.mainMenu.profileView.ownerDataChunk = appDelegate.currentUser; // Update the profile chunk.
        [appDelegate.mainMenu.profileView refreshViewWithDP:NO];
    }
    
    [super viewWillDisappear:animated];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didToggleSwitch:(id)sender
{
    UISwitch *toggleSwitch = (UISwitch *)sender;
    
    [settingsTableView beginUpdates];
    
    [settingsTableView endUpdates];
    
    BOOL switchOn = [toggleSwitch isOn];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ( toggleSwitch.tag == 0 )
    {
        shouldDisplayAddressBookMessage = YES;
        shouldDisplayBluetoothMessage = NO;
        
        [userDefaults setObject:[NSString stringWithFormat:@"%@", switchOn ? @"YES" : @"NO"] forKey:@"SHBDUseAddressBook"];
    }
    else
    {
        shouldDisplayAddressBookMessage = NO;
        shouldDisplayBluetoothMessage = YES;
        
        [userDefaults setObject:[NSString stringWithFormat:@"%@", switchOn ? @"YES" : @"NO"] forKey:@"SHBDUseBluetooth"];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource methods.

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return sortedKeys.count;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
	NSArray *listData =[tableContents objectForKey:[sortedKeys objectAtIndex:section]];
    
	return listData.count;
}

- (CGFloat)tableView:(UITableView *)table heightForHeaderInSection:(NSInteger)section
{
    if ( section == 0 )
    {
        return 50;
    }
    else
    {
        return 10;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ( section == 0 )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 50)];
        NSNumber *versionNumber = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        
        // Add the label.
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, appDelegate.screenBounds.size.width - 40, 50)];
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.opaque = YES;
        headerLabel.text = [NSString stringWithFormat:NSLocalizedString(@"SETTINGS_SIGNATURE", nil), versionNumber];
        headerLabel.textColor = [UIColor colorWithRed:76/255.0 green:86/255.0 blue:108/255.0 alpha:1.0];
        headerLabel.font = [UIFont systemFontOfSize:16];
        headerLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.7];
        headerLabel.shadowOffset = CGSizeMake(0, 1);
        headerLabel.numberOfLines = 0;
        headerLabel.textAlignment = NSTextAlignmentCenter;
        
        [headerView addSubview:headerLabel];
        
        return headerView;
    }
    else
    {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)table heightForFooterInSection:(NSInteger)section
{
    if ( section == 2 && (shouldDisplayAddressBookMessage || shouldDisplayBluetoothMessage) )
    {
        return 50;
    }
    else
    {
        return 20;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 50)];
    
    // Add the label.
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, appDelegate.screenBounds.size.width - 40, 50)];
    footerLabel.backgroundColor = [UIColor clearColor];
    footerLabel.opaque = YES;
    footerLabel.textColor = [UIColor colorWithRed:76/255.0 green:86/255.0 blue:108/255.0 alpha:1.0];
    footerLabel.font = [UIFont systemFontOfSize:16];
    footerLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    footerLabel.shadowOffset = CGSizeMake(0, 1);
    footerLabel.numberOfLines = 0;
    footerLabel.textAlignment = NSTextAlignmentCenter;
    
    [footerView addSubview:footerLabel];
    
    if ( section == 2 && shouldDisplayAddressBookMessage )
    {
        footerView.frame = CGRectMake(footerView.frame.origin.x, footerView.frame.origin.y, footerView.frame.size.width, 50);
        footerLabel.frame = CGRectMake(footerLabel.frame.origin.x, footerLabel.frame.origin.y, footerLabel.frame.size.width, 50);
        footerLabel.text = NSLocalizedString(@"SETTINGS_DESCRIPTION_ADDRESS_BOOK", nil);
        
        return footerView;
    }
    else if ( section == 2 && shouldDisplayBluetoothMessage )
    {
        footerView.frame = CGRectMake(footerView.frame.origin.x, footerView.frame.origin.y, footerView.frame.size.width, 50);
        footerLabel.frame = CGRectMake(footerLabel.frame.origin.x, footerLabel.frame.origin.y, footerLabel.frame.size.width, 50);
        footerLabel.text = NSLocalizedString(@"SETTINGS_DESCRIPTION_BLUETOOTH", nil);
        
        return footerView;
    }
    else
    {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"CellIdentifier";
    
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
	NSArray *listData =[tableContents objectForKey:[sortedKeys objectAtIndex:indexPath.section]];
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
	if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // Set the accessory type.
	}
    
    if ( indexPath.section == 2 && (indexPath.row == 0 || indexPath.row == 1) ) // Use Address Book option has a UISwitch. No need for selection.
    {
        UISwitch *toggleSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        [toggleSwitch addTarget:self action:@selector(didToggleSwitch:) forControlEvents: UIControlEventTouchUpInside];
        toggleSwitch.tag = indexPath.row;
        
        if ( indexPath.row == 0 )
        {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            BOOL switchOn = [[userDefaults stringForKey:@"SHBDUseAddressBook"] boolValue];
            
            toggleSwitch.tag = 0;
            [toggleSwitch setOn:switchOn];
        }
        else if ( indexPath.row == 1 )
        {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            BOOL switchOn = [[userDefaults stringForKey:@"SHBDUseBluetooth"] boolValue];
            
            toggleSwitch.tag = 1;
            [toggleSwitch setOn:switchOn];
        }
        
        cell.accessoryView = toggleSwitch;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else
    {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
        if ( indexPath.section == 1 )
        {
            if ( indexPath.row == 0 )
            {
                cell.imageView.image = [UIImage imageNamed:@"settings_account"];
                cell.imageView.highlightedImage = [appDelegate imageFilledWith:[UIColor whiteColor] using:[UIImage imageNamed:@"settings_account"]];
            }
            else if ( indexPath.row == 1 )
            {
                cell.imageView.image = [UIImage imageNamed:@"settings_profile"];
                cell.imageView.highlightedImage = [appDelegate imageFilledWith:[UIColor whiteColor] using:[UIImage imageNamed:@"settings_profile"]];
            }
            else if ( indexPath.row == 2 )
            {
                cell.imageView.image = [UIImage imageNamed:@"settings_messages"];
                cell.imageView.highlightedImage = [appDelegate imageFilledWith:[UIColor whiteColor] using:[UIImage imageNamed:@"settings_messages"]];
            }
        }
    }
    
    
	cell.textLabel.text = [listData objectAtIndex:indexPath.row];
    
    // Customization. Hide the accessory for the buttons that don't push new view controllers:
    // # Invite Friends
	if ( (indexPath.section == 0 && indexPath.row == 0) )
    {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
	if ( indexPath.section == 0 && indexPath.row == 0 ) // Invite Friends
    {
        NSArray *activityItems = @[NSLocalizedString(@"SETTINGS_INVITATION_BODY", nil), [NSURL URLWithString:@"https://itunes.apple.com/us/app/scapes-messenger/id737271884?ls=1&mt=8"]];
        
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        [activityController setValue:NSLocalizedString(@"SETTINGS_INVITATION_SUBJECT", nil) forKey:@"subject"];
        
        if ( (IS_IOS7) )
        {
            activityController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop];
        }
        else
        {
            activityController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll];
        }
        
        [self.navigationController presentViewController:activityController animated:YES completion:nil];
    }
    else if ( indexPath.section == 1 && indexPath.row == 0) // Account
    {
        SettingsViewController_Account *accountSettings = [[SettingsViewController_Account alloc] init];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SETTINGS_TITLE_MAIN", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
        [self.navigationController pushViewController:accountSettings animated:YES];
    }
    else if ( indexPath.section == 1 && indexPath.row == 1 ) // Profile
    {
        SettingsViewController_Profile *profileSettings = [[SettingsViewController_Profile alloc] init];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SETTINGS_TITLE_MAIN", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
        [self.navigationController pushViewController:profileSettings animated:YES];
    }
    else if ( indexPath.section == 1 && indexPath.row == 2 ) // Messages
    {
        SettingsViewController_Messages *messagingSettings = [[SettingsViewController_Messages alloc] init];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SETTINGS_TITLE_MAIN", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
        [self.navigationController pushViewController:messagingSettings animated:YES];
    }
    else if ( indexPath.section == 2 && indexPath.row == 1 ) // Add Contact By Username
    {
        SHRecipientPickerViewController *recipientPicker = [[SHRecipientPickerViewController alloc] initInMode:SHRecipientPickerModeAddByUsername];
        
        [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [self.navigationController pushViewController:recipientPicker animated:YES];
    }
    else if ( indexPath.section == 3 && indexPath.row == 0 ) // Privacy Policy
    {
        SettingsViewController_Corporate *privacyPolicyView = [[SettingsViewController_Corporate alloc] init];
        [privacyPolicyView setValue:@"privacy" forKey:@"type"];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SETTINGS_TITLE_MAIN", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
        [self.navigationController pushViewController:privacyPolicyView animated:YES];
    }
    else if ( indexPath.section == 3 && indexPath.row == 1 ) // TOS
    {
        SettingsViewController_Corporate *termsView = [[SettingsViewController_Corporate alloc] init];
        [termsView setValue:@"terms" forKey:@"type"];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SETTINGS_TITLE_MAIN", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
        [self.navigationController pushViewController:termsView animated:YES];
    }
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
