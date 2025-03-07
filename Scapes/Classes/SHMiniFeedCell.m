//
//  SHMiniFeedCell.m
//  Scapes
//
//  Created by MachOSX on 8/3/13.
//
//

#import "SHMiniFeedCell.h"

@implementation SHMiniFeedCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if ( self )
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        
        bottomSeparatorLine = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"separator_gray"]];
        bottomSeparatorLine.opaque = YES;
        
        bubble_1 = [[SHChatBubble alloc] initWithFrame:CGRectMake(10, 21, 36, 36) withMiniModeEnabled:YES];
        bubble_1.enabled = NO;
        
        bubble_2 = [[SHChatBubble alloc] initWithFrame:CGRectMake(234, 21, 36, 36) withMiniModeEnabled:YES];
        bubble_2.enabled = NO;
        bubble_2.hidden = YES;
        
        nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 18, 180, 18)];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.textColor = [UIColor whiteColor];
        nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:MIN_MAIN_FONT_SIZE];
        nameLabel.minimumScaleFactor = 8.0 / MIN_MAIN_FONT_SIZE;
        nameLabel.numberOfLines = 1;
        nameLabel.adjustsFontSizeToFitWidth = YES;
        nameLabel.opaque = YES;
        
        statusLabel = [[UILabel alloc] init];
        statusLabel.backgroundColor = [UIColor clearColor];
        statusLabel.textColor = [UIColor whiteColor];
        statusLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
        statusLabel.numberOfLines = 0;
        statusLabel.opaque = YES;
        
        messageLabel_1 = [[UILabel alloc] initWithFrame:CGRectMake(56, nameLabel.frame.size.height + 21, 214, 18)];
        messageLabel_1.backgroundColor = [UIColor clearColor];
        messageLabel_1.textColor = [UIColor whiteColor];
        messageLabel_1.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
        messageLabel_1.numberOfLines = 1;
        messageLabel_1.opaque = YES;
        messageLabel_1.alpha = 0.0;
        messageLabel_1.hidden = YES;
        
        messageLabel_2 = [[UILabel alloc] initWithFrame:CGRectMake(56, nameLabel.frame.size.height + 40, 214, 18)];
        messageLabel_2.backgroundColor = [UIColor clearColor];
        messageLabel_2.textColor = [UIColor whiteColor];
        messageLabel_2.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
        messageLabel_2.numberOfLines = 1;
        messageLabel_2.opaque = YES;
        messageLabel_2.alpha = 0.0;
        messageLabel_2.hidden = YES;
        
        messageLabel_3 = [[UILabel alloc] initWithFrame:CGRectMake(56, nameLabel.frame.size.height + 60, 214, 18)];
        messageLabel_3.backgroundColor = [UIColor clearColor];
        messageLabel_3.textColor = [UIColor whiteColor];
        messageLabel_3.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
        messageLabel_3.numberOfLines = 1;
        messageLabel_3.opaque = YES;
        messageLabel_3.alpha = 0.0;
        messageLabel_3.hidden = YES;
        
        timestampLabel = [[UILabel alloc] init];
        timestampLabel.backgroundColor = [UIColor clearColor];
        timestampLabel.textAlignment = NSTextAlignmentRight;
        timestampLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.35];
        timestampLabel.highlightedTextColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        timestampLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:SECONDARY_FONT_SIZE];
        timestampLabel.minimumScaleFactor = 8.0 / SECONDARY_FONT_SIZE;
        timestampLabel.numberOfLines = 1;
        timestampLabel.adjustsFontSizeToFitWidth = YES;
        timestampLabel.opaque = YES;
        
        if ( (IS_IOS7) ) // iOS 7 fixes.
        {
            nameLabel.highlightedTextColor = [UIColor blackColor];
            statusLabel.highlightedTextColor = [UIColor blackColor];
            timestampLabel.highlightedTextColor = [UIColor blackColor];
        }
        
        [self.contentView addSubview:bottomSeparatorLine];
        [self.contentView addSubview:bubble_1];
        [self.contentView addSubview:bubble_2];
        [self.contentView addSubview:nameLabel];
        [self.contentView addSubview:statusLabel];
        [self.contentView addSubview:messageLabel_1];
        [self.contentView addSubview:messageLabel_2];
        [self.contentView addSubview:messageLabel_3];
        [self.contentView addSubview:timestampLabel];
    }
    
    return self;
}

