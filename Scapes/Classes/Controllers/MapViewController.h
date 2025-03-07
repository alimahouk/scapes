//
//  MapViewController.h
//  Scapes
//
//  Created by MachOSX on 7/3/14.
//
//

#import <MapKit/MapKit.h>
#import "MBProgressHUD.h"

@interface MapViewController : UIViewController <MBProgressHUDDelegate, MKMapViewDelegate, UIActionSheetDelegate>
{
    MBProgressHUD *HUD;
    UIBarButtonItem *shareButton;
    UISegmentedControl *mapTypeControl;
    MKMapView *map;
    MKPointAnnotation *mapPin;
    NSInteger activeSegmentedControlIndex;
}

@property (nonatomic) UIImage *thumbnail;
@property (nonatomic) NSString *calloutTitle;
@property (nonatomic) NSString *calloutSubtitle;
@property (nonatomic) CLLocationCoordinate2D locationToLoad;
@property (nonatomic) BOOL resetsViewWhenPopped;

- (void)mapTypeChanged:(id)sender;
- (NSString *)distanceFromLocation;
- (void)showExportOptions;

@end
