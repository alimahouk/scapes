//
//  SHMapAnnotation.m
//  Scapes
//
//  Created by MachOSX on 7/3/13.
//  Copyright (c) 2014 Scapehouse. All rights reserved.
//

#import "SHMapAnnotation.h"

@implementation SHMapAnnotation

- (id)initWithCoordinates:(CLLocationCoordinate2D)location
{
    self = [super init];
    
    if ( self )
    {
        self.coordinate = location;
    }
    
    return self;
}

@end
