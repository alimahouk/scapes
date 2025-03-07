//
//  SHMapAnnotationView.m
//  Scapes
//
//  Created by MachOSX on 7/3/13.
//  Copyright (c) 2014 Scapehouse. All rights reserved.
//

#import "SHMapAnnotationView.h"

@implementation SHMapAnnotationView

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    
    if ( self )
    {
        userBubble = [[SHChatBubble alloc] initWithFrame:CGRectMake(-10, -17.5, 35, 35) withMiniModeEnabled:YES];
        userBubble.enabled = NO;
        
        [self addSubview:userBubble];
    }
    
    return self;
}

- (void)setThumbnail:(UIImage *)thumbnail
{
    if ( thumbnail )
    {
        [userBubble setImage:thumbnail];
    }
    else
    {
        [userBubble setImage:[UIImage imageNamed:@"user_placeholder"]];
    }
}

@end
