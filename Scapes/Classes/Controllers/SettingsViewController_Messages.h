//
//  SettingsViewController_Messages.h
//  Scapes
//
//  Created by MachOSX on 9/24/13.
//
//



@interface SettingsViewController_Messages : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    UISwipeGestureRecognizer *viewSwipeRecognizer;
    UITableView *settingsTableView;
    NSDictionary *tableContents;
    NSArray *sortedKeys;
    NSArray *optionValues;
}

- (void)goBack;
- (void)didToggleSwitch:(id)sender;
- (void)setMask:(int)maskType value:(int)value;

@end
