//
//  SHGalleryZoomingView.m
//  Scapes
//
//  Created by MachOSX on 6/17/14.
//
//

#import "SHGalleryZoomingView.h"

@implementation SHGalleryZoomingView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if ( self )
    {
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.contentSize = CGSizeMake(0, 0);
        self.maximumZoomScale = 1;
        self.minimumZoomScale = 1;
        self.zoomScale = 1;
        self.opaque = YES;
        
        _photoImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _photoImageView.backgroundColor = [UIColor blackColor];
        _photoImageView.contentMode = UIViewContentModeCenter;
        _photoImageView.userInteractionEnabled = YES;
        _photoImageView.opaque = YES;
        
        [self addSubview:_photoImageView];
    }
    
    return self;
}

- (void)displayImage
{
    if ( _photoImageView.image )
    {
        CGRect photoImageViewFrame;
        photoImageViewFrame.origin = CGPointZero;
        photoImageViewFrame.size = _photoImageView.image.size;
        _photoImageView.frame = photoImageViewFrame;
        self.contentSize = photoImageViewFrame.size;
        
        // Set zoom to minimum zoom.
        [self setMaxMinZoomScalesForCurrentBounds];
        self.zoomScale = self.minimumZoomScale;
        
        [self setNeedsLayout];
    }
}

- (CGFloat)initialZoomScaleWithMinScale
{
    CGFloat zoomScale = self.minimumZoomScale;
    
    if ( _photoImageView )
    {
        // Zoom image to fill if the aspect ratios are fairly similar.
        CGSize boundsSize = self.bounds.size;
        CGSize imageSize = _photoImageView.image.size;
        CGFloat boundsAR = boundsSize.width / boundsSize.height;
        CGFloat imageAR = imageSize.width / imageSize.height;
        CGFloat xScale = boundsSize.width / imageSize.width;    // The scale needed to perfectly fit the image width-wise.
        CGFloat yScale = boundsSize.height / imageSize.height;  // The scale needed to perfectly fit the image height-wise.
                                                                // Zooms standard portrait images on a 3.5in screen but not on a 4in screen.
        if ( fabs(boundsAR - imageAR) < 0.17 )
        {
            zoomScale = MAX(xScale, yScale);
            
            // Ensure we don't zoom in or out too far, just in case.
            zoomScale = MIN(MAX(self.minimumZoomScale, zoomScale), self.maximumZoomScale);
        }
    }
    
    return zoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    // Reset.
	self.maximumZoomScale = 1;
	self.minimumZoomScale = 1;
	self.zoomScale = 1;
    
	// Bail if no image.
	if ( _photoImageView.image == nil )
    {
        return;
    }
    
	// Reset position.
	_photoImageView.frame = CGRectMake(0, (appDelegate.screenBounds.size.height / 2) - (_photoImageView.image.size.height / 2), _photoImageView.frame.size.width, _photoImageView.frame.size.height);
    
	// Sizes.
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _photoImageView.image.size;
    
    // Calculate Min.
    CGFloat xScale = boundsSize.width / imageSize.width;    // The scale needed to perfectly fit the image width-wise.
    CGFloat yScale = boundsSize.height / imageSize.height;  // The scale needed to perfectly fit the image height-wise.
    CGFloat minScale = MIN(xScale, yScale);                 // Use minimum of these to allow the image to become fully visible.
    
    // Calculate Max.
	CGFloat maxScale = 3;
    
    // Image is smaller than screen so no zooming!
	if ( xScale >= 1 && yScale >= 1 )
    {
		minScale = 1.0;
	}
    
	// Set min/max zoom
	self.maximumZoomScale = maxScale;
	self.minimumZoomScale = minScale;
    
    // Initial zoom
    self.zoomScale = [self initialZoomScaleWithMinScale];
    
    // If we're zooming to fill then centralise.
    if ( self.zoomScale != minScale )
    {
        // Centralise.
        self.contentOffset = CGPointMake((imageSize.width * self.zoomScale - boundsSize.width) / 2.0,
                                                   (imageSize.height * self.zoomScale - boundsSize.height) / 2.0);
    }
    
    // Layout.
	[self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Center the image as it becomes smaller than the size of the screen.
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _photoImageView.frame;
    
    // Horizontally.
    if ( frameToCenter.size.width < boundsSize.width )
    {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
	}
    else
    {
        frameToCenter.origin.x = 0;
	}
    
    // Vertically.
    if ( frameToCenter.size.height < boundsSize.height )
    {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
	}
    else
    {
        frameToCenter.origin.y = 0;
	}
    
	// Center.
	if ( !CGRectEqualToRect(_photoImageView.frame, frameToCenter) )
    {
        _photoImageView.frame = frameToCenter;
    }
}

@end
