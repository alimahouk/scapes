//
//  SHBoardItem.m
//  Nightboard
//
//  Created by Ali.cpp on 3/17/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import "SHBoardItem.h"

#import "Constants.h"

@implementation SHBoardItem

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.borderColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0].CGColor;
        self.layer.borderWidth = 1.0;
        self.opaque = YES;
        
        mainLabel = [[TTTAttributedLabel alloc] init];
        mainLabel.numberOfLines = 0;
        mainLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10];
        mainLabel.linkAttributes = @{(id)kCTFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:10]};
        mainLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
        mainLabel.userInteractionEnabled = NO;
        
        [self addSubview:mainLabel];
    }
    
    return self;
}

- (void)setText:(NSString *)text
{
    mainLabel.text = text;
    CGSize maxSize = CGSizeMake(self.frame.size.width - 14, self.frame.size.height - 14);
    
    if ( (IS_IOS7) )
    {
        CGRect textSize = [text boundingRectWithSize:maxSize
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          attributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue" size:10]}
                                             context:nil];
        
        mainLabel.frame = CGRectMake(5, 5, self.frame.size.width - 14, textSize.size.height + 2);
    }
    else // iOS 6 and previous.
    {
        CGSize textSize = [text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:10] constrainedToSize:maxSize lineBreakMode:NSLineBreakByWordWrapping];
        
        mainLabel.frame = CGRectMake(5, 5, self.frame.size.width - 14, textSize.height + 2);
    }
    
    // Highlight the hashtags.
    NSRegularExpression *hashtagRegex = [NSRegularExpression regularExpressionWithPattern:@"(?<=\\s|^)#(\\w*[A-Za-z_]+\\w*)" options:0 error:NULL];
    NSArray *allTags = [hashtagRegex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    
    for ( NSTextCheckingResult *match in allTags )
    {
        int captureIndex;
        
        for ( captureIndex = 1; captureIndex < match.numberOfRanges; captureIndex++ )
        {
            [mainLabel setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
                NSRange boldRange = [match rangeAtIndex:0];
                
                UIFont *boldFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:10];
                CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldFont.fontName, boldFont.pointSize, NULL);
                
                if ( font )
                {
                    [mutableAttributedString addAttribute:(id)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                    [mutableAttributedString addAttribute:(id)kCTForegroundColorAttributeName value:(id)[UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0] range:boldRange];
                    CFRelease(font);
                }
                
                return mutableAttributedString;
            }];
        }
    }
}

- (void)setColor:(UIColor *)color
{
    self.backgroundColor = color;
}

@end
