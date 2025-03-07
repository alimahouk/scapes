//
//  SHGalleryZoomingView.h
//  Scapes
//
//  Created by MachOSX on 6/17/14.
//
//



@interface SHGalleryZoomingView : UIScrollView <UIScrollViewDelegate>
{
    
}

@property (nonatomic) UIImageView *photoImageView;

- (void)displayImage;
- (CGFloat)initialZoomScaleWithMinScale;
- (void)setMaxMinZoomScalesForCurrentBounds;

@end
