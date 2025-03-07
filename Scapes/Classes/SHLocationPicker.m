//
//  SHLocationPicker.m
//  Nightboard
//
//  Created by MachOSX on 2/7/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import "SHLocationPicker.h"

#import "AFHTTPRequestOperationManager.h"
#import "AppDelegate.h"
#import "Constants.h"

@implementation SHLocationPicker

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        venues = [NSMutableArray array];
        
        didDetectCurrentLocation = NO;
        searchInterfaceIsShown = NO;
        mapCenterCount = 0;
        
        _requiresSpecificVenue = NO; // Enabling this disables the "Current Location" option.
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor whiteColor];
    
    searchBox = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 44)];
    searchBox.placeholder = NSLocalizedString(@"GENERIC_SEARCH", nil);
    searchBox.showsCancelButton = YES;
    searchBox.delegate = self;
    
    map = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height / 2)];
    map.showsUserLocation = YES;
    map.showsPointsOfInterest = YES;
    map.delegate = self;
    
    UIImageView *mapSeparatorLine = [[UIImageView alloc] initWithFrame:CGRectMake(0, map.frame.size.height - 0.5, map.frame.size.width, 0.5)];
    mapSeparatorLine.image = [[UIImage imageNamed:@"separator_gray"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    mapSeparatorLine.opaque = YES;
    
    searchOverlay = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    searchOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    searchOverlay.alpha = 0.0;
    searchOverlay.hidden = YES;
    
    listView = [[UITableView alloc] initWithFrame:CGRectMake(0, map.frame.size.height - 64, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - map.frame.size.height + 64)];
    listView.separatorStyle = UITableViewCellSeparatorStyleNone;
    listView.delegate = self;
    listView.dataSource = self;
    listView.hidden = YES;
    
    listRefreshControl = [[UIRefreshControl alloc] init];
    [listRefreshControl addTarget:self action:@selector(fetchNearbyVenuesWithQuery:) forControlEvents:UIControlEventValueChanged];
    
    if ( !(IS_IOS7) )
    {
        map.frame = CGRectMake(map.frame.origin.x, map.frame.origin.y, map.frame.size.width, (appDelegate.screenBounds.size.height / 2) - 64);
        mapSeparatorLine.frame = CGRectMake(0, map.frame.size.height - 0.5, map.frame.size.width, 0.5);
        listView.frame = CGRectMake(0, map.frame.size.height, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - 200);
    }
    
    UITapGestureRecognizer *searchOverlayTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissSearchInterface)];
    [searchOverlay addGestureRecognizer:searchOverlayTapRecognizer];
    
    [self.navigationController.navigationBar addSubview:searchBox];
    
    [listView addSubview:listRefreshControl];
    [contentView addSubview:listView];
    [contentView addSubview:map];
    [map addSubview:mapSeparatorLine];
    [contentView addSubview:searchOverlay];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    [self enableCancelButton];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    [super viewWillAppear:animated];
}

- (void)enableCancelButton
{
    for ( UIView *view in searchBox.subviews )
    {
        BOOL shouldBreak = NO;
        
        for ( id subview in view.subviews )
        {
            if ( [subview isKindOfClass:[UIButton class]] )
            {
                cancelButton = subview;
                cancelButton.enabled = YES;
                
                shouldBreak = YES;
                
                break;
            }
        }
        
        if ( shouldBreak )
        {
            break;
        }
    }
}

- (void)dismissView
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self locationPickerDidCancel];
    }];
}

- (void)dismissSearchInterface
{
    searchInterfaceIsShown = NO;
    
    [searchBox resignFirstResponder];
}

