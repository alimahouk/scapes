//
//  WebBrowserViewController.m
//  Scapes
//
//  Created by MachOSX on 1/29/14.
//
//

#import "WebBrowserViewController.h"

@implementation WebBrowserViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        _resetsViewWhenPopped = NO;
        _shouldReportEndOfActivity = NO;
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor blackColor];
    
    browser = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - 44)];
    browser.scalesPageToFit = YES;
    browser.delegate = self;
    
    lowerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44)];
    
    actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showBrowserOptions)];
    flexibleWidth_1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    flexibleWidth_2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    flexibleWidth_3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if ( !(IS_IOS7) )
    {
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"browser_back_legacy"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
        forwardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"browser_forward_legacy"] style:UIBarButtonItemStylePlain target:self action:@selector(goForward)];
        refreshButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"browser_cancel_legacy"] style:UIBarButtonItemStylePlain target:self action:@selector(reloadPage)];
    }
    else
    {
        backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"browser_back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
        forwardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"browser_forward"] style:UIBarButtonItemStylePlain target:self action:@selector(goForward)];
        refreshButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"browser_cancel"] style:UIBarButtonItemStylePlain target:self action:@selector(reloadPage)];
    }
    
    lowerToolbar.items = @[backButton, flexibleWidth_1, forwardButton, flexibleWidth_2, refreshButton, flexibleWidth_3, actionButton];
    
    if ( !(IS_IOS7) )
    {
        browser.frame = CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - 108);
        lowerToolbar.frame = CGRectMake(0, appDelegate.screenBounds.size.height - 108, appDelegate.screenBounds.size.width, 44);
    }
    
    [contentView addSubview:browser];
    [contentView addSubview:lowerToolbar];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    NSURL *theURL = [NSURL URLWithString:_URL];
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:theURL
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                            timeoutInterval:120.0];
    
    [browser loadRequest:theRequest];
    [self setTitle:_URL];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    self.navigationController.navigationBar.translucent = YES;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionNavigationBar];
    
    if ( appDelegate.mainWindowNavigationController.inPrivateMode )
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        
        if ( !(IS_IOS7) )
        {
            self.navigationController.navigationBar.tintColor = [UIColor blackColor];
            
        }
        else
        {
            self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
        }
    }
    else
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }
    
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
        if ( _resetsViewWhenPopped )
        {
            appDelegate.mainMenu.windowCompositionLayer.scrollEnabled = YES;
            appDelegate.mainMenu.windowCompositionLayer.contentSize = CGSizeMake(appDelegate.screenBounds.size.width * 3 - 40, appDelegate.screenBounds.size.height);
            appDelegate.viewIsDraggable = YES;
            
            if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
            {
                self.navigationController.navigationBar.translucent = NO;
            }
        }
        else
        {
            [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
            [self.navigationController setNavigationBarHidden:YES animated:YES];
        }
    }
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [browser stopLoading];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO]; // For some reason, the delegate method doesn't get called...
    [appDelegate.strobeLight deactivateStrobeLight];
    
    HUD.delegate = nil;
    
    if ( _shouldReportEndOfActivity )
    {
        [appDelegate.presenceManager setPresence:SHUserPresenceActivityStopped withTargetID:appDelegate.mainMenu.messagesView.recipientID forAudience:SHUserPresenceAudienceEveryone];
    }
    
    [super viewDidDisappear:animated];
}

#pragma mark -
#pragma mark Navigation

- (void)goBack
{
    [browser goBack];
}

- (void)goForward
{
    [browser goForward];
}

- (void)reloadPage
{
    if ( loading )
    {
        [browser stopLoading];
    }
    else
    {
        NSURL *URL = [NSURL URLWithString:_URL];
        NSURLRequest *theRequest = [NSURLRequest requestWithURL:URL
                                                    cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                timeoutInterval:120.0];
        [browser loadRequest:theRequest];
    }
}

