//
//  SHBoardDetailsViewController.h
//  Nightboard
//
//  Created by Ali.cpp on 3/18/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Constants.h"
#import "MBProgressHUD.h"

@interface SHBoardDetailsViewController : UIViewController <MBProgressHUDDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UITextFieldDelegate, UIActionSheetDelegate>
{
    MBProgressHUD *HUD;
    UIImagePickerController *photoPicker;
    UIBarButtonItem *saveButton;
    UITableView *listView;
    id activeTextView;
    NSDictionary *tableContents;
    NSArray *sortedKeys;
    NSInteger activeSegmentedControlIndex;
    BOOL changesMade;
}

@property (nonatomic) UIImage *coverPhoto;
@property (nonatomic) NSString *boardID;
@property (nonatomic) NSString *boardName;
@property (nonatomic) NSString *boardDescription;
@property (nonatomic) SHPrivacySetting privacy;
@property (nonatomic) BOOL isLastMember;

- (void)changesMade;
- (void)reloadList;
- (void)boardPrivacyChanged:(id)sender;
- (void)textFieldDidChange:(id)sender;
- (void)updateBoardInfo;
- (void)showLeaveConfirmation;
- (void)leaveBoard;

- (void)showCoverOptions;
- (void)cover_UseLastPhotoTaken;
- (void)uploadCover;
- (void)removeCurrentCover;

// Media Picker
- (void)showMediaPicker_Camera;
- (void)showMediaPicker_Library;
- (void)dismissMediaPicker;

- (void)showNetworkError;

@end
