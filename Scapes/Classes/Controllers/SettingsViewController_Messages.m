//
//  SettingsViewController_Messages.m
//  Scapes
//
//  Created by MachOSX on 9/24/13.
//
//

#import "SettingsViewController_Messages.h"

#import "AFHTTPRequestOperationManager.h"
#import "SettingsViewController_ChatWallpaper.h"
#import "SHSwitch.h"

@implementation SettingsViewController_Messages

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        NSArray *arrTemp1 = [[NSArray alloc]
                             initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_WALLPAPER", nil), nil];
        NSArray *arrTemp2 = [[NSArray alloc]
                             initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_RELATIVE_TIME", nil), nil];
        NSArray *arrTemp3 = [[NSArray alloc]
                             initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_AUTOSAVE_MEDIA", nil), NSLocalizedString(@"SETTINGS_OPTION_HQ_UPLOADS", nil), NSLocalizedString(@"SETTINGS_OPTION_VIBRATE", nil), NSLocalizedString(@"SETTINGS_OPTION_SOUNDS", nil), NSLocalizedString(@"SETTINGS_OPTION_RETURN_KEY_TO_SEND", nil), nil];
        NSArray *arrTemp4 = [[NSArray alloc]
                             initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_LAST_SEEN", nil), nil];
        NSArray *arrTemp5 = [[NSArray alloc]
                             initWithObjects:NSLocalizedString(@"SETTINGS_OPTION_TALKING", nil), nil];
        NSDictionary *temp = [[NSDictionary alloc]
                             initWithObjectsAndKeys:arrTemp1, @"1", arrTemp2,
                             @"2", arrTemp3, @"3", arrTemp4, @"4", arrTemp5, @"5", nil];
        
        tableContents = temp;
        sortedKeys = [[tableContents allKeys] sortedArrayUsingSelector:@selector(compare:)];
        
        // These are the key names to look up in NSUserDefaults.
        // Each table section is an array.
        optionValues = [[NSArray alloc] initWithObjects:@[],
                                                        @[@"SHBDRelativeTime"],
                                                        @[@"SHBDAutosaveMedia",
                                                          @"SHBDHQUploads",
                                                          @"SHBDVibrate",
                                                          @"SHBDSounds",
                                                          @"SHBDReturnKeyToSend"],
                                                        @[@"SHBDLastSeen"],
                                                        @[@"SHBDTalking"], nil];
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
    [self setTitle:NSLocalizedString(@"SETTINGS_TITLE_MESSAGES", nil)];
    
    // Gestures.
    // A lil' easter egg. Swipe to the right to go back!
    viewSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goBack)];
    [viewSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [settingsTableView addGestureRecognizer:viewSwipeRecognizer];
    
    [super viewDidLoad];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // We need to keep an updated reference to the new preference values.
    // It's better than reading them from the disk every time.
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    appDelegate.preference_RelativeTime = [[userDefaults stringForKey:@"SHBDRelativeTime"] boolValue];
    appDelegate.preference_AutosaveMedia = [[userDefaults stringForKey:@"SHBDAutosaveMedia"] boolValue];
    appDelegate.preference_HQUploads = [[userDefaults stringForKey:@"SHBDHQUploads"] boolValue];
    appDelegate.preference_Sounds = [[userDefaults stringForKey:@"SHBDVibrate"] boolValue];
    appDelegate.preference_Vibrate = [[userDefaults stringForKey:@"SHBDSounds"] boolValue];
    appDelegate.preference_LastSeen = [[userDefaults stringForKey:@"SHBDLastSeen"] boolValue];
    appDelegate.preference_Talking = [[userDefaults stringForKey:@"SHBDTalking"] boolValue];
    appDelegate.preference_ReturnKeyToSend = [[userDefaults stringForKey:@"SHBDReturnKeyToSend"] boolValue];
    
    [super viewWillDisappear:animated];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Handle a UISwitch flip

- (void)didToggleSwitch:(id)sender
{
    SHSwitch *toggleSwitch = (SHSwitch *)sender;
    
    BOOL switchOn = [toggleSwitch isOn];
    
    if ( toggleSwitch.indexPath.section == 3 ) // Last Seen
    {
        int mask;
        
        if ( switchOn )
        {
            mask = 0; // 0 = NOT masked!
        }
        else
        {
            mask = 1;
        }
        
        [self setMask:1 value:mask];
        toggleSwitch.enabled = NO;
    }
    else if ( toggleSwitch.indexPath.section == 4 ) // Talking
    {
        int mask;
        
        if ( switchOn )
        {
            mask = 0; // 0 = NOT masked!
        }
        else
        {
            mask = 1;
        }
        
        [self setMask:2 value:mask];
        toggleSwitch.enabled = NO;
    }
    else
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:[NSString stringWithFormat:@"%@", switchOn ? @"YES" : @"NO"] forKey:[[optionValues objectAtIndex:toggleSwitch.indexPath.section] objectAtIndex:toggleSwitch.indexPath.row]];
        [userDefaults synchronize];
    }
}

- (void)setMask:(int)maskType value:(int)value
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight activateStrobeLight];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[[NSNumber numberWithInt:maskType],
                                                                                    [NSNumber numberWithInt:value]]
                                                                          forKeys:@[@"mask_type",
                                                                                    @"mask_value"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/setusermask", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                [appDelegate.strobeLight deactivateStrobeLight];
                
                if ( maskType == 1 ) // Last Seen
                {
                    [appDelegate.networkManager reconnect:NO]; // Reconnect to the server for the change to take effect.
                    
                    if ( value == 1 )
                    {
                        [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"SHBDLastSeen"];
                    }
                    else
                    {
                        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"SHBDLastSeen"];
                    }
                }
                else if ( maskType == 2 ) // Talking
                {
                    if ( value == 1 )
                    {
                        [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"SHBDTalking"];
                    }
                    else
                    {
                        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"SHBDTalking"];
                    }
                }
            }
        }
        else // Some error occurred...
        {
            [appDelegate.strobeLight negativeStrobeLight];
        }
        
        if ( maskType == 1 ) // Last Seen
        {
            // Re-enable the switch.
            UITableViewCell *cell = (UITableViewCell *)[settingsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3]];
            UISwitch *toggleSwitch = (UISwitch *)[cell.accessoryView viewWithTag:0];
            toggleSwitch.enabled = YES;
        }
        else if ( maskType == 2 ) // Talking
        {
            UITableViewCell *cell = (UITableViewCell *)[settingsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:4]];
            UISwitch *toggleSwitch = (UISwitch *)[cell.accessoryView viewWithTag:0];
            toggleSwitch.enabled = YES;
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [appDelegate.strobeLight negativeStrobeLight];
        
        if ( maskType == 1 ) // Last Seen
        {
            // Re-enable the switch.
            UITableViewCell *cell = (UITableViewCell *)[settingsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3]];
            UISwitch *toggleSwitch = (UISwitch *)[cell.accessoryView viewWithTag:0];
            toggleSwitch.enabled = YES;
        }
        else if ( maskType == 2 ) // Talking
        {
            UITableViewCell *cell = (UITableViewCell *)[settingsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:4]];
            UISwitch *toggleSwitch = (UISwitch *)[cell.accessoryView viewWithTag:0];
            toggleSwitch.enabled = YES;
        }
        
        NSLog(@"Error: %@", operation.responseString);
    }];
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

