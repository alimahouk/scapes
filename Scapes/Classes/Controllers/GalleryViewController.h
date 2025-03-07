//
//  GalleryViewController.h
//  Scapes
//
//  Created by MachOSX on 2/25/14.
//
//

#import "SHGalleryZoomingView.h"

@interface GalleryViewController : UIViewController <UIScrollViewDelegate, UIDocumentInteractionControllerDelegate>
{
    UIDocumentInteractionController *documentInteractionController;
    UIBarButtonItem *shareButton;
    SHGalleryZoomingView *mainScrollView;
    BOOL UIIsShown;
}

@property (nonatomic) NSString *mediaLocalPath;
@property (nonatomic) NSData *initialMediaData;
@property (nonatomic) BOOL resetsViewWhenPopped;

- (void)showUI;
- (void)hideUI;
- (void)showExportOptions;
- (void)copyImage;

// Gesture handling.
- (void)userDidTapAndHoldMedia:(UILongPressGestureRecognizer *)longPress;
- (void)userDidTapImage:(UITapGestureRecognizer *)tap;
- (void)userDidDoubleTapImage:(UITapGestureRecognizer *)doubleTap;

@end
