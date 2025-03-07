//
//  SHMapAnnotation.h
//  Scapes
//
//  Created by MachOSX on 7/3/13.
//  Copyright (c) 2014 Scapehouse. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface SHMapAnnotation : NSObject <MKAnnotation>
{
    
}

@property (nonatomic) int cityid;
@property (nonatomic) int countryid;
@property (nonatomic) CLLocationCoordinate2D coordinate;

- (id)initWithCoordinates:(CLLocationCoordinate2D)location;

@end
