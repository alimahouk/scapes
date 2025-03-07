//
//  SettingsViewController_Account.h
//  Scapes
//
//  Created by MachOSX on 9/23/13.
//
//



@interface SettingsViewController_Account : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>
{
    UISwipeGestureRecognizer *viewSwipeRecognizer;
    UITableView *settingsTableView;
    NSDictionary *tableContents;
    NSArray *sortedKeys;
}

- (void)goBack;

@end