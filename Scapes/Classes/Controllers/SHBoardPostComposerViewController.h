//
//  SHBoardPostComposerViewController.h
//  Nightboard
//
//  Created by Ali.cpp on 3/17/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Constants.h"
#import "MBProgressHUD.h"

@interface SHBoardPostComposerViewController : UIViewController <MBProgressHUDDelegate, UITextViewDelegate>
{
    MBProgressHUD *HUD;
    UIBarButtonItem *postButton;
    UITextView *composer;
    SHPostColor postColor;
    CGSize keyboardSize;
}

@property (nonatomic) NSString *boardID;

- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillBeHidden:(NSNotification *)notification;

- (void)didSwipeComposer:(UISwipeGestureRecognizer *)gestureRecognizer;

- (void)post;
- (void)dismissView;
- (void)decideOnEnablingPostButton;

- (void)showNetworkError;

@end
