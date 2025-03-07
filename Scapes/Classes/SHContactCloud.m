//
//  SHContactCloud.m
//  Nightboard
//
//  Created by MachOSX on 8/4/13.
//
//

#import "SHContactCloud.h"

#import "AppDelegate.h"
#import "Sound.h"

@implementation SHContactCloud

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if ( self )
    {
        self.backgroundColor = [UIColor clearColor];
        self.contentSize = CGSizeMake(1 + frame.size.width, 1 + frame.size.height);
        self.scrollsToTop = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.minimumZoomScale = MIN(frame.size.width, frame.size.height) / MAX(frame.size.width, frame.size.height);
        
        _cloudContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        
        _cloudSearchResultsContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _cloudSearchResultsContainer.alpha = 0.0;
        
        _headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, -15, frame.size.width - 40, 20)];
        _headerLabel.backgroundColor = [UIColor clearColor];
        _headerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:MAIN_FONT_SIZE];
        _headerLabel.textColor = [UIColor whiteColor];
        _headerLabel.textAlignment = NSTextAlignmentCenter;
        _headerLabel.minimumScaleFactor = 8.0 / MAIN_FONT_SIZE;
        _headerLabel.adjustsFontSizeToFitWidth = YES;
        _headerLabel.numberOfLines = 1;
        _headerLabel.clipsToBounds = NO;
        _headerLabel.layer.masksToBounds = NO;
        _headerLabel.layer.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
        _headerLabel.layer.shadowRadius = 4.0f;
        _headerLabel.layer.shadowOpacity = 0.9;
        _headerLabel.layer.shadowOffset = CGSizeZero;
        _headerLabel.opaque = YES;
        
        _footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.contentSize.height + 15, frame.size.width - 40, 55)];
        _footerLabel.backgroundColor = [UIColor clearColor];
        _footerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:MAIN_FONT_SIZE];
        _footerLabel.textColor = [UIColor whiteColor];
        _footerLabel.textAlignment = NSTextAlignmentCenter;
        _footerLabel.numberOfLines = 1;
        _footerLabel.minimumScaleFactor = 8.0 / MAIN_FONT_SIZE;
        _footerLabel.adjustsFontSizeToFitWidth = YES;
        _footerLabel.clipsToBounds = NO;
        _footerLabel.layer.masksToBounds = NO;
        _footerLabel.layer.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
        _footerLabel.layer.shadowRadius = 4.0;
        _footerLabel.layer.shadowOpacity = 0.9;
        _footerLabel.layer.shadowOffset = CGSizeZero;
        _footerLabel.opaque = YES;
        
        grid_primary = [[NSMutableArray alloc] init];
        grid_secondary = [[NSMutableArray alloc] init];
        _cloudBubbles = [[NSMutableArray alloc] init];
        _searchResultsBubbles = [[NSMutableArray alloc] init];
        _removedBubbles = [[NSMutableArray alloc] init];
        
        x_max = self.contentSize.width * 2;
        y_max = self.contentSize.height * 2;
        
        _insertBadgeCounts = YES;
        _isInSearchMode = NO;
        _makeRoomForBubbles = NO;
        
        /*
         NOTE REGARDING "CHAT_CLOUD_BUBBLE_PADDING * 2":
         The reason for the *2 is to account for the padding on BOTH sides,
         not just one.
         */
        
        _cellSize = CHAT_CLOUD_BUBBLE_SIZE + CHAT_CLOUD_BUBBLE_PADDING * 2;
        
        [self addSubview:_headerLabel];
        [self addSubview:_footerLabel];
        [self addSubview:_cloudSearchResultsContainer];
        [self addSubview:_cloudContainer];
    }
    
    return self;
}

- (void)setContentSize:(CGSize)contentSize
{
    if ( _isInSearchMode )
    {
        _cloudSearchResultsContainer.frame = CGRectMake(0, 0, contentSize.width, contentSize.height);
    }
    else
    {
        // Resize these together. Keep them in sync.
        _cloudContainer.frame = CGRectMake(0, 0, contentSize.width, contentSize.height);
        _cloudSearchResultsContainer.frame = CGRectMake(0, 0, contentSize.width, contentSize.height);
    }
    
    [super setContentSize:contentSize];
}

- (void)beginUpdates
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    int screenHeightAsBubbles = appDelegate.screenBounds.size.height / _cellSize;
    
    _cellCount = MAX(appDelegate.contactManager.contactCount, screenHeightAsBubbles); // This is the grid size (n x n).
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self layoutPrimaryGrid];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self layoutSecondaryGrid];
    });
}

- (void)endUpdates
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    self.contentSize = CGSizeMake(MAX(self.frame.size.width + 1, appDelegate.contactManager.contactCount * _cellSize), MAX(self.frame.size.height + 1, appDelegate.contactManager.contactCount * _cellSize));
    _footerLabel.frame = CGRectMake(_footerLabel.frame.origin.x, self.contentSize.height + 15, _footerLabel.frame.size.width, _footerLabel.frame.size.height);
}

- (void)layoutPrimaryGrid
{
    for ( int x = 0; x < _cellCount; x++ )
    {
        [grid_primary addObject:[NSMutableArray array]];
        
        for ( int y = 0; y < _cellCount; y++ )
        {
            CGRect gridStruct = CGRectMake(_cellSize * x, _cellSize * y, _cellSize, _cellSize);
            
            if ( SH_DEVELOPMENT_ENVIRONMENT )
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    UIImageView *grid = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"debug_grid_white"]];
                    grid.frame = gridStruct;
                    grid.opaque = YES;
                    
                    [_cloudContainer addSubview:grid];
                });
            }
            
            [[grid_primary objectAtIndex:x] addObject:[NSValue valueWithCGRect:gridStruct]];
        }
    }
}

