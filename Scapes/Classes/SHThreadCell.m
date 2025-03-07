//
//  SHThreadCell.m
//  Scapes
//
//  Created by MachOSX on 8/20/13.
//
//

#import "SHThreadCell.h"
#import "Base64.h"

@implementation SHThreadCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if ( self )
    {
        isCurrentUser = NO;
        messageDidDeliver = NO;
        messageWasRead = NO;
        mediaDownloaded = NO;
        mediaNotFound = NO;
        allowMediaRedownload = NO;
        containsMedia = NO;
        _isLightTheme = NO;
        _shouldDisplayFullMessageStatus = YES;
        _showsDP = NO;
        _showsMessageStatus = NO;
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        
        bubble = [[UIView alloc] init];
        
        bubbleBody = [[UIImageView alloc] init];
        
        textOverlay = [[UIImageView alloc] init];
        textOverlay.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7];
        textOverlay.opaque = YES;
        
        imagePreview = [[UIImageView alloc] init];
        imagePreview.backgroundColor = [UIColor blackColor];
        imagePreview.contentMode = UIViewContentModeScaleAspectFit;
        imagePreview.layer.masksToBounds = YES;
        imagePreview.opaque = YES;
        imagePreview.hidden = YES;
        
        messageStatusIcon = [[UIImageView alloc] init];
        messageStatusIcon.hidden = YES;
        
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityIndicator.hidden = YES;
        
        map = [[MKMapView alloc] init];
        map.userInteractionEnabled = NO;
        map.hidden = YES;
        
        mapPin = [[MKPointAnnotation alloc] init];
        
        attachmentUserBubble = [[SHChatBubble alloc] initWithFrame:CGRectMake(90.5, 90.5, 35, 35) withMiniModeEnabled:YES];
        attachmentUserBubble.enabled = NO;
        attachmentUserBubble.hidden = YES;
        
        // For link tapping to work, all other labels need to have userInteractionEnabled = NO.
        messageTextLabel = [[TTTAttributedLabel alloc] init];
        messageTextLabel.backgroundColor = [UIColor clearColor];
        messageTextLabel.font = [UIFont systemFontOfSize:16];
        messageTextLabel.numberOfLines = 0;
        messageTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        messageTextLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
        messageTextLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink | NSTextCheckingTypePhoneNumber;
        messageTextLabel.userInteractionEnabled = YES;
        messageTextLabel.delegate = self;
        messageTextLabel.opaque = YES;
        
        nameLabel = [[UILabel alloc] init];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:16];
        nameLabel.minimumScaleFactor = 8.0 / 16;
        nameLabel.adjustsFontSizeToFitWidth = YES;
        nameLabel.numberOfLines = 1;
        nameLabel.userInteractionEnabled = NO;
        nameLabel.opaque = YES;
        
        auxiliaryLabel = [[UILabel alloc] init];
        auxiliaryLabel.backgroundColor = [UIColor clearColor];
        auxiliaryLabel.textColor = [UIColor blackColor];
        auxiliaryLabel.font = [UIFont systemFontOfSize:13];
        auxiliaryLabel.numberOfLines = 0;
        auxiliaryLabel.userInteractionEnabled = NO;
        auxiliaryLabel.opaque = YES;
        
        auxiliarySubLabel = [[UILabel alloc] init];
        auxiliarySubLabel.backgroundColor = [UIColor clearColor];
        auxiliarySubLabel.textColor = [UIColor colorWithRed:144.0/255.0 green:143.0/255.0 blue:149.0/255.0 alpha:1.0];
        auxiliarySubLabel.font = [UIFont systemFontOfSize:13];
        auxiliarySubLabel.numberOfLines = 1;
        auxiliarySubLabel.minimumScaleFactor = 10.0 / 13;
        auxiliarySubLabel.adjustsFontSizeToFitWidth = YES;
        auxiliarySubLabel.userInteractionEnabled = NO;
        auxiliarySubLabel.opaque = YES;
        
        messageStatusLabel = [[UILabel alloc] init];
        messageStatusLabel.backgroundColor = [UIColor clearColor];
        messageStatusLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:SECONDARY_FONT_SIZE];
        messageStatusLabel.minimumScaleFactor = 8.0 / SECONDARY_FONT_SIZE;
        messageStatusLabel.adjustsFontSizeToFitWidth = YES;
        messageStatusLabel.numberOfLines = 1;
        
        redownloadMediaButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [redownloadMediaButton setImage:[UIImage imageNamed:@"redownload_media"] forState:UIControlStateNormal];
        [redownloadMediaButton addTarget:self action:@selector(redownloadMedia) forControlEvents:UIControlEventTouchUpInside];
        redownloadMediaButton.frame = CGRectMake(0, 0, 26, 27);
        redownloadMediaButton.opaque = YES;
        redownloadMediaButton.hidden = YES;
        
        UILongPressGestureRecognizer *gesture_longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapAndHoldRow:)];
        gesture_longPress.cancelsTouchesInView = NO;
        [messageTextLabel addGestureRecognizer:gesture_longPress];
        
        UITapGestureRecognizer *gesture_singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapRow:)];
        gesture_singleTap.numberOfTapsRequired = 1;
        gesture_singleTap.cancelsTouchesInView = NO;
        [messageTextLabel addGestureRecognizer:gesture_singleTap];
        
        UITapGestureRecognizer *gesture_doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userDidDoubleTapRow:)];
        gesture_doubleTap.numberOfTapsRequired = 2;
        gesture_doubleTap.cancelsTouchesInView = NO;
        [messageTextLabel addGestureRecognizer:gesture_doubleTap];
        
        [gesture_singleTap requireGestureRecognizerToFail:messageTextLabel.gestureRecognizers[0]];
        [gesture_singleTap requireGestureRecognizerToFail:gesture_doubleTap];
        
        [textOverlay addSubview:auxiliaryLabel];
        [textOverlay addSubview:auxiliarySubLabel];
        [imagePreview addSubview:activityIndicator];
        [bubble addSubview:bubbleBody];
        [bubble addSubview:imagePreview];
        [bubble addSubview:redownloadMediaButton];
        [bubble addSubview:map];
        [bubble addSubview:attachmentUserBubble];
        [bubble addSubview:nameLabel];
        [bubble addSubview:messageTextLabel];
        [self.contentView addSubview:messageStatusIcon];
        [self.contentView addSubview:messageStatusLabel];
        [self.contentView addSubview:bubble];
    }
    
    return self;
}

