//
//  WebBrowserViewController.h
//  Scapes
//
//  Created by MachOSX on 1/29/14.
//
//

#import <MessageUI/MessageUI.h>
#import "MBProgressHUD.h"

@interface WebBrowserViewController : UIViewController <UIWebViewDelegate, MBProgressHUDDelegate, UIActionSheetDelegate>
{
    MBProgressHUD *HUD;
    UIWebView *browser;
    UIToolbar *lowerToolbar;
    UIBarItem *backButton;
    UIBarItem *forwardButton;
    UIBarItem *refreshButton;
    UIBarItem *actionButton;
    UIBarItem *flexibleWidth_1;
    UIBarItem *flexibleWidth_2;
    UIBarItem *flexibleWidth_3;
    BOOL loading;
}

@property (nonatomic) NSString *URL;
@property (nonatomic) BOOL resetsViewWhenPopped;
@property (nonatomic) BOOL shouldReportEndOfActivity;

- (void)goBack;
- (void)goForward;
- (void)reloadPage;
- (void)showBrowserOptions;

@end
