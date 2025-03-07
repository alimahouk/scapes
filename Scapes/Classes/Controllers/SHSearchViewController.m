//
//  SHSearchViewController.m
//  Nightboard
//
//  Created by Ali.cpp on 3/20/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import "SHSearchViewController.h"

#import "AFHTTPRequestOperationManager.h"
#import "AppDelegate.h"
#import "Constants.h"
#import "SHBoardItem.h"
#import "SHBoardPostViewController.h"

@implementation SHSearchViewController

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        posts = [NSMutableArray array];
        searchInterfaceIsShown = NO;
    }
    
    return self;
}

- (void)loadView
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    UIView *contentView = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    contentView.backgroundColor = [UIColor whiteColor];
    
    searchOverlay = [[UIView alloc] initWithFrame:appDelegate.screenBounds];
    searchOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    searchOverlay.alpha = 0.0;
    searchOverlay.hidden = YES;
    
    postContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 0)];
    postContainer.backgroundColor = [UIColor whiteColor];
    postContainer.opaque = YES;
    
    searchBox = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, 44)];
    searchBox.placeholder = @"Search for a #hashtag";
    searchBox.showsCancelButton = YES;
    searchBox.delegate = self;
    
    lowerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, appDelegate.screenBounds.size.height - 44, appDelegate.screenBounds.size.width, 44)];
    
    mainScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, appDelegate.screenBounds.size.width, appDelegate.screenBounds.size.height - 44)];
    mainScrollView.backgroundColor = [UIColor whiteColor];
    mainScrollView.contentSize = CGSizeMake(mainScrollView.frame.size.width, mainScrollView.frame.size.height - 63);
    mainScrollView.opaque = YES;
    
    searchResultsCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, appDelegate.screenBounds.size.width - 20, 44)];
    searchResultsCountLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:MIN_MAIN_FONT_SIZE];
    searchResultsCountLabel.textColor = [UIColor whiteColor];
    searchResultsCountLabel.textAlignment = NSTextAlignmentCenter;
    
    if ( (IS_IOS7) )
    {
        searchResultsCountLabel.textColor = [UIColor grayColor];
    }
    
    UITapGestureRecognizer *searchOverlayTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissSearchInterface)];
    [searchOverlay addGestureRecognizer:searchOverlayTapRecognizer];
    
    [self.navigationController.navigationBar addSubview:searchBox];
    [mainScrollView addSubview:postContainer];
    [lowerToolbar addSubview:searchResultsCountLabel];
    [contentView addSubview:mainScrollView];
    [contentView addSubview:searchOverlay];
    [contentView addSubview:lowerToolbar];
    
    self.view = contentView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self showSearchInterface];
    [self enableCancelButton];
}

- (void)showSearchInterface
{
    searchBox.hidden = NO;
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        searchBox.alpha = 1.0;
    } completion:^(BOOL finished){
        
    }];
}

- (void)hideSearchInterface
{
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        searchBox.alpha = 0.0;
    } completion:^(BOOL finished){
        searchBox.hidden = YES;
    }];
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

- (void)enableSearchInterface
{
    [searchBox becomeFirstResponder];
}

- (void)dismissSearchInterface
{
    searchInterfaceIsShown = NO;
    
    [searchBox resignFirstResponder];
}