- (void)fetchNearbyVenuesWithQuery:(id)query
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [appDelegate.strobeLight activateStrobeLight];
    
    [listRefreshControl beginRefreshing];
    
    NSString *urlString = @"https://api.foursquare.com/v2/venues/search?"; // 4sq requires this first param as v=yyyymmdd.
    
    // Put it together.
    urlString = [urlString stringByAppendingFormat:@"v=20140731"];
    urlString = [urlString stringByAppendingFormat:@"&client_id=ZHK22TFDORRHHDKGN4L40EQKGUBJEXM3F2FPGS14JCM1MKPE"];
    urlString = [urlString stringByAppendingFormat:@"&client_secret=PMQDW1TFREX5P2UJU2G0C42IIT01SQBR52YOHFN2TCW3S2RK"];
    urlString = [urlString stringByAppendingFormat:@"&intent=browse"];
    urlString = [urlString stringByAppendingFormat:@"&radius=800"];
    urlString = [urlString stringByAppendingFormat:@"&ll=%f,%f", appDelegate.locationManager.currentLocation.latitude, appDelegate.locationManager.currentLocation.longitude]; // The ordering is important!!!
    
    if ( [query isKindOfClass:NSString.class] )
    {
        urlString = [urlString stringByAppendingFormat:@"&query=%@", query];
    }
    
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:urlString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            listView.alpha = 1.0;
        } completion:^(BOOL finished){
            
        }];
        
        [venues removeAllObjects];
        [listView reloadData];
        
        for ( NSMutableDictionary *venue in [[responseObject objectForKey:@"response"] objectForKey:@"venues"] )
        {
            [venues addObject:venue];
        }
        
        [listRefreshControl endRefreshing];
        [listView reloadData];
        
        [appDelegate.strobeLight deactivateStrobeLight];
        
        NSLog(@"Response: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)showNetworkError
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.strobeLight negativeStrobeLight];
    [HUD hide:YES];
    
    // We need a slight delay here.
    long double delayInSeconds = 0.45;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        
        HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cross_white"]];
        
        // Set custom view mode.
        HUD.mode = MBProgressHUDModeCustomView;
        HUD.dimBackground = YES;
        HUD.delegate = self;
        HUD.labelText = NSLocalizedString(@"GENERIC_HUD_NETWORK_ERROR", nil);
        
        [HUD show:YES];
        [HUD hide:YES afterDelay:3];
    });
}

#pragma mark -
#pragma mark MKMapViewDelegate methods

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    appDelegate.locationManager.currentLocation = mapView.userLocation.coordinate;
    
    if ( !didDetectCurrentLocation )
    {
        didDetectCurrentLocation = YES;
        listView.hidden = NO;
        
        [self fetchNearbyVenuesWithQuery:nil];
    }
    
    if ( mapCenterCount < 3 )
    {
        MKCoordinateRegion mapRegion;
        mapRegion.center = mapView.userLocation.coordinate;
        mapRegion.span.latitudeDelta = 0.01;
        mapRegion.span.longitudeDelta = 0.01;
        
        [mapView setRegion:mapRegion animated:YES];
    }
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cross_white"]];
    
    // Set custom view mode.
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    
    [HUD show:YES];
    [HUD hide:YES afterDelay:3];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    mapCenterCount++;
}

#pragma mark -
#pragma mark UISearchBarDelegate methods

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self dismissView];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    searchInterfaceIsShown = YES;
    
    [self fetchNearbyVenuesWithQuery:searchBar.text];
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if ( !searchInterfaceIsShown )
    {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            map.frame = CGRectMake(map.frame.origin.x, map.frame.origin.y - 30, map.frame.size.width, map.frame.size.height);
            
            map.alpha = 0.0;
            listView.alpha = 0.0;
        } completion:^(BOOL finished){
            map.frame = CGRectMake(map.frame.origin.x, map.frame.origin.y + 30, map.frame.size.width, map.frame.size.height);
            map.hidden = YES;
        }];
    }
    
    searchOverlay.hidden = NO;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        searchOverlay.alpha = 1.0;
    } completion:^(BOOL finished){
        
    }];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    long double delayInSeconds = 0.005;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self enableCancelButton];
    });
    
    map.hidden = NO;
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        map.alpha = 1.0;
        listView.alpha = 1.0;
        searchOverlay.alpha = 0.0;
    } completion:^(BOOL finished){
        searchOverlay.hidden = YES;
    }];
}

