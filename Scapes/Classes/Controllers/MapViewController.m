//
//  MapViewController.m
//  Scapes
//
//  Created by MachOSX on 7/3/14.
//
//

#import "MapViewController.h"
#import "SHMapAnnotation.h"
#import "SHMapAnnotationView.h"

@implementation MapViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        _resetsViewWhenPopped = NO;
        
        _calloutTitle = @"";
        _calloutSubtitle = @"";
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor whiteColor];
    
    shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showExportOptions)];
    self.navigationItem.rightBarButtonItem = shareButton;
    
    mapTypeControl = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"MAP_TYPE_STANDARD", nil), NSLocalizedString(@"MAP_TYPE_HYBRID", nil), NSLocalizedString(@"MAP_TYPE_SATELLITE", nil)]];
    mapTypeControl.selectedSegmentIndex = 0;
    [mapTypeControl addTarget:self action:@selector(mapTypeChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = mapTypeControl;
    
    map = [[MKMapView alloc] initWithFrame:appDelegate.screenBounds];
    map.showsUserLocation = YES;
    map.showsPointsOfInterest = YES;
    map.delegate = self;
    map.opaque = YES;
    
    [contentView addSubview:map];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    NSString *subtitle = @"";
    MKCoordinateRegion mapRegion;
    mapRegion.center = _locationToLoad;
    mapRegion.span.latitudeDelta = 0.01;
    mapRegion.span.longitudeDelta = 0.01;
    
    [map setRegion:mapRegion animated:YES];
    
    if ( [[NSUserDefaults standardUserDefaults] stringForKey:@"SHBDActiveMapType"] )
    {
        int activeMapType = [[[NSUserDefaults standardUserDefaults] stringForKey:@"SHBDActiveMapType"] intValue];
        
        if ( activeMapType == 0 )
        {
            [map setMapType:MKMapTypeStandard];
        }
        else if ( activeMapType == 1 )
        {
            [map setMapType:MKMapTypeHybrid];
        }
        else if ( activeMapType == 2 )
        {
            [map setMapType:MKMapTypeSatellite];
        }
        
        mapTypeControl.selectedSegmentIndex = activeMapType;
        activeSegmentedControlIndex = activeMapType;
    }
    
    if ( _calloutTitle.length > 0 )
    {
        mapPin = [[MKPointAnnotation alloc] init];
        mapPin.coordinate = _locationToLoad;
        mapPin.title = _calloutTitle;
        
        if ( _calloutSubtitle.length > 0 )
        {
            subtitle = [NSString stringWithFormat:@"%@. %@.", _calloutSubtitle, [self distanceFromLocation]];
        }
        else
        {
            subtitle = [NSString stringWithFormat:@"%@.", [self distanceFromLocation]];
        }
        
        mapPin.subtitle = subtitle;
        [map addAnnotation:mapPin];
    }
    else
    {
        subtitle = [NSString stringWithFormat:@"%@.", [self distanceFromLocation]];
        
        mapPin = [[MKPointAnnotation alloc] init];
        mapPin.coordinate = _locationToLoad;
        mapPin.title = subtitle;
        
        [map addAnnotation:mapPin];
    }
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    self.navigationController.navigationBar.translucent = YES;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    if ( appDelegate.mainWindowNavigationController.inPrivateMode )
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        
        if ( !(IS_IOS7) )
        {
            self.navigationController.navigationBar.tintColor = [UIColor blackColor];
            
        }
        else
        {
            self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
        }
    }
    else
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [map selectAnnotation:mapPin animated:YES];
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if ( viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count - 2] == self ) // View is disappearing because a new view controller was pushed onto the stack.
    {
        
    }
    else if ( [viewControllers indexOfObject:self] == NSNotFound ) // View is disappearing because it was popped from the stack.
    {
        if ( _resetsViewWhenPopped )
        {
            appDelegate.mainMenu.windowCompositionLayer.scrollEnabled = YES;
            appDelegate.mainMenu.windowCompositionLayer.contentSize = CGSizeMake(appDelegate.screenBounds.size.width * 3 - 40, appDelegate.screenBounds.size.height);
            appDelegate.viewIsDraggable = YES;
        }
        else
        {
            [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
            [self.navigationController setNavigationBarHidden:YES animated:YES];
        }
    }
    
    [super viewWillDisappear:animated];
}

