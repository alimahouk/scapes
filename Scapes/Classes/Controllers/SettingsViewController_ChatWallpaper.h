//
//  SettingsViewController_ChatWallpaper.h
//  Scapes
//
//  Created by MachOSX on 12/27/13.
//
//



@interface SettingsViewController_ChatWallpaper : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    UISwipeGestureRecognizer *viewSwipeRecognizer;
    UIBarButtonItem *doneButton;
    UIImagePickerController *photoPicker;
    UIScrollView *photoScrollView;
    UIImageView *wallpaperPreview;
    UIImageView *conversationPreviewRight;
    UIImageView *conversationPreviewLeft;
    UICollectionView *photoCollectionView;
    NSArray *wallpapers_full;
    NSArray *wallpapers_previews;
    UIImage *selectedImage;
}

- (void)goBack;
- (void)presentPhotoLibrary;
- (void)didSelectPhotoTemplate:(id)sender;
- (void)showPreviewOfWallpaper:(UIImage *)wallpaper;
- (void)useWallpaper;

@end
