//
//  SHSearchViewController.h
//  Nightboard
//
//  Created by Ali.cpp on 3/20/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MBProgressHUD.h"

@interface SHSearchViewController : UIViewController <MBProgressHUDDelegate, UISearchBarDelegate>
{
    MBProgressHUD *HUD;
    UIToolbar *lowerToolbar;
    UIButton *cancelButton;
    UISearchBar *searchBox;
    UIScrollView *mainScrollView;
    UIView *searchOverlay;
    UIView *postContainer;
    UILabel *searchResultsCountLabel;
    NSMutableArray *posts;
    BOOL searchInterfaceIsShown;
}

@property (nonatomic) NSString *boardID;
@property (nonatomic) NSString *boardName;
@property (nonatomic) NSString *currentQuery;

- (void)showSearchInterface;
- (void)hideSearchInterface;
- (void)enableCancelButton;
- (void)enableSearchInterface;
- (void)dismissSearchInterface;
- (void)clearSearchField;
- (void)dismissView;

- (void)searchForQuery:(NSString *)query;
- (void)reloadBoardData;

- (void)tappedPost:(id)sender;
- (void)markPostAsViewed:(NSString *)postID;

- (void)showNetworkError;

@end