- (void)populateCellWithData:(NSMutableDictionary *)data
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    int entryType = [[data objectForKey:@"entry_type"] intValue];
    
    [textOverlay removeFromSuperview];
    imagePreview.image = nil;
    imagePreview.hidden = YES;
    attachmentUserBubble.hidden = YES;
    map.hidden = YES;
    
    if ( entryType == 1 )
    {
        ownerID = [[data objectForKey:@"owner_id"] intValue];
        threadType = [[data objectForKey:@"thread_type"] intValue];
        messageText = [data objectForKey:@"message"];
        timestampSentString = [data objectForKey:@"timestamp_sent"];
        location_longitude = [data objectForKey:@"location_longitude"];
        location_latitude = [data objectForKey:@"location_latitude"];
        mediaType = [[data objectForKey:@"media_type"] intValue];
        NSString *mediaHash = [data objectForKey:@"media_hash"];
        mediaLocalPath = [data objectForKey:@"media_local_path"];
        mediaData = [data objectForKey:@"media_data"];
        mediaExtra = [data objectForKey:@"media_extra"];
        NSDate *timestampSentDate = [dateFormatter dateFromString:timestampSentString];
        int messageDidSend = [[data objectForKey:@"status_sent"] intValue];
        messageDidDeliver = [[data objectForKey:@"status_delivered"] boolValue];
        messageWasRead = [[data objectForKey:@"status_read"] boolValue];
        isCurrentUser = (ownerID == [[appDelegate.currentUser objectForKey:@"user_id"] intValue]);
        containsMedia = ( mediaHash.length > 1 && [mediaHash intValue] != -1 );
        mediaNotFound = [[data objectForKey:@"media_not_found"] boolValue];
        BOOL shouldDisplayTextLabel = YES;
        
        messageTextLabel.text = @""; // Clear out the text field first (iOS 7 bug).
        bubble.hidden = NO;
        
        if ( _isLightTheme )
        {
            messageStatusLabel.textColor = [UIColor colorWithRed:225/255.0 green:225/255.0 blue:225/255.0 alpha:1.0];
            messageStatusIcon.image = [UIImage imageNamed:@"tick_read_light"];
        }
        else
        {
            messageStatusLabel.textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
            messageStatusIcon.image = [UIImage imageNamed:@"tick_read_dark"];
        }
        
        if ( !appDelegate.preference_RelativeTime )
        {
            NSDateComponents *currentDatecomponents = [appDelegate.calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:timestampSentDate];
            NSInteger hour = [currentDatecomponents hour];
            NSInteger minute = [currentDatecomponents minute];
            
            NSString *timePostfix = @"am";
            
            if ( hour > 12 ) // Convert back to 12-hour format for display purposes.
            {
                hour -= 12;
                timePostfix = @"pm";
            }
            
            if ( hour == 12 ) // This needs its own fix for the case of 12 pm.
            {
                timePostfix = @"pm";
            }
            
            if ( hour == 0 )
            {
                hour = 12;
            }
            
            timestampSent = [NSString stringWithFormat:@"%d:%02d %@.", (int)hour, (int)minute, timePostfix];
        }
        else
        {
            timestampSent = [NSString stringWithFormat:@"%@.", [appDelegate relativeTimefromDate:timestampSentDate shortened:YES condensed:NO]];
        }
        
        NSString *displayLabel = @"";
        
        if ( _showsDP )
        {
            NSString *firstName = [data objectForKey:@"name_first"];
            NSString *lastName = [data objectForKey:@"name_last"];
            NSString *alias = [data objectForKey:@"alias"];
            
            displayLabel = alias;
            
            if ( displayLabel.length == 0 )
            {
                displayLabel = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            }
            
            nameLabel.text = displayLabel;
            nameLabel.hidden = NO;
        }
        else
        {
            nameLabel.hidden = YES;
        }
        
        if ( isCurrentUser )
        {
            if ( messageDidSend == SHThreadStatusSending )
            {
                messageStatusIcon.hidden = YES;
                
                timestampSent = @"sending...";
            }
            else
            {
                if ( _showsMessageStatus )
                {
                    if ( messageWasRead )
                    {
                        messageStatusIcon.hidden = NO;
                        
                        timestampSent = [timestampSent stringByAppendingString:@" read."];
                    }
                    else
                    {
                        messageStatusIcon.hidden = YES;
                        
                        if ( messageDidDeliver )
                        {
                            timestampSent = [timestampSent stringByAppendingString:@" delivered."];
                        }
                    }
                }
                else
                {
                    messageStatusIcon.hidden = YES;
                }
            }
        }
        else
        {
            messageStatusIcon.hidden = YES;
        }
        
        CGSize textSize_messageText = [messageText sizeWithFont:[UIFont systemFontOfSize:16] constrainedToSize:CGSizeMake(216, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
        CGSize textSize_timestamp = [timestampSent sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:SECONDARY_FONT_SIZE] constrainedToSize:CGSizeMake(216, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
        CGSize contentSize;
        
        if ( isCurrentUser )
        {
            if ( containsMedia )
            {
                imagePreview.hidden = NO;
                shouldDisplayTextLabel = NO;
                auxiliaryLabel.numberOfLines = 0;
                
                if ( mediaNotFound )
                {
                    [self showMediaNotFound];
                }
                else if ( mediaType == SHMediaTypePhoto )
                {
                    UIImage *media = [UIImage imageWithData:mediaData];
                    
                    if ( !media )
                    {
                        mediaDownloaded = NO;
                        
                        if ( allowMediaRedownload )
                        {
                            activityIndicator.hidden = YES;
                            redownloadMediaButton.hidden = NO;
                        }
                        else
                        {
                            [activityIndicator startAnimating];
                            
                            activityIndicator.hidden = NO;
                            redownloadMediaButton.hidden = YES;
                        }
                        
                        contentSize = CGSizeMake(70, 101);
                        bubbleBody.frame = CGRectMake(0.7, 1.5, 119, 119);
                        imagePreview.frame = CGRectMake(0, 0, 120, 120);
                        activityIndicator.center = CGPointMake(imagePreview.center.x - 5, imagePreview.center.y);
                        redownloadMediaButton.center = CGPointMake(imagePreview.center.x - 5, imagePreview.center.y);
                        
                        UIImage *maskImage = [UIImage imageNamed:@"message_mask_right"];
                        
                        CALayer *maskLayer = [CALayer layer];
                        maskLayer.contents = (id)maskImage.CGImage;
                        maskLayer.frame = imagePreview.layer.frame;
                        maskLayer.contentsScale = [UIScreen mainScreen].scale;
                        maskLayer.contentsCenter = CGRectMake(11 / maskImage.size.width,
                                                              13 / maskImage.size.height,
                                                              1.0 / maskImage.size.width,
                                                              1.0 / maskImage.size.height);
                        
                        imagePreview.layer.mask = maskLayer;
                    }
                    else
                    {
                        mediaDownloaded = YES;
                        activityIndicator.hidden = YES;
                        
                        [activityIndicator stopAnimating];
                        
                        thumbnailData = [data objectForKey:@"media_thumbnail"];
                        UIImage *maskImage = [UIImage imageNamed:@"message_mask_right"];
                        UIImage *thumbnail = [UIImage imageWithData:thumbnailData];
                        
                        float maxWidth = 216;
                        
                        CGImageRef imageRef = thumbnail.CGImage;
                        CGFloat width = CGImageGetWidth(imageRef);
                        CGFloat height = CGImageGetHeight(imageRef);
                        CGFloat scaleRatio = maxWidth / width;
                        
                        CGRect bounds = CGRectMake(0, 0, width, height);
                        
                        if ( width > maxWidth )
                        {
                            bounds.size.width = maxWidth;
                            bounds.size.height = height * scaleRatio;
                        }
                        
                        contentSize = CGSizeMake(bounds.size.width - 50, bounds.size.height - 19);
                        
                        imagePreview.frame = bounds;
                        imagePreview.image = thumbnail;
                        
                        CALayer *maskLayer = [CALayer layer];
                        maskLayer.contents = (id)maskImage.CGImage;
                        maskLayer.frame = imagePreview.layer.frame;
                        maskLayer.contentsScale = [UIScreen mainScreen].scale;
                        maskLayer.contentsCenter = CGRectMake(11 / maskImage.size.width,
                                                              13 / maskImage.size.height,
                                                              1.0 / maskImage.size.width,
                                                              1.0 / maskImage.size.height);
                        
                        imagePreview.layer.mask = maskLayer;
                        
                        if ( messageText.length > 0 )
                        {
                            NSString *caption = messageText;
                            
                            if ( messageText.length > 57 )
                            {
                                caption = [messageText substringToIndex:57];
                                caption = [caption stringByAppendingString:@"…"];
                            }
                            
                            textSize_messageText = [caption sizeWithFont:[UIFont systemFontOfSize:13] constrainedToSize:CGSizeMake(216, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
                            float captionHeight = MIN(textSize_messageText.height + 14, 50);
                            
                            auxiliaryLabel.text = caption;
                            auxiliaryLabel.frame = CGRectMake(10, 5, imagePreview.frame.size.width - 30, textSize_messageText.height + 2);
                            
                            textOverlay.frame = CGRectMake(0, imagePreview.frame.size.height - captionHeight, imagePreview.frame.size.width, captionHeight);
                            
                            [imagePreview addSubview:textOverlay];
                        }
                    }
                }
            }
            else if ( threadType == SHThreadTypeMessageLocation )
            {
                NSDictionary *attachment = [mediaExtra objectForKey:@"attachment"];
                
                UIImage *maskImage = [UIImage imageNamed:@"message_mask_right"];
                CGRect bounds = CGRectMake(0, 0, 216, 216);
                contentSize = CGSizeMake(bounds.size.width - 50, bounds.size.height - 19);
                
                map.hidden = NO;
                map.frame = bounds;
                MKCoordinateRegion mapRegion;
                mapRegion.span.latitudeDelta = 0.008;
                mapRegion.span.longitudeDelta = 0.008;
                CLLocationCoordinate2D location = CLLocationCoordinate2DMake([location_latitude floatValue], [location_longitude floatValue]);
                
                mapRegion.center = location;
                [map setRegion:mapRegion animated:NO];
                [map removeAnnotation:mapPin];
                
                if ( [[mediaExtra objectForKey:@"attachment_value"] isEqualToString:@"venue"] )
                {
                    auxiliaryLabel.numberOfLines = 1;
                    auxiliaryLabel.minimumScaleFactor = 10.0 / 13;
                    auxiliaryLabel.adjustsFontSizeToFitWidth = YES;
                    
                    auxiliaryLabel.text = [attachment objectForKey:@"venue_name"];
                    auxiliarySubLabel.text = [attachment objectForKey:@"venue_country"];
                    
                    auxiliaryLabel.frame = CGRectMake(10, 5, bounds.size.width - 30, 18);
                    auxiliarySubLabel.frame = CGRectMake(10, 20, bounds.size.width - 30, 18);
                    
                    textOverlay.frame = CGRectMake(0, bounds.size.height - 46, bounds.size.width, 46);
                    
                    mapPin.coordinate = location;
                    
                    [map addAnnotation:mapPin];
                    [map addSubview:textOverlay];
                }
                
                else
                {
                    NSData *base64Data_userThumbnail = [NSData dataWithBase64EncodedString:[attachment objectForKey:@"user_thumbnail"]];
                    UIImage *userThumbnail = [UIImage imageWithData:base64Data_userThumbnail];
                    
                    if ( userThumbnail )
                    {
                        [attachmentUserBubble setImage:userThumbnail];
                    }
                    else
                    {
                        [attachmentUserBubble setImage:[UIImage imageNamed:@"user_placeholder"]];
                    }
                    
                    attachmentUserBubble.hidden = NO;
                }
                
                CALayer *maskLayer = [CALayer layer];
                maskLayer.contents = (id)maskImage.CGImage;
                maskLayer.frame = map.layer.frame;
                maskLayer.contentsScale = [UIScreen mainScreen].scale;
                maskLayer.contentsCenter = CGRectMake(11 / maskImage.size.width,
                                                      13 / maskImage.size.height,
                                                      1.0 / maskImage.size.width,
                                                      1.0 / maskImage.size.height);
                
                map.layer.mask = maskLayer;
                
                shouldDisplayTextLabel = NO;
            }
            else
            {
                contentSize = textSize_messageText;
            }
            
            if ( threadType == SHThreadTypeMessage || threadType == SHThreadTypeMessageLocation )
            {
                messageTextLabel.linkAttributes = @{(id)kCTForegroundColorAttributeName: [UIColor colorWithRed:59/255.0 green:89/255.0 blue:152/255.0 alpha:1.0], (id)kCTUnderlineStyleAttributeName: [NSNumber numberWithInt:kCTUnderlineStyleSingle]};
                messageTextLabel.textColor = [UIColor colorWithRed:59/255.0 green:89/255.0 blue:152/255.0 alpha:1.0];
                messageTextLabel.frame = CGRectMake(20, 1, contentSize.width + 10, contentSize.height + 15);
                
                bubbleBody.frame = CGRectMake(0, 0, contentSize.width + 48, contentSize.height + 19);
                messageStatusLabel.frame = CGRectMake(appDelegate.screenBounds.size.width - 24 - textSize_timestamp.width, bubbleBody.frame.size.height + 14, textSize_timestamp.width, textSize_timestamp.height);
                
                [self setThreadClass:SHThreadTypeMessageCurrentUser];
                
                bubble.frame = CGRectMake(appDelegate.screenBounds.size.width - 60 - contentSize.width, 10, appDelegate.screenBounds.size.width, bubbleBody.frame.size.height + 20);
            }
            else
            {
                messageTextLabel.linkAttributes = @{(id)kCTForegroundColorAttributeName: [UIColor whiteColor], (id)kCTUnderlineStyleAttributeName: [NSNumber numberWithInt:kCTUnderlineStyleSingle]};
                messageTextLabel.textColor = [UIColor whiteColor];
                messageTextLabel.frame = CGRectMake(25, 5, contentSize.width + 10, contentSize.height + 15);
                
                bubbleBody.frame = CGRectMake(0, 0, contentSize.width + 55, contentSize.height + 25);
                bubble.frame = CGRectMake(appDelegate.screenBounds.size.width - 60 - contentSize.width, 10, appDelegate.screenBounds.size.width, bubbleBody.frame.size.height + 30);
                
                messageStatusLabel.frame = CGRectMake(appDelegate.screenBounds.size.width - 24 - textSize_timestamp.width, bubbleBody.frame.size.height + 10, textSize_timestamp.width, textSize_timestamp.height);
                messageStatusIcon.hidden = YES;
                
                [self setThreadClass:SHThreadTypeStatusCurrentUser];
            }
            
            nameLabel.hidden = YES;
            
            if ( messageWasRead || messageDidSend == 0 )
            {
                messageStatusIcon.frame = CGRectMake(messageStatusLabel.frame.origin.x - 21, messageStatusLabel.frame.origin.y, 16, 16);
            }
        }
        else
        {
            CGSize textSize_name = [displayLabel sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:16] constrainedToSize:CGSizeMake(216, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
            
            if ( containsMedia )
            {
                imagePreview.hidden = NO;
                shouldDisplayTextLabel = NO;
                auxiliaryLabel.numberOfLines = 0;
                
                if ( mediaNotFound )
                {
                    [self showMediaNotFound];
                }
                else if ( mediaType == SHMediaTypePhoto )
                {
                    UIImage *media = [UIImage imageWithData:mediaData];
                    
                    if ( !media )
                    {
                        mediaDownloaded = NO;
                        
                        if ( allowMediaRedownload )
                        {
                            activityIndicator.hidden = YES;
                            redownloadMediaButton.hidden = NO;
                        }
                        else
                        {
                            [activityIndicator startAnimating];
                            
                            activityIndicator.hidden = NO;
                            redownloadMediaButton.hidden = YES;
                        }
                        
                        contentSize = CGSizeMake(70, 101);
                        bubbleBody.frame = CGRectMake(0.7, 1.5, 119, 119);
                        imagePreview.frame = CGRectMake(0, 0, 120, 120);
                        activityIndicator.center = CGPointMake(imagePreview.center.x + 5, imagePreview.center.y);
                        redownloadMediaButton.center = CGPointMake(imagePreview.center.x + 5, imagePreview.center.y);
                        
                        UIImage *maskImage = [UIImage imageNamed:@"message_mask_left"];
                        
                        CALayer *maskLayer = [CALayer layer];
                        maskLayer.contents = (id)maskImage.CGImage;
                        maskLayer.frame = imagePreview.layer.frame;
                        maskLayer.contentsScale = [UIScreen mainScreen].scale;
                        maskLayer.contentsCenter = CGRectMake(20 / maskImage.size.width,
                                                              21 / maskImage.size.height,
                                                              1.0 / maskImage.size.width,
                                                              1.0 / maskImage.size.height);
                        
                        imagePreview.layer.mask = maskLayer;
                    }
                    else
                    {
                        mediaDownloaded = YES;
                        activityIndicator.hidden = YES;
                        
                        [activityIndicator stopAnimating];
                        
                        thumbnailData = [data objectForKey:@"media_thumbnail"];
                        UIImage *maskImage = [UIImage imageNamed:@"message_mask_left"];
                        UIImage *thumbnail = [UIImage imageWithData:thumbnailData];
                        
                        float maxWidth = 216;
                        
                        CGImageRef imageRef = thumbnail.CGImage;
                        CGFloat width = CGImageGetWidth(imageRef);
                        CGFloat height = CGImageGetHeight(imageRef);
                        CGFloat scaleRatio = maxWidth / width;
                        
                        CGRect bounds = CGRectMake(0, 0, width, height);
                        
                        if ( width > maxWidth )
                        {
                            bounds.size.width = maxWidth;
                            bounds.size.height = height * scaleRatio;
                        }
                        
                        contentSize = CGSizeMake(bounds.size.width - 50, bounds.size.height - 19);
                        
                        imagePreview.frame = bounds;
                        imagePreview.image = thumbnail;
                        
                        CALayer *maskLayer = [CALayer layer];
                        maskLayer.contents = (id)maskImage.CGImage;
                        maskLayer.frame = imagePreview.layer.frame;
                        maskLayer.contentsScale = [UIScreen mainScreen].scale;
                        maskLayer.contentsCenter = CGRectMake(20 / maskImage.size.width,
                                                              21 / maskImage.size.height,
                                                              1.0 / maskImage.size.width,
                                                              1.0 / maskImage.size.height);
                        
                        imagePreview.layer.mask = maskLayer;
                        
                        if ( messageText.length > 0 )
                        {
                            NSString *caption = messageText;
                            
                            if ( messageText.length > 57 )
                            {
                                caption = [messageText substringToIndex:57];
                                caption = [caption stringByAppendingString:@"…"];
                            }
                            
                            textSize_messageText = [caption sizeWithFont:[UIFont systemFontOfSize:13] constrainedToSize:CGSizeMake(216, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
                            float captionHeight = MIN(textSize_messageText.height + 14, 50);
                            
                            auxiliaryLabel.text = caption;
                            auxiliaryLabel.frame = CGRectMake(20, 5, imagePreview.frame.size.width - 30, textSize_messageText.height + 2);
                            
                            textOverlay.frame = CGRectMake(0, imagePreview.frame.size.height - captionHeight, imagePreview.frame.size.width, captionHeight);
                            
                            [imagePreview addSubview:textOverlay];
                        }
                    }
                }
            }
            else if ( threadType == SHThreadTypeMessageLocation )
            {
                NSDictionary *attachment = [mediaExtra objectForKey:@"attachment"];
                
                UIImage *maskImage = [UIImage imageNamed:@"message_mask_left"];
                CGRect bounds = CGRectMake(0, 0, 216, 216);
                contentSize = CGSizeMake(bounds.size.width - 50, bounds.size.height - 19);
                
                map.hidden = NO;
                map.frame = bounds;
                MKCoordinateRegion mapRegion;
                mapRegion.span.latitudeDelta = 0.008;
                mapRegion.span.longitudeDelta = 0.008;
                CLLocationCoordinate2D location = CLLocationCoordinate2DMake([location_latitude floatValue], [location_longitude floatValue]);
                
                mapRegion.center = location;
                [map setRegion:mapRegion animated:NO];
                [map removeAnnotation:mapPin];
                
                if ( [[mediaExtra objectForKey:@"attachment_value"] isEqualToString:@"venue"] )
                {
                    auxiliaryLabel.numberOfLines = 1;
                    auxiliaryLabel.minimumScaleFactor = 10.0 / 13;
                    auxiliaryLabel.adjustsFontSizeToFitWidth = YES;
                    
                    auxiliaryLabel.text = [attachment objectForKey:@"venue_name"];
                    auxiliarySubLabel.text = [attachment objectForKey:@"venue_country"];
                    
                    auxiliaryLabel.frame = CGRectMake(20, 5, bounds.size.width - 30, 18);
                    auxiliarySubLabel.frame = CGRectMake(20, 20, bounds.size.width - 30, 18);
                    
                    textOverlay.frame = CGRectMake(0, bounds.size.height - 46, bounds.size.width, 46);
                    
                    mapPin.coordinate = location;
                    
                    [map addAnnotation:mapPin];
                    [map addSubview:textOverlay];
                }
                
                else
                {
                    NSData *base64Data_userThumbnail = [NSData dataWithBase64EncodedString:[attachment objectForKey:@"user_thumbnail"]];
                    UIImage *userThumbnail = [UIImage imageWithData:base64Data_userThumbnail];
                    
                    if ( userThumbnail )
                    {
                        [attachmentUserBubble setImage:userThumbnail];
                    }
                    else
                    {
                        [attachmentUserBubble setImage:[UIImage imageNamed:@"user_placeholder"]];
                    }
                    
                    attachmentUserBubble.hidden = NO;
                }
                
                CALayer *maskLayer = [CALayer layer];
                maskLayer.contents = (id)maskImage.CGImage;
                maskLayer.frame = map.layer.frame;
                maskLayer.contentsScale = [UIScreen mainScreen].scale;
                maskLayer.contentsCenter = CGRectMake(20 / maskImage.size.width,
                                                      21 / maskImage.size.height,
                                                      1.0 / maskImage.size.width,
                                                      1.0 / maskImage.size.height);
                
                map.layer.mask = maskLayer;
                
                shouldDisplayTextLabel = NO;
            }
            else
            {
                contentSize = textSize_messageText;
            }
            
            if ( threadType == SHThreadTypeMessage || threadType == SHThreadTypeMessageLocation )
            {
                messageTextLabel.linkAttributes = @{(id)kCTForegroundColorAttributeName: [UIColor colorWithRed:0/255.0 green:115/255.0 blue:185/255.0 alpha:1.0], (id)kCTUnderlineStyleAttributeName: [NSNumber numberWithInt:kCTUnderlineStyleSingle]};
                messageTextLabel.textColor = [UIColor blackColor];
                messageTextLabel.frame = CGRectMake(26, 1, contentSize.width + 10, contentSize.height + 15);
                
                if ( _showsDP )
                {
                    nameLabel.frame = CGRectMake(26, 5, textSize_name.width, textSize_name.height);
                    messageTextLabel.frame = CGRectMake(messageTextLabel.frame.origin.x, messageTextLabel.frame.origin.y + textSize_name.height, contentSize.width + 10, contentSize.height + 15); // Shift the message text down.
                    
                    bubbleBody.frame = CGRectMake(0, 0, MAX(textSize_name.width, contentSize.width) + 48, contentSize.height + 39);
                }
                else
                {
                    bubbleBody.frame = CGRectMake(0, 0, contentSize.width + 48, contentSize.height + 19);
                }
                
                bubble.frame = CGRectMake(10, 10, appDelegate.screenBounds.size.width, bubbleBody.frame.size.height + 20);
                messageStatusLabel.frame = CGRectMake(23, bubbleBody.frame.size.height + 14, textSize_timestamp.width, textSize_timestamp.height);
                
                [self setThreadClass:SHThreadTypeMessageRemoteUser];
            }
            else
            {
                messageTextLabel.linkAttributes = @{(id)kCTForegroundColorAttributeName: [UIColor whiteColor], (id)kCTUnderlineStyleAttributeName: [NSNumber numberWithInt:kCTUnderlineStyleSingle]};
                messageTextLabel.textColor = [UIColor whiteColor];
                messageTextLabel.frame = CGRectMake(26, 5, contentSize.width + 10, contentSize.height + 15);
                
                bubbleBody.frame = CGRectMake(0, 0, contentSize.width + 50, contentSize.height + 25);
                bubble.frame = CGRectMake(5, 10, appDelegate.screenBounds.size.width, bubbleBody.frame.size.height + 30);
                
                messageStatusLabel.frame = CGRectMake(23, bubbleBody.frame.size.height + 10, textSize_timestamp.width, textSize_timestamp.height);
                
                [self setThreadClass:SHThreadTypeStatusRemoteUser];
            }
        }
        
        if ( shouldDisplayTextLabel )
        {
            messageTextLabel.text = messageText;
        }
        
        messageStatusLabel.text = timestampSent;
        messageStatusLabel.textAlignment = NSTextAlignmentLeft;
        
        /*NSRegularExpression *mentionRegex = [NSRegularExpression regularExpressionWithPattern:@"(@[a-zA-Z0-9_]+)" options:0 error:NULL];
         NSArray *allMentions = [mentionRegex matchesInString:messageText options:0 range:NSMakeRange(0, messageText.length)];
         
         for ( NSTextCheckingResult *mentionMatch in allMentions )
         {
         int captureIndex;
         
         for ( captureIndex = 1; captureIndex < mentionMatch.numberOfRanges; captureIndex++ )
         {
         [messageTextLabel addLinkToURL:[NSURL URLWithString:[messageText substringWithRange:[mentionMatch rangeAtIndex:captureIndex]]] withRange:[mentionMatch rangeAtIndex:1]]; // Embedding a custom link in a substring.
         }
         }*/
    }
    else
    {
        NSDate *date = [dateFormatter dateFromString:[data objectForKey:@"date"]];
        
        if ( _isLightTheme )
        {
            messageStatusLabel.textColor = [UIColor colorWithRed:225/255.0 green:225/255.0 blue:225/255.0 alpha:1.0];
        }
        else
        {
            messageStatusLabel.textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
        }
        
        messageStatusIcon.hidden = YES;
        bubble.hidden = YES;
        
        messageStatusLabel.frame = CGRectMake(15, 5, appDelegate.screenBounds.size.width - 30, 44);
        messageStatusLabel.textAlignment = NSTextAlignmentCenter;
        messageStatusLabel.text = [[appDelegate dayForTime:date relative:YES condensed:NO] stringByAppendingString:@"."];
    }
    
    [CATransaction commit];
}

- (void)setThreadClass:(SHThreadClass)theThreadClass
{
    switch ( theThreadClass )
    {
        case SHThreadTypeMessageRemoteUser:
        {
            bubbleBody.image = [[UIImage imageNamed:@"message_bubble_left"] stretchableImageWithLeftCapWidth:21 topCapHeight:21];
            
            break;
        }
        
        case SHThreadTypeMessageCurrentUser:
        {
            bubbleBody.image = [[UIImage imageNamed:@"message_bubble_right"] stretchableImageWithLeftCapWidth:12 topCapHeight:13];
            
            break;
        }
        
        case SHThreadTypeStatusRemoteUser:
        {
            bubbleBody.image = [[UIImage imageNamed:@"message_bubble_transparent_left"] stretchableImageWithLeftCapWidth:21 topCapHeight:20];
            
            break;
        }
        
        case SHThreadTypeStatusCurrentUser:
        {
            bubbleBody.image = [[UIImage imageNamed:@"message_bubble_transparent_right"] stretchableImageWithLeftCapWidth:21 topCapHeight:20];
            
            break;
        }
        
        default:
            break;
    }
}

- (void)updateThreadStatus:(SHThreadStatus)status
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( status == SHThreadStatusSending )
    {
        messageStatusIcon.hidden = YES;
        
        timestampSent = @"sending...";
    }
    else if ( status == SHThreadStatusSent )
    {
        if ( !appDelegate.preference_RelativeTime )
        {
            NSDate *timestampSentDate = [dateFormatter dateFromString:timestampSentString];
            NSDateComponents *currentDatecomponents = [appDelegate.calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:timestampSentDate];
            NSInteger hour = [currentDatecomponents hour];
            NSInteger minute = [currentDatecomponents minute];
            
            NSString *timePostfix = @"am";
            
            if ( hour > 12 ) // Convert back to 12-hour format for display purposes.
            {
                hour -= 12;
                timePostfix = @"pm";
            }
            
            if ( hour == 12 ) // This needs its own fix for the case of 12 pm.
            {
                timePostfix = @"pm";
            }
            
            if ( hour == 0 )
            {
                hour = 12;
            }
            
            timestampSent = [NSString stringWithFormat:@"%d:%02d %@.", (int)hour, (int)minute, timePostfix];
        }
        else
        {
            timestampSent = @"now.";
        }
    }
    else
    {
        if ( status == SHThreadStatusRead && !messageWasRead ) // Only run this block if it hasn't been run before.
        {
            messageDidDeliver = YES;
            messageWasRead = YES;
            messageStatusIcon.hidden = NO;
            
            timestampSent = [timestampSent stringByReplacingOccurrencesOfString:@" delivered." withString:@""];
            timestampSent = [timestampSent stringByAppendingString:@" read."];
        }
        else if ( status == SHThreadStatusDelivered && !messageDidDeliver )
        {
            messageDidDeliver = YES;
            
            if ( !messageWasRead ) // Sometimes acknowledgements arrive out of order, so we don't want that screwing up the displayed info.
            {
                messageStatusIcon.hidden = YES;
                
                timestampSent = [timestampSent stringByAppendingString:@" delivered."];
            }
        }
    }
    
    CGSize textSize_messageText = [messageText sizeWithFont:[UIFont systemFontOfSize:16] constrainedToSize:CGSizeMake(216, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    CGSize textSize_timestamp = [timestampSent sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:SECONDARY_FONT_SIZE] constrainedToSize:CGSizeMake(216, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    CGSize contentSize;
    
    if ( containsMedia )
    {
        if ( !mediaDownloaded )
        {
            contentSize = CGSizeMake(120, 120);
        }
        else
        {
            UIImage *thumbnail = [UIImage imageWithData:thumbnailData];
            
            float maxWidth = 216;
            
            CGImageRef imageRef = thumbnail.CGImage;
            CGFloat width = CGImageGetWidth(imageRef);
            CGFloat height = CGImageGetHeight(imageRef);
            CGFloat scaleRatio = maxWidth / width;
            
            CGRect bounds = CGRectMake(0, 0, width, height);
            
            if ( width > maxWidth )
            {
                bounds.size.width = maxWidth;
                bounds.size.height = height * scaleRatio;
            }
            
            contentSize = CGSizeMake(bounds.size.width - 50, bounds.size.height - 19);
        }
    }
    else if ( mediaExtra && [mediaExtra isKindOfClass:NSDictionary.class] && [[mediaExtra objectForKey:@"attachment_type"] isEqualToString:@"location"] )
    {
        contentSize = CGSizeMake(166, 197);
    }
    else
    {
        contentSize = textSize_messageText;
    }
    
    if ( status == SHThreadStatusSent )
    {
        if ( _isLightTheme )
        {
            messageStatusLabel.textColor = [UIColor colorWithRed:225/255.0 green:225/255.0 blue:225/255.0 alpha:1.0];
            messageStatusIcon.image = [UIImage imageNamed:@"tick_read_light"];
        }
        else
        {
            messageStatusLabel.textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
            messageStatusIcon.image = [UIImage imageNamed:@"tick_read_dark"];
        }
    }
    
    messageStatusLabel.frame = CGRectMake(appDelegate.screenBounds.size.width - 24 - textSize_timestamp.width, bubbleBody.frame.size.height + 14, textSize_timestamp.width, textSize_timestamp.height);
    bubble.frame = CGRectMake(appDelegate.screenBounds.size.width - 60 - contentSize.width, 10, appDelegate.screenBounds.size.width, bubbleBody.frame.size.height + 20);
    
    if ( status == SHThreadStatusRead || status == SHThreadStatusSendingFailed )
    {
        messageStatusIcon.frame = CGRectMake(messageStatusLabel.frame.origin.x - 21, messageStatusLabel.frame.origin.y, 16, 16);
    }
    
    messageStatusLabel.text = timestampSent;
}

/*
 *  NOTE: theThreadType here indicates whether the thread belongs to the current
 *  user or the remote user, not whether it's a message or a status update!
 */
- (void)updateTimestampWithTime:(NSString *)timestampString messageStatus:(SHThreadStatus)status
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDate *timestampSentDate = [dateFormatter dateFromString:timestampString];
    timestampSent = [NSString stringWithFormat:@"%@.", [appDelegate relativeTimefromDate:timestampSentDate shortened:YES condensed:NO]];
    
    if ( isCurrentUser )
    {
        if ( status == SHThreadStatusSending )
        {
            timestampSent = @"sending...";
        }
        else if ( status == SHThreadStatusSendingFailed )
        {
            timestampSent = NSLocalizedString(@"MESSAGES_NOTICE_UNSENT_MESSAGE", nil);
        }
        
        if ( _showsMessageStatus )
        {
            if ( status == SHThreadStatusRead )
            {
                timestampSent = [timestampSent stringByAppendingString:@" read."];
            }
            else if ( status == SHThreadStatusDelivered )
            {
                timestampSent = [timestampSent stringByAppendingString:@" delivered."];
            }
        }
    }
    
    CGSize textSize_timestamp = [timestampSent sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:SECONDARY_FONT_SIZE] constrainedToSize:CGSizeMake(216, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    
    if ( isCurrentUser )
    {
        if ( threadType == 1)
        {
            messageStatusLabel.frame = CGRectMake(appDelegate.screenBounds.size.width - 24 - textSize_timestamp.width, bubbleBody.frame.size.height + 14, textSize_timestamp.width, textSize_timestamp.height);
        }
        else
        {
            messageStatusLabel.frame = CGRectMake(appDelegate.screenBounds.size.width - 24 - textSize_timestamp.width, bubbleBody.frame.size.height + 10, textSize_timestamp.width, textSize_timestamp.height);
        }
    }
    else
    {
        if ( threadType == 1)
        {
            messageStatusLabel.frame = CGRectMake(23, bubbleBody.frame.size.height + 14, textSize_timestamp.width, textSize_timestamp.height);
        }
        else
        {
            messageStatusLabel.frame = CGRectMake(23, bubbleBody.frame.size.height + 10, textSize_timestamp.width, textSize_timestamp.height);
        }
        
    }
    
    messageStatusIcon.frame = CGRectMake(messageStatusLabel.frame.origin.x - 21, messageStatusLabel.frame.origin.y, 16, 16);
    messageStatusLabel.text = timestampSent;
}

- (void)setMedia:(UIImage *)original withThumbnail:(UIImage *)image atPath:(NSString *)localPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    [appDelegate.mainMenu.messagesView.conversationTable beginUpdates];
    
    mediaData = UIImageJPEGRepresentation(original, 1.0);
    thumbnailData = UIImageJPEGRepresentation(image, 1.0);
    mediaLocalPath = localPath;
    mediaDownloaded = YES;
    containsMedia = YES;
    activityIndicator.hidden = YES;
    
    [activityIndicator stopAnimating];
    
    float maxWidth = 216;
    
    CGImageRef imageRef = image.CGImage;
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    CGFloat scaleRatio = maxWidth / width;
    
    CGRect bounds = CGRectMake(0, 0, width, height);
    
    if ( width > maxWidth )
    {
        bounds.size.width = maxWidth;
        bounds.size.height = height * scaleRatio;
    }
    
    CGSize contentSize = CGSizeMake(bounds.size.width - 50, bounds.size.height - 19);
    
    if ( isCurrentUser )
    {
        UIImage *maskImage = [UIImage imageNamed:@"message_mask_right"];
        
        bubbleBody.frame = CGRectMake(0, 0, contentSize.width + 50, contentSize.height + 19);
        imagePreview.frame = bounds;
        imagePreview.image = image;
        
        CALayer *maskLayer = [CALayer layer];
        maskLayer.contents = (id)maskImage.CGImage;
        maskLayer.frame = imagePreview.layer.frame;
        maskLayer.contentsScale = [UIScreen mainScreen].scale;
        maskLayer.contentsCenter = CGRectMake(11 / maskImage.size.width,
                                              14 / maskImage.size.height,
                                              1.0 / maskImage.size.width,
                                              1.0 / maskImage.size.height);
        
        imagePreview.layer.mask = maskLayer;
        
        if ( messageText.length > 0 )
        {
            NSString *caption = messageText;
            
            if ( messageText.length > 57 )
            {
                caption = [messageText substringToIndex:57];
                caption = [caption stringByAppendingString:@"…"];
            }
            
            CGSize textSize_messageText = [caption sizeWithFont:[UIFont systemFontOfSize:13] constrainedToSize:CGSizeMake(216, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
            float captionHeight = MIN(textSize_messageText.height + 14, 50);
            
            auxiliaryLabel.text = caption;
            auxiliaryLabel.frame = CGRectMake(10, 5, imagePreview.frame.size.width - 20, textSize_messageText.height + 2);
            
            textOverlay.frame = CGRectMake(0, imagePreview.frame.size.height - captionHeight, imagePreview.frame.size.width, captionHeight);
            
            [imagePreview addSubview:textOverlay];
        }
        
        messageTextLabel.frame = CGRectMake(20, 1, contentSize.width + 10, contentSize.height + 15);
    }
    else
    {
        UIImage *maskImage = [UIImage imageNamed:@"message_mask_left"];
        
        bubbleBody.frame = CGRectMake(0, 0, contentSize.width + 50, contentSize.height + 19);
        imagePreview.frame = bounds;
        imagePreview.image = image;
        
        CALayer *maskLayer = [CALayer layer];
        maskLayer.contents = (id)maskImage.CGImage;
        maskLayer.frame = imagePreview.layer.frame;
        maskLayer.contentsScale = [UIScreen mainScreen].scale;
        maskLayer.contentsCenter = CGRectMake(20 / maskImage.size.width,
                                              21 / maskImage.size.height,
                                              1.0 / maskImage.size.width,
                                              1.0 / maskImage.size.height);
        
        imagePreview.layer.mask = maskLayer;
        
        if ( messageText.length > 0 )
        {
            NSString *caption = messageText;
            
            if ( messageText.length > 57 )
            {
                caption = [messageText substringToIndex:57];
                caption = [caption stringByAppendingString:@"…"];
            }
            
            CGSize textSize_messageText = [caption sizeWithFont:[UIFont systemFontOfSize:13] constrainedToSize:CGSizeMake(216, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
            float captionHeight = MIN(textSize_messageText.height + 14, 50);
            
            auxiliaryLabel.text = caption;
            auxiliaryLabel.frame = CGRectMake(20, 5, imagePreview.frame.size.width - 30, textSize_messageText.height + 2);
            
            textOverlay.frame = CGRectMake(0, imagePreview.frame.size.height - captionHeight, imagePreview.frame.size.width, captionHeight);
            
            [imagePreview addSubview:textOverlay];
        }
        
        messageTextLabel.frame = CGRectMake(26, 1, contentSize.width + 10, contentSize.height + 15);
    }
    
    CGSize textSize_timestamp = [timestampSent sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:SECONDARY_FONT_SIZE] constrainedToSize:CGSizeMake(216, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    
    bubble.frame = CGRectMake(10, 10, appDelegate.screenBounds.size.width, bubbleBody.frame.size.height + 20);
    messageStatusLabel.frame = CGRectMake(23, bubbleBody.frame.size.height + 12, textSize_timestamp.width, textSize_timestamp.height);
    
    [appDelegate.mainMenu.messagesView.conversationTable endUpdates];
}

- (void)showMediaNotFound
{
    [activityIndicator stopAnimating];
    
    allowMediaRedownload = NO;
    mediaNotFound = YES;
    activityIndicator.hidden = YES;
    redownloadMediaButton.hidden = YES;
    
    NSString *notFoundMessage = NSLocalizedString(@"MESSAGES_MEDIA_NOT_FOUND", nil);
    
    CGSize textSize_messageText = [notFoundMessage sizeWithFont:[UIFont systemFontOfSize:13] constrainedToSize:CGSizeMake(216, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    float captionHeight = MIN(textSize_messageText.height + 14, 50);
    
    auxiliaryLabel.text = notFoundMessage;
    auxiliaryLabel.frame = CGRectMake(20, 5, imagePreview.frame.size.width - 30, textSize_messageText.height + 2);
    
    textOverlay.frame = CGRectMake(0, imagePreview.frame.size.height - captionHeight, imagePreview.frame.size.width, captionHeight);
    
    [imagePreview addSubview:textOverlay];
}

- (void)showMediaRedownloadButton
{
    [activityIndicator stopAnimating];
    
    allowMediaRedownload = YES;
    activityIndicator.hidden = YES;
    redownloadMediaButton.hidden = NO;
}

- (void)copyMessage
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = messageText;
}

- (void)copyImage
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.image = [UIImage imageWithData:mediaData];
}

- (void)copyLocation
{
    NSString *locationString = [NSString stringWithFormat:@"Latitude: %@, Longitude: %@", location_latitude, location_longitude];
    [[UIPasteboard generalPasteboard] setString:locationString];
}

- (void)deleteMessage
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.mainMenu.messagesView deleteThreadAtIndexPath:[appDelegate.mainMenu.messagesView.conversationTable indexPathForCell:self] deletionConfirmed:NO];
}

- (void)resendMessage
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.mainMenu.messagesView resendMessageAtIndexPath:[appDelegate.mainMenu.messagesView.conversationTable indexPathForCell:self]];
}

- (void)redownloadMedia;
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [activityIndicator startAnimating];
    
    allowMediaRedownload = NO;
    activityIndicator.hidden = NO;
    redownloadMediaButton.hidden = YES;
    
    [appDelegate.mainMenu.messagesView redownloadMediaFromSender:appDelegate.mainMenu.messagesView.recipientID atIndexPath:[appDelegate.mainMenu.messagesView.conversationTable indexPathForCell:self]];
}

#pragma mark -
#pragma mark Gestures

- (void)userDidTapRow:(UITapGestureRecognizer *)tap
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.mainMenu.messagesView resetView];
    
    if ( containsMedia && mediaDownloaded )
    {
        [appDelegate.mainMenu.messagesView showGalleryForMedia:[UIImage imageWithData:mediaData] atPath:mediaLocalPath];
    }
    else
    {
        if ( mediaExtra && [mediaExtra isKindOfClass:NSDictionary.class] )
        {
            NSMutableDictionary *attachment = [[mediaExtra objectForKey:@"attachment"] mutableCopy];
            
            if ( threadType == SHThreadTypeMessageLocation )
            {
                [attachment setObject:[mediaExtra objectForKey:@"attachment_value"] forKey:@"attachment_value"];
                [attachment setObject:location_latitude forKey:@"location_latitude"];
                [attachment setObject:location_longitude forKey:@"location_longitude"];
                
                [appDelegate.mainMenu.messagesView showMapForLocation:attachment];
            }
        }
    }
}

- (void)userDidDoubleTapRow:(UITapGestureRecognizer *)doubleTap
{
    NSLog(@"double tapped!");
}

- (void)userDidTapAndHoldRow:(UILongPressGestureRecognizer *)longPress
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( longPress.state == UIGestureRecognizerStateBegan )
    {
        _menuController = [UIMenuController sharedMenuController];
        UIMenuItem *menuItem_copy = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"GENERIC_COPY", nil) action:@selector(copyMessage)];
        UIMenuItem *menuItem_copy_image = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"GENERIC_COPY", nil) action:@selector(copyImage)];
        UIMenuItem *menuItem_copy_location = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"GENERIC_COPY", nil) action:@selector(copyLocation)];
        UIMenuItem *menuItem_delete = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"GENERIC_DELETE", nil) action:@selector(deleteMessage)];
        
        // We don't want the UIMenuController dismissing the keyboard.
        if ( [appDelegate.mainMenu.messagesView.messageBox isFirstResponder] )
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didHideEditMenu:) name:UIMenuControllerDidHideMenuNotification object:nil];
            appDelegate.mainMenu.messagesView.messageBox.overrideNextResponder = self;
        }
        else
        {
            [self becomeFirstResponder]; // Become first responder BEFORE showing the menu!
        }
        
        if ( threadType == SHThreadTypeMessage )
        {
            if ( mediaType == SHMediaTypePhoto )
            {
                [_menuController setMenuItems:@[menuItem_copy_image, menuItem_delete]];
            }
            else
            {
                [_menuController setMenuItems:@[menuItem_copy, menuItem_delete]];
            }
        }
        else if ( threadType == SHThreadTypeMessageLocation )
        {
            [_menuController setMenuItems:@[menuItem_copy_location, menuItem_delete]];
        }
        else
        {
            [_menuController setMenuItems:@[menuItem_copy]];
        }
        
        [_menuController setTargetRect:bubbleBody.frame inView:bubbleBody];
        [_menuController setMenuVisible:YES animated:YES];
    }
}