- (void)clearSearchField
{
    searchBox.text = @"";
    
    // Clear out the old data.
    [posts removeAllObjects];
    [[postContainer subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)dismissView
{
    searchResultsCountLabel.text = @"";
    
    [self dismissSearchInterface];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)searchForQuery:(NSString *)query
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( [query hasPrefix:@"#"] )
    {
        query = [query substringFromIndex:1];
    }
    
    _currentQuery = query;
    searchBox.text = query;
    [self dismissSearchInterface];
    
    // Show the HUD.
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.customView = [[UIImageView alloc] init];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.dimBackground = YES;
    HUD.delegate = self;
    [HUD show:YES];
    
    searchResultsCountLabel.text = NSLocalizedString(@"GENERIC_LOADING", nil);
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[_boardID,
                                                                                    query]
                                                                          forKeys:@[@"board_id",
                                                                                    @"hashtag"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager.operationQueue cancelAllOperations]; // If the user searches for something else while the results are still loading.
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/search", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        [HUD hide:YES];
        
        if ( responseData )
        {
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            // Clear out the old data.
            [posts removeAllObjects];
            [[postContainer subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
            
            if ( errorCode == 0 )
            {
                posts = [[responseData objectForKey:@"response"] mutableCopy];
                
                // Pretty format the result count.
                NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
                [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                NSString *viewCountFormatted = [numberFormatter stringFromNumber:[NSNumber numberWithLong:posts.count]];
                
                searchResultsCountLabel.text = [NSString stringWithFormat:@"%@ result%@.", viewCountFormatted, (posts.count != 1 ? @"s" : @"")];;
                
                for ( int i = 0; i < posts.count; i++ )
                {
                    NSMutableDictionary *post = [[posts objectAtIndex:i] mutableCopy];
                    [post setObject:@"0" forKey:@"viewed"];
                    
                    [posts setObject:post atIndexedSubscript:i];
                }
                
                [self reloadBoardData];
            }
            else
            {
                [self showNetworkError];
            }
        }
        else
        {
            [self showNetworkError];
        }
        
        //NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        [self showNetworkError];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)reloadBoardData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    int postSize = (int)(appDelegate.screenBounds.size.width / 3);
    int rows = floor(posts.count / 3);
    
    if ( posts.count % 3 != 0 )
    {
        rows += posts.count % 3;
    }
    
    for ( int i = 0; i < rows; i++ )
    {
        for ( int j = 0; j < 3; j++ )
        {
            int currentIndex = (i * 3) + j;
            
            if ( currentIndex < posts.count )
            {
                NSMutableDictionary *post = [posts objectAtIndex:currentIndex];
                
                SHBoardItem *item = [[SHBoardItem alloc] init];
                [item addTarget:self action:@selector(tappedPost:) forControlEvents:UIControlEventTouchUpInside];
                SHPostColor color = [[post objectForKey:@"color"] intValue];
                item.data = post;
                
                // Add some padding between the items.
                CGRect frame = CGRectMake(postSize * j, postSize * i, postSize - 1, postSize - 1);
                
                // Column padding.
                if ( j == 1 )
                {
                    frame = CGRectMake(postSize * j + 0.5, frame.origin.y, frame.size.width, frame.size.height);
                }
                else if ( j == 2)
                {
                    frame = CGRectMake(postSize * j + 1, frame.origin.y, frame.size.width, frame.size.height);
                }
                
                // Row padding.
                if ( i > 0 )
                {
                    frame = CGRectMake(frame.origin.x, postSize * i + 1, frame.size.width, frame.size.height);
                }
                
                item.frame = frame;
                [item setText:[post objectForKey:@"text"]]; // NOTE: set the text AFTER the frame.
                [item setColor:[appDelegate colorForCode:color]];
                
                [posts setObject:item atIndexedSubscript:currentIndex];
                [postContainer addSubview:item];
            }
        }
    }
    
    postContainer.frame = CGRectMake(postContainer.frame.origin.x, postContainer.frame.origin.y, postContainer.frame.size.width, rows * postSize);
    mainScrollView.contentSize = CGSizeMake(mainScrollView.frame.size.width, MAX(mainScrollView.frame.size.height - 63, postContainer.frame.size.height));
}

- (void)tappedPost:(id)sender
{
    SHBoardItem *tappedItem = (SHBoardItem *)sender;
    SHBoardPostViewController *postView = [[SHBoardPostViewController alloc] init];
    [postView setPost:tappedItem.data];
    
    [self hideSearchInterface];
    [self.navigationController pushViewController:postView animated:YES];
}

- (void)markPostAsViewed:(NSString *)postID
{
    for ( int i = 0; i < posts.count; i++ )
    {
        SHBoardItem *post = [posts objectAtIndex:i];
        NSString *targetPostID = [post.data objectForKey:@"post_id"];
        
        if ( targetPostID.intValue == postID.intValue )
        {
            [post.data setObject:@"1" forKey:@"viewed"];
            [posts setObject:post atIndexedSubscript:i];
            
            break;
        }
    }
}

- (void)showNetworkError
{
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
        HUD.labelText = @"Oops! :(";
        
        [HUD show:YES];
        [HUD hide:YES afterDelay:3];
    });
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
    
    [self searchForQuery:searchBar.text];
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
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
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        searchOverlay.alpha = 0.0;
    } completion:^(BOOL finished){
        searchOverlay.hidden = YES;
    }];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods

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
