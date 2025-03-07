//
//  SHChatBubble.h
//  Scapes
//
//  Created by MachOSX on 8/3/13.
//
//

@class SHChatBubble;

@protocol SHChatBubbleDelegate<NSObject>

- (void)didSelectBubble:(SHChatBubble *)bubble;

@optional

- (void)didTapAndHoldBubble:(SHChatBubble *)bubble;

@end

@interface SHChatBubble : UIButton
{
    UILongPressGestureRecognizer *gesture_longPress;
    UIImage *roundedImage;
    UIImageView *thumbnail;
    UIImageView *thumbnailFrame;
    UIImageView *blockFrame;
    UIImageView *statusFrame;
    UIImageView *notificationBadge;
    UIButton *messagePreview;
    UIButton *typingIndicator;
    UILabel *label;
    UILabel *badgeCountLabel;
    NSTimer *timer_messagePreview;
    NSTimer *timer_typingIndicatorAnimation;
    NSString *labelText;
    SHUserPresence presence;
    BOOL isInMiniMode;
}

@property (nonatomic, weak) id <SHChatBubbleDelegate> delegate;

// Use this dictionary to pass in any secondary data.
@property (nonatomic) NSMutableDictionary *metadata;
@property (nonatomic) SHChatBubbleType bubbleType;
@property (nonatomic) int badgeCount;
@property (nonatomic) BOOL isBlocked;
@property (nonatomic) BOOL isShowingTypingIndicator;
@property (nonatomic) BOOL shouldRoundImage;

- (id)initWithFrame:(CGRect)frame withMiniModeEnabled:(BOOL)miniEnabled;
- (id)initWithFrame:(CGRect)frame andImage:(UIImage *)theImage withMiniModeEnabled:(BOOL)miniEnabled;
- (void)setupView;
- (void)darkenImage;
- (void)restoreImage;

- (void)enableMiniMode;
- (void)setImage:(UIImage *)theImage;
- (void)setBubbleMetadata:(NSMutableDictionary *)theMetadata;
- (void)setLabelText:(NSString *)theText;
- (void)setLabelText:(NSString *)theText withFont:(UIFont *)font;
- (void)setPresence:(SHUserPresence)thePresence animated:(BOOL)animated;
- (void)setBadgeCount:(int)count;
- (void)setBlocked:(BOOL)blocked;
- (void)showPreviewForMessage:(NSString *)message fromDirection:(SHChatBubbleTypingIndicatorDirection)direction;
- (void)hideMessagePreview;
- (void)showTypingIndicatorFromDirection:(SHChatBubbleTypingIndicatorDirection)direction;
- (void)animateTypingIndicator;
- (void)hideTypingIndicator;

// Gesture handling.
- (void)userDidTapAndHold:(UILongPressGestureRecognizer *)longPress;

@end