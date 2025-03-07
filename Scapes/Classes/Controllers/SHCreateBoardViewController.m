//
//  SHCreateBoardViewController.m
//  Nightboard
//
//  Created by Ali.cpp on 3/13/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import "SHCreateBoardViewController.h"

#import "NSString+Utils.h"

#import "AFHTTPRequestOperationManager.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "SHBoardViewController.h"

@implementation SHCreateBoardViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        activeSegmentedControlIndex = 0;
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    self.navigationController.navigationBar.translucent = NO;
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0];
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height)];
    
    cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"GENERIC_CANCEL", nil) style:UIBarButtonItemStylePlain target:self action:@selector(dismissView)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    createButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"GENERIC_CREATE", nil) style:UIBarButtonItemStyleDone target:self action:@selector(createBoard)];
    createButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = createButton;
    
    CGSize maxSize = CGSizeMake(appDelegate.screenBounds.size.width - 40, CGFLOAT_MAX);
    CGSize textSize_mainExplanationLabel = [NSLocalizedString(@"CREATE_BOARD_MAIN_EXPLANATION", nil) sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE] constrainedToSize:maxSize lineBreakMode:NSLineBreakByWordWrapping];
    
    CGSize textSize_privacyExplanationLabel = [NSLocalizedString(@"CREATE_BOARD_OPEN_EXPLANATION", nil) sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE] constrainedToSize:maxSize lineBreakMode:NSLineBreakByWordWrapping];
    
    UILabel *explanationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, appDelegate.screenBounds.size.width - 40, textSize_mainExplanationLabel.height)];
    explanationLabel.textColor = [UIColor grayColor];
    explanationLabel.numberOfLines = 0;
    explanationLabel.text = NSLocalizedString(@"CREATE_BOARD_MAIN_EXPLANATION", nil);
    
    boardNameField = [[UITextField alloc] initWithFrame:CGRectMake(20, explanationLabel.frame.origin.y + explanationLabel.frame.size.height + 30, appDelegate.screenBounds.size.width - 40, 44)];
    [boardNameField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    boardNameField.borderStyle = UITextBorderStyleNone;
    boardNameField.placeholder = NSLocalizedString(@"CREATE_BOARD_PLACEHOLDER", nil);
    boardNameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    boardNameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    boardNameField.returnKeyType = UIReturnKeyDone;
    boardNameField.enablesReturnKeyAutomatically = YES;
    boardNameField.delegate = self;
    boardNameField.tag = 0;
    
    segmentedControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"CREATE_BOARD_OPEN", nil), NSLocalizedString(@"CREATE_BOARD_CLOSED", nil)]];
    [segmentedControl addTarget:self action:@selector(boardPrivacyChanged) forControlEvents:UIControlEventValueChanged];
    segmentedControl.frame = CGRectMake(20, boardNameField.frame.origin.y + boardNameField.frame.size.height + 10, appDelegate.screenBounds.size.width - 40, 32);
    segmentedControl.selectedSegmentIndex = activeSegmentedControlIndex;
    
    privacyExplanationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, segmentedControl.frame.origin.y + segmentedControl.frame.size.height + 20, appDelegate.screenBounds.size.width - 40, textSize_privacyExplanationLabel.height)];
    privacyExplanationLabel.textColor = [UIColor grayColor];
    privacyExplanationLabel.numberOfLines = 0;
    privacyExplanationLabel.text = NSLocalizedString(@"CREATE_BOARD_OPEN_EXPLANATION", nil);
    
    fieldBG = [[UIScrollView alloc] initWithFrame:CGRectMake(0, explanationLabel.frame.origin.y + explanationLabel.frame.size.height + 20, appDelegate.screenBounds.size.width, boardNameField.frame.size.height + segmentedControl.frame.size.height + privacyExplanationLabel.frame.size.height + 60)];
    fieldBG.backgroundColor = [UIColor whiteColor];
    
    scrollView.contentSize = CGSizeMake(appDelegate.screenBounds.size.width, privacyExplanationLabel.frame.origin.y + privacyExplanationLabel.frame.size.height + 20);
    
    [scrollView addSubview:fieldBG];
    [scrollView addSubview:explanationLabel];
    [scrollView addSubview:boardNameField];
    [scrollView addSubview:segmentedControl];
    [scrollView addSubview:privacyExplanationLabel];
    [contentView addSubview:scrollView];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:NSLocalizedString(@"CREATE_BOARD_TITLE", nil)];
    [boardNameField becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [super viewDidAppear:animated];
    
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionNavigationBar];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [super viewWillDisappear:animated];
    
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dismissView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)boardPrivacyChanged
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    CGSize maxSize = CGSizeMake(appDelegate.screenBounds.size.width - 40, CGFLOAT_MAX);
    
    if ( segmentedControl.selectedSegmentIndex == 0 &&
        segmentedControl.selectedSegmentIndex != activeSegmentedControlIndex )
    {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            privacyExplanationLabel.alpha = 0.0;
        } completion:^(BOOL finished){
            CGSize textSize_privacyExplanationLabel = [NSLocalizedString(@"CREATE_BOARD_OPEN_EXPLANATION", nil) sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE] constrainedToSize:maxSize lineBreakMode:NSLineBreakByWordWrapping];
            
            privacyExplanationLabel.text = NSLocalizedString(@"CREATE_BOARD_OPEN_EXPLANATION", nil);
            privacyExplanationLabel.frame = CGRectMake(privacyExplanationLabel.frame.origin.x, privacyExplanationLabel.frame.origin.y, privacyExplanationLabel.frame.size.width, textSize_privacyExplanationLabel.height);
            
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                fieldBG.frame = CGRectMake(fieldBG.frame.origin.x, fieldBG.frame.origin.y, fieldBG.frame.size.width, boardNameField.frame.size.height + segmentedControl.frame.size.height + textSize_privacyExplanationLabel.height + 60);
                privacyExplanationLabel.alpha = 1.0;
            } completion:^(BOOL finished){
                
            }];
        }];
        
    }
    else if ( segmentedControl.selectedSegmentIndex == 1 &&
             segmentedControl.selectedSegmentIndex != activeSegmentedControlIndex )
    {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            privacyExplanationLabel.alpha = 0.0;
        } completion:^(BOOL finished){
            CGSize textSize_privacyExplanationLabel = [NSLocalizedString(@"CREATE_BOARD_CLOSED_EXPLANATION", nil) sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE] constrainedToSize:maxSize lineBreakMode:NSLineBreakByWordWrapping];
            
            privacyExplanationLabel.text = NSLocalizedString(@"CREATE_BOARD_CLOSED_EXPLANATION", nil);
            privacyExplanationLabel.frame = CGRectMake(privacyExplanationLabel.frame.origin.x, privacyExplanationLabel.frame.origin.y, privacyExplanationLabel.frame.size.width, textSize_privacyExplanationLabel.height);
            
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                fieldBG.frame = CGRectMake(fieldBG.frame.origin.x, fieldBG.frame.origin.y, fieldBG.frame.size.width, boardNameField.frame.size.height + segmentedControl.frame.size.height + textSize_privacyExplanationLabel.height + 60);
                privacyExplanationLabel.alpha = 1.0;
            } completion:^(BOOL finished){
                
            }];
        }];
    }
    
    activeSegmentedControlIndex = segmentedControl.selectedSegmentIndex;
}

