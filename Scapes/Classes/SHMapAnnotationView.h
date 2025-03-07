//
//  SHMapAnnotationView.h
//  Scapes
//
//  Created by MachOSX on 7/3/13.
//  Copyright (c) 2014 Scapehouse. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "SHChatBubble.h"

@interface SHMapAnnotationView : MKPinAnnotationView
{
    SHChatBubble *userBubble;
}

- (void)setThumbnail:(UIImage *)thumbnail;

@end