- (void)layoutSecondaryGrid
{
    for ( int x = 0; x < _cellCount + 1; x++ )
    {
        [grid_secondary addObject:[NSMutableArray array]];
        
        for ( int y = 0; y < _cellCount + 1; y++ )
        {
            CGRect gridStruct = CGRectMake(_cellSize * (x - 0.5), _cellSize * (y - 0.5), _cellSize, _cellSize);
            
            if ( SH_DEVELOPMENT_ENVIRONMENT )
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    UIImageView *grid = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"debug_grid_red"]];
                    grid.frame = gridStruct;
                    grid.opaque = YES;
                    
                    [_cloudContainer addSubview:grid];
                });
            }
            
            [[grid_secondary objectAtIndex:x] addObject:[NSValue valueWithCGRect:gridStruct]];
        }
    }
}

- (CGRect)cellForPoint:(CGPoint)point
{
    int cell_x = point.x / _cellSize;
    int cell_y = point.y / _cellSize;
    float remainder_x = fmod(point.x, _cellSize);
    float remainder_y = fmod(point.y, _cellSize);
    
    if ( (remainder_x == 0 && remainder_y != 0) || (remainder_x != 0 && remainder_y == 0) ) // Point lies right on the border of 2 cells.
    {
        /* Since the secondary grid cells come at half the intervals of the, 
           primary grid cells rounding will make a big difference in accuracy. */
        
        cell_x = (int)lroundf(point.x / _cellSize);
        cell_y = (int)lroundf(point.y / _cellSize);
        
        // Required bumps.
        if ( point.x > _cellSize / 2 && point.x < _cellSize )
        {
            cell_x += 1;
        }
        
        if ( point.y > _cellSize / 2 && point.y < _cellSize )
        {
            cell_y += 1;
        }
        
        return [[[grid_secondary objectAtIndex:cell_x] objectAtIndex:cell_y] CGRectValue];
    }
    else if ( remainder_x == 0 && remainder_y == 0 )                                        // Point lies right on a corner, in the middle of 4 cells.
    {
        return [[[grid_secondary objectAtIndex:cell_x] objectAtIndex:cell_y] CGRectValue];
    }
    else
    {
        return [[[grid_primary objectAtIndex:cell_x] objectAtIndex:cell_y] CGRectValue];
    }
}

- (NSMutableSet *)cellsForBubble:(SHChatBubble *)bubble
{
    int pos_x = [[bubble.metadata objectForKey:@"coordinate_x"] intValue];
    int pos_y = [[bubble.metadata objectForKey:@"coordinate_y"] intValue];
    
    CGRect cell_1 = [self cellForPoint:CGPointMake(pos_x, pos_y)];                                                   // Upper-left corner.
    CGRect cell_2 = [self cellForPoint:CGPointMake(pos_x + CHAT_CLOUD_BUBBLE_SIZE, pos_y)];                          // Upper-right corner.
    CGRect cell_3 = [self cellForPoint:CGPointMake(pos_x, pos_y + CHAT_CLOUD_BUBBLE_SIZE)];                          // Lower-left corner.
    CGRect cell_4 = [self cellForPoint:CGPointMake(pos_x + CHAT_CLOUD_BUBBLE_SIZE, pos_y + CHAT_CLOUD_BUBBLE_SIZE)]; // Lower-right corner.
    
    /*NSLog(@"=====");
    NSLog(@"cell 1: x=%f y=%f", cell_1.origin.x, cell_1.origin.y);
    NSLog(@"cell 2: x=%f y=%f", cell_2.origin.x, cell_2.origin.y);
    NSLog(@"cell 3: x=%f y=%f", cell_3.origin.x, cell_3.origin.y);
    NSLog(@"cell 4: x=%f y=%f", cell_4.origin.x, cell_4.origin.y);*/
    NSMutableSet *cellToad = [[NSMutableSet alloc] init];
    
    [cellToad addObject:[NSValue valueWithCGRect:cell_1]];
    [cellToad addObject:[NSValue valueWithCGRect:cell_2]];
    [cellToad addObject:[NSValue valueWithCGRect:cell_3]];
    [cellToad addObject:[NSValue valueWithCGRect:cell_4]];
    
    return cellToad;
}

- (NSMutableSet *)bubblesForCell:(CGRect)cell
{
    NSMutableSet *bubbleToad = [[NSMutableSet alloc] init];
    NSMutableArray *searchTarget;
    
    if ( _isInSearchMode )
    {
        searchTarget = _searchResultsBubbles;
    }
    else
    {
        searchTarget = _cloudBubbles;
    }
    
    for ( int i = 0; i < searchTarget.count; i++ )
    {
        SHChatBubble *bubble = [searchTarget objectAtIndex:i];
        
        // Make sure the co-ordinate values are actually ints.
        if ( strcmp([[bubble.metadata objectForKey:@"coordinate_x"] objCType], @encode(int)) == 0 &&
            strcmp([[bubble.metadata objectForKey:@"coordinate_y"] objCType], @encode(int)) == 0 )
        {
            int pos_x = [[bubble.metadata objectForKey:@"coordinate_x"] intValue];
            int pos_y = [[bubble.metadata objectForKey:@"coordinate_y"] intValue];
            CGPoint upperLeftCorner = CGPointMake(pos_x, pos_y);
            CGPoint upperRightCorner = CGPointMake(pos_x + _cellSize, pos_y);
            CGPoint lowerLeftCorner = CGPointMake(pos_x, pos_y + _cellSize);
            CGPoint lowerRightCorner = CGPointMake(pos_x + _cellSize, pos_y + _cellSize);
            
            if ( CGRectContainsPoint(cell, upperLeftCorner) ||
                CGRectContainsPoint(cell, upperRightCorner) ||
                CGRectContainsPoint(cell, lowerLeftCorner)  ||
                CGRectContainsPoint(cell, lowerRightCorner) )
            {
                [bubbleToad addObject:bubble];
            }
        }
    }
    
    return bubbleToad;
}

