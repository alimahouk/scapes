//
//  SHBoardDetailsViewController.m
//  Nightboard
//
//  Created by Ali.cpp on 3/18/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import "SHBoardDetailsViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>

#import "NSString+Utils.h"

#import "AFHTTPRequestOperationManager.h"
#import "AppDelegate.h"
#import "SHBoardViewController.h"

@implementation SHBoardDetailsViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        changesMade = NO;
        _isLastMember = NO;
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor whiteColor];
    
    photoPicker = [[UIImagePickerController alloc] init];
    photoPicker.mediaTypes = @[(NSString *)kUTTypeImage];
    photoPicker.delegate = self;
    
    saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"GENERIC_SAVE", nil) style:UIBarButtonItemStyleDone target:self action:@selector(updateBoardInfo)];
    saveButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = saveButton;
    
    listView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height) style:UITableViewStyleGrouped];
    listView.backgroundView = nil; // Fix for iOS 6+.
    listView.backgroundColor = [UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0];
    listView.delegate = self;
    listView.dataSource = self;
    listView.tag = 1;
    
    [contentView addSubview:listView];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    activeSegmentedControlIndex = _privacy - 1;
    
    [self reloadList];
    [self setTitle:NSLocalizedString(@"BOARD_DETAILS_TITLE", nil)];
}

- (void)changesMade
{
    saveButton.enabled = YES;
    changesMade = YES;
}

- (void)reloadList
{
    NSArray *arrTemp1 = [[NSArray alloc]
                         initWithObjects:NSLocalizedString(@"BOARD_DETAILS_NAME", nil), NSLocalizedString(@"BOARD_DETAILS_DESCRIPTION", nil), nil];
    NSArray *arrTemp2 = [[NSArray alloc]
                         initWithObjects:NSLocalizedString(@"BOARD_ADD_COVER", nil), nil];
    
    if ( _coverPhoto )
    {
        arrTemp2 = [[NSArray alloc]
                    initWithObjects:NSLocalizedString(@"BOARD_CHANGE_COVER", nil), NSLocalizedString(@"BOARD_REMOVE_COVER", nil), nil];
    }
    
    NSArray *arrTemp3 = [[NSArray alloc]
                         initWithObjects:@"Privacy", nil];
    NSArray *arrTemp4 = [[NSArray alloc]
                         initWithObjects:NSLocalizedString(@"BOARD_LEAVE", nil), nil];
    
    NSDictionary *temp = [[NSDictionary alloc]
                          initWithObjectsAndKeys:arrTemp1, @"1", arrTemp2,
                          @"2", arrTemp3, @"3", arrTemp4, @"4", nil];
    
    tableContents = temp;
    sortedKeys = [[tableContents allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    [listView reloadData];
}

- (void)boardPrivacyChanged:(id)sender
{
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    
    activeSegmentedControlIndex = segmentedControl.selectedSegmentIndex;
    
    [listView beginUpdates];
    [listView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [listView endUpdates];
    
    [self changesMade];
}

- (void)textFieldDidChange:(id)sender
{
    UITextField *textField = (UITextField *)sender;
    
    if ( textField.tag == 4 ) // Board name field.
    {
        [self changesMade];
        
        if ( textField.text.length > 0 )
        {
            saveButton.enabled = YES;
        }
        else
        {
            saveButton.enabled = NO;
        }
    }
}

- (void)updateBoardInfo
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight activateStrobeLight];
    
    if ( activeTextView )
    {
        [activeTextView resignFirstResponder];
        activeTextView = nil;
    }
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    UITableViewCell *nameCell = [listView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell *descriptionCell = [listView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITextField *nameField = (UITextField *)[nameCell.contentView viewWithTag:4];
    UITextView *descriptionField = (UITextView *)[descriptionCell.contentView viewWithTag:5];
    
    NSString *name = nameField.text;
    NSString *description = descriptionField.text;
    NSString *privacy = [NSString stringWithFormat:@"%d", (int)activeSegmentedControlIndex + 1];
    
    name = [name stringByTrimmingLeadingWhitespace];
    
    if ( name.length == 0 )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:NSLocalizedString(@"BOARD_DETAILS_ERROR_NAME", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"GENERIC_BACK", nil)
                                              otherButtonTitles:nil];
        [alert show];
        [HUD hide:YES];
        [appDelegate.strobeLight negativeStrobeLight];
        [nameField becomeFirstResponder];
        
        return;
    }
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[_boardID,
                                                                                    name,
                                                                                    description,
                                                                                    privacy]
                                                                          forKeys:@[@"board_id",
                                                                                    @"name",
                                                                                    @"description",
                                                                                    @"privacy"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/updateboardinfo", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        [HUD hide:YES];
        
        if ( responseData )
        {
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            if ( errorCode == 0 )
            {
                NSArray *viewControllers = self.navigationController.viewControllers;
                SHBoardViewController *senderView = [viewControllers objectAtIndex:0];
                
                saveButton.enabled = NO;
                changesMade = NO;
                
                [appDelegate.strobeLight affirmativeStrobeLight];
                [senderView loadBoardBatch:0];
                
                _boardName = name;
                _boardDescription = description;
                
                // We need a slight delay here.
                long double delayInSeconds = 0.45;
                
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    HUD = [[MBProgressHUD alloc] initWithView:self.view];
                    [self.view addSubview:HUD];
                    
                    HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_white"]];
                    
                    // Set custom view mode.
                    HUD.mode = MBProgressHUDModeCustomView;
                    HUD.dimBackground = YES;
                    HUD.delegate = self;
                    
                    [HUD show:YES];
                    [HUD hide:YES afterDelay:2];
                });
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
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)showLeaveConfirmation
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"BOARD_DETAILS_LEAVE_CONFIRMATION", nil)
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                               destructiveButtonTitle:NSLocalizedString(@"BOARD_LEAVE", nil)
                                                    otherButtonTitles:nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.tag = 0;
    [actionSheet showFromRect:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44) inView:self.view animated:YES];
}

