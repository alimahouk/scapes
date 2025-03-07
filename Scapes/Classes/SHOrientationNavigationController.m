//
//  SHOrientationNavigationController.m
//  Scapes
//
//  Created by MachOSX on 10/6/13.
//
//

#import "SHOrientationNavigationController.h"

@implementation SHOrientationNavigationController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        _inPrivateMode = NO;
    }
    
    return self;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
}

#pragma mark -
#pragma mark Orientation Changes

- (BOOL)shouldAutorotate
{
    return _autoRotates;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