- (CGPoint)emptyPointForBubble:(SHChatBubble *)bubble
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    int bubbleWidth = CHAT_CLOUD_BUBBLE_SIZE + CHAT_CLOUD_BUBBLE_PADDING * 2;
    int bubbleHeight = CHAT_CLOUD_BUBBLE_SIZE + CHAT_CLOUD_BUBBLE_PADDING * 2;
    int fullBubbleWidth = CHAT_CLOUD_BUBBLE_SIZE + CHAT_CLOUD_BUBBLE_PADDING * 2 + 10;
    int fullBubbleHeight = CHAT_CLOUD_BUBBLE_SIZE + CHAT_CLOUD_BUBBLE_PADDING * 2 + 10;
    
    int screenHeightAsBubbles = bubbleHeight * (appDelegate.screenBounds.size.height / bubbleWidth);
    int screenWidthAsBubbles = bubbleHeight * (appDelegate.screenBounds.size.width / bubbleWidth);
    
    NSMutableArray *activeArray;
    
    if ( _isInSearchMode )
    {
        activeArray = _searchResultsBubbles;
    }
    else
    {
        activeArray = _cloudBubbles;
    }
    
    CGSize gridSize = CGSizeMake(MAX(bubbleHeight * activeArray.count, screenWidthAsBubbles), MAX(bubbleWidth * activeArray.count, screenHeightAsBubbles));
    CGPoint origin = CGPointMake(gridSize.width / 2, gridSize.height / 2);
    
    // Initial starting point is the center of the cloud.
    int start_x = origin.x - (bubbleWidth / 4);  // Move each bubble back a quarter of its width.
    int start_y = origin.y - (bubbleHeight / 4); // They appear slightly off-centered otherwise.
    
    if ( activeArray.count == 0 ) // Empty cloud. Just drop the top entry in the middle.
    {
        return CGPointMake(start_x, start_y);
    }
    
    // We move up one full bubble length, plus some random extra padding value.
    start_y += fullBubbleHeight + 20 + (int)arc4random_uniform(10);
    
    int angle = 1;
    int radius = fabs(origin.y - start_y);
    int x = (origin.x - (bubbleWidth / 4)) + radius * cos(DEGREES_TO_RADIANS(angle)); // Init these.
    int y = (origin.y - (bubbleHeight / 4)) + radius * sin(DEGREES_TO_RADIANS(angle));
    
    // Next, we traverse a circular path (counter-clockwise) till we find an empty spot to drop the contact.
    for ( int j = 0; j < activeArray.count; j++ )
    {
        SHChatBubble *bubble = [activeArray objectAtIndex:j];
        CGPoint placedContact = CGPointMake([[bubble.metadata objectForKey:@"coordinate_x"] intValue], [[bubble.metadata objectForKey:@"coordinate_y"] intValue]);
        
        int target_x = placedContact.x;
        int target_y = placedContact.y;
        //NSLog(@"target_x:%d, target_y:%d", target_x, target_y);
        while ( true )
        {
            x = origin.x + radius * cos(DEGREES_TO_RADIANS(angle)); // Angle should be fed in radians.
            y = origin.y + radius * sin(DEGREES_TO_RADIANS(angle));
            //NSLog(@"radius:%d, angle:%d, x:%d, y:%d", radius, angle, x, y);
            
            int upperLeftCorner_x = x - (fullBubbleWidth / 2);
            int upperLeftCorner_y = y - (fullBubbleHeight / 2);
            int upperLeftCorner_x_target = target_x - (fullBubbleWidth / 2);
            int upperLeftCorner_y_target = target_y - (fullBubbleHeight / 2);
            
            // Do we collide with this contact's bubble?
            if ( !(upperLeftCorner_x_target < (upperLeftCorner_x + bubbleWidth) && (upperLeftCorner_x_target + bubbleWidth) > upperLeftCorner_x &&
                   upperLeftCorner_y_target < (upperLeftCorner_y + fullBubbleHeight) && (upperLeftCorner_y_target + fullBubbleHeight) > upperLeftCorner_y) ) // Note: The condition inside the brackets checks for interlaps. Not the result to get no overlaps.
            {
                // If not, move on to the next one.
                break;
            }
            else
            {
                if ( angle >= radius * 2.23 || angle == 360 ) // Reset to 1.
                {
                    if ( start_y < gridSize.height - fullBubbleHeight ) // Leave some padding.
                    {
                        // We move down one full bubble length, plus some random extra padding value.
                        start_y += fullBubbleHeight + 20 + (int)arc4random_uniform(10);
                        radius *= 2;
                        
                        angle = 1;
                    }
                    else
                    {
                        break;
                    }
                }
                else
                {
                    angle++;
                }
            }
        }
    }
    
    // Loop completed without collisions. Place the bubble.
    return CGPointMake(x, y);
}