- (void)leaveBoard
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight activateStrobeLight];
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[_boardID]
                                                                          forKeys:@[@"board_id"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/leaveboard", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                HUD.delegate = nil;
                listView.delegate = nil;
                
                [HUD hide:YES];
                [appDelegate.strobeLight deactivateStrobeLight];
                
                if ( _isLastMember )
                {
                    [appDelegate.mainMenu removeBoard:_boardID];
                    [appDelegate.mainMenu refreshCloud];
                    
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
                else
                {
                    NSArray *viewControllers = self.navigationController.viewControllers;
                    SHBoardViewController *senderView = [viewControllers objectAtIndex:0];
                    
                    [senderView loadBoardBatch:0];
                    [self.navigationController popViewControllerAnimated:YES];
                }
                
                [appDelegate.modelManager executeUpdate:@"DELETE FROM sh_board WHERE board_id = :board_id"
                                withParameterDictionary:@{@"board_id": _boardID}];
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
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

#pragma mark -
#pragma mark Cover photo

- (void)showCoverOptions
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIActionSheet *actionSheet;
    
    if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ) // If the device has a camera.
    {
        if ( !_coverPhoto )
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"BOARD_DETAILS_COVER_SHEET_TITLE", nil)
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"GENERIC_PHOTO_CAMERA_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LIBRARY_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LAST_TAKEN", nil), nil];
        }
        else
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"BOARD_DETAILS_COVER_SHEET_TITLE", nil)
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                        destructiveButtonTitle:NSLocalizedString(@"GENERIC_PHOTO_REMOVE", nil)
                                             otherButtonTitles:NSLocalizedString(@"GENERIC_PHOTO_CAMERA_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LIBRARY_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LAST_TAKEN", nil), nil];
        }
    }
    else
    {
        if ( !_coverPhoto )
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"BOARD_DETAILS_COVER_SHEET_TITLE", nil)
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"GENERIC_PHOTO_LIBRARY_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LAST_TAKEN", nil), nil];
        }
        else
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"BOARD_DETAILS_COVER_SHEET_TITLE", nil)
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                        destructiveButtonTitle:NSLocalizedString(@"GENERIC_PHOTO_REMOVE", nil)
                                             otherButtonTitles:NSLocalizedString(@"GENERIC_PHOTO_LIBRARY_VERBOSE", nil),
                           NSLocalizedString(@"GENERIC_PHOTO_LAST_TAKEN", nil), nil];
        }
    }
    
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.tag = 1;
    
    [actionSheet showFromRect:self.view.frame inView:appDelegate.window animated:YES];
}

