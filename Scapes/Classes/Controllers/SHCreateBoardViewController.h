//
//  SHCreateBoardViewController.h
//  Nightboard
//
//  Created by Ali.cpp on 3/13/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MBProgressHUD.h"

@interface SHCreateBoardViewController : UIViewController <MBProgressHUDDelegate, UITextFieldDelegate>
{
    MBProgressHUD *HUD;
    UIScrollView *scrollView;
    UIView *fieldBG;
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *createButton;
    UISegmentedControl *segmentedControl;
    UILabel *privacyExplanationLabel;
    UITextField *boardNameField;
    CGSize keyboardSize;
    NSInteger activeSegmentedControlIndex;
}

- (void)dismissView;
- (void)boardPrivacyChanged;
- (void)createBoard;

- (void)keyboardWillShow:(NSNotification *)notification;
- (void)textFieldDidChange:(id)sender;

- (void)showNetworkError;

@end
