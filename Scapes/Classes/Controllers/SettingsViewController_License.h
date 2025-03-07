//
//  SettingsViewController_License.h
//  Scapes
//
//  Created by MachOSX on 4/1/14.
//
//

#import "MBProgressHUD.h"

@interface SettingsViewController_License : UIViewController <SHLicenseManagerDelegate, MBProgressHUDDelegate, UITableViewDelegate, UITableViewDataSource>
{
    MBProgressHUD *HUD;
    UISwipeGestureRecognizer *viewSwipeRecognizer;
    UITableView *settingsTableView;
    NSDictionary *tableContents;
    NSArray *sortedKeys;
    SHLicense licenseType;
}

@property (nonatomic) BOOL showsExpiryMessage;

- (void)goBack;
- (void)registerPurchase;

- (void)showNetworkError;

@end