- (void)cover_UseLastPhotoTaken
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    // Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop){
        
        // Within the group enumeration block, filter to enumerate just photos.
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        
        // Chooses the photo at the last index
        [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:[group numberOfAssets] - 1] options:0 usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop){
            
            // The end of the enumeration is signaled by asset == nil.
            if ( alAsset )
            {
                ALAssetRepresentation *representation = [alAsset defaultRepresentation];
                UIImage *selectedImage = [UIImage imageWithCGImage:[representation fullScreenImage]];
                
                _coverPhoto = selectedImage;
                
                [self uploadCover];
            }
        }];
    } failureBlock: ^(NSError *error){
        // Typically you should handle an error more gracefully than this.
        NSLog(@"No groups");
    }];
}

- (void)uploadCover
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight activateStrobeLight];
    
    NSData *imageData = UIImageJPEGRepresentation(_coverPhoto, 0.7);
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[_boardID]
                                                                          forKeys:@[@"board_id"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/boardcoverupload", SH_DOMAIN] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        if ( imageData )
        {
            [formData appendPartWithFileData:imageData name:@"image_file" fileName:@"image_file.jpg" mimeType:@"image/jpeg"];
        }
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        [HUD hide:YES];
        
        if ( responseData )
        {
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            if ( errorCode == 0 )
            {
                NSArray *viewControllers = self.navigationController.viewControllers;
                SHBoardViewController *senderView = [viewControllers objectAtIndex:0];
                
                [appDelegate.strobeLight affirmativeStrobeLight];
                [senderView loadBoardBatch:0];
                [self reloadList];
                
                NSString *newHash = [responseData objectForKey:@"response"];
                //[cover setImage:_coverPhoto];
                
                [appDelegate.modelManager executeUpdate:@"UPDATE sh_board SET cover_hash = :cover_hash, dp = :dp "
                 @"WHERE board_id = :board_id"
                                withParameterDictionary:@{@"cover_hash": newHash,
                                                          @"dp": UIImageJPEGRepresentation(_coverPhoto, 1.0),
                                                          @"board_id": _boardID}];
                
                // We need a slight delay here.
                long double delayInSeconds = 0.45;
                
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    HUD = [[MBProgressHUD alloc] initWithView:self.view];
                    [self.view addSubview:HUD];
                    
                    HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_white"]];
                    
                    // Set custom view mode.
                    HUD.mode = MBProgressHUDModeCustomView;
                    HUD.dimBackground = YES;
                    HUD.delegate = self;
                    
                    [HUD show:YES];
                    [HUD hide:YES afterDelay:2];
                });
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
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)removeCurrentCover
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.strobeLight activateStrobeLight];
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[_boardID]
                                                                          forKeys:@[@"board_id"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/boardcoverremove", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                
                _coverPhoto = nil;
                
                [appDelegate.strobeLight affirmativeStrobeLight];
                [senderView loadBoardBatch:0];
                [self reloadList];
                
                //[cover setImage:newSelectedDP];
                
                [HUD hide:YES];
                
                // We need a slight delay here.
                long double delayInSeconds = 0.45;
                
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    HUD = [[MBProgressHUD alloc] initWithView:self.view];
                    [self.view addSubview:HUD];
                    
                    HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_white"]];
                    
                    // Set custom view mode.
                    HUD.mode = MBProgressHUDModeCustomView;
                    HUD.dimBackground = YES;
                    HUD.delegate = self;
                    
                    [HUD show:YES];
                    [HUD hide:YES afterDelay:2];
                });
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
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

