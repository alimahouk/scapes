//
//  SHBoardItem.h
//  Nightboard
//
//  Created by Ali.cpp on 3/17/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TTTAttributedLabel.h"

@interface SHBoardItem : UIButton
{
    TTTAttributedLabel *mainLabel;
}

@property (nonatomic) NSMutableDictionary *data;

- (void)setText:(NSString *)text;
- (void)setColor:(UIColor *)color;

@end
