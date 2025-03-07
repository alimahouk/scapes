//
//  SHLocationManager.m
//  Scapes
//
//  Created by MachOSX on 11/9/13.
//
//

#import "SHLocationManager.h"

@implementation SHLocationManager

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _locationManager.delegate = self;
        
        _geoCoder = [[CLGeocoder alloc] init];
        
        // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
        if ( [_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)] )
        {
            [_locationManager requestWhenInUseAuthorization];
        }
        
        // Get the user's current location & save it.
        [self startLocationUpdates];
    }
    
    return self;
}

- (void)updateLocation
{
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ( [_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)] )
    {
        [_locationManager requestWhenInUseAuthorization];
    }
    
    [_locationManager startUpdatingLocation];
}

- (void)startLocationUpdates
{
    [_locationManager startUpdatingLocation];
    
    timer_locationUpdates = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(updateLocation) userInfo:nil repeats:YES]; // Run this every 5 minutes.
}

- (void)pauseLocationUpdates
{
    [timer_locationUpdates invalidate];
    timer_locationUpdates = nil;
}

- (void)resumeLocationUpdates
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( appDelegate.SHToken ) // Only if a user is logged in.
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        
        NSString *lastUpdate = [appDelegate.currentUser objectForKey:@"last_location_check"];
        NSDate *lastUpdateTime;
        
        if ( lastUpdate.length > 0 )
        {
            lastUpdateTime = [dateFormatter dateFromString:lastUpdate];
        }
        
        NSDate *dateToday = [NSDate date];
        
        // Perform a refresh every 5 minutes.
        if ( lastUpdate.length == 0 || [dateToday timeIntervalSinceDate:lastUpdateTime] > 300 ) // More than 5 minutes have already passed.
        {
            [self updateLocation];
            
            timer_locationUpdates = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(updateLocation) userInfo:nil repeats:YES];
        }
        else // Less than 5 mins have passed. Set the timer for when 5 mins have passed.
        {
            timer_locationUpdatesResume = [NSTimer scheduledTimerWithTimeInterval:(300 - [dateToday timeIntervalSinceDate:lastUpdateTime]) target:self selector:@selector(updateLocation) userInfo:nil repeats:NO];
        }
    }
}

#pragma mark -
#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _currentLocation = newLocation.coordinate;
    
    NSString *timeNow = [appDelegate.modelManager dateTodayString];
    
    [appDelegate.currentUser setObject:timeNow forKey:@"last_location_check"];
    
    [appDelegate.modelManager executeUpdate:@"UPDATE sh_current_user SET last_location_check = :last_location_check"
                    withParameterDictionary:@{@"last_location_check": timeNow}];
    
    [timer_locationUpdatesResume invalidate];
    timer_locationUpdatesResume = nil;
    
    [_locationManager stopUpdatingLocation];
    [self locationManagerDidUpdateLocation];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if ( status != kCLAuthorizationStatusAuthorized || ![CLLocationManager locationServicesEnabled] )
    {
        _currentLocation = CLLocationCoordinate2DMake(9999, 9999);
        
        [self locationManagerUpdateDidFail];
    }
    
    [timer_locationUpdatesResume invalidate];
    timer_locationUpdatesResume = nil;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    _currentLocation = CLLocationCoordinate2DMake(9999, 9999);
    
    [timer_locationUpdatesResume invalidate];
    timer_locationUpdatesResume = nil;
    [self locationManagerUpdateDidFail];
}

#pragma mark -
#pragma mark LocationManagerDelegate methods

- (void)locationManagerDidUpdateLocation
{
    if ( [_delegate respondsToSelector:@selector(locationManagerDidUpdateLocation)] )
    {
        [_delegate locationManagerDidUpdateLocation];
    }
}

- (void)locationManagerUpdateDidFail
{
    if ( [_delegate respondsToSelector:@selector(locationManagerDidUpdateLocation)] )
    {
        [_delegate locationManagerUpdateDidFail];
    }
}

@end
