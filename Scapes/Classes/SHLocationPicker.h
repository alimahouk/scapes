//
//  SHLocationPicker.h
//  Nightboard
//
//  Created by MachOSX on 2/7/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MapKit/MapKit.h>

#import "MBProgressHUD.h"

@class SHLocationPicker;

@protocol SHLocationPickerDelegate<NSObject>
@optional

- (void)locationPickerDidPickVenue:(NSDictionary *)venue;
- (void)locationPickerDidPickCurrentLocation;
- (void)locationPickerDidCancel;

@end

@interface SHLocationPicker : UIViewController <MBProgressHUDDelegate, MKMapViewDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
{
    MBProgressHUD *HUD;
    UIButton *cancelButton;
    UISearchBar *searchBox;
    MKMapView *map;
    UIView *searchOverlay;
    UIRefreshControl *listRefreshControl;
    UITableView *listView;
    UITableViewCell *listCell;
    NSMutableArray *venues;
    BOOL didDetectCurrentLocation;
    BOOL searchInterfaceIsShown;
    int mapCenterCount;
}

@property (nonatomic) BOOL requiresSpecificVenue;
@property (nonatomic, weak) id <SHLocationPickerDelegate> delegate;

- (void)enableCancelButton;
- (void)dismissView;
- (void)dismissSearchInterface;

- (void)fetchNearbyVenuesWithQuery:(id)query;

- (void)showNetworkError;

@end
