//
//  SHPresenceManager.m
//  Scapes
//
//  Created by MachOSX on 9/17/13.
//
//

#import "SHPresenceManager.h"

#import "AFHTTPRequestOperationManager.h"

@implementation SHPresenceManager

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        didNotifyDelegateOnlinePresence = NO;
        didNotifyDelegateOfflinePresence = NO;
        
        [self resetPresenceForAll];
    }
    
    return self;
}

- (void)resetPresenceForAll
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [db executeUpdate:@"UPDATE sh_user_online_status SET status = 1, timestamp = :timestamp"
                    withParameterDictionary:@{@"timestamp": @""}];
            
            [appDelegate.mainMenu.contactCloud updatePresenceWithDB:db];
        }];
    });
    
    // The UI updates are handled by the delegate.
}

- (void)refreshPresenceForAll
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/getallpresence", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        if ( responseData )
        {
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            if ( errorCode == 0 )
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
                    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                        for ( NSDictionary *presenceData in [responseData objectForKey:@"response"] )
                        {
                            [db executeUpdate:@"UPDATE sh_user_online_status "
                                                @"SET status = :status, target_id = :target_id, audience = :audience, masked = :masked, timestamp = :timestamp "
                                                @"WHERE user_id = :user_id"
                                withParameterDictionary:presenceData];
                        }
                        
                        [appDelegate.mainMenu.contactCloud updatePresenceWithDB:db];
                    }];
                });
            }
        }
        else // Some error occurred...
        {
            
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ( appDelegate.networkManager.reachabilityStatus != NotReachable ) // Retry.
        {
            // We need a slight delay here.
            long double delayInSeconds = 3.0;
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self refreshPresenceForAll];
            });
        }
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)fetchLatestPresenceForUserID:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[userID]
                                                                          forKeys:@[@"user_id"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/getuserpresence", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        if ( responseData )
        {
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            if ( errorCode == 0 )
            {
                NSDictionary *presenceData = [responseData objectForKey:@"response"];
                NSString *presence = [presenceData objectForKey:@"status"];
                NSString *presenceTarget = [presenceData objectForKey:@"target_id"];
                NSString *presenceAudience = [presenceData objectForKey:@"audience"];
                NSString *presenceMasked = [presenceData objectForKey:@"masked"];
                NSString *presenceTimestamp = [presenceData objectForKey:@"timestamp"];
                
                [appDelegate.mainMenu.messagesView didFetchPresenceForCurrentRecipient:presenceData];
                
                NSDictionary *argsDict_presence = [NSDictionary dictionaryWithObjectsAndKeys:userID, @"user_id",
                                                   presence, @"status",
                                                   presenceTarget, @"target_id",
                                                   presenceAudience, @"audience",
                                                   presenceMasked, @"masked",
                                                   presenceTimestamp, @"timestamp", nil];
                
                [appDelegate.modelManager executeUpdate:@"UPDATE sh_user_online_status "
                                                        @"SET status = :status, target_id = :target_id, audience = :audience, masked = :masked, timestamp = :timestamp "
                                                        @"WHERE user_id = :user_id"
                                withParameterDictionary:argsDict_presence];
            }
            else if ( errorCode == 66 ) // Blocked by this person.
            {
                NSString *presence = [NSString stringWithFormat:@"%d", SHUserPresenceOfflineMasked];
                NSString *presenceTarget = @"-1";
                NSString *presenceAudience = [NSString stringWithFormat:@"%d", SHUserPresenceAudienceEveryone];
                NSString *presenceMasked = @"1";
                NSString *presenceTimestamp = [appDelegate.modelManager dateTodayString];
                
                NSDictionary *argsDict_presence = [NSDictionary dictionaryWithObjectsAndKeys:userID, @"user_id",
                                                   presence, @"status",
                                                   presenceTarget, @"target_id",
                                                   presenceAudience, @"audience",
                                                   presenceMasked, @"masked",
                                                   presenceTimestamp, @"timestamp", nil];
                
                [appDelegate.mainMenu.messagesView didFetchPresenceForCurrentRecipient:argsDict_presence];
                
                [appDelegate.modelManager executeUpdate:@"UPDATE sh_user_online_status "
                                                        @"SET status = :status, target_id = :target_id, audience = :audience, masked = :masked, timestamp = :timestamp "
                                                        @"WHERE user_id = :user_id"
                                withParameterDictionary:argsDict_presence];
            }
        }
        else // Some error occurred...
        {
            
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ( appDelegate.networkManager.reachabilityStatus != NotReachable ) // Retry.
        {
            // We need a slight delay here.
            long double delayInSeconds = 3.0;
            
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self fetchLatestPresenceForUserID:userID];
            });
        }
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)setAway
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [appDelegate beginBackgroundUpdateTask];
        [self setPresence:SHUserPresenceAway withTargetID:@"-1" forAudience:SHUserPresenceAudienceEveryone];
    });
}

