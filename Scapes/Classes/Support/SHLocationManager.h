//
//  SHLocationManager.h
//  Scapes
//
//  Created by MachOSX on 11/9/13.
//
//

#import <CoreLocation/CoreLocation.h>
@class SHLocationManager;

@protocol SHLocationManagerDelegate<NSObject>
@optional

- (void)locationManagerDidUpdateLocation;
- (void)locationManagerUpdateDidFail;

@end

@interface SHLocationManager : NSObject <CLLocationManagerDelegate>
{
    NSTimer *timer_locationUpdates;
    NSTimer *timer_locationUpdatesResume;
}

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *geoCoder;
@property (nonatomic) CLLocationCoordinate2D currentLocation;
@property (nonatomic, weak) id <SHLocationManagerDelegate> delegate;

- (void)updateLocation;
- (void)startLocationUpdates;
- (void)pauseLocationUpdates;
- (void)resumeLocationUpdates;

@end
