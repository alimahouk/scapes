//
//  SHBoardPostViewController.h
//  Nightboard
//
//  Created by Ali.cpp on 3/17/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Constants.h"
#import "TTTAttributedLabel.h"

@interface SHBoardPostViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate, TTTAttributedLabelDelegate>
{
    UIToolbar *lowerToolbar;
    UIScrollView *mainScrollView;
    UITextView *composer;
    UIBarButtonItem *editButton;
    UIBarButtonItem *deleteButton;
    UIBarButtonItem *shareButton;
    TTTAttributedLabel *postLabel;
    UILabel *timestampLabel;
    UILabel *viewsLabel;
    NSMutableDictionary *postData;
    NSString *activeLink;
    SHPostColor postColor;
    CGSize keyboardSize;
    BOOL isPostOwner;
    BOOL inEditingMode;
}

@property (nonatomic) NSString *postID;
@property (nonatomic) NSString *boardID;
@property (nonatomic) NSString *boardName;

- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillBeHidden:(NSNotification *)notification;

- (void)setPost:(NSMutableDictionary *)post;
- (void)redrawView;
- (void)showSharingOptions;
- (void)enterEditingMode;
- (void)exitEditingMode;
- (void)decideOnEnablingDoneButton;
- (void)saveEdits;
- (void)deletePost;
- (void)confirmDelete;
- (void)recordView;

@end
