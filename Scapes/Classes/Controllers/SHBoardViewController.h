//
//  SHBoardViewController.h
//  Nightboard
//
//  Created by Ali.cpp on 3/14/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Constants.h"
#import "MBProgressHUD.h"
#import "SHChatBubble.h"

@interface SHBoardViewController : UIViewController <MBProgressHUDDelegate, UIScrollViewDelegate, SHChatBubbleDelegate>
{
    MBProgressHUD *HUD;
    UIBarButtonItem *closeButton;
    UIBarButtonItem *moreActionsButton;
    UIRefreshControl *refreshControl;
    UIView *titleView;
    UIView *scrollViewBackground;
    UIView *headerBackground;
    UIView *coverContainer;
    UIView *memberPreviewContainer;
    UIView *postContainer;
    UIScrollView *mainScrollView;
    UIImageView *cover;
    UIImageView *leavePostIcon;
    UIImageView *joinIcon;
    UIImageView *privacyIcon;
    UIButton *leavePostButton;
    UIButton *joinButton;
    UIButton *requestsButton;
    UILabel *titleLabel;
    UILabel *subtitleLabel;
    UILabel *loadStatusLabel;
    UILabel *dateCreatedLabel;
    UILabel *descriptionLabel;
    UIImage *coverPhoto;
    NSMutableArray *memberPreviewList;
    NSMutableArray *posts;
    NSDateFormatter *dateFormatter;
    NSDate *dateCreated;
    NSString *boardName;
    NSString *boardDescription;
    NSString *coverHash;
    SHPrivacySetting boardPrivacy;
    BOOL userIsMember;
    BOOL userDidSendJoinRequest;
    BOOL coverDidAnimate;
    int memberCount;
    int requestCount;
    int postSize;
    int batch;
    float coverBlurRadius;
    float oldXOffset;
}

@property (nonatomic) NSString *boardID;
@property (nonatomic) NSString *currentCoverHash;
@property (nonatomic) UIImage *currentCover;

- (void)dismissView;
- (void)moreBoardOptions;
- (void)presentPostComposer;
- (void)presentSearchWithQuery:(NSString *)query;
- (void)tappedPost:(id)sender;
- (void)viewPendingRequests;
- (void)markPostAsViewed:(NSString *)postID;

- (void)joinBoard;
- (void)loadBoardBatch:(int)batchNo;
- (void)refreshBoard;
- (void)reloadBoardData;

- (void)processMemberPreview;

- (void)loadCoverPhoto;
- (void)processCoverPhoto;
- (void)revealCover;
- (void)obscureCover;
- (UIImage *)blurImage:(UIImage *)sourceImage radius:(float)radius;

- (void)showNetworkError;

@end