#pragma mark -
#pragma mark Media Picker

- (void)showMediaPicker_Camera
{
    photoPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    photoPicker.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:photoPicker animated:YES completion:NULL];
}

- (void)showMediaPicker_Library
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:photoPicker animated:YES completion:NULL];
}

- (void)dismissMediaPicker
{
    [photoPicker dismissViewControllerAnimated:NO completion:nil];
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
#pragma mark UITableViewDataSource methods.

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return sortedKeys.count;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    NSArray *listData =[tableContents objectForKey:[sortedKeys objectAtIndex:section]];
    
    return listData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CellIdentifier";
    
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSArray *listData =[tableContents objectForKey:[sortedKeys objectAtIndex:indexPath.section]];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    UISegmentedControl *segmentedControl;
    UILabel *privacyExplanationLabel;
    UILabel *cellTextLabel;
    UIView *privacyFieldBackground;
    UITextField *boardNameField;
    UITextView *boardDescriptionField;
    
    if ( cell == nil )
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // Set the accessory type.
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.frame = CGRectMake(20, 10, tableView.frame.size.width, 20);
        
        segmentedControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"CREATE_BOARD_OPEN", nil), NSLocalizedString(@"CREATE_BOARD_CLOSED", nil)]];
        [segmentedControl addTarget:self action:@selector(boardPrivacyChanged:) forControlEvents:UIControlEventValueChanged];
        segmentedControl.frame = CGRectMake(20, 20, appDelegate.screenBounds.size.width - 40, 32);
        segmentedControl.selectedSegmentIndex = activeSegmentedControlIndex;
        segmentedControl.tag = 1;
        segmentedControl.hidden = YES;
        
        privacyExplanationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, segmentedControl.frame.origin.y + segmentedControl.frame.size.height + 20, tableView.frame.size.width - 40, 20)];
        privacyExplanationLabel.textColor = [UIColor grayColor];
        privacyExplanationLabel.numberOfLines = 0;
        privacyExplanationLabel.text = NSLocalizedString(@"CREATE_BOARD_OPEN_EXPLANATION", nil);
        privacyExplanationLabel.tag = 2;
        privacyExplanationLabel.hidden = YES;
        
        privacyFieldBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, segmentedControl.frame.size.height + privacyExplanationLabel.frame.size.height + 60)];
        privacyFieldBackground.backgroundColor = [UIColor whiteColor];
        privacyFieldBackground.tag = 3;
        privacyFieldBackground.hidden = YES;
        
        boardNameField = [[UITextField alloc] initWithFrame:CGRectMake(140, 0, tableView.frame.size.width - 160, 44)];
        [boardNameField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        boardNameField.borderStyle = UITextBorderStyleNone;
        boardNameField.placeholder = NSLocalizedString(@"CREATE_BOARD_PLACEHOLDER", nil);
        boardNameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        boardNameField.clearButtonMode = UITextFieldViewModeWhileEditing;
        boardNameField.returnKeyType = UIReturnKeyDone;
        boardNameField.enablesReturnKeyAutomatically = YES;
        boardNameField.delegate = self;
        boardNameField.text = _boardName;
        boardNameField.tag = 4;
        boardNameField.hidden = YES;
        
        boardDescriptionField = [[UITextView alloc] initWithFrame:CGRectMake(15, 40, tableView.frame.size.width - 40, 140)];
        boardDescriptionField.font = [UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE];
        boardDescriptionField.delegate = self;
        boardDescriptionField.text = _boardDescription;
        boardDescriptionField.tag = 5;
        boardDescriptionField.hidden = YES;
        
        cellTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, tableView.frame.size.width - 40, 44)];
        cellTextLabel.numberOfLines = 1;
        cellTextLabel.tag = 6;
        cellTextLabel.hidden = YES;
        
        [cell.contentView addSubview:privacyFieldBackground];
        [cell.contentView addSubview:segmentedControl];
        [cell.contentView addSubview:privacyExplanationLabel];
        [cell.contentView addSubview:boardNameField];
        [cell.contentView addSubview:boardDescriptionField];
        [cell.contentView addSubview:cellTextLabel];
    }
    
    segmentedControl = (UISegmentedControl *)[cell.contentView viewWithTag:1];
    privacyExplanationLabel = (UILabel *)[cell.contentView viewWithTag:2];
    privacyFieldBackground = (UIView *)[cell.contentView viewWithTag:3];
    boardNameField = (UITextField *)[cell.contentView viewWithTag:4];
    boardDescriptionField = (UITextView *)[cell.contentView viewWithTag:5];
    cellTextLabel = (UILabel *)[cell.contentView viewWithTag:6];
    
    if ( indexPath.section == 0 && indexPath.row == 0 )
    {
        boardNameField.hidden = NO;
    }
    else
    {
        boardNameField.hidden = YES;
    }
    
    if ( indexPath.section == 0 && indexPath.row == 1 )
    {
        boardDescriptionField.hidden = NO;
    }
    else
    {
        boardDescriptionField.hidden = YES;
    }
    
    if ( indexPath.section == 2 && indexPath.row == 0 )
    {
        cellTextLabel.hidden = YES;
        privacyExplanationLabel.hidden = NO;
        privacyFieldBackground.hidden = NO;
        segmentedControl.hidden = NO;
        segmentedControl.selectedSegmentIndex = activeSegmentedControlIndex;
        
        CGSize maxSize = CGSizeMake(tableView.frame.size.width - 40, CGFLOAT_MAX);
        
        if ( activeSegmentedControlIndex == 0 )
        {
            CGSize textSize_privacyExplanationLabel = [NSLocalizedString(@"CREATE_BOARD_OPEN_EXPLANATION", nil) sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE] constrainedToSize:maxSize lineBreakMode:NSLineBreakByWordWrapping];
            
            privacyExplanationLabel.text = NSLocalizedString(@"CREATE_BOARD_OPEN_EXPLANATION", nil);
            privacyExplanationLabel.frame = CGRectMake(privacyExplanationLabel.frame.origin.x, privacyExplanationLabel.frame.origin.y, privacyExplanationLabel.frame.size.width, textSize_privacyExplanationLabel.height);
            
            privacyFieldBackground.frame = CGRectMake(privacyFieldBackground.frame.origin.x, privacyFieldBackground.frame.origin.y, privacyFieldBackground.frame.size.width, segmentedControl.frame.size.height + textSize_privacyExplanationLabel.height + 60);
        }
        else if ( activeSegmentedControlIndex == 1 )
        {
            CGSize textSize_privacyExplanationLabel = [NSLocalizedString(@"CREATE_BOARD_CLOSED_EXPLANATION", nil) sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE] constrainedToSize:maxSize lineBreakMode:NSLineBreakByWordWrapping];
            
            privacyExplanationLabel.text = NSLocalizedString(@"CREATE_BOARD_CLOSED_EXPLANATION", nil);
            privacyExplanationLabel.frame = CGRectMake(privacyExplanationLabel.frame.origin.x, privacyExplanationLabel.frame.origin.y, privacyExplanationLabel.frame.size.width, textSize_privacyExplanationLabel.height);
            
            privacyFieldBackground.frame = CGRectMake(privacyFieldBackground.frame.origin.x, privacyFieldBackground.frame.origin.y, privacyFieldBackground.frame.size.width, segmentedControl.frame.size.height + textSize_privacyExplanationLabel.height + 60);
        }
    }
    else
    {
        cellTextLabel.hidden = NO;
        privacyExplanationLabel.hidden = YES;
        privacyFieldBackground.hidden = YES;
        segmentedControl.hidden = YES;
        
        cellTextLabel.text = [listData objectAtIndex:indexPath.row];
        
        if ( (IS_IOS7) )
        {
            if ( (indexPath.section == 1 && indexPath.row == 1) ||
                (indexPath.section == 3 && indexPath.row == 0) )
            {
                cellTextLabel.textColor = [UIColor redColor];
            }
            else if ( indexPath.section == 0 )
            {
                cellTextLabel.textColor = [UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0];
            }
            else
            {
                cellTextLabel.textColor = [UIColor blackColor];
            }
        }
    }
    
    if ( indexPath.section == 0 || indexPath.section == 2 )
    {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else
    {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( indexPath.section == 0 && indexPath.row == 1 )
    {
        return 200;
    }
    
    if ( indexPath.section == 2 && indexPath.row == 0 )
    {
        CGSize maxSize = CGSizeMake(appDelegate.screenBounds.size.width - 40, CGFLOAT_MAX);
        CGSize textSize_privacyExplanationLabel;
        
        if ( activeSegmentedControlIndex == 0 )
        {
            textSize_privacyExplanationLabel = [NSLocalizedString(@"CREATE_BOARD_OPEN_EXPLANATION", nil) sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE] constrainedToSize:maxSize lineBreakMode:NSLineBreakByWordWrapping];
        }
        else if ( activeSegmentedControlIndex == 1 )
        {
            textSize_privacyExplanationLabel = [NSLocalizedString(@"CREATE_BOARD_CLOSED_EXPLANATION", nil) sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:MAIN_FONT_SIZE] constrainedToSize:maxSize lineBreakMode:NSLineBreakByWordWrapping];
        }
        
        return textSize_privacyExplanationLabel.height + 92;
    }
    
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.section == 1 && indexPath.row == 0 )
    {
        [self showCoverOptions];
    }
    else if ( indexPath.section == 1 && indexPath.row == 1 )
    {
        [self removeCurrentCover];
    }
    else if ( indexPath.section == 3 )
    {
        [self showLeaveConfirmation];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods.

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ( scrollView.tag == 1 ) // Main list view.
    {
        if ( activeTextView )
        {
            [activeTextView resignFirstResponder];
            activeTextView = nil;
        }
    }
}