- (CGFloat)tableView:(UITableView *)table heightForFooterInSection:(NSInteger)section
{
    if ( section == 1 )
    {
        return 50;
    }
    else if ( section == 3 || section == 4 )
    {
        return 75;
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
    footerLabel.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
    footerLabel.font = [UIFont systemFontOfSize:16];
    footerLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    footerLabel.shadowOffset = CGSizeMake(0, 1);
    footerLabel.numberOfLines = 0;
    footerLabel.textAlignment = NSTextAlignmentCenter;
    
    [footerView addSubview:footerLabel];
    
    if ( section == 1 )
    {
        footerView.frame = CGRectMake(footerView.frame.origin.x, footerView.frame.origin.y, footerView.frame.size.width, 50);
        footerLabel.frame = CGRectMake(footerLabel.frame.origin.x, footerLabel.frame.origin.y, footerLabel.frame.size.width, 50);
        footerLabel.text = NSLocalizedString(@"SETTINGS_DESCRIPTION_RELATIVE_TIME", nil);
        
        return footerView;
    }
    else if ( section == 3 )
    {
        footerView.frame = CGRectMake(footerView.frame.origin.x, footerView.frame.origin.y, footerView.frame.size.width, 75);
        footerLabel.frame = CGRectMake(footerLabel.frame.origin.x, footerLabel.frame.origin.y, footerLabel.frame.size.width, 75);
        footerLabel.text = NSLocalizedString(@"SETTINGS_DESCRIPTION_LAST_SEEN", nil);
        
        return footerView;
    }
    else if ( section == 4 )
    {
        footerView.frame = CGRectMake(footerView.frame.origin.x, footerView.frame.origin.y, footerView.frame.size.width, 75);
        footerLabel.frame = CGRectMake(footerLabel.frame.origin.x, footerLabel.frame.origin.y, footerLabel.frame.size.width, 75);
        footerLabel.text = NSLocalizedString(@"SETTINGS_DESCRIPTION_TALKING", nil);
        
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
    
    NSArray *listData =[tableContents objectForKey:[sortedKeys objectAtIndex:indexPath.section]];
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
	if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
    
	cell.textLabel.text = [listData objectAtIndex:indexPath.row];
    
    // Set the accessory type.
   if ( (indexPath.section == 0 && indexPath.row == 0) )
    {
        cell.accessoryView = nil;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	}
    else
    {
        SHSwitch *toggleSwitch = [[SHSwitch alloc] initWithFrame:CGRectZero];
        [toggleSwitch addTarget:self action:@selector(didToggleSwitch:) forControlEvents:UIControlEventTouchUpInside];
        toggleSwitch.indexPath = indexPath;
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        BOOL switchOn = [[userDefaults stringForKey:[[optionValues objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]] boolValue];
        
        [toggleSwitch setOn:switchOn];
        
        cell.accessoryView = toggleSwitch;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ( indexPath.section == 0 && indexPath.row == 0 ) // Chat Wallpaper
    {
        SettingsViewController_ChatWallpaper *chatWallpaperView = [[SettingsViewController_ChatWallpaper alloc] init];
        
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SETTINGS_TITLE_MESSAGES", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
        [self.navigationController pushViewController:chatWallpaperView animated:YES];
    }
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
