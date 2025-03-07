//
//  SettingsViewController_PasscodeTimeout.h
//  Scapes
//
//  Created by MachOSX on 11/17/13.
//
//



@interface SettingsViewController_PasscodeTimeout : UIViewController <UITableViewDelegate, UITableViewDataSource, SHPasscodeViewDelegate>
{
    UISwipeGestureRecognizer *viewSwipeRecognizer;
    UITableView *settingsTableView;
    NSDictionary *tableContents;
    NSArray *sortedKeys;
    NSIndexPath *currentSelection;
}

- (void)goBack;

@end
