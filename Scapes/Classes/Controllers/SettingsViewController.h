//
//  SettingsViewController.h
//  Scapes
//
//  Created by MachOSX on 9/11/13.
//
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    UISwipeGestureRecognizer *viewSwipeRecognizer;
    UITableView *settingsTableView;
    NSDictionary *tableContents;
    NSArray *sortedKeys;
    BOOL shouldDisplayAddressBookMessage;
    BOOL shouldDisplayBluetoothMessage;
}

- (void)goBack;
- (void)didToggleSwitch:(id)sender;

@end
