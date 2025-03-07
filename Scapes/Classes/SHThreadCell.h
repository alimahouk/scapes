//
//  SHThreadCell.h
//  Scapes
//
//  Created by MachOSX on 8/20/13.
//
//

#import <MapKit/MapKit.h>
#import "TTTAttributedLabel.h"
#import "SHChatBubble.h"

@interface SHThreadCell : UITableViewCell <TTTAttributedLabelDelegate, UIGestureRecognizerDelegate>
{
    UIView *bubble;
    UIView *textOverlay;
    UIImageView *bubbleBody;
    UIImageView *imagePreview;
    UIImageView *messageStatusIcon;
    UIActivityIndicatorView *activityIndicator;
    MKMapView *map;
    MKPointAnnotation *mapPin;
    SHChatBubble *attachmentUserBubble;
    TTTAttributedLabel *messageTextLabel;
    UILabel *nameLabel;
    UILabel *auxiliaryLabel;
    UILabel *auxiliarySubLabel;
    UILabel *messageStatusLabel;
    UIButton *redownloadMediaButton;
    NSDateFormatter *dateFormatter;
    NSString *messageText;
    NSString *location_longitude;
    NSString *location_latitude;
    NSString *timestampSentString;
    NSString *timestampSent;
    NSString *mediaLocalPath;
    NSData *mediaData;
    NSData *thumbnailData;
    NSDictionary *mediaExtra;
    SHMediaType mediaType;
    int threadType;
    int ownerID;
    BOOL isCurrentUser;
    BOOL messageDidDeliver;
    BOOL messageWasRead;
    BOOL containsMedia;
    BOOL mediaDownloaded;
    BOOL mediaNotFound;
    BOOL allowMediaRedownload;
}

@property (nonatomic) UIMenuController *menuController;
@property (nonatomic) BOOL isLightTheme;
@property (nonatomic) BOOL shouldDisplayFullMessageStatus;
@property (nonatomic) BOOL showsDP;
@property (nonatomic) BOOL showsMessageStatus;

- (void)populateCellWithData:(NSMutableDictionary *)data;
- (void)setThreadClass:(SHThreadClass)theThreadClass;
- (void)updateThreadStatus:(SHThreadStatus)status;
- (void)updateTimestampWithTime:(NSString *)timestampString messageStatus:(SHThreadStatus)status;
- (void)setMedia:(UIImage *)original withThumbnail:(UIImage *)image atPath:(NSString *)localPath;
- (void)showMediaNotFound;
- (void)showMediaRedownloadButton;

- (void)copyMessage;
- (void)copyImage;
- (void)copyLocation;
- (void)deleteMessage;
- (void)resendMessage;
- (void)redownloadMedia;

// Gesture handling.
- (void)userDidTapRow:(UITapGestureRecognizer *)tap;
- (void)userDidDoubleTapRow:(UITapGestureRecognizer *)doubleTap;
- (void)userDidTapAndHoldRow:(UILongPressGestureRecognizer *)longPress;
- (void)didHideEditMenu:(NSNotification *)notification;

@end
