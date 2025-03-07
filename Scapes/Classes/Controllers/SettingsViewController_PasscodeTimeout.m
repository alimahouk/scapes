//
//  SettingsViewController_PasscodeTimeout.m
//  Scapes
//
//  Created by MachOSX on 11/17/13.
//
//

#import "SettingsViewController_PasscodeTimeout.h"

@implementation SettingsViewController_PasscodeTimeout

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        NSArray *arrTemp1 = [[NSArray alloc] initWithObjects:
                             NSLocalizedString(@"SETTINGS_DESCRIPTION_PASSCODE_TIMEOUT_IMMEDIATE", nil),
                             NSLocalizedString(@"SETTINGS_DESCRIPTION_PASSCODE_TIMEOUT_1_MIN", nil),
                             NSLocalizedString(@"SETTINGS_DESCRIPTION_PASSCODE_TIMEOUT_3_MINS", nil),
                             NSLocalizedString(@"SETTINGS_DESCRIPTION_PASSCODE_TIMEOUT_5_MINS", nil),
                             NSLocalizedString(@"SETTINGS_DESCRIPTION_PASSCODE_TIMEOUT_10_MINS", nil),
                             NSLocalizedString(@"SETTINGS_DESCRIPTION_PASSCODE_TIMEOUT_15_MINS", nil), nil];
        NSDictionary *temp = [[NSDictionary alloc]
                              initWithObjectsAndKeys:arrTemp1, @"1", nil];
        
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
    [self setTitle:NSLocalizedString(@"SETTINGS_TITLE_PASSCODE_TIMEOUT", nil)];
    
    // Gestures.
    // A lil' easter egg. Swipe to the right to go back!
    viewSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goBack)];
    [viewSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [settingsTableView addGestureRecognizer:viewSwipeRecognizer];
    
    [super viewDidLoad];
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
	static NSString *cellIdentifier = @"CellIdentifier";
    
    NSArray *listData = [tableContents objectForKey:[sortedKeys objectAtIndex:indexPath.section]];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
	if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // Set the accessory type.
	}
    
    cell.textLabel.text = [listData objectAtIndex:indexPath.row];
    
    int passCodeTimeout = [[[NSUserDefaults standardUserDefaults] stringForKey:@"SHBDPasscodeTimeout"] intValue];
    
    switch ( passCodeTimeout )
    {
        case 0:
        {
            if ( indexPath.row == 0 )
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                currentSelection = indexPath;
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            break;
        }
            
        case 1:
        {
            if ( indexPath.row == 1 )
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                currentSelection = indexPath;
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            break;
        }
            
        case 3:
        {
            if ( indexPath.row == 2 )
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                currentSelection = indexPath;
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            break;
        }
        
        case 5:
        {
            if ( indexPath.row == 3 )
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                currentSelection = indexPath;
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            break;
        }
            
        case 10:
        {
            if ( indexPath.row == 4 )
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                currentSelection = indexPath;
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            break;
        }
            
        case 15:
        {
            if ( indexPath.row == 5 )
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                currentSelection = indexPath;
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            break;
        }
            
        default:
            break;
    }
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ( indexPath.row )
    {
        case 0:
        {
            [[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:@"SHBDPasscodeTimeout"];
            break;
        }
        
        case 1:
        {
            [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"SHBDPasscodeTimeout"];
            break;
        }
            
        case 2:
        {
            [[NSUserDefaults standardUserDefaults] setObject:@"3" forKey:@"SHBDPasscodeTimeout"];
            break;
        }
            
        case 3:
        {
            [[NSUserDefaults standardUserDefaults] setObject:@"5" forKey:@"SHBDPasscodeTimeout"];
            break;
        }
            
        case 4:
        {
            [[NSUserDefaults standardUserDefaults] setObject:@"10" forKey:@"SHBDPasscodeTimeout"];
            break;
        }
            
        case 5:
        {
            [[NSUserDefaults standardUserDefaults] setObject:@"15" forKey:@"SHBDPasscodeTimeout"];
            break;
        }
            
        default:
            break;
    }
    
    UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:currentSelection];
    UITableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
    
    oldCell.accessoryType = UITableViewCellAccessoryNone;
    newCell.accessoryType = UITableViewCellAccessoryCheckmark;
    currentSelection = indexPath;
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
