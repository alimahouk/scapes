//
//  SHMiniFeedCell.h
//  Scapes
//
//  Created by MachOSX on 8/3/13.
//
//

#import "SHChatBubble.h"

@interface SHMiniFeedCell : UITableViewCell
{
    UIImageView *bottomSeparatorLine;
    SHChatBubble *bubble_1;
    SHChatBubble *bubble_2;
    UILabel *nameLabel;
    UILabel *statusLabel;
    UILabel *messageLabel_1;
    UILabel *messageLabel_2;
    UILabel *messageLabel_3;
    UILabel *timestampLabel;
    NSDateFormatter *dateFormatter;
    int entryType;
}

- (void)populateCellWithData:(NSMutableDictionary *)data;
- (void)insertAdHocMessage:(NSDictionary *)messageData;

@end