- (void)populateCellWithData:(NSMutableDictionary *)data
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    entryType = [[data objectForKey:@"entry_type"] intValue];
    
    if ( entryType == 1 )
    {
        NSString *firstName = [data objectForKey:@"name_first"];
        NSString *lastName = [data objectForKey:@"name_last"];
        NSString *alias = [data objectForKey:@"alias"];
        NSString *statusText = [data objectForKey:@"message"];
        NSString *timestamp = [data objectForKey:@"timestamp_sent"];
        NSDate *timestamp_relative = [dateFormatter dateFromString:timestamp];
        NSString *timestampText = [NSString stringWithFormat:@"%@.", [appDelegate relativeTimefromDate:timestamp_relative shortened:YES condensed:YES]];
        SHUserPresence presence = [[data objectForKey:@"presence"] intValue];
        NSString *displayLabel = alias;
        
        if ( displayLabel.length == 0 )
        {
            displayLabel = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        }
        
        nameLabel.text = displayLabel;
        statusLabel.text = statusText;
        timestampLabel.text = timestampText;
        
        UIImage *currentDP = [UIImage imageWithData:[data objectForKey:@"alias_dp"]];
        
        if ( !currentDP )
        {
            currentDP = [UIImage imageWithData:[data objectForKey:@"dp"]];
            
            if ( !currentDP )
            {
                currentDP = [UIImage imageNamed:@"user_placeholder"];
            }
        }
        
        [bubble_1 setPresence:presence animated:NO];
        [bubble_1 setImage:currentDP];
        
        CGSize textSize_status = [statusText sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE] constrainedToSize:CGSizeMake(200, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
        CGSize textSize_timestamp = [timestampText sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:SECONDARY_FONT_SIZE] constrainedToSize:CGSizeMake(75, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
        
        bottomSeparatorLine.frame = CGRectMake(56, textSize_status.height + 58.5, appDelegate.screenBounds.size.width - 56, 0.5);
        statusLabel.frame = CGRectMake(56, nameLabel.frame.size.height + 22, 200, textSize_status.height + 2);
        timestampLabel.frame = CGRectMake(appDelegate.screenBounds.size.width - textSize_timestamp.width - 10, 20, textSize_timestamp.width, 13);
        
        messageLabel_1.alpha = 0.0;
        messageLabel_2.alpha = 0.0;
        messageLabel_3.alpha = 0.0;
        
        timestampLabel.hidden = NO;
        statusLabel.hidden = NO;
        
        messageLabel_1.hidden = YES;
        messageLabel_2.hidden = YES;
        messageLabel_3.hidden = YES;
        
        bubble_2.hidden = YES;
    }
    else
    {
        NSMutableArray *originalParticipantData = [data objectForKey:@"original_participant_data"];
        NSMutableArray *currentMessages = [data objectForKey:@"message_data"];
        NSMutableDictionary *participant_1 = [originalParticipantData objectAtIndex:0];
        NSMutableDictionary *participant_2 = [originalParticipantData objectAtIndex:1];
        NSString *originalUserID_1 = [participant_1 objectForKey:@"user_id"];
        SHUserPresence presence_participant_1 = [[participant_1 objectForKey:@"presence"] intValue];
        SHUserPresence presence_participant_2 = [[participant_2 objectForKey:@"presence"] intValue];
        
        UIImage *DP_1 = [UIImage imageWithData:[participant_1 objectForKey:@"alias_dp"]];
        UIImage *DP_2 = [UIImage imageWithData:[participant_2 objectForKey:@"alias_dp"]];
        
        if ( !DP_1 )
        {
            DP_1 = [UIImage imageWithData:[participant_1 objectForKey:@"dp"]];
        }
        
        if ( !DP_2 )
        {
            DP_2 = [UIImage imageWithData:[participant_2 objectForKey:@"dp"]];
        }
        
        [bubble_1 setImage:DP_1];
        [bubble_2 setImage:DP_2];
        [bubble_1 setPresence:presence_participant_1 animated:NO];
        [bubble_2 setPresence:presence_participant_2 animated:NO];
        
        bubble_2.hidden = NO;
        
        NSString *participantName_1 = [participant_1 objectForKey:@"alias"];
        NSString *participantName_2 = [participant_2 objectForKey:@"alias"];
        
        if ( participantName_1.length == 0 )
        {
            participantName_1 = [participant_1 objectForKey:@"name_first"];
        }
        
        if ( participantName_2.length == 0 )
        {
            participantName_2 = [participant_2 objectForKey:@"name_first"];
        }
        
        nameLabel.text = [NSString stringWithFormat:@"%@ + %@", participantName_1, participantName_2];
        timestampLabel.hidden = YES;
        statusLabel.hidden = YES;
        
        bottomSeparatorLine.frame = CGRectMake(56, 85, appDelegate.screenBounds.size.width - 56, 0.5);
        
        int messageOwner_1 = [[[currentMessages objectAtIndex:0] objectForKey:@"owner_id"] intValue];
        NSString *messageOwnerName_1 = @"";
        
        if ( messageOwner_1 == originalUserID_1.intValue )
        {
            messageOwnerName_1 = participantName_1;
        }
        else
        {
            messageOwnerName_1 = participantName_2;
        }
        
        NSString *ownerInitial_1 = [messageOwnerName_1 stringByRemovingEmoji];
        ownerInitial_1 = [ownerInitial_1 stringByReplacingOccurrencesOfString:@"☺" withString:@""];
        ownerInitial_1 = [ownerInitial_1 stringByReplacingOccurrencesOfString:@"☹" withString:@""];
        ownerInitial_1 = [ownerInitial_1 stringByReplacingOccurrencesOfString:@"❤" withString:@""];
        ownerInitial_1 = [ownerInitial_1 stringByReplacingOccurrencesOfString:@"❤️" withString:@""];
        ownerInitial_1 = [ownerInitial_1 stringByReplacingOccurrencesOfString:@"★" withString:@""];
        ownerInitial_1 = [ownerInitial_1 stringByReplacingOccurrencesOfString:@"☆" withString:@""];
        ownerInitial_1 = [ownerInitial_1 stringByReplacingOccurrencesOfString:@"☀" withString:@""];
        ownerInitial_1 = [ownerInitial_1 stringByReplacingOccurrencesOfString:@"☁" withString:@""];
        ownerInitial_1 = [ownerInitial_1 stringByReplacingOccurrencesOfString:@"☂" withString:@""];
        ownerInitial_1 = [ownerInitial_1 stringByReplacingOccurrencesOfString:@"☃" withString:@""];
        ownerInitial_1 = [ownerInitial_1 stringByReplacingOccurrencesOfString:@"☎" withString:@""];
        ownerInitial_1 = [ownerInitial_1 stringByReplacingOccurrencesOfString:@"☏" withString:@""];
        ownerInitial_1 = [ownerInitial_1 stringByReplacingOccurrencesOfString:@"☢" withString:@""];
        ownerInitial_1 = [ownerInitial_1 stringByReplacingOccurrencesOfString:@"☣" withString:@""];
        ownerInitial_1 = [ownerInitial_1 stringByReplacingOccurrencesOfString:@"☯" withString:@""];
        ownerInitial_1 = [ownerInitial_1 stringByTrimmingLeadingWhitespace];
        
        messageLabel_1.alpha = 1.0;
        messageLabel_1.hidden = NO;
        messageLabel_1.text = [NSString stringWithFormat:@"%@: %@", [ownerInitial_1 substringToIndex:1], [[currentMessages objectAtIndex:0] objectForKey:@"message"]];
        
        if ( currentMessages.count > 1 )
        {
            int messageOwner_2 = [[[currentMessages objectAtIndex:1] objectForKey:@"owner_id"] intValue];
            NSString *messageOwnerName_2 = @"";
            
            if ( messageOwner_2 == originalUserID_1.intValue )
            {
                messageOwnerName_2 = participantName_1;
            }
            else
            {
                messageOwnerName_2 = participantName_2;
            }
            
            NSString *ownerInitial_2 = [messageOwnerName_2 stringByRemovingEmoji];
            ownerInitial_2 = [ownerInitial_2 stringByReplacingOccurrencesOfString:@"☺" withString:@""];
            ownerInitial_2 = [ownerInitial_2 stringByReplacingOccurrencesOfString:@"☹" withString:@""];
            ownerInitial_2 = [ownerInitial_2 stringByReplacingOccurrencesOfString:@"❤" withString:@""];
            ownerInitial_2 = [ownerInitial_2 stringByReplacingOccurrencesOfString:@"❤️" withString:@""];
            ownerInitial_2 = [ownerInitial_2 stringByReplacingOccurrencesOfString:@"★" withString:@""];
            ownerInitial_2 = [ownerInitial_2 stringByReplacingOccurrencesOfString:@"☆" withString:@""];
            ownerInitial_2 = [ownerInitial_2 stringByReplacingOccurrencesOfString:@"☀" withString:@""];
            ownerInitial_2 = [ownerInitial_2 stringByReplacingOccurrencesOfString:@"☁" withString:@""];
            ownerInitial_2 = [ownerInitial_2 stringByReplacingOccurrencesOfString:@"☂" withString:@""];
            ownerInitial_2 = [ownerInitial_2 stringByReplacingOccurrencesOfString:@"☃" withString:@""];
            ownerInitial_2 = [ownerInitial_2 stringByReplacingOccurrencesOfString:@"☎" withString:@""];
            ownerInitial_2 = [ownerInitial_2 stringByReplacingOccurrencesOfString:@"☏" withString:@""];
            ownerInitial_2 = [ownerInitial_2 stringByReplacingOccurrencesOfString:@"☢" withString:@""];
            ownerInitial_2 = [ownerInitial_2 stringByReplacingOccurrencesOfString:@"☣" withString:@""];
            ownerInitial_2 = [ownerInitial_2 stringByReplacingOccurrencesOfString:@"☯" withString:@""];
            ownerInitial_2 = [ownerInitial_2 stringByTrimmingLeadingWhitespace];
            
            messageLabel_2.alpha = 1.0;
            messageLabel_2.hidden = NO;
            messageLabel_2.text = [NSString stringWithFormat:@"%@: %@", [ownerInitial_2 substringToIndex:1], [[currentMessages objectAtIndex:1] objectForKey:@"message"]];
        }
    }
}

- (void)insertAdHocMessage:(NSDictionary *)messageData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    int messageOwner = [[messageData objectForKey:@"owner_id"] intValue];
    NSString *messageOwnerName = @"";
    NSString *message = [messageData objectForKey:@"message"];
    SHMediaType mediaType = [[messageData objectForKey:@"media_type"] intValue];
    
    if ( mediaType == SHMediaTypePhoto )
    {
        NSString *icon = @"📷 ";
        message = [icon stringByAppendingString:message];
    }
    else if ( mediaType == SHMediaTypeMovie )
    {
        NSString *icon = @"📹 ";
        message = [icon stringByAppendingString:message];
    }
    
    FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :user_id"
                        withParameterDictionary:@{@"user_id": [NSNumber numberWithInt:messageOwner]}];
    
    while ( [s1 next] )
    {
        messageOwnerName = [s1 stringForColumn:@"alias"];
        
        if ( messageOwnerName.length == 0 )
        {
            messageOwnerName = [s1 stringForColumn:@"name_first"];
        }
    }
    
    [s1 close];
    [appDelegate.modelManager.results close];
    [appDelegate.modelManager.DB close];
    
    NSString *initial = [messageOwnerName stringByRemovingEmoji];
    initial = [initial stringByReplacingOccurrencesOfString:@"☺" withString:@""];
    initial = [initial stringByReplacingOccurrencesOfString:@"☹" withString:@""];
    initial = [initial stringByReplacingOccurrencesOfString:@"❤" withString:@""];
    initial = [initial stringByReplacingOccurrencesOfString:@"❤️" withString:@""];
    initial = [initial stringByReplacingOccurrencesOfString:@"★" withString:@""];
    initial = [initial stringByReplacingOccurrencesOfString:@"☆" withString:@""];
    initial = [initial stringByReplacingOccurrencesOfString:@"☀" withString:@""];
    initial = [initial stringByReplacingOccurrencesOfString:@"☁" withString:@""];
    initial = [initial stringByReplacingOccurrencesOfString:@"☂" withString:@""];
    initial = [initial stringByReplacingOccurrencesOfString:@"☃" withString:@""];
    initial = [initial stringByReplacingOccurrencesOfString:@"☎" withString:@""];
    initial = [initial stringByReplacingOccurrencesOfString:@"☏" withString:@""];
    initial = [initial stringByReplacingOccurrencesOfString:@"☢" withString:@""];
    initial = [initial stringByReplacingOccurrencesOfString:@"☣" withString:@""];
    initial = [initial stringByReplacingOccurrencesOfString:@"☯" withString:@""];
    initial = [initial stringByTrimmingLeadingWhitespace];
    
    if ( messageLabel_2.text.length == 0 )
    {
        messageLabel_2.text = [NSString stringWithFormat:@"%@: %@", [initial substringToIndex:1], message];
        messageLabel_2.hidden = NO;
        
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            messageLabel_2.alpha = 1.0;
        } completion:^(BOOL finished){
            
        }];
    }
    else
    {
        messageLabel_3.text = [NSString stringWithFormat:@"%@: %@", [initial substringToIndex:1], message];
        messageLabel_3.hidden = NO;
        
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            messageLabel_1.frame = CGRectMake(messageLabel_1.frame.origin.x, messageLabel_1.frame.origin.y - 19, messageLabel_1.frame.size.width, messageLabel_1.frame.size.height);
            messageLabel_2.frame = CGRectMake(messageLabel_2.frame.origin.x, messageLabel_2.frame.origin.y - 19, messageLabel_2.frame.size.width, messageLabel_2.frame.size.height);
            messageLabel_3.frame = CGRectMake(messageLabel_3.frame.origin.x, messageLabel_3.frame.origin.y - 19, messageLabel_3.frame.size.width, messageLabel_3.frame.size.height);
            messageLabel_3.alpha = 1.0;
            messageLabel_1.alpha = 0.0;
        } completion:^(BOOL finished){
            // Reset everything.
            messageLabel_1.alpha = 1.0;
            messageLabel_3.alpha = 0.0;
            messageLabel_3.hidden = YES;
            
            messageLabel_1.frame = CGRectMake(56, nameLabel.frame.size.height + 21, 180, 18);
            messageLabel_2.frame = CGRectMake(56, nameLabel.frame.size.height + 40, 180, 18);
            messageLabel_3.frame = CGRectMake(56, nameLabel.frame.size.height + 60, 180, 18);
            
            messageLabel_1.text = messageLabel_2.text;
            messageLabel_2.text = messageLabel_3.text;
            messageLabel_3.text = @"";
        }];
    }
}

// Override these methods to customize cell highlighting.
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if ( highlighted )
    {
        self.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    }
    else
    {
        self.contentView.backgroundColor = [UIColor clearColor];
    }
    
    [super setHighlighted:highlighted animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