- (void)setPresence:(SHUserPresence)presence withTargetID:(NSString *)targetID forAudience:(SHUserPresenceAudience)audience
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( appDelegate.networkManager.networkState == SHNetworkStateConnected )
    {
        if ( presence == SHUserPresenceOffline || presence == SHUserPresenceOfflineMasked )
        {
            [appDelegate.networkManager disconnect];
        }
        else
        {
            if ( (presence == SHUserPresenceOnline || presence == SHUserPresenceOnlineMasked) &&
                appDelegate.networkManager.networkState == SHNetworkStateConnected ) // User is returning from being away.
            {
                [appDelegate.messageManager fetchUnreadMessages];
            }
            
            if ( appDelegate.networkManager.networkState == SHNetworkStateConnected ) // Don't bother unless the socket is connected.
            {
                NSString *presenceValue = [NSString stringWithFormat:@"%d", presence];
                NSString *audienceValue = [NSString stringWithFormat:@"%d", audience];
                NSString *masked = @"0";
                
                if ( !appDelegate.preference_Talking )
                {
                    masked = @"1";
                }
                
                NSMutableDictionary *status = [[NSMutableDictionary alloc] initWithObjects:@[@"presence",
                                                                                             @{@"presence": presenceValue,
                                                                                               @"target_id": targetID,
                                                                                               @"audience": audienceValue,
                                                                                               @"masked": masked}]
                                                                                   forKeys:@[@"messageType", @"messageValue"]];
                
                [appDelegate.networkManager sendServerMessageWithPayload:status];
            }
        }
    }
}

- (void)currentUserPresenceChanged
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *timeNow = [appDelegate.modelManager dateTodayString];
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            if ( appDelegate.networkManager.networkState == SHNetworkStateConnected )
            {
                if ( !didNotifyDelegateOnlinePresence )
                {
                    didNotifyDelegateOnlinePresence = YES;
                    didNotifyDelegateOfflinePresence = NO;
                    
                    [db executeUpdate:@"UPDATE sh_user_online_status "
                                        @"SET status = 2, timestamp = :timestamp WHERE user_id = :current_user_id"
                            withParameterDictionary:@{@"current_user_id": [appDelegate.currentUser objectForKey:@"user_id"],
                                                      @"timestamp": timeNow}];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [self refreshPresenceForAll];
                        [appDelegate.messageManager fetchUnreadMessages];
                        [self currentUserPresenceDidChange];
                    });
                }
            }
            else
            {
                if ( !didNotifyDelegateOfflinePresence ) // Only notify the delegate once per presence change (in case of continuous reconnection attempts).
                {
                    didNotifyDelegateOnlinePresence = NO;
                    didNotifyDelegateOfflinePresence = YES;
                    
                    [db executeUpdate:@"UPDATE sh_user_online_status "
                                        @"SET status = 1, timestamp = :timestamp WHERE user_id = :current_user_id"
                            withParameterDictionary:@{@"current_user_id": [appDelegate.currentUser objectForKey:@"user_id"],
                                                            @"timestamp": timeNow}];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [self resetPresenceForAll];
                        [self currentUserPresenceDidChange];
                    });
                }
            }
        }];
    });
}

- (void)presenceChanged:(SHUserPresence)presence forUserID:(NSString *)userID withTargetID:(NSString *)targetID forAudience:(SHUserPresenceAudience)audience
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( !targetID )
    {
        targetID = @"-1";
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *timeNow = [appDelegate.modelManager dateTodayString];
        
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [db executeUpdate:@"UPDATE sh_user_online_status "
                                @"SET status = :presence, target_id = :target_id, audience = :audience, timestamp = :timestamp WHERE user_id = :user_id"
                    withParameterDictionary:@{@"user_id": userID,
                                              @"target_id": targetID,
                                              @"presence": [NSNumber numberWithInt:presence],
                                              @"audience": [NSNumber numberWithInt:audience],
                                              @"timestamp": timeNow}];
            
            /*FMResultSet *s2 = [db executeQuery:@"SELECT * FROM sh_user_online_status WHERE user_id = :user_id"
                       withParameterDictionary:@{@"user_id": userID}];
            
            while ( [s2 next] )
            {
                NSString *presence = [s2 stringForColumn:@"status"];
                NSString *presenceTargetID = [s2 stringForColumn:@"target_id"];
                NSString *audience = [s2 stringForColumn:@"audience"];
            }
            
            [s2 close];*/
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self presenceDidChange:presence forUserID:userID withTargetID:targetID forAudience:audience];
            });
        }];
    });
}

#pragma mark -
#pragma mark SHPresenceManagerDelegate methods.

- (void)currentUserPresenceDidChange
{
    if ( [_delegate respondsToSelector:@selector(currentUserPresenceDidChange)] )
    {
        [_delegate currentUserPresenceDidChange];
    }
}

- (void)presenceDidChange:(SHUserPresence)presence forUserID:(NSString *)userID withTargetID:(NSString *)targetID forAudience:(SHUserPresenceAudience)audience
{
    if ( [_delegate respondsToSelector:@selector(presenceDidChange:forUserID:withTargetID:forAudience:)] )
    {
        [_delegate presenceDidChange:presence forUserID:userID withTargetID:targetID forAudience:audience];
    }
}

@end
