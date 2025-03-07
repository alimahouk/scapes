//
//  SHContactCloud.h
//  Nightboard
//
//  Created by MachOSX on 8/4/13.
//
//

#import <UIKit/UIKit.h>

#import "Constants.h"
#import "FMDB.h"
#import "SHChatBubble.h"

@class SHContactCloud;

@protocol SHContactCloudDelegate<UIScrollViewDelegate>

- (void)didSelectBubble:(SHChatBubble *)bubble inCloud:(SHContactCloud *)theCloud;
- (void)didTapAndHoldBubble:(SHChatBubble *)bubble inCloud:(SHContactCloud *)theCloud;

@end

@interface SHContactCloud : UIScrollView <SHChatBubbleDelegate>
{
    NSMutableArray *grid_primary;
    NSMutableArray *grid_secondary;
    int x_max;
    int y_max;
}

@property (nonatomic, weak) id <SHContactCloudDelegate> cloudDelegate;
@property (nonatomic) UIView *cloudContainer;
@property (nonatomic) UIView *cloudSearchResultsContainer;
@property (nonatomic) UILabel *headerLabel;
@property (nonatomic) UILabel *footerLabel;
@property (nonatomic) NSMutableArray *cloudBubbles;
@property (nonatomic) NSMutableArray *searchResultsBubbles;
@property (nonatomic) NSMutableArray *removedBubbles;
@property (nonatomic) int cellSize;
@property (nonatomic) int cellCount;
@property (nonatomic) BOOL isInSearchMode;
@property (nonatomic) BOOL insertBadgeCounts;
@property (nonatomic) BOOL makeRoomForBubbles;

- (void)beginUpdates;
- (void)endUpdates;

- (void)layoutPrimaryGrid;
- (void)layoutSecondaryGrid;

- (CGRect)cellForPoint:(CGPoint)point;
- (NSMutableSet *)cellsForBubble:(SHChatBubble *)bubble;
- (NSMutableSet *)bubblesForCell:(CGRect)cell;

- (CGPoint)emptyPointForBubble:(SHChatBubble *)bubble;
- (void)insertBubble:(SHChatBubble *)bubble atPoint:(CGPoint)point animated:(BOOL)animated;
- (void)removeBubble:(SHChatBubble *)bubble permanently:(BOOL)permanently animated:(BOOL)animated;
- (void)moveBubble:(SHChatBubble *)bubble toPoint:(CGPoint)point animated:(BOOL)animated;

- (void)setDP:(UIImage *)DP forUser:(NSString *)userID;
- (void)removeDPForUser:(NSString *)userID;
- (void)renameBubble:(NSString *)alias forUser:(NSString *)userID;

- (void)gotoCellForBubble:(SHChatBubble *)bubble animated:(BOOL)animated;
- (void)jumpToCenter;
- (void)updatePresenceWithDB:(FMDatabase *)db;

- (void)emptyBitBucket;

@end