#pragma mark -
#pragma mark UITextViewDelegate methods.

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    activeTextView = textView;
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self changesMade];
}

#pragma mark -
#pragma mark UITextFieldDelegate methods.

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    activeTextView = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return NO;
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:@"public.image"])
    {
        UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        _coverPhoto = selectedImage;
        
        [self uploadCover];
    }
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( actionSheet.tag == 0 ) // Leave Board
    {
        if ( buttonIndex == 0 )
        {
            [self leaveBoard];
        }
    }
    else if ( actionSheet.tag == 1 ) // Cover options.
    {
        if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ) // If the device has a camera.
        {
            if ( !_coverPhoto )
            {
                if ( buttonIndex == 0 )      // Camera.
                {
                    [self showMediaPicker_Camera];
                }
                else if ( buttonIndex == 1 ) // Library.
                {
                    [self showMediaPicker_Library];
                }
                else if ( buttonIndex == 2 ) // Last photo taken.
                {
                    [self cover_UseLastPhotoTaken];
                }
            }
            else
            {
                if ( buttonIndex == 0 )      // Remove photo.
                {
                    [self removeCurrentCover];
                }
                else if ( buttonIndex == 1 ) // Camera.
                {
                    [self showMediaPicker_Camera];
                }
                else if ( buttonIndex == 2 ) // Library.
                {
                    [self showMediaPicker_Library];
                }
                else if ( buttonIndex == 3 ) // Last photo taken.
                {
                    [self cover_UseLastPhotoTaken];
                }
            }
        }
        else
        {
            if ( !_coverPhoto )
            {
                if ( buttonIndex == 0 ) // Library.
                {
                    [self showMediaPicker_Library];
                }
                else if ( buttonIndex == 1 ) // Last photo taken.
                {
                    [self cover_UseLastPhotoTaken];
                }
            }
            else
            {
                if ( buttonIndex == 0 )      // Remove photo.
                {
                    [self removeCurrentCover];
                }
                else if ( buttonIndex == 1 ) // Library.
                {
                    [self showMediaPicker_Library];
                }
                else if ( buttonIndex == 2 ) // Last photo taken.
                {
                    [self cover_UseLastPhotoTaken];
                }
            }
        }
    }
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
