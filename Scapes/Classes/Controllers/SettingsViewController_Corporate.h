//
//  SettingsViewController_Corporate.h
//  Scapes
//
//  Created by MachOSX on 9/23/13.
//
//

#import "MBProgressHUD.h"

@interface SettingsViewController_Corporate : UIViewController <UIWebViewDelegate, MBProgressHUDDelegate>
{
    UIWebView *browser;
    MBProgressHUD *HUD;
}

@property (nonatomic) NSString *type;

@end