- (void)mapTypeChanged:(id)sender
{
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    
    if ( segmentedControl.selectedSegmentIndex == 0 &&
        segmentedControl.selectedSegmentIndex != activeSegmentedControlIndex )
    {
        [map setMapType:MKMapTypeStandard];
    }
    else if ( segmentedControl.selectedSegmentIndex == 1 &&
             segmentedControl.selectedSegmentIndex != activeSegmentedControlIndex )
    {
        [map setMapType:MKMapTypeHybrid];
    }
    else if ( segmentedControl.selectedSegmentIndex == 2 &&
             segmentedControl.selectedSegmentIndex != activeSegmentedControlIndex )
    {
        [map setMapType:MKMapTypeSatellite];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLong:segmentedControl.selectedSegmentIndex] forKey:@"SHBDActiveMapType"];
    
    activeSegmentedControlIndex = segmentedControl.selectedSegmentIndex;
}

- (NSString *)distanceFromLocation
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:_locationToLoad.latitude longitude:_locationToLoad.longitude];
    CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:appDelegate.locationManager.currentLocation.latitude longitude:appDelegate.locationManager.currentLocation.longitude];
    CLLocationDistance distance = [location distanceFromLocation:currentLocation];
    NSString *distanceUnit = NSLocalizedString(@"UNIT_DISTANCE_FEET", nil);
    
    if ( distance >= 3280.84 )
    {
        distanceUnit = NSLocalizedString(@"UNIT_DISTANCE_KM", nil);
        distance = distance / 3280.84;
    }
    
    int roundedDistance = (int)lroundf(distance);
    
    NSNumber *value = [NSNumber numberWithInt:roundedDistance];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setGroupingSeparator:@","];
    
    return [NSString stringWithFormat:@"%@ %@", [numberFormatter stringForObjectValue:value], distanceUnit];
}

- (void)showExportOptions
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIActionSheet *actionSheet;
    BOOL googleMapsInstalled = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]];
    
    if ( googleMapsInstalled )
    {
        actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"GENERIC_OPEN_IN", nil)
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                        destructiveButtonTitle:nil
                                         otherButtonTitles:NSLocalizedString(@"SERVICE_APPLE_MAPS", nil), NSLocalizedString(@"SERVICE_GOOGLE_MAPS", nil), NSLocalizedString(@"MAP_COPY_COORDS", nil), nil];
        
    }
    else
    {
        actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"GENERIC_OPEN_IN", nil)
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"GENERIC_CANCEL", nil)
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:NSLocalizedString(@"SERVICE_APPLE_MAPS", nil), NSLocalizedString(@"MAP_COPY_COORDS", nil), nil];
    }
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.tag = 0;
    
    [actionSheet showFromRect:self.view.frame inView:appDelegate.window animated:YES];
}

#pragma mark -
#pragma mark MKMapViewDelegate methods.

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    appDelegate.locationManager.currentLocation = mapView.userLocation.coordinate;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ( [annotation isKindOfClass:[MKUserLocation class]] )
    {
        return nil;
    }
    else if ( _calloutTitle.length > 0 )
    {
        return nil;
    }
    
    static NSString *AnnotationIdentifier = @"AnnotationIdentifier";
    SHMapAnnotationView *pinView = (SHMapAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
    
    if ( !pinView )
    {
        pinView = [[SHMapAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
        pinView.canShowCallout = YES;
        pinView.frame = CGRectMake(0, 0, 35, 35);
    }
    
    [pinView setThumbnail:_thumbnail];
    
    return pinView;
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( actionSheet.tag == 0 ) // Export options.
    {
        BOOL googleMapsInstalled = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]];
        
        if ( buttonIndex == 0 ) // Open in Apple Maps.
        {
            MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:_locationToLoad addressDictionary:nil];
            MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
            
            if ( _calloutTitle.length > 0 )
            {
                mapItem.name = _calloutTitle;
            }
            
            [mapItem openInMapsWithLaunchOptions:nil];
        }
        else if ( buttonIndex == 1 ) // Open in Google Maps (in case it's installed)
        {
            if ( googleMapsInstalled )
            {
                NSString *locationString = [NSString stringWithFormat:@"comgooglemaps://?q=%f,%f", _locationToLoad.latitude, _locationToLoad.longitude];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:locationString]];
            }
            else
            {
                NSString *locationString = [NSString stringWithFormat:@"Latitude: %f, Longitude: %f", _locationToLoad.latitude, _locationToLoad.longitude];
                [[UIPasteboard generalPasteboard] setString:locationString];
            }
        }
        else if ( buttonIndex == 2 ) // Copy co-ordinates.
        {
            if ( googleMapsInstalled )
            {
                NSString *locationString = [NSString stringWithFormat:@"Latitude: %f, Longitude: %f", _locationToLoad.latitude, _locationToLoad.longitude];
                [[UIPasteboard generalPasteboard] setString:locationString];
            }
        }
    }
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods.

- (void)hudWasHidden:(MBProgressHUD *)hud
{
	// Remove HUD from screen when the HUD was hidden.
	[HUD removeFromSuperview];
	HUD = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