#pragma mark -
#pragma mark UITableViewDataSource methods.

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ( _requiresSpecificVenue )
    {
        return venues.count + 1;
    }
    
    return venues.count + 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"ListCell";
    listCell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    UILabel *statusLabel;
    UIImageView *separatorLine;
    
    if ( listCell == nil )
    {
        listCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        listCell.backgroundColor = [UIColor clearColor];
        listCell.frame = CGRectZero;
        listCell.contentView.opaque = YES;
        
        if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
        {
            listCell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        
        statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, listView.frame.size.width - 20, 28)];
        statusLabel.backgroundColor = [UIColor clearColor];
        statusLabel.numberOfLines = 1;
        statusLabel.opaque = YES;
        statusLabel.tag = 7;
        
        separatorLine = [[UIImageView alloc] initWithFrame:CGRectMake(20, 67.5, listView.frame.size.width - 20, 0.5)];
        separatorLine.image = [[UIImage imageNamed:@"separator_gray"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
        separatorLine.opaque = YES;
        separatorLine.tag = 8;
        separatorLine.hidden = YES;
        
        [listCell addSubview:statusLabel];
        [listCell addSubview:separatorLine];
    }
    
    statusLabel = (UILabel *)[listCell viewWithTag:7];
    separatorLine = (UIImageView *)[listCell viewWithTag:8];
    
    NSInteger attributionRow = venues.count + 1;
    
    if ( _requiresSpecificVenue )
    {
        attributionRow -= 1;
    }
    
    if ( indexPath.row == attributionRow )
    {
        statusLabel.textColor = [UIColor grayColor];
        statusLabel.textAlignment = NSTextAlignmentCenter;
        statusLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:MAIN_FONT_SIZE];
        statusLabel.text = NSLocalizedString(@"ATTRIBUTION_FOURSQUARE", nil);
        
        separatorLine.hidden = YES;
    }
    else if ( indexPath.row == 0 && !_requiresSpecificVenue )
    {
        statusLabel.textColor = [UIColor blackColor];
        statusLabel.textAlignment = NSTextAlignmentLeft;
        statusLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
        statusLabel.text = @"📍 current location.";
        
        separatorLine.hidden = NO;
    }
    else
    {
        NSInteger row = indexPath.row;
        
        if ( !_requiresSpecificVenue )
        {
            row -= 1;
        }
        
        NSDictionary *venue = [venues objectAtIndex:row];
        
        statusLabel.textColor = [UIColor blackColor];
        statusLabel.textAlignment = NSTextAlignmentLeft;
        statusLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
        statusLabel.text = [venue objectForKey:@"name"];
        
        separatorLine.hidden = YES;
    }
    
    return listCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 68;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger attributionRow = venues.count + 1;
    
    if ( _requiresSpecificVenue )
    {
        attributionRow -= 1;
    }
    
    if ( indexPath.row == 0 && !_requiresSpecificVenue )
    {
        [self locationPickerDidPickCurrentLocation];
    }
    else if ( indexPath.row < attributionRow )
    {
        NSInteger row = indexPath.row;
        
        if ( !_requiresSpecificVenue )
        {
            row -= 1;
        }
        
        [self locationPickerDidPickVenue:[venues objectAtIndex:row]];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods.

- (void)hudWasHidden:(MBProgressHUD *)hud
{
	// Remove HUD from screen when the HUD was hidden.
	[HUD removeFromSuperview];
	HUD = nil;
}

#pragma mark -
#pragma mark SHLocationPickerDelegate methods

- (void)locationPickerDidPickVenue:(NSDictionary *)venue
{
    map.showsUserLocation = NO;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if ( [_delegate respondsToSelector:@selector(locationPickerDidPickVenue:)] )
    {
        [_delegate locationPickerDidPickVenue:venue];
    }
}

- (void)locationPickerDidPickCurrentLocation
{
    map.showsUserLocation = NO;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if ( [_delegate respondsToSelector:@selector(locationPickerDidPickCurrentLocation)] )
    {
        [_delegate locationPickerDidPickCurrentLocation];
    }
}

- (void)locationPickerDidCancel
{
    map.showsUserLocation = NO;
    
    if ( [_delegate respondsToSelector:@selector(locationPickerDidCancel)] )
    {
        [_delegate locationPickerDidCancel];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