- (void)createBoard
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSString *boardName = boardNameField.text;
    NSString *privacy = [NSString stringWithFormat:@"%d", activeSegmentedControlIndex == 0 ? SHPrivacySettingPublic : SHPrivacySettingPrivate];
    
    boardName = [boardName stringByTrimmingLeadingWhitespace];
    
    if ( boardName.length == 0 )
    {
        [appDelegate.strobeLight negativeStrobeLight];
        
        return;
    }
    
    [appDelegate.strobeLight activateStrobeLight];
    [boardNameField resignFirstResponder];
    boardNameField.enabled = NO;
    cancelButton.enabled = NO;
    createButton.enabled = NO;
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[boardName,
                                                                                    privacy]
                                                                          forKeys:@[@"name",
                                                                                    @"privacy"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/createboard", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                NSString *boardID = [NSString stringWithFormat:@"%@", [responseData objectForKey:@"response"]];
                
                [self dismissViewControllerAnimated:YES completion:^{
                    SHBoardViewController *boardView = [[SHBoardViewController alloc] init];
                    SHOrientationNavigationController *navigationController = [[SHOrientationNavigationController alloc] initWithRootViewController:boardView];
                    navigationController.autoRotates = NO;
                    
                    boardView.boardID = boardID;
                    [appDelegate.contactManager requestFollowing];
                    [appDelegate.mainMenu presentViewController:navigationController animated:YES completion:nil];
                }];
                
                [appDelegate.strobeLight deactivateStrobeLight];
            }
            else
            {
                [self showNetworkError];
            }
        }
        else
        {
            [self showNetworkError];
        }
        
        NSLog(@"Response: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDictionary *info = [notification userInfo];
    keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    scrollView.frame = CGRectMake(scrollView.frame.origin.x, scrollView.frame.origin.y, scrollView.frame.size.width, appDelegate.screenBounds.size.height - keyboardSize.height - 64);
}

- (void)textFieldDidChange:(id)sender
{
    UITextField *textField = (UITextField *)sender;
    
    if ( textField.tag == 0 )
    {
        if ( textField.text.length > 0 )
        {
            createButton.enabled = YES;
        }
        else
        {
            createButton.enabled = NO;
        }
    }
}

- (void)showNetworkError
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight negativeStrobeLight];
    [HUD hide:YES];
    
    cancelButton.enabled = YES;
    createButton.enabled = YES;
    boardNameField.enabled = YES;
    [boardNameField becomeFirstResponder];
    
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
#pragma mark UITextFieldDelegate methods.

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ( textField.tag == 0 )
    {
        [self createBoard];
    }
    
    return NO;
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
