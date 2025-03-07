//
//  SHModelManager.m
//  Scapes
//
//  Created by MachOSX on 8/3/13.
//
//

#import "SHModelManager.h"

@implementation SHModelManager

- (id)init
{
	if ( self = [super init] )
    {
        [self synchronizeLatestDB];
	}
    
	return self;
}

// This returns a SQLite-friendly timestamp.
- (NSString *)dateTodayString
{
    NSDate *today = [NSDate date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    
    return [dateFormatter stringFromDate:today];
}

- (int)schemaVersion
{
    FMResultSet *s1 = [self executeQuery:@"PRAGMA user_version" withParameterDictionary:nil];
    int version = 0;
    
    while ( [s1 next] )
    {
        version = [s1 intForColumnIndex:0];
    }
    
    [s1 close];
    [_results close];
    [_DB close];
    
    return version;
}

- (void)incrementSchemaVersion
{
    int currentVersion = [self schemaVersion];
    currentVersion++;
    
    NSString *query = [NSString stringWithFormat:@"PRAGMA user_version = %d", currentVersion];
    FMResultSet *s1 = [self executeQuery:query withParameterDictionary:nil];
    [s1 next];
    [s1 close];
}

#pragma mark - 
#pragma mark Database Creation
/******************************************************************
 Every database has a table called "db_metadata", which stores the
 time that the file was last backed up & the time it was last
 modified (entered manually).
 ******************************************************************/

- (void)synchronizeLatestDB
{
    // Get the documents directory.
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [dirPaths objectAtIndex:0];
    NSString *templateDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DB_TEMPLATE_NAME];
    
    _databasePath = [documentsDirectory stringByAppendingPathComponent:DB_TEMPLATE_NAME];
    _DB = [FMDatabase databaseWithPath:_databasePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    if ( ![fileManager fileExistsAtPath:_databasePath] )
    {
        if ( [fileManager copyItemAtPath:templateDBPath toPath:_databasePath error:&error] )
        {
            NSLog(@"Database created!");
            
            if ( ![_DB open] )
            {
                NSLog(@"FMDB: failed to open the database!");
            }
            else
            {
                [self updateMetadataOfDB:_DB]; // Update the last modded timestamp.
                NSLog(@"Successfully updated the fresh DB's metadata!");
            }
        }
        else
        {
            NSLog(@"Failed to copy the DB file: %@", error);
        }
    }
    
    /*
     *  Schema/App versions
     *  ==
     *  1: v1.0
     *  2: v1.1
     *  3: v1.2
     */
    switch ( [self schemaVersion] )
    {
        case 1: // Update for users still on the 1.0 schema.
        {
            NSDictionary *defaultMediaExtra = @{@"attachment_type": @"null"};
            NSData *data = [NSJSONSerialization dataWithJSONObject:defaultMediaExtra options:NSJSONWritingPrettyPrinted error:nil];
            
            [self executeUpdate:@"UPDATE sh_thread SET media_extra = :media_extra"
                    withParameterDictionary:@{@"media_extra": data}];
            
            [self incrementSchemaVersion];
            
            break;
        }
            
        case 2: // Update for users still on the 1.1 schema.
        {
            FMResultSet *s1 = [self executeQuery:@"SELECT * FROM sh_chat_cloud"
                          withParameterDictionary:nil];
            
            NSMutableArray *list = [NSMutableArray array];
            
            while ( [s1 next] )
            {
                NSString *alias = [s1 stringForColumn:@"alias"];
                NSString *lastViewTimestamp = [s1 stringForColumn:@"last_view_timestamp"];
                NSString *lastMessageTimestamp = [s1 stringForColumn:@"last_message_timestamp"];
                id DP = [s1 dataForColumn:@"dp"];
                id aliasDP = [s1 dataForColumn:@"alias_dp"];
                
                if ( !alias )
                {
                    alias = @"";
                }
                
                if ( !lastViewTimestamp )
                {
                    lastViewTimestamp = @"";
                }
                
                if ( !lastMessageTimestamp )
                {
                    lastMessageTimestamp = @"";
                }
                
                if ( !DP )
                {
                    DP = @"";
                }
                
                if ( !aliasDP )
                {
                    aliasDP = @"";
                }
                
                NSMutableDictionary *contactData = [[NSMutableDictionary alloc] initWithObjects:@[[s1 stringForColumn:@"sh_user_id"],
                                                                                                  [s1 stringForColumn:@"name_first"],
                                                                                                  [s1 stringForColumn:@"name_last"],
                                                                                                  alias,
                                                                                                  [s1 stringForColumn:@"user_handle"],
                                                                                                  [s1 stringForColumn:@"hidden"],
                                                                                                  [s1 stringForColumn:@"temp"],
                                                                                                  [s1 stringForColumn:@"blocked"],
                                                                                                  [s1 stringForColumn:@"dp_hash"],
                                                                                                  DP,
                                                                                                  aliasDP,
                                                                                                  [s1 stringForColumn:@"email_address"],
                                                                                                  [s1 stringForColumn:@"gender"],
                                                                                                  [s1 stringForColumn:@"birthday"],
                                                                                                  [s1 stringForColumn:@"location_country"],
                                                                                                  [s1 stringForColumn:@"location_state"],
                                                                                                  [s1 stringForColumn:@"location_city"],
                                                                                                  [s1 stringForColumn:@"website"],
                                                                                                  [s1 stringForColumn:@"bio"],
                                                                                                  [s1 stringForColumn:@"last_status_id"],
                                                                                                  [s1 stringForColumn:@"total_messages_sent"],
                                                                                                  [s1 stringForColumn:@"total_messages_received"],
                                                                                                  [s1 stringForColumn:@"unread_thread_count"],
                                                                                                  [s1 stringForColumn:@"view_count"],
                                                                                                  [s1 stringForColumn:@"facebook_id"],
                                                                                                  [s1 stringForColumn:@"twitter_id"],
                                                                                                  [s1 stringForColumn:@"instagram_id"],
                                                                                                  [s1 stringForColumn:@"join_date"],
                                                                                                  lastViewTimestamp,
                                                                                                  lastMessageTimestamp,
                                                                                                  [s1 stringForColumn:@"coordinate_x"],
                                                                                                  [s1 stringForColumn:@"coordinate_y"],
                                                                                                  [s1 stringForColumn:@"rank_score"]]
                                                                                        forKeys:@[@"user_id",
                                                                                                  @"name_first",
                                                                                                  @"name_last",
                                                                                                  @"alias",
                                                                                                  @"user_handle",
                                                                                                  @"hidden",
                                                                                                  @"temp",
                                                                                                  @"blocked",
                                                                                                  @"dp_hash",
                                                                                                  @"dp",
                                                                                                  @"alias_dp",
                                                                                                  @"email_address",
                                                                                                  @"gender",
                                                                                                  @"birthday",
                                                                                                  @"location_country",
                                                                                                  @"location_state",
                                                                                                  @"location_city",
                                                                                                  @"website",
                                                                                                  @"bio",
                                                                                                  @"last_status_id",
                                                                                                  @"total_messages_sent",
                                                                                                  @"total_messages_received",
                                                                                                  @"unread_thread_count",
                                                                                                  @"view_count",
                                                                                                  @"facebook_id",
                                                                                                  @"twitter_id",
                                                                                                  @"instagram_id",
                                                                                                  @"join_date",
                                                                                                  @"last_view_timestamp",
                                                                                                  @"last_message_timestamp",
                                                                                                  @"coordinate_x",
                                                                                                  @"coordinate_y",
                                                                                                  @"rank_score"]];
                [list addObject:contactData];
            }
            
            [s1 close];
            
            [self executeUpdate:@"DROP TABLE sh_chat_cloud"
                    withParameterDictionary:nil];
            
            [self executeUpdate:@"CREATE TABLE 'sh_cloud' ('sh_user_id' INTEGER PRIMARY KEY  NOT NULL, 'temp' BOOL DEFAULT (0), 'follows_user' BOOL DEFAULT (0), 'hidden' BOOL DEFAULT (0), 'blocked' BOOL DEFAULT (0), 'rank_score' REAL, 'coordinate_x' INTEGER, 'coordinate_y' INTEGER, 'name_first' VARCHAR, 'name_last' VARCHAR, 'alias' VARCHAR, 'user_handle' VARCHAR, 'raw_user_id' INTEGER, 'dp_hash' VARCHAR, 'dp' BLOB, 'alias_dp' BLOB, 'last_status_id' INTEGER, 'unread_thread_count' INTEGER DEFAULT (0), 'relationship_type' VARCHAR, 'email_address' VARCHAR, 'gender' VARCHAR, 'birthday' DATETIME, 'timezone' INTEGER, 'total_messages_sent' INTEGER DEFAULT (0), 'total_messages_received' INTEGER DEFAULT (0), 'total_media_sent' INTEGER DEFAULT (0), 'total_media_received' INTEGER DEFAULT (0), 'location_country' VARCHAR, 'location_state' VARCHAR, 'location_city' VARCHAR, 'bio' VARCHAR, 'facebook_id' VARCHAR, 'twitter_id' VARCHAR, 'instagram_id' VARCHAR, 'join_date' DATETIME, 'website' VARCHAR, 'last_view_timestamp' DATETIME, 'last_message_timestamp' DATETIME, 'media_count' INTEGER DEFAULT (0), 'view_count' INTEGER DEFAULT (0) );"
                    withParameterDictionary:nil];
            
            for ( NSMutableDictionary *contact in list )
            {
                [self executeUpdate:@"INSERT INTO sh_cloud "
                 @"(sh_user_id, temp, hidden, blocked, name_first, name_last, alias, user_handle, dp_hash, dp, alias_dp, email_address, gender, birthday, location_country, location_state, location_city, website, bio, facebook_id, twitter_id, instagram_id, join_date, last_view_timestamp, last_message_timestamp, last_status_id, total_messages_sent, total_messages_received, unread_thread_count, view_count, coordinate_x, coordinate_y, rank_score) "
                 @"VALUES (:user_id, :temp, :hidden, :blocked, :name_first, :name_last, :alias, :user_handle, :dp_hash, :dp, :alias_dp, :email_address, :gender, :birthday, :location_country, :location_state, :location_city, :website, :bio, :facebook_id, :twitter_id, :instagram_id, :join_date, :last_view_timestamp, :last_message_timestamp, :last_status_id, :total_messages_sent, :total_messages_received, :unread_thread_count, :view_count, :coordinate_x, :coordinate_y, :rank_score)"
                        withParameterDictionary:contact];
            }
            
            [self incrementSchemaVersion];
            
            break;
        }
            
        default:
        {
            break;
        }
    }
}

- (void)resetDB
{
    // Get the template file.
    NSString *templateDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DB_TEMPLATE_NAME];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    if ( [fileManager fileExistsAtPath:_databasePath] )
    {
        if ( [fileManager removeItemAtPath:_databasePath error:&error] )
        {
            if ( [fileManager copyItemAtPath:templateDBPath toPath:_databasePath error:&error] )
            {
                NSLog(@"Database reset!");
                
                if ( ![_DB open] )
                {
                    NSLog(@"FMDB: failed to open the database!");
                }
                else
                {
                    [self updateMetadataOfDB:_DB]; // Update the last modded timestamp.
                    NSLog(@"Successfully updated the fresh DB's metadata!");
                }
            }
            else
            {
                NSLog(@"Failed to re-copy the DB file: %@", error);
            }
        }
    }
    else
    {
        if ( [fileManager copyItemAtPath:templateDBPath toPath:_databasePath error:&error] )
        {
            NSLog(@"Database reset!");
            
            if ( ![_DB open] )
            {
                NSLog(@"FMDB: failed to open the database!");
            }
            else
            {
                [self updateMetadataOfDB:_DB]; // Update the last modded timestamp.
                NSLog(@"Successfully updated the fresh DB's metadata!");
            }
        }
        else
        {
            NSLog(@"Failed to re-copy the DB file: %@", error);
        }
    }
}

