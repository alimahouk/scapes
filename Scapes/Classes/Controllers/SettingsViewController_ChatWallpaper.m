//
//  SettingsViewController_ChatWallpaper.m
//  Scapes
//
//  Created by MachOSX on 12/27/13.
//
//

#import <MobileCoreServices/UTCoreTypes.h>
#import "SettingsViewController_ChatWallpaper.h"

#define PREVIEW_SIZE    CGSizeMake(90, 168)
#define PREVIEW_PADDING 10

@implementation SettingsViewController_ChatWallpaper

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        wallpapers_full = @[[UIImage imageNamed:@"chat_wallpaper_1.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_2.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_3.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_4.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_5.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_6.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_7.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_8.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_9.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_10.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_11.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_12.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_13.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_14.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_15.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_16.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_17.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_18.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_19.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_20.jpg"],
                            [UIImage imageNamed:@"chat_wallpaper_21.jpg"]];
        
        wallpapers_previews = @[[appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_1.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_2.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_3.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_4.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_5.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_6.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_7.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_8.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_9.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_10.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_11.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_12.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_13.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_14.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_15.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_16.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_17.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_18.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_19.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_20.jpg"] scaledToSize:PREVIEW_SIZE],
                                [appDelegate imageWithImage:[UIImage imageNamed:@"chat_wallpaper_21.jpg"] scaledToSize:PREVIEW_SIZE]];
    }
    
    return self;
}

- (void)loadView
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:screenBounds];
    contentView.backgroundColor = [UIColor blackColor];
    
    doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"GENERIC_USE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(useWallpaper)];
    
    photoPicker = [[UIImagePickerController alloc] init];
    photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    photoPicker.mediaTypes = @[(NSString *)kUTTypeImage];
    photoPicker.delegate = self;
    
    UIScrollView *conversationScrollView = [[UIScrollView alloc] initWithFrame:screenBounds];
    conversationScrollView.backgroundColor = [UIColor clearColor];
    conversationScrollView.contentSize = CGSizeMake(screenBounds.size.width, screenBounds.size.height - 64 + 1);
    conversationScrollView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    conversationScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0);
    
    photoScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, screenBounds.size.height - PREVIEW_SIZE.height - 20, screenBounds.size.width, PREVIEW_SIZE.height + 20)];
    photoScrollView.backgroundColor = [UIColor colorWithRed:61/255.0 green:62/255.0 blue:66/255.0 alpha:0.9];
    photoScrollView.contentSize = CGSizeMake(PREVIEW_SIZE.width * (wallpapers_previews.count + 2) + PREVIEW_PADDING * (wallpapers_previews.count + 2), photoScrollView.frame.size.height);
    photoScrollView.contentInset = UIEdgeInsetsMake(0, 10, 0, 0);
    photoScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    photoScrollView.scrollsToTop = NO;
    
    float scaleFactor = appDelegate.screenBounds.size.width / 744;
    
    wallpaperPreview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 1392 * scaleFactor)]; // 744 is the actual width of the image.
    wallpaperPreview.backgroundColor = [UIColor whiteColor];
    wallpaperPreview.contentMode = UIViewContentModeScaleAspectFill;
    wallpaperPreview.opaque = YES;
    
    conversationPreviewLeft = [[UIImageView alloc] initWithFrame:CGRectMake(0, -64, 320, 568)];
    conversationPreviewLeft.image = [UIImage imageNamed:@"wallpaper_test_dark_left"];
    conversationPreviewLeft.opaque = YES;
    
    conversationPreviewRight = [[UIImageView alloc] initWithFrame:CGRectMake(appDelegate.screenBounds.size.width - 320, -64, 320, 568)];
    conversationPreviewRight.image = [UIImage imageNamed:@"wallpaper_test_dark_right"];
    conversationPreviewRight.opaque = YES;
    
    NSData *wallpaperData = [appDelegate.currentUser objectForKey:@"chat_wallpaper"];
    
    if ( [UIImage imageWithData:wallpaperData] )
    {
        wallpaperPreview.image = [UIImage imageWithData:wallpaperData];
        
        if ( [appDelegate isDarkImage:wallpaperPreview.image] )
        {
            conversationPreviewLeft.image = [UIImage imageNamed:@"wallpaper_test_light_left"];
            conversationPreviewRight.image = [UIImage imageNamed:@"wallpaper_test_light_right"];
        }
        else
        {
            conversationPreviewLeft.image = [UIImage imageNamed:@"wallpaper_test_dark_left"];
            conversationPreviewRight.image = [UIImage imageNamed:@"wallpaper_test_dark_right"];
        }
    }
    
    if ( !(IS_IOS7) )
    {
        photoScrollView.frame = CGRectMake(0, screenBounds.size.height - PREVIEW_SIZE.height - 88, screenBounds.size.width, PREVIEW_SIZE.height + 20);
    }
    
    for ( int i = 0; i < wallpapers_previews.count + 2; i++ )
    {
        UIButton *previewButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [previewButton addTarget:self action:@selector(didSelectPhotoTemplate:) forControlEvents:UIControlEventTouchUpInside];
        previewButton.frame = CGRectMake(PREVIEW_SIZE.width * i + PREVIEW_PADDING * i , 10, PREVIEW_SIZE.width, PREVIEW_SIZE.height);
        previewButton.opaque = YES;
        previewButton.tag = i;
        
        if ( i < wallpapers_previews.count )
        {
            UIImage *preview = [wallpapers_previews objectAtIndex:i];
            [previewButton setImage:preview forState:UIControlStateNormal];
        }
        else if ( i == wallpapers_previews.count )
        {
            previewButton.backgroundColor = [UIColor whiteColor];
        }
        else
        {
            [previewButton setImage:[UIImage imageNamed:@"chat_wallpaper_lib"] forState:UIControlStateNormal];
        }
        
        [photoScrollView addSubview:previewButton];
    }
    
    [conversationScrollView addSubview:conversationPreviewLeft];
    [conversationScrollView addSubview:conversationPreviewRight];
    [contentView addSubview:wallpaperPreview];
    [contentView addSubview:conversationScrollView];
    [contentView addSubview:photoScrollView];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    // Gestures.
    // A lil' easter egg. Swipe to the right to go back!
    viewSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(goBack)];
    [viewSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:viewSwipeRecognizer];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
    {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav_bar_legacy_white"] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:224/255.0 green:224/255.0 blue:224/255.0 alpha:1.0];
        self.navigationController.navigationBar.shadowImage = [UIImage imageNamed:@"nav_bar_shadow_line"];
    }
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    if ( viewControllers.count > 1 && [viewControllers objectAtIndex:viewControllers.count - 2] == self ) // View is disappearing because a new view controller was pushed onto the stack.
    {
        
    }
    else if ( [viewControllers indexOfObject:self] == NSNotFound ) // View is disappearing because it was popped from the stack.
    {
        if ( !(IS_IOS7) ) // Non-iOS 7 fixes.
        {
            [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
            self.navigationController.navigationBar.tintColor = nil;
        }
    }
    
    [super viewWillDisappear:animated];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)presentPhotoLibrary
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    [self presentViewController:photoPicker animated:YES completion:NULL];
}