- (void)insertBubble:(SHChatBubble *)bubble atPoint:(CGPoint)point animated:(BOOL)animated
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( _isInSearchMode || _makeRoomForBubbles )
    {
        point = [self emptyPointForBubble:bubble];
    }
    
    if ( _isInSearchMode )
    {
        [_searchResultsBubbles addObject:bubble];
    }
    else
    {
        [_cloudBubbles addObject:bubble];
    }
    
    // Add the co-ordinates to the bubble's metadata dictionary & set its frame.
    [bubble.metadata setObject:[NSNumber numberWithFloat:point.x] forKey:@"coordinate_x"];
    [bubble.metadata setObject:[NSNumber numberWithFloat:point.y] forKey:@"coordinate_y"];
    bubble.layer.anchorPoint = CGPointMake(0.5, 0.5);
    bubble.delegate = self;
    
    //NSLog(@"%@ added at: x = %f y = %f", [bubble.metadata objectForKey:@"name_first"], point.x, point.y);
    
    NSInteger x_rand = arc4random_uniform(appDelegate.screenBounds.size.height);
    NSInteger y_rand = arc4random_uniform(appDelegate.screenBounds.size.height);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Keep in mind that a bubble's anchor point is its center.
        // We manually take the padding into account here.
        bubble.frame = CGRectMake(x_rand, y_rand, bubble.frame.size.width, bubble.frame.size.height);
        
        if ( (IS_IOS7) ) // iOS 7 only!
        {
            //[appDelegate registerPrallaxEffectForView:bubble depth:PARALLAX_DEPTH_HEAVY]; // Parallax.
        }
        
        if ( _isInSearchMode )
        {
            [_cloudSearchResultsContainer addSubview:bubble];
        }
        else
        {
            [_cloudContainer addSubview:bubble];
        }
        
        NSString *displayLabel = [bubble.metadata objectForKey:@"alias"];
        
        if ( displayLabel.length == 0 )
        {
            if ( bubble.bubbleType == SHChatBubbleTypeUser )
            {
                displayLabel = [NSString stringWithFormat:@"%@ %@", [bubble.metadata objectForKey:@"name_first"], [bubble.metadata objectForKey:@"name_last"]];
            }
            else
            {
                displayLabel = [bubble.metadata objectForKey:@"name"];
            }
        }
        
        [bubble setLabelText:displayLabel];
        
        if ( animated )
        {
            bubble.alpha = 0.0;
            
            [bubble setTransform:CGAffineTransformMakeScale(0.1, 0.1)];
            
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                bubble.transform = CGAffineTransformMakeScale(1.2, 1.2);
            } completion:^(BOOL finished){
                [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                    bubble.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished){
                    
                }];
            }];
            
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                bubble.alpha = 1.0;
            } completion:^(BOOL finished){
                
            }];
            
            [UIView animateWithDuration:1.0 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                bubble.frame = CGRectMake(point.x - CHAT_CLOUD_BUBBLE_PADDING * 2, point.y - CHAT_CLOUD_BUBBLE_PADDING * 2 - 10, bubble.frame.size.width, bubble.frame.size.height);
            } completion:^(BOOL finished){
                
            }];
        }
    });
}

- (void)removeBubble:(SHChatBubble *)bubble permanently:(BOOL)permanently animated:(BOOL)animated
{
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        if ( animated )
        {
            bubble.transform = CGAffineTransformMakeScale(0.1, 0.1);
            bubble.alpha = 0.0;
        }
    } completion:^(BOOL finished){
        [bubble removeFromSuperview];
    }];
    
    if ( permanently )
    {
        [_cloudBubbles removeObject:bubble];
    }
    else
    {
        // Keep it in a buffer for retrieval later on.
        [_removedBubbles addObject:bubble];
    }
}

- (void)setDP:(UIImage *)DP forUser:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for ( int i = 0; i < _cloudBubbles.count; i++ )
            {
                SHChatBubble *bubble = [_cloudBubbles objectAtIndex:i];
                int bubbleUserID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                
                if ( bubbleUserID == userID.intValue )
                {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [bubble setImage:DP];
                    });
                    
                    [bubble.metadata setObject:UIImageJPEGRepresentation(DP, 1.0) forKey:@"alias_dp"];
                }
            }
            
            [db executeUpdate:@"UPDATE sh_cloud "
                                @"SET alias_dp = :alias_dp "
                                @"WHERE sh_user_id = :user_id"
                    withParameterDictionary:@{@"user_id": userID,
                                              @"alias_dp": UIImageJPEGRepresentation(DP, 1.0)}];
        }];
    });
}

- (void)removeDPForUser:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for ( int i = 0; i < _cloudBubbles.count; i++ )
            {
                SHChatBubble *bubble = [_cloudBubbles objectAtIndex:i];
                int bubbleUserID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                UIImage *oldDP = [UIImage imageWithData:[bubble.metadata objectForKey:@"dp"]];
                
                if ( bubbleUserID == userID.intValue )
                {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [bubble setImage:oldDP];
                    });
                    
                    [bubble.metadata setObject:@"" forKey:@"alias_dp"];
                }
            }
            
            [db executeUpdate:@"UPDATE sh_cloud "
                                @"SET alias_dp = :alias_dp "
                                @"WHERE sh_user_id = :user_id"
                    withParameterDictionary:@{@"user_id": userID,
                                              @"alias_dp": @""}];
        }];
    });
}