#pragma mark -
#pragma mark Database Updates

- (void)updateMetadataOfDB:(FMDatabase *)targetDB
{
    FMResultSet *s = [targetDB executeQuery:@"SELECT * FROM db_metadata"];
    
    if ( [s next] )
    {
        [targetDB executeUpdate:@"UPDATE db_metadata SET last_changes_date = ? WHERE id = 1", [self dateTodayString]];
    }
    else
    {
        [targetDB executeUpdate:@"INSERT INTO db_metadata (last_changes_date) VALUES (?)", [self dateTodayString]];
    }
    
    [s close]; // Very important that you close this!
    
    if ( [targetDB lastErrorCode] != 0 )
    {
        NSLog(@"FMDB Metadata INSERT Error: %@", [targetDB lastError]);
    }
}

- (BOOL)executeUpdate:(NSString *)statement withParameterDictionary:argsDict
{
    if ( ![_DB open] )
    {
        NSLog(@"FMDB: failed to open database!");
        return NO;
    }
    else
    {
        [self updateMetadataOfDB:_DB]; // Update the last modded timestamp.
        sqlite3_exec(_DB.sqliteHandle, [[NSString stringWithFormat:@"PRAGMA foreign_keys = ON;"] UTF8String], NULL, NULL, NULL);
        
        BOOL success = [_DB executeUpdate:statement withParameterDictionary:argsDict];
        
        if ( [_DB lastErrorCode] != 0 )
        {
            NSLog(@"FMDB Insert Error: %@", [_DB lastError]);
        }
        
        [_DB close];
        
        return success;
    }
}