- (void)didSelectPhotoTemplate:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSInteger index = button.tag;
    
    if ( index == wallpapers_previews.count )
    {
        [self showPreviewOfWallpaper:nil];
    }
    else if ( index == wallpapers_previews.count + 1 )
    {
        [self presentPhotoLibrary];
    }
    else
    {
        [self showPreviewOfWallpaper:[wallpapers_full objectAtIndex:index]];
    }
}

- (void)showPreviewOfWallpaper:(UIImage *)wallpaper
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    self.navigationItem.rightBarButtonItem = doneButton;
    selectedImage = wallpaper;
    
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        wallpaperPreview.alpha = 0.0;
    } completion:^(BOOL finished){
        wallpaperPreview.image = wallpaper;
        
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            wallpaperPreview.alpha = 1.0;
        } completion:^(BOOL finished){
            
        }];
    }];
    
    if ( wallpaper && [appDelegate isDarkImage:wallpaper] )
    {
        conversationPreviewLeft.image = [UIImage imageNamed:@"wallpaper_test_light_left"];
        conversationPreviewRight.image = [UIImage imageNamed:@"wallpaper_test_light_right"];
    }
    else
    {
        conversationPreviewLeft.image = [UIImage imageNamed:@"wallpaper_test_dark_left"];
        conversationPreviewRight.image = [UIImage imageNamed:@"wallpaper_test_dark_right"];
    }
}

- (void)useWallpaper
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    // Update the wallpaper in the window.
    [appDelegate.mainMenu.messagesView setCurrentWallpaper:selectedImage];
    
    if ( selectedImage )
    {
        [appDelegate.currentUser setObject:UIImageJPEGRepresentation(selectedImage, 1.0) forKey:@"chat_wallpaper"];
        
        [appDelegate.modelManager executeUpdate:@"UPDATE sh_current_user SET chat_wallpaper = :chat_wallpaper"
                        withParameterDictionary:@{@"chat_wallpaper": UIImageJPEGRepresentation(selectedImage, 1.0)}];
    }
    else
    {
        [appDelegate.currentUser setObject:@"" forKey:@"chat_wallpaper"];
        
        [appDelegate.modelManager executeUpdate:@"UPDATE sh_current_user SET chat_wallpaper = :chat_wallpaper"
                        withParameterDictionary:@{@"chat_wallpaper": @""}]; // Make it blank.
    }
    
    
    [appDelegate.strobeLight setStrobeLightPosition:SHStrobeLightPositionStatusBar];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
    [self showPreviewOfWallpaper:[info objectForKey:UIImagePickerControllerOriginalImage]];
}

#pragma mark -
#pragma mark UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return wallpapers_previews.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CellIdentifier" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    cell.opaque = YES;
    
    UIImageView *imagePreview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, PREVIEW_SIZE.width, PREVIEW_SIZE.height)];
    imagePreview.image = [wallpapers_previews objectAtIndex:indexPath.row];
    imagePreview.tag = 7;
    
    [cell addSubview:imagePreview];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(95, 170);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self showPreviewOfWallpaper:[wallpapers_full objectAtIndex:indexPath.row]];
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
