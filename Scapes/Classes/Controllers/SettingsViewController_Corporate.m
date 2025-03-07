//
//  SettingsViewController_Corporate.m
//  Scapes
//
//  Created by MachOSX on 9/23/13.
//
//

#import "SettingsViewController_Corporate.h"

@implementation SettingsViewController_Corporate

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        
    }
    
    return self;
}

- (void)loadView
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    UIView *contentView = [[UIView alloc] initWithFrame:screenBounds];
    contentView.backgroundColor = [UIColor whiteColor];
    
    browser = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, screenBounds.size.width, screenBounds.size.height - 64)];
    browser.delegate = self;
    browser.scalesPageToFit = YES;
    
    [contentView addSubview:browser];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    if ( [_type isEqualToString:@"privacy"] )
    {
        [self setTitle:NSLocalizedString(@"SETTINGS_TITLE_PRIVACY", nil)];
    }
    else
    {
        [self setTitle:NSLocalizedString(@"SETTINGS_TITLE_TOS", nil)];
    }
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSString *URL;
    
    if ( [_type isEqualToString:@"privacy"] )
    {
        URL = [NSString stringWithFormat:@"http://%@/corporate/privacy", SH_DOMAIN];
    }
    else
    {
        URL = [NSString stringWithFormat:@"http://%@/corporate/tos", SH_DOMAIN];
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                            timeoutInterval:60.0];
    
    [browser loadRequest:request];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if ( viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count - 2] == self ) // View is disappearing because a new view controller was pushed onto the stack.
    {
        
        
    }
    else if ( [viewControllers indexOfObject:self] == NSNotFound ) // View is disappearing because it was popped from the stack.
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [appDelegate.strobeLight deactivateStrobeLight];
    }
    
    [super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods.

- (void)hudWasHidden:(MBProgressHUD *)hud
{
	// Remove HUD from screen when the HUD was hidden.
	[HUD removeFromSuperview];
	HUD = nil;
}

#pragma mark -
#pragma mark UIWebViewDelegate methods.

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
	HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cross_white"]];
    
    // Set custom view mode.
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    HUD.labelText = NSLocalizedString(@"GENERIC_HUD_NETWORK_ERROR", nil);
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [appDelegate.strobeLight negativeStrobeLight];
    
    [HUD show:YES];
    [HUD hide:YES afterDelay:3];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [appDelegate.strobeLight activateStrobeLight];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [appDelegate.strobeLight deactivateStrobeLight];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
