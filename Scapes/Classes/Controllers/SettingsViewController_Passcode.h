//
//  SettingsViewController_Passcode.h
//  Nightboard
//
//  Created by MachOSX on 11/13/13.
//
//

#import "MBProgressHUD.h"

@interface SettingsViewController_Passcode : UIViewController <MBProgressHUDDelegate, UITableViewDelegate, UITableViewDataSource, SHPasscodeViewDelegate, UIAlertViewDelegate>
{
    MBProgressHUD *HUD;
    UISwipeGestureRecognizer *viewSwipeRecognizer;
    UITableView *settingsTableView;
    NSDictionary *tableContents;
    NSArray *sortedKeys;
    NSString *currentPasscode;
    BOOL isRemovingPasscode;
}

- (void)goBack;
- (void)checkForPassword;
- (void)createPassword:(NSString *)password;
- (void)createPasscode;
- (void)removePasscode;

- (void)showNetworkError;

@end
