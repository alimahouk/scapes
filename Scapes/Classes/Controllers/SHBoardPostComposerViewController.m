//
//  SHBoardPostComposerViewController.m
//  Nightboard
//
//  Created by Ali.cpp on 3/17/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import "SHBoardPostComposerViewController.h"

#import "NSString+Utils.h"

#import "AFHTTPRequestOperationManager.h"
#import "AppDelegate.h"
#import "SHBoardViewController.h"

@implementation SHBoardPostComposerViewController

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
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor whiteColor];
    
    postButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"GENERIC_POST", nil) style:UIBarButtonItemStyleDone target:self action:@selector(post)];
    postButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = postButton;
    
    postColor = arc4random_uniform(6);
    
    composer = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 100) textContainer:nil];
    composer.backgroundColor = [appDelegate colorForCode:postColor];
    composer.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
    composer.textColor = [UIColor blackColor];
    composer.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    composer.keyboardType = UIKeyboardTypeTwitter;
    composer.delegate = self;
    
    UISwipeGestureRecognizer *swipeUpGestureRecognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeComposer:)];
    swipeUpGestureRecognizerLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [composer addGestureRecognizer:swipeUpGestureRecognizerLeft];
    
    UISwipeGestureRecognizer *swipeUpGestureRecognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeComposer:)];
    swipeUpGestureRecognizerRight.direction = UISwipeGestureRecognizerDirectionRight;
    [composer addGestureRecognizer:swipeUpGestureRecognizerRight];
    
    [contentView addSubview:composer];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:NSLocalizedString(@"BOARD_POST_COMPOSER_TITLE", nil)];
    [composer becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    if ( ![[NSUserDefaults standardUserDefaults] stringForKey:@"SHBDTutorialPostColor"] )
    {
        UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height)];
        overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
        [self.view addSubview:overlay];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 64, appDelegate.screenBounds.size.width - 40, 120)];
        titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:MAIN_FONT_SIZE];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.numberOfLines = 0;
        titleLabel.text = @"👆\nSwipe left or right\nto change the post's color.";
        [overlay addSubview:titleLabel];
        
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"SHBDTutorialPostColor"];
        
        [UIView animateWithDuration:0.35 delay:5 options:UIViewAnimationOptionCurveLinear animations:^{
            overlay.alpha = 0.0;
        } completion:^(BOOL finished){
            [overlay removeFromSuperview];
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDictionary *info = [notification userInfo];
    keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    composer.frame = CGRectMake(composer.frame.origin.x, composer.frame.origin.y, composer.frame.size.width, appDelegate.screenBounds.size.height - keyboardSize.height);
}

- (void)keyboardWillBeHidden:(NSNotification *)notification
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    composer.frame = CGRectMake(composer.frame.origin.x, composer.frame.origin.y, composer.frame.size.width, appDelegate.screenBounds.size.height);
}

- (void)didSwipeComposer:(UISwipeGestureRecognizer *)gestureRecognizer
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( gestureRecognizer.direction == UISwipeGestureRecognizerDirectionRight )
    {
        if ( postColor == 1 )
        {
            postColor = 6;
        }
        else
        {
            postColor--;
        }
    }
    else
    {
        if ( postColor == 6 )
        {
            postColor = 1;
        }
        else
        {
            postColor++;
        }
    }
    
    [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        composer.backgroundColor = [appDelegate colorForCode:postColor];
    } completion:^(BOOL finished){
        
    }];
}

- (void)post
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight activateStrobeLight];
    [composer resignFirstResponder];
    composer.editable = NO;
    postButton.enabled = NO;
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    NSString *post = composer.text;
    
    if ( post.length > MAX_POST_LENGTH )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"BOARD_POST_COMPOSER_LENGTH_ERROR_TITLE", nil)
                                                        message:NSLocalizedString(@"BOARD_POST_COMPOSER_LENGTH_ERROR", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"GENERIC_BACK", nil)
                                              otherButtonTitles:nil];
        [alert show];
        
        return;
    }
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[_boardID,
                                                                                    [NSString stringWithFormat:@"%d", postColor],
                                                                                    post]
                                                                          forKeys:@[@"board_id",
                                                                                    @"color",
                                                                                    @"text"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/createboardpost", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        if ( responseData )
        {
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            if ( errorCode == 0 )
            {
                NSArray *viewControllers = self.navigationController.viewControllers;
                SHBoardViewController *senderView = [viewControllers objectAtIndex:0];
                
                [senderView loadBoardBatch:0];
                [appDelegate.strobeLight affirmativeStrobeLight];
                [self dismissView];
            }
            else
            {
                composer.editable = YES;
                [composer becomeFirstResponder];
                [self decideOnEnablingPostButton];
                [self showNetworkError];
            }
        }
        else
        {
            [self showNetworkError];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        composer.editable = YES;
        [composer becomeFirstResponder];
        [self decideOnEnablingPostButton];
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)dismissView
{
    [composer resignFirstResponder];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)decideOnEnablingPostButton
{
    NSString *post = composer.text;
    
    post = [post stringByTrimmingLeadingWhitespace];
    
    if ( post.length > 0 )
    {
        postButton.enabled = YES;
    }
    else
    {
        postButton.enabled = NO;
    }
}

- (void)showNetworkError
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight negativeStrobeLight];
    [HUD hide:YES];
    
    // We need a slight delay here.
    long double delayInSeconds = 0.45;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        
        HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cross_white"]];
        
        // Set custom view mode.
        HUD.mode = MBProgressHUDModeCustomView;
        HUD.dimBackground = YES;
        HUD.delegate = self;
        HUD.labelText = NSLocalizedString(@"GENERIC_HUD_NETWORK_ERROR", nil);
        
        [HUD show:YES];
        [HUD hide:YES afterDelay:3];
    });
}

#pragma mark -
#pragma mark UITextViewDelegate methods

- (void)textViewDidChange:(UITextView *)textView
{
    [self decideOnEnablingPostButton];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

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