- (void)didHideEditMenu:(NSNotification *)notification
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    appDelegate.mainMenu.messagesView.messageBox.overrideNextResponder = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidHideMenuNotification object:nil];
}

- (BOOL)canPerformAction:(SEL)selector withSender:(id)sender
{
    if ( selector == @selector(copyMessage) ||
        selector == @selector(copyImage) ||
        selector == @selector(deleteMessage) ||
        selector == @selector(copyLocation) )
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark -
#pragma mark TTTAttributedLabelDelegate methods

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSString *URL = url.absoluteString;
    
    // If the URL is an @mention, we push a profile view controller, otherwise we push a normal browser view.
    NSRegularExpression *mentionRegex = [NSRegularExpression regularExpressionWithPattern:@"(@[a-zA-Z0-9_]+)" options:0 error:NULL];
    NSArray *mentionCheckingResults = [mentionRegex matchesInString:URL options:0 range:NSMakeRange(0, URL.length)];
    
    for ( NSTextCheckingResult *NTCR in mentionCheckingResults )
    {
        NSString *match = [URL substringWithRange:[NTCR rangeAtIndex:1]];
        NSString *processedUsername = [match substringWithRange:NSMakeRange(1, match.length - 1)];
        
        NSLog(@"tapped on %@", processedUsername);
        
        return;
    }
    
    SHUserPresenceAudience audience = SHUserPresenceAudienceEveryone;
    
    if ( appDelegate.mainMenu.messagesView.inPrivateMode || !appDelegate.preference_Talking )
    {
        audience = SHUserPresenceAudienceRecipient;
    }
    
    BOOL shouldReportEndOfActivity = NO;
    
    if ( ownerID != [[appDelegate.currentUser objectForKey:@"user_id"] intValue] ) // Don't broadcast when checking your own link.
    {
        [appDelegate.presenceManager setPresence:SHUserPresenceCheckingLink withTargetID:appDelegate.mainMenu.messagesView.recipientID forAudience:audience];
        shouldReportEndOfActivity = YES;
    }
    
    [appDelegate.mainMenu.messagesView showWebBrowserForURL:URL reportEndOfActivity:shouldReportEndOfActivity];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.mainMenu.messagesView showOptionsForTappedPhoneNumber:phoneNumber];
    NSLog(@"tapped phone number: %@", phoneNumber);
}

@end