- (FMResultSet *)executeQuery:(NSString *)statement withParameterDictionary:argsDict
{
    if ( ![_DB open] )
    {
        NSLog(@"FMDB: failed to open database!");
        return nil;
    }
    else
    {
        _results = [_DB executeQuery:statement withParameterDictionary:argsDict];
        
        if ( [_DB lastErrorCode] != 0 )
        {
            NSLog(@"FMDB SELECT Error: %@", [_DB lastError]);
        }
        
        return _results;
    }
}

- (void)saveCurrentUserData:(NSDictionary *)userData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSString *userID = [NSString stringWithFormat:@"%@", [userData objectForKey:@"user_id"]];
    NSString *firstName = [userData objectForKey:@"name_first"];
    NSString *lastName = [userData objectForKey:@"name_last"];
    UIImage *chatWallpaper = [UIImage imageNamed:DEFAULT_WALLPAPER];
    NSString *alias = @"";
    NSString *userHandle = @"";
    __block NSString *DPHash = @"";
    id imageData_alias = @""; // Insert this as a blank string since the user can't have an alias DP for themselves.
    NSString *email = @"";
    NSString *gender = @"";
    NSString *birthday = @"";
    NSString *location_country = @"";
    NSString *location_state = @"";
    NSString *location_city = @"";
    NSString *website = @"";
    NSString *bio = @"";
    NSString *facebookHandle = @"";
    NSString *twitterHandle = @"";
    NSString *instagramHandle = @"";
    NSString *joinDate = [userData objectForKey:@"join_date"];
    int totalMessagesSent = [[userData objectForKey:@"total_messages_sent"] intValue];
    int totalMessagesReceived = [[userData objectForKey:@"total_messages_received"] intValue];
    
    SHUserPresenceAudience mask_talking = [[userData objectForKey:@"talking_mask"] intValue];
    SHUserPresenceAudience mask_presence = [[userData objectForKey:@"presence_mask"] intValue];
    
    NSString *lastStatus = [userData objectForKey:@"message"];
    NSString *lastStatusID = [userData objectForKey:@"thread_id"];
    NSString *lastStatusTimestamp = [userData objectForKey:@"timestamp_sent"];
    NSString *lastStatusPrivacy = [userData objectForKey:@"privacy"];
    NSString *lastStatusType = [userData objectForKey:@"thread_type"];
    NSString *lastStatusOwnerType = [userData objectForKey:@"owner_type"];
    NSString *lastStatusLocation_latitude = @"";
    NSString *lastStatusLocation_longitude = @"";
    NSString *lastStatusRootItemID = [userData objectForKey:@"root_item_id"];
    NSString *lastStatusChildCount = [userData objectForKey:@"child_count"];
    NSString *lastStatusUnreadMessageCount = [userData objectForKey:@"unread_message_count"];
    NSString *lastStatusGroupID = [userData objectForKey:@"group_id"];
    NSString *lastStatusStatus_sent = [userData objectForKey:@"status_sent"];
    NSString *lastStatusStatus_delivered = [userData objectForKey:@"status_delivered"];
    NSString *lastStatusStatus_read = [userData objectForKey:@"status_read"];
    NSString *lastStatusTimestamp_delivered = [userData objectForKey:@"timestamp_delivered"];
    NSString *lastStatusTimestamp_read = [userData objectForKey:@"timestamp_read"];
    NSString *lastStatusMediaType = @"";
    NSString *lastStatusMediaFileSize = @"";
    NSString *lastStatusMediaLocalPath = @"";
    NSString *lastStatusMediaHash = @"";
    NSString *lastStatusMediaData = @"";
    NSString *lastStatusMediaExtra = @"";
    
    NSDate *dateToday = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    
    if ( mask_talking == 1 ) // 1 meaning the mask is activated.
    {
        appDelegate.preference_Talking = NO;
        [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"SHBDTalking"];
    }
    else
    {
        appDelegate.preference_Talking = YES;
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"SHBDTalking"];
    }
    
    if ( mask_presence == 1 )
    {
        appDelegate.preference_LastSeen = NO;
        [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"SHBDLastSeen"];
    }
    else
    {
        appDelegate.preference_LastSeen = YES;
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"SHBDLastSeen"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // =======================================
    
    if ( [userData objectForKey:@"license"] && ![[NSNull null] isEqual:[userData objectForKey:@"license"]] )
    {
        NSDictionary *licenseData = [userData objectForKey:@"license"];
        SHLicense licenseType = [[licenseData objectForKey:@"license_type"] intValue];
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:licenseType] forKey:@"SHBDLicenseType"];
        
        if ( licenseType != SHLicenseLifetime )
        {
            NSDate *purchaseDate = [dateFormatter dateFromString:[licenseData objectForKey:@"timestamp"]];
            
            if ( [dateToday timeIntervalSinceDate:purchaseDate] > 31536000 ) // Check if a year has passed since the subscription.
            {
                [appDelegate disableApp];
                
                return;
            }
        }
    }
    else
    {
        NSDate *joined = [dateFormatter dateFromString:joinDate];
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:SHLicenseTrial] forKey:@"SHBDLicenseType"];
        
        if ( [dateToday timeIntervalSinceDate:joined] > 31536000 ) // Check if a year has passed since the user joined.
        {
            [appDelegate disableApp];
            
            return;
        }
    }
    
    if ( [userData objectForKey:@"user_handle"] && ![[NSNull null] isEqual:[userData objectForKey:@"user_handle"]] )
    {
        userHandle = [userData objectForKey:@"user_handle"];
    }
    
    if ( [userData objectForKey:@"dp_hash"] && ![[NSNull null] isEqual:[userData objectForKey:@"dp_hash"]] )
    {
        DPHash = [userData objectForKey:@"dp_hash"];
    }
    
    if ( [userData objectForKey:@"email_address"] && ![[NSNull null] isEqual:[userData objectForKey:@"email_address"]] )
    {
        email = [userData objectForKey:@"email_address"];
    }
    
    if ( [userData objectForKey:@"gender"] && ![[NSNull null] isEqual:[userData objectForKey:@"gender"]] )
    {
        gender = [userData objectForKey:@"gender"];
    }
    
    if ( [userData objectForKey:@"location_country"] && ![[NSNull null] isEqual:[userData objectForKey:@"location_country"]] )
    {
        location_country = [userData objectForKey:@"location_country"];
    }
    
    if ( [userData objectForKey:@"location_state"] && ![[NSNull null] isEqual:[userData objectForKey:@"location_state"]] )
    {
        location_state = [userData objectForKey:@"location_state"];
    }
    
    if ( [userData objectForKey:@"location_city"] && ![[NSNull null] isEqual:[userData objectForKey:@"location_city"]] )
    {
        location_city = [userData objectForKey:@"location_city"];
    }
    
    if ( [userData objectForKey:@"website"] && ![[NSNull null] isEqual:[userData objectForKey:@"website"]] )
    {
        website = [userData objectForKey:@"website"];
    }
    
    if ( [userData objectForKey:@"bio"] && ![[NSNull null] isEqual:[userData objectForKey:@"bio"]] )
    {
        bio = [userData objectForKey:@"bio"];
    }
    
    if ( [userData objectForKey:@"facebook_id"] && ![[NSNull null] isEqual:[userData objectForKey:@"facebook_id"]] )
    {
        facebookHandle = [userData objectForKey:@"facebook_id"];
    }
    
    if ( [userData objectForKey:@"twitter_id"] && ![[NSNull null] isEqual:[userData objectForKey:@"twitter_id"]] )
    {
        twitterHandle = [userData objectForKey:@"twitter_id"];
    }
    
    if ( [userData objectForKey:@"instagram_id"] && ![[NSNull null] isEqual:[userData objectForKey:@"instagram_id"]] )
    {
        instagramHandle = [userData objectForKey:@"instagram_id"];
    }
    
    if ( [userData objectForKey:@"location_latitude"] && ![[NSNull null] isEqual:[userData objectForKey:@"location_latitude"]] )
    {
        lastStatusLocation_latitude = [userData objectForKey:@"location_latitude"];
        lastStatusLocation_longitude = [userData objectForKey:@"location_longitude"];
    }
    
    if ( [userData objectForKey:@"birthday"] && ![[NSNull null] isEqual:[userData objectForKey:@"birthday"]] )
    {
        birthday = [userData objectForKey:@"birthday"];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            __block NSData *imageData;
            
            if ( DPHash.length > 0 )
            {
                NSURL *DPURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/userphotos/%@/profile/f_%@.jpg", SH_DOMAIN, userID, DPHash]];
                
                NSURLRequest *request = [NSURLRequest requestWithURL:DPURL];
                [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                    if ( data )
                    {
                        imageData = data;
                    }
                    else // Download failed.
                    {
                        DPHash = @""; // Clear the hash out so the manager attempts to redownload the image on the next launch.
                        
                        imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0);
                    }
                    
                    // Now, we might not need all the data we're inserting here, but it's necessary to make an exact copy
                    // of what any of the other users might look like, or else everything breaks...
                    NSDictionary *argsDict_currentUser = [NSDictionary dictionaryWithObjectsAndKeys:userID, @"user_id",
                                                          firstName, @"name_first",
                                                          lastName, @"name_last",
                                                          alias, @"alias",
                                                          userHandle, @"user_handle",
                                                          DPHash, @"dp_hash",
                                                          imageData, @"dp",
                                                          imageData_alias, @"alias_dp",
                                                          UIImageJPEGRepresentation(chatWallpaper, 1.0), @"chat_wallpaper",
                                                          lastStatusID, @"last_status_id",
                                                          email, @"email_address",
                                                          gender, @"gender",
                                                          birthday, @"birthday",
                                                          location_country, @"location_country",
                                                          location_state, @"location_state",
                                                          location_city, @"location_city",
                                                          website, @"website",
                                                          bio, @"bio",
                                                          facebookHandle, @"facebook_id",
                                                          twitterHandle, @"twitter_id",
                                                          instagramHandle, @"instagram_id",
                                                          joinDate, @"join_date",
                                                          [NSNumber numberWithInt:totalMessagesSent], @"total_messages_sent",
                                                          [NSNumber numberWithInt:totalMessagesReceived], @"total_messages_received",
                                                          [NSNumber numberWithInt:0], @"view_count",
                                                          [NSNumber numberWithInt:0], @"coordinate_x",
                                                          [NSNumber numberWithInt:0], @"coordinate_y",
                                                          [NSNumber numberWithFloat:0.0], @"rank_score", nil];
                    
                    [db executeUpdate:@"INSERT INTO sh_current_user "
                                        @"(user_id, name_first, name_last, user_handle, dp_hash, dp, chat_wallpaper, email_address, gender, birthday, location_country, location_state, location_city, website, bio, facebook_id, twitter_id, instagram_id, join_date, last_status_id, total_messages_sent, total_messages_received) "
                                        @"VALUES (:user_id, :name_first, :name_last, :user_handle, :dp_hash, :dp, :chat_wallpaper, :email_address, :gender, :birthday, :location_country, :location_state, :location_city, :website, :bio, :facebook_id, :twitter_id, :instagram_id, :join_date, :last_status_id, :total_messages_sent, :total_messages_received)"
                            withParameterDictionary:argsDict_currentUser];
                    
                    [db executeUpdate:@"INSERT INTO sh_cloud "
                                        @"(sh_user_id, name_first, name_last, alias, user_handle, dp_hash, dp, alias_dp, last_status_id, email_address, gender, birthday, location_country, location_state, location_city, website, bio, facebook_id, twitter_id, instagram_id, total_messages_sent, total_messages_received, view_count, coordinate_x, coordinate_y, rank_score) "
                                        @"VALUES (:user_id, :name_first, :name_last, :alias, :user_handle, :dp_hash, :dp, :alias_dp, :last_status_id, :email_address, :gender, :birthday, :location_country, :location_state, :location_city, :website, :bio, :facebook_id, :twitter_id, :instagram_id, :total_messages_sent, :total_messages_received, :view_count, :coordinate_x, :coordinate_y, :rank_score)"
                            withParameterDictionary:argsDict_currentUser];
                    
                    // Insert the phone numbers.
                    for ( NSDictionary *phoneNumberPack in [userData objectForKey:@"phone_numbers"] )
                    {
                        NSString *userCountryCallingCode = [phoneNumberPack objectForKey:@"country_calling_code"];
                        NSString *userPrefix = [phoneNumberPack objectForKey:@"prefix"];
                        NSString *userPhoneNumber = [phoneNumberPack objectForKey:@"phone_number"];
                        NSString *userPhoneNumberTimestamp = [phoneNumberPack objectForKey:@"timestamp"];
                        
                        NSDictionary *argsDict_phoneNumber = [NSDictionary dictionaryWithObjectsAndKeys:userCountryCallingCode, @"country_calling_code",
                                                              userPrefix, @"prefix",
                                                              userPhoneNumber, @"phone_number",
                                                              userPhoneNumberTimestamp, @"timestamp",
                                                              userID, @"user_id", nil];
                        
                        [db executeUpdate:@"INSERT INTO sh_phone_numbers "
                                            @"(country_calling_code, prefix, phone_number, timestamp, sh_user_id) "
                                            @"VALUES (:country_calling_code, :prefix, :phone_number, :timestamp, :user_id)"
                                withParameterDictionary:argsDict_phoneNumber];
                    }
                    
                    // Store the latest status update.
                    NSMutableDictionary *argsDict_status = [[NSDictionary dictionaryWithObjectsAndKeys:lastStatusID, @"thread_id",
                                                             userID, @"owner_id",
                                                             lastStatusOwnerType, @"owner_type",
                                                             lastStatus, @"message",
                                                             lastStatusType, @"thread_type",
                                                             lastStatusPrivacy, @"privacy",
                                                             lastStatusTimestamp, @"timestamp_sent",
                                                             lastStatusLocation_latitude, @"location_latitude",
                                                             lastStatusLocation_longitude, @"location_longitude",
                                                             lastStatusRootItemID, @"root_item_id",
                                                             lastStatusChildCount, @"child_count",
                                                             lastStatusUnreadMessageCount, @"unread_message_count",
                                                             lastStatusGroupID, @"group_id",
                                                             lastStatusStatus_sent, @"status_sent",
                                                             lastStatusStatus_delivered, @"status_delivered",
                                                             lastStatusStatus_read, @"status_read",
                                                             lastStatusTimestamp_delivered, @"timestamp_delivered",
                                                             lastStatusTimestamp_read, @"timestamp_read",
                                                             lastStatusMediaType, @"media_type",
                                                             lastStatusMediaFileSize, @"media_file_size",
                                                             lastStatusMediaLocalPath, @"media_local_path",
                                                             lastStatusMediaHash, @"media_hash",
                                                             lastStatusMediaData, @"media_data",
                                                             lastStatusMediaExtra, @"media_extra", nil] mutableCopy];
                    
                    if ( [lastStatusMediaExtra isKindOfClass:NSDictionary.class] )
                    {
                        NSData *mediaExtraData = [NSJSONSerialization dataWithJSONObject:lastStatusMediaExtra options:NSJSONWritingPrettyPrinted error:nil];
                        [argsDict_status setObject:mediaExtraData forKey:@"media_extra"];
                    }
                    
                    [db executeUpdate:@"INSERT INTO sh_thread "
                                        @"(thread_id, thread_type, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                                        @"VALUES (:thread_id, :thread_type, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent, :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                            withParameterDictionary:argsDict_status];
                    
                    // Save presence for the current user.
                    [db executeUpdate:@"INSERT INTO sh_user_online_status "
                                        @"(user_id, status, target_id, audience, timestamp) "
                                        @"VALUES (:user_id, 1, :presence_target, :audience, :timestamp)"
                            withParameterDictionary:@{@"user_id": userID,
                                                      @"presence_target": @"",
                                                      @"audience": [NSNumber numberWithInt:SHUserPresenceAudienceEveryone],
                                                      @"timestamp": [self dateTodayString]}];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [appDelegate refreshCurrentUserData];
                        [appDelegate.mainMenu.messagesView setCurrentWallpaper:chatWallpaper]; // Set the default wallpaper in the window.
                        [appDelegate.networkManager connect];
                    });
                }];
            }
            else
            {
                imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0);
                
                // Now, we might not need all the data we're inserting here, but it's necessary to make an exact copy
                // of what any of the other users might look like, or else everything breaks...
                NSDictionary *argsDict_currentUser = [NSDictionary dictionaryWithObjectsAndKeys:userID, @"user_id",
                                                      firstName, @"name_first",
                                                      lastName, @"name_last",
                                                      alias, @"alias",
                                                      userHandle, @"user_handle",
                                                      DPHash, @"dp_hash",
                                                      imageData, @"dp",
                                                      imageData_alias, @"alias_dp",
                                                      UIImageJPEGRepresentation(chatWallpaper, 1.0), @"chat_wallpaper",
                                                      lastStatusID, @"last_status_id",
                                                      email, @"email_address",
                                                      gender, @"gender",
                                                      birthday, @"birthday",
                                                      location_country, @"location_country",
                                                      location_state, @"location_state",
                                                      location_city, @"location_city",
                                                      website, @"website",
                                                      bio, @"bio",
                                                      facebookHandle, @"facebook_id",
                                                      twitterHandle, @"twitter_id",
                                                      instagramHandle, @"instagram_id",
                                                      joinDate, @"join_date",
                                                      [NSNumber numberWithInt:totalMessagesSent], @"total_messages_sent",
                                                      [NSNumber numberWithInt:totalMessagesReceived], @"total_messages_received",
                                                      [NSNumber numberWithInt:0], @"view_count",
                                                      [NSNumber numberWithInt:0], @"coordinate_x",
                                                      [NSNumber numberWithInt:0], @"coordinate_y",
                                                      [NSNumber numberWithFloat:0.0], @"rank_score", nil];
                
                [db executeUpdate:@"INSERT INTO sh_current_user "
                                    @"(user_id, name_first, name_last, user_handle, dp_hash, dp, chat_wallpaper, email_address, gender, birthday, location_country, location_state, location_city, website, bio, facebook_id, twitter_id, instagram_id, join_date, last_status_id, total_messages_sent, total_messages_received) "
                                    @"VALUES (:user_id, :name_first, :name_last, :user_handle, :dp_hash, :dp, :chat_wallpaper, :email_address, :gender, :birthday, :location_country, :location_state, :location_city, :website, :bio, :facebook_id, :twitter_id, :instagram_id, :join_date, :last_status_id, :total_messages_sent, :total_messages_received)"
                        withParameterDictionary:argsDict_currentUser];
                
                [db executeUpdate:@"INSERT INTO sh_cloud "
                                    @"(sh_user_id, name_first, name_last, alias, user_handle, dp_hash, dp, alias_dp, last_status_id, email_address, gender, birthday, location_country, location_state, location_city, website, bio, facebook_id, twitter_id, instagram_id, total_messages_sent, total_messages_received, view_count, coordinate_x, coordinate_y, rank_score) "
                                    @"VALUES (:user_id, :name_first, :name_last, :alias, :user_handle, :dp_hash, :dp, :alias_dp, :last_status_id, :email_address, :gender, :birthday, :location_country, :location_state, :location_city, :website, :bio, :facebook_id, :twitter_id, :instagram_id, :total_messages_sent, :total_messages_received, :view_count, :coordinate_x, :coordinate_y, :rank_score)"
                        withParameterDictionary:argsDict_currentUser];
                
                // Insert the phone numbers.
                for ( NSDictionary *phoneNumberPack in [userData objectForKey:@"phone_numbers"] )
                {
                    NSString *userCountryCallingCode = [phoneNumberPack objectForKey:@"country_calling_code"];
                    NSString *userPrefix = [phoneNumberPack objectForKey:@"prefix"];
                    NSString *userPhoneNumber = [phoneNumberPack objectForKey:@"phone_number"];
                    NSString *userPhoneNumberTimestamp = [phoneNumberPack objectForKey:@"timestamp"];
                    
                    NSDictionary *argsDict_phoneNumber = [NSDictionary dictionaryWithObjectsAndKeys:userCountryCallingCode, @"country_calling_code",
                                                          userPrefix, @"prefix",
                                                          userPhoneNumber, @"phone_number",
                                                          userPhoneNumberTimestamp, @"timestamp",
                                                          userID, @"user_id", nil];
                    
                    [db executeUpdate:@"INSERT INTO sh_phone_numbers "
                                        @"(country_calling_code, prefix, phone_number, timestamp, sh_user_id) "
                                        @"VALUES (:country_calling_code, :prefix, :phone_number, :timestamp, :user_id)"
                            withParameterDictionary:argsDict_phoneNumber];
                }
                
                // Store the latest status update.
                NSMutableDictionary *argsDict_status = [[NSDictionary dictionaryWithObjectsAndKeys:lastStatusID, @"thread_id",
                                                         userID, @"owner_id",
                                                         lastStatusOwnerType, @"owner_type",
                                                         lastStatus, @"message",
                                                         lastStatusType, @"thread_type",
                                                         lastStatusPrivacy, @"privacy",
                                                         lastStatusTimestamp, @"timestamp_sent",
                                                         lastStatusLocation_latitude, @"location_latitude",
                                                         lastStatusLocation_longitude, @"location_longitude",
                                                         lastStatusRootItemID, @"root_item_id",
                                                         lastStatusChildCount, @"child_count",
                                                         lastStatusUnreadMessageCount, @"unread_message_count",
                                                         lastStatusGroupID, @"group_id",
                                                         lastStatusStatus_sent, @"status_sent",
                                                         lastStatusStatus_delivered, @"status_delivered",
                                                         lastStatusStatus_read, @"status_read",
                                                         lastStatusTimestamp_delivered, @"timestamp_delivered",
                                                         lastStatusTimestamp_read, @"timestamp_read",
                                                         lastStatusMediaType, @"media_type",
                                                         lastStatusMediaFileSize, @"media_file_size",
                                                         lastStatusMediaLocalPath, @"media_local_path",
                                                         lastStatusMediaHash, @"media_hash",
                                                         lastStatusMediaData, @"media_data",
                                                         lastStatusMediaExtra, @"media_extra", nil] mutableCopy];
                
                NSData *mediaExtraData = [NSJSONSerialization dataWithJSONObject:lastStatusMediaExtra options:NSJSONWritingPrettyPrinted error:nil];
                [argsDict_status setObject:mediaExtraData forKey:@"media_extra"];
                
                [db executeUpdate:@"INSERT INTO sh_thread "
                                    @"(thread_id, thread_type, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                                    @"VALUES (:thread_id, :thread_type, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent, :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                        withParameterDictionary:argsDict_status];
                
                // Save presence for the current user.
                [db executeUpdate:@"INSERT INTO sh_user_online_status "
                                    @"(user_id, status, target_id, audience, timestamp) "
                                    @"VALUES (:user_id, 1, :presence_target, :audience, :timestamp)"
                        withParameterDictionary:@{@"user_id": userID,
                                                  @"presence_target": @"",
                                                  @"audience": [NSNumber numberWithInt:SHUserPresenceAudienceEveryone],
                                                  @"timestamp": [self dateTodayString]}];
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [appDelegate refreshCurrentUserData];
                    [appDelegate.mainMenu.messagesView setCurrentWallpaper:chatWallpaper]; // Set the default wallpaper in the window.
                    [appDelegate.networkManager connect];
                });
            }
        }];
    });
}

