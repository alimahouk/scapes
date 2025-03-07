//
//  GalleryViewController.m
//  Scapes
//
//  Created by MachOSX on 2/25/14.
//
//

#import "GalleryViewController.h"

@implementation GalleryViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        UIIsShown = YES;
        _resetsViewWhenPopped = NO;
        
        self.wantsFullScreenLayout = YES;
        
        if ( [self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)] )
        {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    
    if ( !(IS_IOS7) )
    {
        contentView.backgroundColor = [UIColor blackColor];
    }
    else
    {
        if ( appDelegate.mainWindowNavigationController.inPrivateMode )
        {
            contentView.backgroundColor = [UIColor blackColor];
        }
        else
        {
            contentView.backgroundColor = [UIColor whiteColor];
        }
    }
    
    shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showExportOptions)];
    self.navigationItem.rightBarButtonItem = shareButton;
    
    mainScrollView = [[SHGalleryZoomingView alloc] initWithFrame:appDelegate.screenBounds];
    mainScrollView.delegate = self;
    
    UILongPressGestureRecognizer *gesture_longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapAndHoldMedia:)];
    gesture_longPress.cancelsTouchesInView = NO;
    [mainScrollView.photoImageView addGestureRecognizer:gesture_longPress];
    
    UITapGestureRecognizer *gesture_singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapImage:)];
    gesture_singleTap.numberOfTapsRequired = 1;
    gesture_singleTap.cancelsTouchesInView = NO;
    [mainScrollView addGestureRecognizer:gesture_singleTap];
    
    UITapGestureRecognizer *gesture_doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userDidDoubleTapImage:)];
    gesture_doubleTap.numberOfTapsRequired = 2;
    gesture_doubleTap.cancelsTouchesInView = NO;
    [mainScrollView.photoImageView addGestureRecognizer:gesture_doubleTap];
    
    [gesture_singleTap requireGestureRecognizerToFail:gesture_doubleTap];
    
    [contentView addSubview:mainScrollView];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    UIImage *initialImageView = [UIImage imageWithData:_initialMediaData];
    mainScrollView.photoImageView.image = initialImageView;
    
    [mainScrollView displayImage];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    self.navigationController.navigationBar.translucent = YES;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
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
            [appDelegate.mainMenu enableCompositionLayerScrolling];
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

- (void)showUI
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationController.navigationBar.alpha = 0.0;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.navigationController.navigationBar.alpha = 1.0;
        
        if ( (IS_IOS7) && !appDelegate.mainWindowNavigationController.inPrivateMode )
        {
            self.view.backgroundColor = [UIColor whiteColor];
        }
    } completion:^(BOOL finished){
        
    }];
    
    UIIsShown = YES;
}

- (void)hideUI
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.navigationController.navigationBar.alpha = 0.0;
        
        if ( (IS_IOS7) )
        {
            self.view.backgroundColor = [UIColor blackColor];
        }
    } completion:^(BOOL finished){
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    }];
    
    UIIsShown = NO;
}

- (void)showExportOptions
{
    NSURL *path = [NSURL fileURLWithPath:_mediaLocalPath];
    NSArray *activityItems = @[path];
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    [self.navigationController presentViewController:activityController animated:YES completion:nil];
    
    /*documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:path];
    documentInteractionController.delegate = self;
    documentInteractionController
    
    [documentInteractionController presentOpenInMenuFromBarButtonItem:shareButton animated:YES];*/
}

- (void)copyImage
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.image = [UIImage imageWithData:_initialMediaData];
}

#pragma mark -
#pragma mark Gestures

- (BOOL)canPerformAction:(SEL)selector withSender:(id)sender
{
    if ( selector == @selector(copyImage) )
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)userDidTapAndHoldMedia:(UILongPressGestureRecognizer *)longPress
{
    if ( [longPress state] == UIGestureRecognizerStateBegan )
    {
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(copyImage)];
        
        [mainScrollView.photoImageView becomeFirstResponder];
        [menuController setMenuItems:[NSArray arrayWithObject:menuItem]];
        [menuController setTargetRect:mainScrollView.photoImageView.frame inView:self.view];
        [menuController setMenuVisible:YES animated:YES];
    }
}

- (void)userDidTapImage:(UITapGestureRecognizer *)tap
{
    if ( UIIsShown )
    {
        [self hideUI];
    }
    else
    {
        [self showUI];
    }
}

- (void)userDidDoubleTapImage:(UITapGestureRecognizer *)doubleTap
{
    if ( UIIsShown )
    {
        [self hideUI];
    }
    
    CGPoint touchPoint = [doubleTap locationInView:mainScrollView.photoImageView];
    
    // Zoom.
	if ( mainScrollView.zoomScale != mainScrollView.minimumZoomScale && mainScrollView.zoomScale != [mainScrollView initialZoomScaleWithMinScale] )
    {
		// Zoom out.
		[mainScrollView setZoomScale:mainScrollView.minimumZoomScale animated:YES];
	}
    else
    {
		// Zoom in to twice the size.
        CGFloat newZoomScale = ((mainScrollView.maximumZoomScale + mainScrollView.minimumZoomScale) / 2);
        CGFloat xsize = mainScrollView.bounds.size.width / newZoomScale;
        CGFloat ysize = mainScrollView.bounds.size.height / newZoomScale;
        [mainScrollView zoomToRect:CGRectMake(touchPoint.x - xsize / 2, touchPoint.y - ysize / 2, xsize, ysize) animated:YES];
	}
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return mainScrollView.photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	if ( UIIsShown )
    {
        [self hideUI];
    }
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    if ( UIIsShown )
    {
        [self hideUI];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end