- (void)showBrowserOptions
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIActionSheet *actionSheet;
    
    if ( [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]] )
    {
        actionSheet = [[UIActionSheet alloc] initWithTitle:_URL
                                      delegate:self
                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                        destructiveButtonTitle:nil
                             otherButtonTitles:NSLocalizedString(@"OPTION_OPEN_SAFARI", nil), NSLocalizedString(@"OPTION_OPEN_GOOGLE_CHROME", nil), NSLocalizedString(@"OPTION_COPY_LINK", nil), nil];
    }
    else
    {
        actionSheet = [[UIActionSheet alloc] initWithTitle:_URL
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:NSLocalizedString(@"OPTION_OPEN_SAFARI", nil), NSLocalizedString(@"OPTION_COPY_LINK", nil), nil];
    }
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.tag = 0;
    
    [actionSheet showFromRect:self.view.frame inView:appDelegate.window animated:YES];
}

#pragma mark -
#pragma mark UIWebViewDelegate methods

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [appDelegate.strobeLight activateStrobeLight];
    
    loading = YES;
    
    [refreshButton setImage:[UIImage imageNamed:@"browser_cancel"]];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [appDelegate.strobeLight deactivateStrobeLight];
    
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    if ( title.length > 0 )
    {
        [self setTitle:title];
    }
    else
    {
        [self setTitle:_URL];
    }
    
    loading = NO;
    
    [refreshButton setImage:[UIImage imageNamed:@"browser_reload"]];
    
    if ( browser.canGoBack )
    {
        backButton.enabled = YES;
    }
    else
    {
        backButton.enabled = NO;
    }
    
    if ( browser.canGoForward )
    {
        forwardButton.enabled = YES;
    }
    else
    {
        forwardButton.enabled = NO;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if ( error.code != -999 )
    {
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        
        HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cross_white"]];
        
        // Set custom view mode.
        HUD.mode = MBProgressHUDModeCustomView;
        HUD.dimBackground = YES;
        HUD.delegate = self;
        
        [HUD show:YES];
        [HUD hide:YES afterDelay:3];
        
        [appDelegate.strobeLight negativeStrobeLight];
        
        NSLog(@"%@", error);
    }
    else
    {
        [appDelegate.strobeLight deactivateStrobeLight];
    }
    
    loading = NO;
    [refreshButton setImage:[UIImage imageNamed:@"browser_reload"]];
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( actionSheet.tag == 0 ) // Browser options.
    {
        if ( buttonIndex == 0 ) // Open in Safari
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_URL]];
        }
        else if ( buttonIndex == 1 ) // Copy Link
        {
            if ( [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]] )
            {
                NSURL *inputURL = [NSURL URLWithString:_URL];
                NSString *scheme = inputURL.scheme;
                NSString *chromeScheme = nil; // Replace the URL Scheme with the Chrome equivalent.
                
                if ( [scheme isEqualToString:@"http"] )
                {
                    chromeScheme = @"googlechrome";
                }
                else if ( [scheme isEqualToString:@"https"] )
                {
                    chromeScheme = @"googlechromes";
                }
                
                // Proceed only if a valid Google Chrome URI Scheme is available.
                if ( chromeScheme )
                {
                    NSString *absoluteString = [inputURL absoluteString];
                    NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
                    NSString *URLNoScheme = [absoluteString substringFromIndex:rangeForScheme.location];
                    NSString *chromeURLString = [chromeScheme stringByAppendingString:URLNoScheme];
                    NSURL *chromeURL = [NSURL URLWithString:chromeURLString];
                    
                    // Open the URL with Chrome.
                    [[UIApplication sharedApplication] openURL:chromeURL];
                }
            }
            else
            {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string = _URL;
            }
        }
        else if ( buttonIndex == 2 ) // Copy Link (in case Chrome is installed)
        {
            if ( [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]] )
            {
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string = _URL;
            }
        }
    }
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods.

- (void)hudWasHidden:(MBProgressHUD *)hud
{
	// Remove HUD from screen when the HUD was hidden.
	[HUD removeFromSuperview];
	HUD = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