- (void)renameBubble:(NSString *)alias forUser:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for ( int i = 0; i < _cloudBubbles.count; i++ )
            {
                SHChatBubble *bubble = [_cloudBubbles objectAtIndex:i];
                int bubbleUserID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                NSString *fullName = [NSString stringWithFormat:@"%@ %@", [bubble.metadata objectForKey:@"name_first"], [bubble.metadata objectForKey:@"name_last"]];
                
                if ( bubbleUserID == userID.intValue )
                {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        if ( alias.length > 0 )
                        {
                            [bubble setLabelText:alias];
                        }
                        else
                        {
                            [bubble setLabelText:fullName];
                        }
                    });
                    
                    [bubble.metadata setObject:alias forKey:@"alias"];
                }
            }
            
            [db executeUpdate:@"UPDATE sh_cloud "
                                @"SET alias = :alias "
                                @"WHERE sh_user_id = :user_id"
                    withParameterDictionary:@{@"user_id": userID,
                                              @"alias": alias}];
        }];
    });
}

- (void)moveBubble:(SHChatBubble *)bubble toPoint:(CGPoint)point animated:(BOOL)animated
{
    [self removeBubble:bubble permanently:NO animated:YES];
    
    long double delayInSeconds = 0.26;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self insertBubble:bubble atPoint:point animated:YES];
    });
}

- (void)gotoCellForBubble:(SHChatBubble *)bubble animated:(BOOL)animated
{
    long double delayInSeconds = 0.0;
    
    [self setZoomScale:1.0 animated:YES];
    
    // Zoom in after a slight delay, otherwise the zoom scale messes up scrollRectToVisible.
    if ( self.zoomScale != 1.0 )
    {
        delayInSeconds = 0.3;
    }
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        CGRect cell = bubble.frame;
        
        CGPoint center = cell.origin;
        center.x += cell.size.width / 2;
        center.y += cell.size.height / 2;
        
        center.x *= self.zoomScale;
        center.y *= self.zoomScale;
        
        CGRect centeredRect = CGRectMake(center.x - self.frame.size.width / 2,
                                         center.y - self.frame.size.height / 2,
                                         self.frame.size.width,
                                         self.frame.size.height);
        
        [self scrollRectToVisible:centeredRect animated:animated];
    });
}

- (void)jumpToCenter
{
    [self setZoomScale:1.0 animated:YES];
    
    // Wait till zooming animation completes.
    long double delayInSeconds = 0.3;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        CGFloat centerOffset_x = (self.contentSize.width / 2) - (self.bounds.size.width / 2);
        CGFloat centerOffset_y = (self.contentSize.height / 2) - (self.bounds.size.height / 2);
        
        [self setContentOffset:CGPointMake(centerOffset_x, centerOffset_y) animated:YES];
    });
}