- (NSMutableDictionary *)refreshCurrentUserData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    
    NSString *accessToken = [appDelegate.credsKeychainItem objectForKey:(__bridge id)(kSecValueData)];
    NSString *accessTokenID = [[NSUserDefaults standardUserDefaults] stringForKey:@"SHSilphScope"];
    
    FMResultSet *s1 = [self executeQuery:@"SELECT * FROM sh_current_user"
                 withParameterDictionary:nil];
    
    // Read & store current user's data.
    while ( [s1 next] )
    {
        NSString *userHandle = [s1 stringForColumn:@"user_handle"];
        NSString *alias = @"";
        NSString *DPHash = [s1 stringForColumn:@"dp_hash"];
        NSData *DP = [s1 dataForColumn:@"dp"];
        NSString *aliasDP = @"";
        id chatWallpaper = [s1 dataForColumn:@"chat_wallpaper"];
        NSString *emailAddress = [s1 stringForColumn:@"email_address"];
        NSString *gender = [s1 stringForColumn:@"gender"];
        NSString *birthday = [s1 stringForColumn:@"birthday"];
        NSString *location_country = [s1 stringForColumn:@"location_country"];
        NSString *location_state = [s1 stringForColumn:@"location_state"];
        NSString *location_city = [s1 stringForColumn:@"location_city"];
        NSString *website = [s1 stringForColumn:@"website"];
        NSString *bio = [s1 stringForColumn:@"bio"];
        NSString *facebookHandle = [s1 stringForColumn:@"facebook_id"];
        NSString *twitterHandle = [s1 stringForColumn:@"twitter_id"];
        NSString *instagramHandle = [s1 stringForColumn:@"instagram_id"];
        NSString *lastStatusID = [s1 stringForColumn:@"last_status_id"];
        NSString *magicRunDate = [s1 stringForColumn:@"last_magic_run"];
        NSString *lastLocationCheck = [s1 stringForColumn:@"last_location_check"];
        NSString *lastMiniFeedRefresh = [s1 stringForColumn:@"last_mini_feed_refresh"];
        NSString *lastPasscodeUnlock = [s1 stringForColumn:@"last_passcode_unlock"];
        
        if ( !DPHash || DPHash.length == 0 )
        {
            DPHash = @"";
            DP = UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0);
        }
        
        if ( !userHandle )
        {
            userHandle = @"";
        }
        
        if ( !chatWallpaper )
        {
            chatWallpaper = @"";
        }
        
        if ( !emailAddress )
        {
            emailAddress = @"";
        }
        
        if ( !gender )
        {
            gender = @"";
        }
        
        if ( !birthday )
        {
            birthday = @"";
        }
        
        if ( !location_country )
        {
            location_country = @"";
        }
        
        if ( !location_state )
        {
            location_state = @"";
        }
        
        if ( !location_city )
        {
            location_city = @"";
        }
        
        if ( !website )
        {
            website = @"";
        }
        
        if ( !bio )
        {
            bio = @"";
        }
        
        if ( !facebookHandle )
        {
            facebookHandle = @"";
        }
        
        if ( !twitterHandle )
        {
            twitterHandle = @"";
        }
        
        if ( !instagramHandle )
        {
            instagramHandle = @"";
        }
        
        if ( !lastStatusID )
        {
            lastStatusID = @"";
        }
        
        if ( !lastStatusID )
        {
            lastStatusID = @"";
        }
        
        if ( !magicRunDate )
        {
            magicRunDate = @"";
        }
        
        if ( !lastLocationCheck )
        {
            lastLocationCheck = @"";
        }
        
        if ( !lastMiniFeedRefresh )
        {
            lastMiniFeedRefresh = @"";
        }
        
        if ( !lastPasscodeUnlock )
        {
            lastPasscodeUnlock = @"";
        }
        
        if ( accessToken )
        {
            [data setObject:accessToken forKey:@"access_token"];
        }
        
        if ( accessTokenID )
        {
            [data setObject:accessTokenID forKey:@"access_token_id"];
        }
        
        [data setObject:[s1 stringForColumn:@"user_id"] forKey:@"user_id"];
        [data setObject:[s1 stringForColumn:@"name_first"] forKey:@"name_first"];
        [data setObject:[s1 stringForColumn:@"name_last"] forKey:@"name_last"];
        [data setObject:userHandle forKey:@"user_handle"];
        [data setObject:alias forKey:@"alias"];
        [data setObject:DPHash forKey:@"dp_hash"];
        [data setObject:DP forKey:@"dp"];
        [data setObject:aliasDP forKey:@"alias_dp"];
        [data setObject:chatWallpaper forKey:@"chat_wallpaper"];
        [data setObject:emailAddress forKey:@"email_address"];
        [data setObject:gender forKey:@"gender"];
        [data setObject:birthday forKey:@"birthday"];
        [data setObject:location_country forKey:@"location_country"];
        [data setObject:location_state forKey:@"location_state"];
        [data setObject:location_city forKey:@"location_city"];
        [data setObject:website forKey:@"website"];
        [data setObject:bio forKey:@"bio"];
        [data setObject:facebookHandle forKey:@"facebook_id"];
        [data setObject:twitterHandle forKey:@"twitter_id"];
        [data setObject:instagramHandle forKey:@"instagram_id"];
        [data setObject:[s1 stringForColumn:@"join_date"] forKey:@"join_date"];
        [data setObject:lastStatusID forKey:@"last_status_id"];
        [data setObject:[NSNumber numberWithInt:[s1 intForColumn:@"total_messages_sent"]] forKey:@"total_messages_sent"];
        [data setObject:[NSNumber numberWithInt:[s1 intForColumn:@"total_messages_received"]] forKey:@"total_messages_received"];
        [data setObject:[NSNumber numberWithInt:[s1 intForColumn:@"unread_thread_count"]] forKey:@"unread_thread_count"];
        [data setObject:magicRunDate forKey:@"last_magic_run"];
        [data setObject:lastLocationCheck forKey:@"last_location_check"];
        [data setObject:lastMiniFeedRefresh forKey:@"last_mini_feed_refresh"];
        [data setObject:lastPasscodeUnlock forKey:@"last_passcode_unlock"];
    }
    
    [s1 close]; // Very important that you close this!
    
    if ( data.count > 0 )
    {
        // Add the user's phone numbers.
        NSMutableArray *phoneNumbers = [NSMutableArray array];
        
        FMResultSet *s2 = [self executeQuery:@"SELECT * FROM sh_phone_numbers WHERE sh_user_id = :sh_user_id ORDER BY timestamp DESC"
                   withParameterDictionary:@{@"sh_user_id": [data objectForKey:@"user_id"]}];
        
        while ( [s2 next] )
        {
            NSString *callingCode = [s2 stringForColumn:@"country_calling_code"];
            NSString *prefix = [s2 stringForColumn:@"prefix"];
            NSString *phoneNumber = [s2 stringForColumn:@"phone_number"];
            NSString *timestamp = [s2 stringForColumn:@"timestamp"];
            NSMutableDictionary *phoneNumberPack = [NSMutableDictionary dictionary];
            
            if ( callingCode )
            {
                [phoneNumberPack setObject:callingCode forKey:@"country_calling_code"];
            }
            
            if ( prefix )
            {
                [phoneNumberPack setObject:prefix forKey:@"prefix"];
            }
            
            if ( phoneNumber )
            {
                [phoneNumberPack setObject:phoneNumber forKey:@"phone_number"];
            }
            
            if ( timestamp )
            {
                [phoneNumberPack setObject:timestamp forKey:@"timestamp"];
            }
            
            [phoneNumbers addObject:phoneNumberPack];
        }
        
        [s2 close];
        
        [data setObject:phoneNumbers forKey:@"phone_numbers"];
    }
    
    [_results close];
    [_DB close];
    
    return data;
}

@end