- (void)updatePresenceWithDB:(FMDatabase *)db
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( db )
    {
        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_user_online_status "
                   withParameterDictionary:nil];
        
        int activeRecipientUserID = [[appDelegate.mainMenu.activeRecipientBubble.metadata objectForKey:@"user_id"] intValue];
        BOOL updatedRecipientBubble = NO;
        
        while ( [s1 next] )
        {
            NSString *userID = [s1 stringForColumn:@"user_id"];
            SHUserPresence presence = [[s1 stringForColumn:@"status"] intValue];
            NSString *presenceTargetID = [s1 stringForColumn:@"target_id"];
            SHUserPresenceAudience audience = [[s1 stringForColumn:@"audience"] intValue];
            NSString *timestamp = [s1 stringForColumn:@"timestamp"];
            BOOL updatedChatCloud = NO;
            
            if ( appDelegate.mainMenu.messagesView.recipientID.intValue == userID.intValue )
            {
                [appDelegate.mainMenu.messagesView presenceDidChange:presence time:timestamp forRecipientWithTargetID:presenceTargetID forAudience:audience withDB:db];
            }
            
            if ( userID.intValue != [[appDelegate.currentUser objectForKey:@"user_id"] intValue] )
            {
                for ( int i = 0; i < _cloudBubbles.count; i++ )
                {
                    SHChatBubble *bubble = [_cloudBubbles objectAtIndex:i];
                    int bubbleUserID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                    
                    if ( bubbleUserID == userID.intValue )
                    {
                        [bubble.metadata setObject:[NSNumber numberWithInt:presence] forKey:@"presence"];
                        [bubble.metadata setObject:presenceTargetID forKey:@"presence_target"];
                        [bubble.metadata setObject:[NSNumber numberWithInt:audience] forKey:@"audience"];
                        [bubble.metadata setObject:timestamp forKey:@"presence_timestamp"];
                        
                        [_cloudBubbles setObject:bubble atIndexedSubscript:i];
                        
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            [bubble setPresence:presence animated:YES];
                            
                            // Show a typing indicator if the current user is the target.
                            if ( presenceTargetID.intValue == [[appDelegate.currentUser objectForKey:@"user_id"] intValue] )
                            {
                                if ( presence == SHUserPresenceTyping ) // Show the typing bubble.
                                {
                                    [bubble showTypingIndicatorFromDirection:SHChatBubbleTypingIndicatorDirectionLeft];
                                }
                                else
                                {
                                    [bubble hideTypingIndicator];
                                }
                            }
                            else
                            {
                                if ( bubble.isShowingTypingIndicator )
                                {
                                    [bubble hideTypingIndicator];
                                }
                            }
                        });
                        
                        updatedChatCloud = YES;
                    }
                    
                    if ( appDelegate.mainMenu.activeRecipientBubble.metadata )
                    {
                        if ( bubbleUserID == userID.intValue && bubbleUserID == activeRecipientUserID )
                        {
                            [appDelegate.mainMenu.activeRecipientBubble.metadata setObject:[NSNumber numberWithInt:presence] forKey:@"presence"];
                            [appDelegate.mainMenu.activeRecipientBubble.metadata setObject:presenceTargetID forKey:@"presence_target"];
                            [appDelegate.mainMenu.activeRecipientBubble.metadata setObject:[NSNumber numberWithInt:audience] forKey:@"audience"];
                            [appDelegate.mainMenu.activeRecipientBubble.metadata setObject:timestamp forKey:@"presence_timestamp"];
                            
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                [appDelegate.mainMenu.activeRecipientBubble setPresence:presence animated:YES];
                                
                                // Show a typing indicator if the current user is the target.
                                if ( [presenceTargetID intValue] == [[appDelegate.currentUser objectForKey:@"user_id"] intValue] )
                                {
                                    if ( presence == SHUserPresenceTyping ) // Show the typing bubble.
                                    {
                                        [appDelegate.mainMenu.activeRecipientBubble showTypingIndicatorFromDirection:SHChatBubbleTypingIndicatorDirectionRight];
                                    }
                                    else
                                    {
                                        [appDelegate.mainMenu.activeRecipientBubble hideTypingIndicator];
                                    }
                                }
                                else
                                {
                                    if ( appDelegate.mainMenu.activeRecipientBubble.isShowingTypingIndicator )
                                    {
                                        [appDelegate.mainMenu.activeRecipientBubble hideTypingIndicator];
                                    }
                                }
                            });
                            
                            updatedRecipientBubble = YES;
                        }
                    }
                    else // No active recipient.
                    {
                        updatedRecipientBubble = YES;
                    }
                    
                    if ( updatedChatCloud && updatedRecipientBubble )
                    {
                        break;
                    }
                }
            }
            
            for ( int i = 0; i < appDelegate.mainMenu.SHMiniFeedEntries.count; i++ )
            {
                NSMutableDictionary *entry = [appDelegate.mainMenu.SHMiniFeedEntries objectAtIndex:i];
                int entryType = [[entry objectForKey:@"entry_type"] intValue];
                
                if ( entryType == 1 )
                {
                    int targetUserID = [[entry objectForKey:@"user_id"] intValue];
                    
                    if ( targetUserID == userID.intValue )
                    {
                        [entry setObject:[NSNumber numberWithInt:presence] forKey:@"presence"];
                        [appDelegate.mainMenu.SHMiniFeedEntries setObject:entry atIndexedSubscript:i];
                        
                        break;
                    }
                }
                else if ( entryType == 2 )
                {
                    NSArray *originalParticipants = [[entry objectForKey:@"tag"] allObjects];
                    NSMutableArray *originalParticipantData = [entry objectForKey:@"original_participant_data"];
                    
                    int originalParticipant_1 = [[originalParticipants objectAtIndex:0] intValue];
                    int originalParticipant_2 = [[originalParticipants objectAtIndex:1] intValue];
                    
                    if ( originalParticipant_1 == userID.intValue )
                    {
                        NSMutableDictionary *participant_1 = [originalParticipantData objectAtIndex:0];
                        int index = 0;
                        
                        if ( [[participant_1 objectForKey:@"user_id"] intValue] != originalParticipant_1 )
                        {
                            participant_1 = [originalParticipantData objectAtIndex:1];
                            index = 1;
                        }
                        
                        [participant_1 setObject:[NSNumber numberWithInt:presence] forKey:@"presence"];
                        [originalParticipantData setObject:participant_1 atIndexedSubscript:index];
                        [entry setObject:originalParticipantData forKey:@"original_participant_data"];
                        [appDelegate.mainMenu.SHMiniFeedEntries setObject:entry atIndexedSubscript:i];
                        
                        break;
                    }
                    else if ( originalParticipant_2 == userID.intValue )
                    {
                        NSMutableDictionary *participant_2 = [originalParticipantData objectAtIndex:1];
                        int index = 1;
                        
                        if ( [[participant_2 objectForKey:@"user_id"] intValue] != originalParticipant_2 )
                        {
                            participant_2 = [originalParticipantData objectAtIndex:0];
                            index = 0;
                        }
                        
                        [participant_2 setObject:[NSNumber numberWithInt:presence] forKey:@"presence"];
                        [originalParticipantData setObject:participant_2 atIndexedSubscript:index];
                        [entry setObject:originalParticipantData forKey:@"original_participant_data"];
                        [appDelegate.mainMenu.SHMiniFeedEntries setObject:entry atIndexedSubscript:i];
                        
                        break;
                    }
                }
            }
            
            if ( presence == SHUserPresenceOffline || presence == SHUserPresenceOfflineMasked ) // Search the feed for ad hocs when someone goes offline.
            {
                for ( int i = 0; i < appDelegate.mainMenu.SHMiniFeedEntries.count; i++ )
                {
                    NSMutableDictionary *entry = [appDelegate.mainMenu.SHMiniFeedEntries objectAtIndex:i];
                    int entryType = [[entry objectForKey:@"entry_type"] intValue];
                    
                    if ( entryType == 2 )
                    {
                        NSMutableArray *originalParticipantData = [entry objectForKey:@"original_participant_data"];
                        NSMutableDictionary *participant_1 = [originalParticipantData objectAtIndex:0];
                        NSMutableDictionary *participant_2 = [originalParticipantData objectAtIndex:1];
                        SHUserPresence presence_participant_1 = [[participant_1 objectForKey:@"presence"] intValue];
                        SHUserPresence presence_participant_2 = [[participant_2 objectForKey:@"presence"] intValue];
                        
                        // If 2 main participants in an ad hoc convo go offline, the convo entry disappears.
                        if ( (presence_participant_1 == SHUserPresenceOffline || presence_participant_1 == SHUserPresenceOfflineMasked) &&
                            (presence_participant_2 == SHUserPresenceOffline || presence_participant_2 == SHUserPresenceOfflineMasked) )
                        {
                            [appDelegate.mainMenu.SHMiniFeedEntries removeObjectAtIndex:i];
                            i--; // Backtrack to make up for the removed element!
                        }
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [appDelegate.mainMenu.SHMiniFeed reloadData]; // To refresh the presence states.
            });
        }
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
            [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_user_online_status "
                           withParameterDictionary:nil];
                
                int activeRecipientUserID = [[appDelegate.mainMenu.activeRecipientBubble.metadata objectForKey:@"user_id"] intValue];
                BOOL updatedRecipientBubble = NO;
                
                while ( [s1 next] )
                {
                    NSString *userID = [s1 stringForColumn:@"user_id"];
                    SHUserPresence presence = [[s1 stringForColumn:@"status"] intValue];;
                    NSString *presenceTargetID = [s1 stringForColumn:@"target_id"];
                    SHUserPresenceAudience audience = [[s1 stringForColumn:@"audience"] intValue];
                    NSString *timestamp = [s1 stringForColumn:@"timestamp"];
                    BOOL updatedChatCloud = NO;
                    
                    if ( appDelegate.mainMenu.messagesView.recipientID.intValue == userID.intValue )
                    {
                        [appDelegate.mainMenu.messagesView presenceDidChange:presence time:timestamp forRecipientWithTargetID:presenceTargetID forAudience:audience withDB:db];
                    }
                    
                    if ( userID.intValue != [[appDelegate.currentUser objectForKey:@"user_id"] intValue] )
                    {
                        for ( int i = 0; i < _cloudBubbles.count; i++ )
                        {
                            SHChatBubble *bubble = [_cloudBubbles objectAtIndex:i];
                            int bubbleUserID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                            
                            if ( bubbleUserID == userID.intValue )
                            {
                                [bubble.metadata setObject:[NSNumber numberWithInt:presence] forKey:@"presence"];
                                [bubble.metadata setObject:presenceTargetID forKey:@"presence_target"];
                                [bubble.metadata setObject:[NSNumber numberWithInt:audience] forKey:@"audience"];
                                [bubble.metadata setObject:timestamp forKey:@"presence_timestamp"];
                                
                                [_cloudBubbles setObject:bubble atIndexedSubscript:i];
                                
                                dispatch_async(dispatch_get_main_queue(), ^(void){
                                    [bubble setPresence:presence animated:YES];
                                    
                                    // Show a typing indicator if the current user is the target.
                                    if ( [presenceTargetID intValue] == [[appDelegate.currentUser objectForKey:@"user_id"] intValue] )
                                    {
                                        if ( presence == SHUserPresenceTyping ) // Show the typing bubble.
                                        {
                                            [bubble showTypingIndicatorFromDirection:SHChatBubbleTypingIndicatorDirectionLeft];
                                        }
                                        else
                                        {
                                            [bubble hideTypingIndicator];
                                        }
                                    }
                                    else
                                    {
                                        if ( bubble.isShowingTypingIndicator )
                                        {
                                            [bubble hideTypingIndicator];
                                        }
                                    }
                                });
                                
                                updatedChatCloud = YES;
                            }
                            
                            if ( appDelegate.mainMenu.activeRecipientBubble.metadata )
                            {
                                if ( bubbleUserID == activeRecipientUserID )
                                {
                                    [appDelegate.mainMenu.activeRecipientBubble.metadata setObject:[NSNumber numberWithInt:presence] forKey:@"presence"];
                                    [appDelegate.mainMenu.activeRecipientBubble.metadata setObject:presenceTargetID forKey:@"presence_target"];
                                    [appDelegate.mainMenu.activeRecipientBubble.metadata setObject:[NSNumber numberWithInt:audience] forKey:@"audience"];
                                    [appDelegate.mainMenu.activeRecipientBubble.metadata setObject:timestamp forKey:@"presence_timestamp"];
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^(void){
                                        [appDelegate.mainMenu.activeRecipientBubble setPresence:presence animated:YES];
                                        
                                        // Show a typing indicator if the current user is the target.
                                        if ( [presenceTargetID intValue] == [[appDelegate.currentUser objectForKey:@"user_id"] intValue] )
                                        {
                                            if ( presence == SHUserPresenceTyping ) // Show the typing bubble.
                                            {
                                                [appDelegate.mainMenu.activeRecipientBubble showTypingIndicatorFromDirection:SHChatBubbleTypingIndicatorDirectionRight];
                                            }
                                            else
                                            {
                                                [appDelegate.mainMenu.activeRecipientBubble hideTypingIndicator];
                                            }
                                        }
                                        else
                                        {
                                            if ( appDelegate.mainMenu.activeRecipientBubble.isShowingTypingIndicator )
                                            {
                                                [appDelegate.mainMenu.activeRecipientBubble hideTypingIndicator];
                                            }
                                        }
                                    });
                                    
                                    updatedRecipientBubble = YES;
                                }
                            }
                            else // No active recipient.
                            {
                                updatedRecipientBubble = YES;
                            }
                            
                            if ( updatedChatCloud && updatedRecipientBubble )
                            {
                                break;
                            }
                        }
                    }
                    
                    for ( int i = 0; i < appDelegate.mainMenu.SHMiniFeedEntries.count; i++ )
                    {
                        NSMutableDictionary *entry = [appDelegate.mainMenu.SHMiniFeedEntries objectAtIndex:i];
                        int entryType = [[entry objectForKey:@"entry_type"] intValue];
                        
                        if ( entryType == 1 )
                        {
                            int targetUserID = [[entry objectForKey:@"user_id"] intValue];
                            
                            if ( targetUserID == userID.intValue )
                            {
                                [entry setObject:[NSNumber numberWithInt:presence] forKey:@"presence"];
                                [appDelegate.mainMenu.SHMiniFeedEntries setObject:entry atIndexedSubscript:i];
                                
                                break;
                            }
                        }
                        else if ( entryType == 2 )
                        {
                            NSArray *originalParticipants = [[entry objectForKey:@"tag"] allObjects];
                            NSMutableArray *originalParticipantData = [entry objectForKey:@"original_participant_data"];
                            
                            int originalParticipant_1 = [[originalParticipants objectAtIndex:0] intValue];
                            int originalParticipant_2 = [[originalParticipants objectAtIndex:1] intValue];
                            
                            if ( originalParticipant_1 == userID.intValue )
                            {
                                NSMutableDictionary *participant_1 = [originalParticipantData objectAtIndex:0];
                                int index = 0;
                                
                                if ( [[participant_1 objectForKey:@"user_id"] intValue] != originalParticipant_1 )
                                {
                                    participant_1 = [originalParticipantData objectAtIndex:1];
                                    index = 1;
                                }
                                
                                [participant_1 setObject:[NSNumber numberWithInt:presence] forKey:@"presence"];
                                [originalParticipantData setObject:participant_1 atIndexedSubscript:index];
                                [entry setObject:originalParticipantData forKey:@"original_participant_data"];
                                [appDelegate.mainMenu.SHMiniFeedEntries setObject:entry atIndexedSubscript:i];
                                
                                break;
                            }
                            else if ( originalParticipant_2 == userID.intValue )
                            {
                                NSMutableDictionary *participant_2 = [originalParticipantData objectAtIndex:1];
                                int index = 1;
                                
                                if ( [[participant_2 objectForKey:@"user_id"] intValue] != originalParticipant_2 )
                                {
                                    participant_2 = [originalParticipantData objectAtIndex:0];
                                    index = 0;
                                }
                                
                                [participant_2 setObject:[NSNumber numberWithInt:presence] forKey:@"presence"];
                                [originalParticipantData setObject:participant_2 atIndexedSubscript:index];
                                [entry setObject:originalParticipantData forKey:@"original_participant_data"];
                                [appDelegate.mainMenu.SHMiniFeedEntries setObject:entry atIndexedSubscript:i];
                                
                                break;
                            }
                        }
                    }
                    
                    if ( presence == SHUserPresenceOffline || presence == SHUserPresenceOfflineMasked ) // Search the feed for ad hocs when someone goes offline.
                    {
                        for ( int i = 0; i < appDelegate.mainMenu.SHMiniFeedEntries.count; i++ )
                        {
                            NSMutableDictionary *entry = [appDelegate.mainMenu.SHMiniFeedEntries objectAtIndex:i];
                            int entryType = [[entry objectForKey:@"entry_type"] intValue];
                            
                            if ( entryType == 2 )
                            {
                                NSMutableArray *originalParticipantData = [entry objectForKey:@"original_participant_data"];
                                NSMutableDictionary *participant_1 = [originalParticipantData objectAtIndex:0];
                                NSMutableDictionary *participant_2 = [originalParticipantData objectAtIndex:1];
                                SHUserPresence presence_participant_1 = [[participant_1 objectForKey:@"presence"] intValue];
                                SHUserPresence presence_participant_2 = [[participant_2 objectForKey:@"presence"] intValue];
                                
                                // If 2 main participants in an ad hoc convo go offline, the convo entry disappears.
                                if ( (presence_participant_1 == SHUserPresenceOffline || presence_participant_1 == SHUserPresenceOfflineMasked) &&
                                    (presence_participant_2 == SHUserPresenceOffline || presence_participant_2 == SHUserPresenceOfflineMasked) )
                                {
                                    [appDelegate.mainMenu.SHMiniFeedEntries removeObjectAtIndex:i];
                                    i--; // Backtrack to make up for the removed element!
                                }
                            }
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [appDelegate.mainMenu.SHMiniFeed reloadData]; // To refresh the presence states.
                    });
                }
            }];
        });
    }
}

- (void)emptyBitBucket
{
    // Throw 'em. Throw that shit. Throw 'em all.
    [_removedBubbles removeAllObjects];
}

#pragma mark -
#pragma mark SHChatCloudDelegate methods.

- (void)didSelectBubble:(SHChatBubble *)bubble inCloud:(SHContactCloud *)theCloud
{
    if ( [_cloudDelegate respondsToSelector:@selector(didSelectBubble:inCloud:)] )
    {
        [_cloudDelegate didSelectBubble:bubble inCloud:self];
    }
}

- (void)didTapAndHoldBubble:(SHChatBubble *)bubble inCloud:(SHContactCloud *)theCloud
{
    if ( [_cloudDelegate respondsToSelector:@selector(didTapAndHoldBubble:inCloud:)] )
    {
        [_cloudDelegate didTapAndHoldBubble:bubble inCloud:self];
    }
}

#pragma mark -
#pragma mark SHChatBubbleDelegate methods.

// Forward these to the chat cloud delegate.
- (void)didSelectBubble:(SHChatBubble *)bubble
{
    [self didSelectBubble:bubble inCloud:self];
}

- (void)didTapAndHoldBubble:(SHChatBubble *)bubble
{
    [self didTapAndHoldBubble:bubble inCloud:self];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
