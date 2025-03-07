//
//  SHMessageManager.m
//  Scapes
//
//  Created by MachOSX on 9/17/13.
//
//

#import "SHMessageManager.h"

#import <Audiotoolbox/AudioToolbox.h>

#import "AFHTTPRequestOperationManager.h"
#import "SHMessageTimer.h"
#import "Sound.h"

@implementation SHMessageManager

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        messageQueue = [NSMutableArray array];
        
        if ( appDelegate.SHToken && appDelegate.SHToken.length > 0 )
        {
            [self setup];
        }
    }
    
    return self;
}

- (void)setup
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inDatabase:^(FMDatabase *db) {
            // Delete any stale ad hoc messages.
            FMResultSet *s1 = [db executeQuery:@"SELECT thread_id FROM sh_thread "
                               @"WHERE temp = 1"
                       withParameterDictionary:nil];
            
            while ( [s1 next] )
            {
                NSString *staleThreadID = [s1 stringForColumnIndex:0];
                
                [db executeUpdate:@"DELETE FROM sh_message_dispatch "
                 @"WHERE thread_id = :thread_id"
          withParameterDictionary:@{@"thread_id": staleThreadID}];
                
                [db executeUpdate:@"DELETE FROM sh_thread "
                 @"WHERE thread_id = :thread_id AND temp = 1"
          withParameterDictionary:@{@"thread_id": staleThreadID}];
            }
            
            [s1 close];
        }];
        
        [self updateUnreadThreadCount];
        [self acknowledgeLateDelivery];
    });
}

- (void)fetchUnreadMessages
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/getlatestmessages", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                        NSMutableSet *potentiallyNewContacts = [NSMutableSet set];
                        NSMutableArray *threads = [[[responseData objectForKey:@"response"] objectForKey:@"threads"] mutableCopy];
                        NSString *unreadThreadCount = [[responseData objectForKey:@"response"] objectForKey:@"unread_thread_count"];
                        BOOL shouldVibrate = NO;
                        
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            // Update the app's icon badge count.
                            _unreadThreadCount = [unreadThreadCount intValue];
                            [appDelegate.currentUser setObject:unreadThreadCount forKey:@"unread_thread_count"];
                            
                            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:_unreadThreadCount];
                            [appDelegate.mainMenu updateUnreadBadge:_unreadThreadCount];
                        });
                        
                        for ( int i = 0; i < threads.count; i++ )
                        {
                            NSMutableDictionary *messageData = [[threads objectAtIndex:i] mutableCopy];
                            NSString *threadID = [messageData objectForKey:@"thread_id"];
                            NSString *ownerID = [messageData objectForKey:@"owner_id"];
                            BOOL delivered = [[messageData objectForKey:@"status_delivered"] boolValue];
                            // The media_extra data needs to be converted into a dictionary in a separate step.
                            NSDictionary *mediaExtra = [NSJSONSerialization JSONObjectWithData:[[messageData objectForKey:@"media_extra"] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
                            BOOL shouldSkip = NO;
                            
                            if ( mediaExtra )
                            {
                                [messageData setObject:mediaExtra forKey:@"media_extra"];
                            }
                            
                            BOOL isBlocked = [appDelegate.contactManager isBlocked:ownerID withDB:db];
                            
                            if ( isBlocked ) // Message from a blocked contact. Ignore it.
                            {
                                shouldSkip = YES;
                                
                                [threads removeObjectAtIndex:i];
                                i--; // Backtrack!
                            }
                            
                            if ( !isBlocked )
                            {
                                FMResultSet *s1= [db executeQuery:@"SELECT COUNT(*) FROM sh_thread "
                                                                    @"WHERE thread_id = :thread_id"
                                          withParameterDictionary:@{@"thread_id": threadID}];
                                
                                while ( [s1 next] )
                                {
                                    int count = [s1 intForColumnIndex:0];
                                    
                                    if ( count > 0 ) // Thread is already stored. Move on to the next one.
                                    {
                                        shouldSkip = YES;
                                        
                                        if ( !delivered )
                                        {
                                            // Mark it as delivered.
                                            [appDelegate.messageManager acknowledgeDeliveryForMessage:threadID toOwnerID:ownerID];
                                        }
                                        
                                        [threads removeObjectAtIndex:i];
                                        i--; // Backtrack!
                                    }
                                    else
                                    {
                                        shouldVibrate = YES;
                                    }
                                }
                                
                                [s1 close];
                            }
                            
                            if ( !isBlocked )
                            {
                                [potentiallyNewContacts addObject:ownerID];
                            }
                            
                            if ( shouldSkip )
                            {
                                continue;
                            }
                            
                            [messageData setObject:[appDelegate.currentUser objectForKey:@"user_id"] forKey:@"recipient_id"]; // This field is missing here when fetched straight from the DB.
                            
                            if ( [[NSNull null] isEqual:[messageData objectForKey:@"timestamp_delivered"]] )
                            {
                                [messageData setObject:@"" forKey:@"timestamp_delivered"];
                            }
                            
                            if ( [[NSNull null] isEqual:[messageData objectForKey:@"timestamp_read"]] )
                            {
                                [messageData setObject:@"" forKey:@"timestamp_read"];
                            }
                            
                            [threads setObject:messageData atIndexedSubscript:i];
                        }
                        
                        for ( NSString *userID in potentiallyNewContacts )
                        {
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                [appDelegate.contactManager addUser:userID]; // Just in case this was a message from a non-contact, add this person.
                            });
                        }
                        
                        [self parseReceivedMessageBatch:threads withDB:db];
                        
                        if ( shouldVibrate )
                        {
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                if ( appDelegate.preference_Vibrate )
                                {
                                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); // Vibrate.
                                }
                                
                                if ( appDelegate.preference_Sounds ) // Play the sound effect.
                                {
                                    [Sound playSoundEffect:11];
                                }
                            });
                        }
                        
                        [db executeUpdate:@"UPDATE sh_current_user SET unread_thread_count = :unread_thread_count"
                            withParameterDictionary:@{@"unread_thread_count": unreadThreadCount}];
                        
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            [self startUnreadMessageCheckTimer];
                            
                            if ( appDelegate.mainMenu.didDownloadInitialFeed )
                            {
                                [appDelegate.mainMenu resumeMiniFeedRefreshCycle];
                            }
                            
                            if ( [NSString stringWithFormat:@"%@", appDelegate.mainMenu.messagesView.recipientID].length > 0 )
                            {
                                [self fetchLatestMessagesStateForUserID:appDelegate.mainMenu.messagesView.recipientID withIDInQueue:-1];
                            }
                        });
                    }];
                });
            }
            else if ( errorCode == 404 ) // We're up to date.
            {
                [self startUnreadMessageCheckTimer];
                
                if ( appDelegate.mainMenu.didDownloadInitialFeed )
                {
                    [appDelegate.mainMenu resumeMiniFeedRefreshCycle];
                }
                
                [appDelegate.currentUser setObject:@"0" forKey:@"unread_thread_count"];
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
                
                [appDelegate.modelManager executeUpdate:@"UPDATE sh_current_user "
                                                        @"SET unread_thread_count = :unread_thread_count"
                                withParameterDictionary:@{@"unread_thread_count": @"0"}];
                
                if ( [NSString stringWithFormat:@"%@", appDelegate.mainMenu.messagesView.recipientID].length > 0 )
                {
                    [self fetchLatestMessagesStateForUserID:appDelegate.mainMenu.messagesView.recipientID withIDInQueue:-1];
                }
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
                [self fetchUnreadMessages];
            });
        }
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)fetchLatestMessagesStateForUserID:(NSString *)userID withIDInQueue:(int64_t)pendingThreadID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[userID]
                                                                              forKeys:@[@"recipient_id"]];
        
        NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
        
        NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                     @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                     @"request": jsonString};
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/getlastmessagesbetweenusers", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                            NSDictionary *messageData = [responseData objectForKey:@"response"];
                            NSMutableArray *threads = [[messageData objectForKey:@"messages"] mutableCopy];
                            SHThreadPrivacy privacy = [[messageData objectForKey:@"privacy"] intValue];
                            BOOL foundCopyInQueue = NO; // For messages stuck in outbox.
                            
                            for ( int i = 0; i < threads.count; i++ )
                            {
                                NSMutableDictionary *messageData = [[threads objectAtIndex:i] mutableCopy];
                                NSString *threadID = [messageData objectForKey:@"thread_id"];
                                int64_t ownerID = [[messageData objectForKey:@"owner_id"] intValue];
                                NSString *message = [messageData objectForKey:@"message"];
                                NSString *timestampSent = [messageData objectForKey:@"timestamp_sent"];
                                NSString *location_latitude = [messageData objectForKey:@"location_latitude"];
                                NSString *location_longitude = [messageData objectForKey:@"location_longitude"];
                                int threadType = [[messageData objectForKey:@"thread_type"] intValue];
                                BOOL isBlocked = [appDelegate.contactManager isBlocked:[messageData objectForKey:@"owner_id"] withDB:db];
                                
                                if ( isBlocked )
                                {
                                    continue;
                                }
                                
                                [messageData setObject:@"1" forKey:@"entry_type"];
                                [messageData setObject:@"1" forKey:@"status_sent"];
                                [messageData setObject:@"-1" forKey:@"media_local_path"];
                                [messageData setObject:@"-1" forKey:@"media_data"];
                                
                                // The media_extra data needs to be converted into a dictionary in a separate step.
                                NSDictionary *mediaExtra = [NSJSONSerialization JSONObjectWithData:[[messageData objectForKey:@"media_extra"] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
                                
                                if ( mediaExtra )
                                {
                                    [messageData setObject:mediaExtra forKey:@"media_extra"];
                                }
                                
                                if ( [[NSNull null] isEqual:[messageData objectForKey:@"timestamp_delivered"]] )
                                {
                                    [messageData setObject:@"" forKey:@"timestamp_delivered"];
                                }
                                
                                if ( [[NSNull null] isEqual:[messageData objectForKey:@"timestamp_read"]] )
                                {
                                    [messageData setObject:@"" forKey:@"timestamp_read"];
                                }
                                
                                if ( [[NSNull null] isEqual:[messageData objectForKey:@"location_latitude"]] )
                                {
                                    location_latitude = @"";
                                    location_longitude = @"";
                                    
                                    [messageData setObject:location_latitude forKey:@"location_latitude"];
                                    [messageData setObject:location_longitude forKey:@"location_longitude"];
                                }
                                
                                // Check if the message is still stuck in the outbox.
                                for ( int i = 0; i < messageQueue.count; i++ )
                                {
                                    NSMutableDictionary *queuedMessageData = [messageQueue objectAtIndex:i];
                                    int64_t targetID = [[queuedMessageData objectForKey:@"thread_id"] intValue];
                                    int64_t targetOwnerID = [[queuedMessageData objectForKey:@"owner_id"] intValue];
                                    NSString *targetMessage = [queuedMessageData objectForKey:@"message"];
                                    NSString *targetTimestampSent = [queuedMessageData objectForKey:@"timestamp_sent"];
                                    
                                    if ( targetOwnerID == ownerID && [targetMessage isEqualToString:message] && [targetTimestampSent isEqualToString:timestampSent] )
                                    {
                                        if ( pendingThreadID == targetID )
                                        {
                                            foundCopyInQueue = YES;
                                        }
                                        
                                        [messageQueue removeObjectAtIndex:i]; // Clear it out.
                                        
                                        // Update the auto-generated ID & sent status so the message doesn't keep resending.
                                        [db executeUpdate:@"UPDATE sh_thread "
                                                            @"SET thread_id = :thread_id_new, status_sent = 1 "
                                                            @"WHERE thread_id = :generated_id"
                                            withParameterDictionary:@{@"thread_id_new": threadID,
                                                                      @"generated_id": [queuedMessageData objectForKey:@"thread_id"]}];
                                        
                                        [db executeUpdate:@"UPDATE sh_message_dispatch "
                                                            @"SET thread_id = :thread_id_new "
                                                            @"WHERE thread_id = :generated_id"
                                            withParameterDictionary:@{@"thread_id_new": threadID,
                                                                      @"generated_id": [queuedMessageData objectForKey:@"thread_id"]}];
                                        
                                        i--;
                                    }
                                }
                                
                                // First, check if the thread's already stored.
                                FMResultSet *s1 = [db executeQuery:@"SELECT COUNT(thread_id) FROM sh_thread WHERE thread_id = :thread_id OR (owner_id = :owner_id AND message = :message AND timestamp_sent = :timestamp_sent)"
                                           withParameterDictionary:@{@"thread_id": threadID,
                                                                     @"owner_id": [messageData objectForKey:@"owner_id"],
                                                                     @"message": [messageData objectForKey:@"message"],
                                                                     @"timestamp_sent": [messageData objectForKey:@"timestamp_sent"]}];
                                
                                int count = 0;
                                
                                while ( [s1 next] )
                                {
                                    count = [s1 intForColumnIndex:0];
                                }
                                
                                [s1 close];
                                
                                if ( count == 0 ) // Thread not stored locally yet.
                                {
                                    NSMutableDictionary *messageData_local = [messageData mutableCopy];
                                    
                                    if ( [[messageData objectForKey:@"media_extra"] isKindOfClass:NSDictionary.class] )
                                    {
                                        NSData *mediaExtraData = [NSJSONSerialization dataWithJSONObject:[messageData objectForKey:@"media_extra"] options:NSJSONWritingPrettyPrinted error:nil];
                                        [messageData_local setObject:mediaExtraData forKey:@"media_extra"];
                                    }
                                    
                                    [db executeUpdate:@"INSERT INTO sh_thread "
                                                        @"(thread_id, thread_type, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                                                        @"VALUES (:thread_id, :thread_type, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent, :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                                        withParameterDictionary:messageData_local];
                                    
                                    if ( threadType == 1 )
                                    {
                                        [db executeUpdate:@"INSERT INTO sh_message_dispatch "
                                                            @"(thread_id, sender_id, sender_type, recipient_id, timestamp) "
                                                            @"VALUES (:thread_id, :owner_id, :owner_type, :recipient_id, :timestamp_sent)"
                                            withParameterDictionary:messageData_local];
                                    }
                                }
                                else // Thread exists, update its metadata.
                                {
                                    NSMutableDictionary *messageData_local = [messageData mutableCopy];
                                    
                                    if ( [[messageData objectForKey:@"media_extra"] isKindOfClass:NSDictionary.class] )
                                    {
                                        NSData *mediaExtraData = [NSJSONSerialization dataWithJSONObject:[messageData objectForKey:@"media_extra"] options:NSJSONWritingPrettyPrinted error:nil];
                                        [messageData_local setObject:mediaExtraData forKey:@"media_extra"];
                                    }
                                    
                                    [db executeUpdate:@"UPDATE sh_thread "
                                                        @"SET thread_id = :thread_id, root_item_id = :root_item_id, child_count = :child_count, owner_id = :owner_id, owner_type = :owner_type, unread_message_count = :unread_message_count, privacy = :privacy, group_id = :group_id, status_sent = :status_sent, status_delivered = :status_delivered, status_read = :status_read, timestamp_sent = :timestamp_sent, timestamp_delivered = :timestamp_delivered, timestamp_read = :timestamp_read, message = :message, location_longitude = :location_longitude, location_latitude = :location_latitude, media_type = :media_type, media_hash = :media_hash "
                                                        @"WHERE thread_id = :thread_id"
                                        withParameterDictionary:messageData_local];
                                    
                                    [db executeUpdate:@"UPDATE sh_message_dispatch "
                                                        @"SET sender_id = :owner_id, recipient_id = :recipient_id "
                                                        @"WHERE thread_id = :thread_id"
                                        withParameterDictionary:messageData_local];
                                }
                                
                                [threads setObject:messageData atIndexedSubscript:i];
                            }
                            
                            if ( pendingThreadID != -1 && !foundCopyInQueue )
                            {
                                for ( int i = 0; i < messageQueue.count; i++ )
                                {
                                    NSMutableDictionary *messageData = [messageQueue objectAtIndex:i];
                                    int64_t targetID = [[messageData objectForKey:@"thread_id"] intValue];
                                    
                                    if ( targetID == pendingThreadID )
                                    {
                                        [messageQueue removeObjectAtIndex:i]; // The dispatcher will keep trying to resend the copy left in the queue, so remove it.
                                        
                                        break;
                                    }
                                }
                            }
                            
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                [self conversation:userID privacyChanged:privacy];
                                [self messageManagerDidFetchMessageState:threads forUserID:userID];
                                [appDelegate.mainMenu.messagesView.initialMessagesFetchedIDs addObject:userID]; // Fetched this user's initial message state. Mark them.
                                
                                if ( pendingThreadID == -1 )
                                {
                                    [self dispatchAllMessagesForRecipient:userID]; // Attempt to send out any messages that previously failed to send.
                                }
                            });
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
                    [self fetchLatestMessagesStateForUserID:userID withIDInQueue:pendingThreadID];
                });
            }
            
            NSLog(@"Error: %@", operation.responseString);
        }];
    });
}

- (void)acknowledgeLateDelivery
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSString *currentUserID = [appDelegate.currentUser objectForKey:@"user_id"];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_thread "
                                            @"WHERE thread_type IN (1, 8) AND temp = 0 AND status_delivered = 0 AND owner_id <> :current_user_id"
                   withParameterDictionary:@{@"current_user_id": currentUserID}];
        
        while ( [s1 next])
        {
            NSString *threadID = [s1 stringForColumn:@"thread_id"];
            
            FMResultSet *s2 = [db executeQuery:@"SELECT recipient_id FROM sh_message_dispatch "
                                                @"WHERE thread_id = :thread_id"
                       withParameterDictionary:@{@"thread_id": threadID}];
            
            NSString *recipientID = @"";
            
            while ( [s2 next])
            {
                recipientID = @"";
            }
            
            [s2 close];
            
            if ( recipientID.length > 0 )
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [appDelegate.messageManager acknowledgeDeliveryForMessage:threadID toOwnerID:recipientID];
                });
            }
        }
        
        [s1 close];
    }];
}

/*
 *  Send out any messages that were in the message queue.
 *  You'll find any unsent messages here (because the client went
 *  offline, sending failure, etc.)
 */
- (void)dispatchAllMessagesForRecipient:(NSString *)recipientID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_thread "
                                                @"INNER JOIN sh_message_dispatch "
                                                @"ON sh_thread.thread_id = sh_message_dispatch.thread_id AND sh_thread.thread_type IN (1, 8) AND (sh_thread.status_sent = :flagValue_sendingFailed OR sh_thread.status_sent = :flagValue_sending) AND sh_thread.hidden = 0 AND sh_thread.temp = 0 AND sh_message_dispatch.sender_id = :current_user_id AND sh_message_dispatch.recipient_id = :recipient_id"
                       withParameterDictionary:@{@"current_user_id": [appDelegate.currentUser objectForKey:@"user_id"],
                                                 @"recipient_id": recipientID,
                                                 @"flagValue_sendingFailed": [NSNumber numberWithInt:SHThreadStatusSendingFailed],
                                                 @"flagValue_sending": [NSNumber numberWithInt:SHThreadStatusSending]}];
            
            while ( [s1 next] )
            {
                NSMutableDictionary *messageData = [[NSMutableDictionary alloc] initWithObjects:@[@"1",
                                                                                                  [s1 stringForColumn:@"thread_id"],
                                                                                                  [s1 stringForColumn:@"thread_type"],
                                                                                                  [s1 stringForColumn:@"root_item_id"],
                                                                                                  [s1 stringForColumn:@"child_count"],
                                                                                                  [s1 stringForColumn:@"owner_id"],
                                                                                                  [s1 stringForColumn:@"owner_type"],
                                                                                                  [s1 stringForColumn:@"group_id"],
                                                                                                  [s1 stringForColumn:@"unread_message_count"],
                                                                                                  [s1 stringForColumn:@"privacy"],
                                                                                                  [NSNumber numberWithInt:SHThreadStatusSendingFailed],
                                                                                                  [s1 stringForColumn:@"status_delivered"],
                                                                                                  [s1 stringForColumn:@"status_read"],
                                                                                                  [s1 stringForColumn:@"timestamp_sent"],
                                                                                                  [s1 stringForColumn:@"timestamp_delivered"],
                                                                                                  [s1 stringForColumn:@"timestamp_read"],
                                                                                                  [s1 stringForColumn:@"message"],
                                                                                                  [s1 stringForColumn:@"location_longitude"],
                                                                                                  [s1 stringForColumn:@"location_latitude"],
                                                                                                  [s1 stringForColumn:@"media_type"],
                                                                                                  [s1 stringForColumn:@"media_file_size"],
                                                                                                  [s1 stringForColumn:@"media_local_path"],
                                                                                                  [s1 stringForColumn:@"media_hash"],
                                                                                                  [s1 dataForColumn:@"media_data"],
                                                                                                  [s1 dataForColumn:@"media_extra"]]
                                                                                        forKeys:@[@"entry_type",
                                                                                                  @"thread_id",
                                                                                                  @"thread_type",
                                                                                                  @"root_item_id",
                                                                                                  @"child_count",
                                                                                                  @"owner_id",
                                                                                                  @"owner_type",
                                                                                                  @"group_id",
                                                                                                  @"unread_message_count",
                                                                                                  @"privacy",
                                                                                                  @"status_sent",
                                                                                                  @"status_delivered",
                                                                                                  @"status_read",
                                                                                                  @"timestamp_sent",
                                                                                                  @"timestamp_delivered",
                                                                                                  @"timestamp_read",
                                                                                                  @"message",
                                                                                                  @"location_longitude",
                                                                                                  @"location_latitude",
                                                                                                  @"media_type",
                                                                                                  @"media_file_size",
                                                                                                  @"media_local_path",
                                                                                                  @"media_hash",
                                                                                                  @"media_data",
                                                                                                  @"media_extra"]];
                
                SHUserPresenceAudience audience = SHUserPresenceAudienceEveryone;
                SHThreadPrivacy privacy = [[s1 stringForColumn:@"privacy"] intValue];
                
                if ( privacy == SHThreadPrivacyPrivate )
                {
                    audience = SHUserPresenceAudienceRecipient;
                }
                else
                {
                    if ( !appDelegate.preference_Talking )
                    {
                        audience = SHUserPresenceAudienceRecipient;
                    }
                }
                
                FMResultSet *s2 = [db executeQuery:@"SELECT recipient_id FROM sh_message_dispatch "
                                                    @"WHERE thread_id = :thread_id"
                           withParameterDictionary:@{@"thread_id": [messageData objectForKey:@"thread_id"]}];
                
                while ( [s2 next] )
                {
                    [messageData setObject:[s2 stringForColumnIndex:0] forKey:@"recipient_id"];
                }
                
                [s2 close];
                
                BOOL shouldResend = YES;
                
                // Check if this message is still stuck in the outbox before attempting to resend it.
                if ( [self messageExistsInQueue:[messageData objectForKey:@"thread_id"]] )
                {
                    shouldResend = NO;
                }
                
                if ( shouldResend )
                {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        // Don't add the message to the queue here. The dispatcher does that later.
                        [self dispatchMessage:messageData forAudience:audience];
                    });
                }
            }
            
            [s1 close];
        }];
    });
}

- (BOOL)messageExistsInQueue:(NSString *)messageID
{
    for ( int i = 0; i < messageQueue.count; i++ )
    {
        NSMutableDictionary *queuedMessageData = [messageQueue objectAtIndex:i];
        int64_t targetID = [[queuedMessageData objectForKey:@"thread_id"] intValue];
        
        if ( targetID == [messageID intValue] )
        {
            return YES;
        }
    }
    
    return NO;
}

- (void)clearMessageQueue
{
    [messageQueue removeAllObjects];
}

- (void)parseReceivedMessage:(NSDictionary *)messageData shouldVibrate:(BOOL)vibrate withDB:(FMDatabase *)db
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( [appDelegate.contactManager isBlocked:[messageData objectForKey:@"owner_id"] withDB:db] ) // Message from a blocked contact. Ignore it.
    {
        return;
    }
    
    if ( db )
    {
        NSMutableDictionary *messageData_mutable = [messageData mutableCopy];
        NSString *threadID = [messageData objectForKey:@"thread_id"];
        NSString *ownerID = [messageData objectForKey:@"owner_id"];
        [messageData_mutable setObject:@"1" forKey:@"entry_type"];
        [messageData_mutable setObject:@"0" forKey:@"media_not_found"];
        [messageData_mutable setObject:@"1" forKey:@"status_delivered"];
        [messageData_mutable setObject:@"-1" forKey:@"media_local_path"];
        [messageData_mutable setObject:@"-1" forKey:@"media_data"]; // Download & save this media when viewed in the conversation.
        BOOL mediaExtraContainsDictionary = NO;
        
        if ( [[messageData_mutable objectForKey:@"media_extra"] isKindOfClass:NSDictionary.class] )
        {
            NSMutableDictionary *mediaExtra = [[messageData_mutable objectForKey:@"media_extra"] mutableCopy];
            mediaExtraContainsDictionary = YES;
            
            // Insert the DP of the message sender. No need in the case of a venue though.
            if ( [[mediaExtra objectForKey:@"attachment_type"] isEqualToString:@"location"] && [[mediaExtra objectForKey:@"attachment_value"] isEqualToString:@"current_location"] )
            {
                FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :user_id"
                           withParameterDictionary:@{@"user_id": ownerID}];
                
                while ( [s1 next] )
                {
                    NSData *DP = [s1 dataForColumn:@"alias_dp"];
                    
                    UIImage *currentDP = [UIImage imageWithData:DP];
                    
                    if ( !currentDP )
                    {
                        DP = [s1 dataForColumn:@"dp"];
                    }
                    
                    NSString *base64_userThumbnail = [DP base64Encoding];
                    NSMutableDictionary *attachmentData = [[mediaExtra objectForKey:@"attachment"] mutableCopy];
                    
                    if ( attachmentData )
                    {
                        [attachmentData setObject:base64_userThumbnail forKey:@"user_thumbnail"];
                    }
                    else
                    {
                        attachmentData = [@{@"user_thumbnail": base64_userThumbnail} mutableCopy];
                    }
                    
                    [mediaExtra setObject:attachmentData forKey:@"attachment"];
                }
                
                [s1 close];
            }
            
            NSData *data = [NSJSONSerialization dataWithJSONObject:mediaExtra options:NSJSONWritingPrettyPrinted error:nil];
            [messageData_mutable setObject:data forKey:@"media_extra"];
        }
        
        [db executeUpdate:@"INSERT INTO sh_thread "
                            @"(thread_id, thread_type, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                            @"VALUES (:thread_id, :thread_type, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent, :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                withParameterDictionary:messageData_mutable];
        
        [db executeUpdate:@"INSERT INTO sh_message_dispatch "
                            @"(thread_id, sender_id, sender_type, recipient_id, timestamp) "
                            @"VALUES (:thread_id, :owner_id, :owner_type, :recipient_id, :timestamp_sent)"
                withParameterDictionary:messageData_mutable];
        
        if ( mediaExtraContainsDictionary )
        {
            NSDictionary *attachmentData = [NSJSONSerialization JSONObjectWithData:[messageData_mutable objectForKey:@"media_extra"] options:NSJSONReadingAllowFragments error:nil];
            [messageData_mutable setObject:attachmentData forKey:@"media_extra"];
        }
        
        [self messageManagerDidReceiveMessage:messageData_mutable];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if ( vibrate )
            {
                if ( appDelegate.preference_Vibrate )
                {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); // Vibrate.
                }
                
                if ( appDelegate.preference_Sounds ) // Play the sound effect.
                {
                    [Sound playSoundEffect:11];
                }
            }
            
            [appDelegate.contactManager addUser:ownerID]; // Just in case this was a message from a non-contact, follow this person.
        });
        
        [self acknowledgeDeliveryForMessage:threadID toOwnerID:ownerID];
        
        // Count of all messages ever received.
        FMResultSet *s1 = [db executeQuery:@"SELECT total_messages_received FROM sh_cloud WHERE sh_user_id = :user_id"
                   withParameterDictionary:@{@"user_id": ownerID}];
        
        int totalMessagesReceivedCount = 0;
        
        while ( [s1 next] )
        {
            totalMessagesReceivedCount = [s1 intForColumnIndex:0] + 1;
        }
        
        [s1 close];
        
        s1 = [db executeQuery:@"SELECT total_messages_received FROM sh_current_user WHERE user_id = :user_id"
                    withParameterDictionary:@{@"user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
        
        int globalMessagesReceivedCount = 0;
        
        while ( [s1 next] )
        {
            globalMessagesReceivedCount = [s1 intForColumnIndex:0] + 1;
        }
        
        [s1 close];
        
        // Update all counts.
        [db executeUpdate:@"UPDATE sh_cloud "
                            @"SET total_messages_received = :total_messages_received "
                            @"WHERE sh_user_id = :user_id"
                withParameterDictionary:@{@"total_messages_received": [NSNumber numberWithInt:totalMessagesReceivedCount],
                                          @"user_id": ownerID}];
        
        [db executeUpdate:@"UPDATE sh_current_user "
                            @"SET total_messages_received = :total_messages_received"
                withParameterDictionary:@{@"total_messages_received": [NSNumber numberWithInt:globalMessagesReceivedCount]}];
        
        [appDelegate.currentUser setObject:[NSNumber numberWithInt:globalMessagesReceivedCount] forKey:@"total_messages_received"];
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
            [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                NSMutableDictionary *messageData_mutable = [messageData mutableCopy];
                NSString *threadID = [messageData objectForKey:@"thread_id"];
                NSString *ownerID = [messageData objectForKey:@"owner_id"];
                [messageData_mutable setObject:@"1" forKey:@"entry_type"];
                [messageData_mutable setObject:@"0" forKey:@"media_not_found"];
                [messageData_mutable setObject:@"1" forKey:@"status_delivered"];
                [messageData_mutable setObject:@"-1" forKey:@"media_local_path"];
                [messageData_mutable setObject:@"-1" forKey:@"media_data"]; // Download & save this media when viewed in the conversation.
                BOOL mediaExtraContainsDictionary = NO;
                
                if ( [[messageData_mutable objectForKey:@"media_extra"] isKindOfClass:NSDictionary.class] )
                {
                    NSMutableDictionary *mediaExtra = [[messageData_mutable objectForKey:@"media_extra"] mutableCopy];
                    mediaExtraContainsDictionary = YES;
                    
                    // Insert the DP of the message sender. No need in the case of a venue though.
                    if ( [[mediaExtra objectForKey:@"attachment_type"] isEqualToString:@"location"] && [[mediaExtra objectForKey:@"attachment_value"] isEqualToString:@"current_location"] )
                    {
                        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :user_id"
                                   withParameterDictionary:@{@"user_id": ownerID}];
                        
                        while ( [s1 next] )
                        {
                            NSData *DP = [s1 dataForColumn:@"alias_dp"];
                            
                            UIImage *currentDP = [UIImage imageWithData:DP];
                            
                            if ( !currentDP )
                            {
                                DP = [s1 dataForColumn:@"dp"];
                            }
                            
                            NSString *base64_userThumbnail = [DP base64Encoding];
                            NSMutableDictionary *attachmentData = [[mediaExtra objectForKey:@"attachment"] mutableCopy];
                            
                            if ( attachmentData )
                            {
                                [attachmentData setObject:base64_userThumbnail forKey:@"user_thumbnail"];
                            }
                            else
                            {
                                attachmentData = [@{@"user_thumbnail": base64_userThumbnail} mutableCopy];
                            }
                            
                            [mediaExtra setObject:attachmentData forKey:@"attachment"];
                        }
                        
                        [s1 close];
                    }
                    
                    NSData *data = [NSJSONSerialization dataWithJSONObject:mediaExtra options:NSJSONWritingPrettyPrinted error:nil];
                    [messageData_mutable setObject:data forKey:@"media_extra"];
                }
                
                [db executeUpdate:@"INSERT INTO sh_thread "
                                    @"(thread_id, thread_type, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                                    @"VALUES (:thread_id, :thread_type, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent, :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                        withParameterDictionary:messageData_mutable];
                
                [db executeUpdate:@"INSERT INTO sh_message_dispatch "
                                    @"(thread_id, sender_id, sender_type, recipient_id, timestamp) "
                                    @"VALUES (:thread_id, :owner_id, :owner_type, :recipient_id, :timestamp_sent)"
                        withParameterDictionary:messageData_mutable];
                
                if ( mediaExtraContainsDictionary )
                {
                    NSDictionary *attachmentData = [NSJSONSerialization JSONObjectWithData:[messageData_mutable objectForKey:@"media_extra"] options:NSJSONReadingAllowFragments error:nil];
                    [messageData_mutable setObject:attachmentData forKey:@"media_extra"];
                }
                
                [self messageManagerDidReceiveMessage:messageData_mutable];
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    if ( vibrate )
                    {
                        if ( appDelegate.preference_Vibrate )
                        {
                            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate); // Vibrate.
                        }
                        
                        if ( appDelegate.preference_Sounds ) // Play the sound effect.
                        {
                            [Sound playSoundEffect:11];
                        }
                    }
                    
                    [appDelegate.contactManager addUser:ownerID]; // Just in case this was a message from a non-contact, follow this person.
                });
                
                [self acknowledgeDeliveryForMessage:threadID toOwnerID:ownerID];
                
                // Count of all messages ever received.
                FMResultSet *s1 = [db executeQuery:@"SELECT total_messages_received FROM sh_cloud WHERE sh_user_id = :user_id"
                           withParameterDictionary:@{@"user_id": ownerID}];
                
                int totalMessagesReceivedCount = 0;
                
                while ( [s1 next] )
                {
                    totalMessagesReceivedCount = [s1 intForColumnIndex:0] + 1;
                }
                
                [s1 close];
                
                s1 = [db executeQuery:@"SELECT total_messages_received FROM sh_current_user WHERE user_id = :user_id"
                            withParameterDictionary:@{@"user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
                
                int globalMessagesReceivedCount = 0;
                
                while ( [s1 next] )
                {
                    globalMessagesReceivedCount = [s1 intForColumnIndex:0] + 1;
                }
                
                [s1 close];
                
                // Update all counts.
                [db executeUpdate:@"UPDATE sh_cloud "
                                    @"SET total_messages_received = :total_messages_received "
                                    @"WHERE sh_user_id = :user_id"
                        withParameterDictionary:@{@"total_messages_received": [NSNumber numberWithInt:totalMessagesReceivedCount],
                                    @"user_id": ownerID}];
                
                [db executeUpdate:@"UPDATE sh_current_user "
                                    @"SET total_messages_received = :total_messages_received"
                        withParameterDictionary:@{@"total_messages_received": [NSNumber numberWithInt:globalMessagesReceivedCount]}];
                
                [appDelegate.currentUser setObject:[NSNumber numberWithInt:globalMessagesReceivedCount] forKey:@"total_messages_received"];
            }];
        });
    }
}

- (void)parseReceivedMessageBatch:(NSMutableArray *)messages withDB:(FMDatabase *)db
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    for ( int i = 0; i < messages.count; i++ )
    {
        if ( db )
        {
            NSMutableDictionary *messageData_mutable = [[messages objectAtIndex:i] mutableCopy];
            NSString *threadID = [messageData_mutable objectForKey:@"thread_id"];
            NSString *ownerID = [messageData_mutable objectForKey:@"owner_id"];
            [messageData_mutable setObject:@"1" forKey:@"entry_type"];
            [messageData_mutable setObject:@"0" forKey:@"media_not_found"];
            [messageData_mutable setObject:@"1" forKey:@"status_delivered"];
            [messageData_mutable setObject:@"-1" forKey:@"media_local_path"];
            [messageData_mutable setObject:@"-1" forKey:@"media_data"]; // Download & save this media when viewed in the conversation.
            BOOL mediaExtraContainsDictionary = NO;
            
            if ( [[messageData_mutable objectForKey:@"media_extra"] isKindOfClass:NSDictionary.class] )
            {
                NSMutableDictionary *mediaExtra = [[messageData_mutable objectForKey:@"media_extra"] mutableCopy];
                mediaExtraContainsDictionary = YES;
                
                // Insert the DP of the message sender. No need in the case of a venue though.
                if ( [[mediaExtra objectForKey:@"attachment_type"] isEqualToString:@"location"] && [[mediaExtra objectForKey:@"attachment_value"] isEqualToString:@"current_location"] )
                {
                    FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :user_id"
                               withParameterDictionary:@{@"user_id": ownerID}];
                    
                    while ( [s1 next] )
                    {
                        NSData *DP = [s1 dataForColumn:@"alias_dp"];
                        
                        UIImage *currentDP = [UIImage imageWithData:DP];
                        
                        if ( !currentDP )
                        {
                            DP = [s1 dataForColumn:@"dp"];
                        }
                        
                        NSString *base64_userThumbnail = [DP base64Encoding];
                        NSMutableDictionary *attachmentData = [[mediaExtra objectForKey:@"attachment"] mutableCopy];
                        
                        if ( attachmentData )
                        {
                            [attachmentData setObject:base64_userThumbnail forKey:@"user_thumbnail"];
                        }
                        else
                        {
                            attachmentData = [@{@"user_thumbnail": base64_userThumbnail} mutableCopy];
                        }
                        
                        [mediaExtra setObject:attachmentData forKey:@"attachment"];
                    }
                    
                    [s1 close];
                }
                
                NSData *data = [NSJSONSerialization dataWithJSONObject:mediaExtra options:NSJSONWritingPrettyPrinted error:nil];
                [messageData_mutable setObject:data forKey:@"media_extra"];
            }
            
            [db executeUpdate:@"INSERT INTO sh_thread "
                                @"(thread_id, thread_type, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                                @"VALUES (:thread_id, :thread_type, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent, :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                    withParameterDictionary:messageData_mutable];
            
            [db executeUpdate:@"INSERT INTO sh_message_dispatch "
                                @"(thread_id, sender_id, sender_type, recipient_id, timestamp) "
                                @"VALUES (:thread_id, :owner_id, :owner_type, :recipient_id, :timestamp_sent)"
                    withParameterDictionary:messageData_mutable];
            
            [self acknowledgeDeliveryForMessage:threadID toOwnerID:ownerID];
            
            if ( mediaExtraContainsDictionary )
            {
                NSDictionary *attachmentData = [NSJSONSerialization JSONObjectWithData:[messageData_mutable objectForKey:@"media_extra"] options:NSJSONReadingAllowFragments error:nil];
                [messageData_mutable setObject:attachmentData forKey:@"media_extra"];
            }
            
            [messages setObject:messageData_mutable atIndexedSubscript:i];
            
            // Count of all messages ever received.
            FMResultSet *s1 = [db executeQuery:@"SELECT total_messages_received FROM sh_cloud WHERE sh_user_id = :user_id"
                       withParameterDictionary:@{@"user_id": ownerID}];
            
            int totalMessagesReceivedCount = 0;
            
            while ( [s1 next] )
            {
                totalMessagesReceivedCount = [s1 intForColumnIndex:0] + 1;
            }
            
            [s1 close];
            
            s1 = [db executeQuery:@"SELECT total_messages_received FROM sh_current_user WHERE user_id = :user_id"
                        withParameterDictionary:@{@"user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
            
            int globalMessagesReceivedCount = 0;
            
            while ( [s1 next] )
            {
                globalMessagesReceivedCount = [s1 intForColumnIndex:0] + 1;
            }
            
            [s1 close];
            
            // Update all counts.
            [db executeUpdate:@"UPDATE sh_cloud "
                                @"SET total_messages_received = :total_messages_received "
                                @"WHERE sh_user_id = :user_id"
                    withParameterDictionary:@{@"total_messages_received": [NSNumber numberWithInt:totalMessagesReceivedCount],
                                @"user_id": ownerID}];
            
            [db executeUpdate:@"UPDATE sh_current_user "
                                @"SET total_messages_received = :total_messages_received"
                    withParameterDictionary:@{@"total_messages_received": [NSNumber numberWithInt:globalMessagesReceivedCount]}];
            
            [appDelegate.currentUser setObject:[NSNumber numberWithInt:globalMessagesReceivedCount] forKey:@"total_messages_received"];
        }
        else
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
                [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    NSMutableDictionary *messageData_mutable = [[messages objectAtIndex:i] mutableCopy];
                    NSString *threadID = [messageData_mutable objectForKey:@"thread_id"];
                    NSString *ownerID = [messageData_mutable objectForKey:@"owner_id"];
                    [messageData_mutable setObject:@"1" forKey:@"entry_type"];
                    [messageData_mutable setObject:@"0" forKey:@"media_not_found"];
                    [messageData_mutable setObject:@"1" forKey:@"status_delivered"];
                    [messageData_mutable setObject:@"-1" forKey:@"media_local_path"];
                    [messageData_mutable setObject:@"-1" forKey:@"media_data"]; // Download & save this media when viewed in the conversation.
                    BOOL mediaExtraContainsDictionary = NO;
                    
                    if ( [[messageData_mutable objectForKey:@"media_extra"] isKindOfClass:NSDictionary.class] )
                    {
                        NSMutableDictionary *mediaExtra = [[messageData_mutable objectForKey:@"media_extra"] mutableCopy];
                        mediaExtraContainsDictionary = YES;
                        
                        // Insert the DP of the message sender. No need in the case of a venue though.
                        if ( [[mediaExtra objectForKey:@"attachment_type"] isEqualToString:@"location"] && [[mediaExtra objectForKey:@"attachment_value"] isEqualToString:@"current_location"] )
                        {
                            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :user_id"
                                       withParameterDictionary:@{@"user_id": ownerID}];
                            
                            while ( [s1 next] )
                            {
                                NSData *DP = [s1 dataForColumn:@"alias_dp"];
                                
                                UIImage *currentDP = [UIImage imageWithData:DP];
                                
                                if ( !currentDP )
                                {
                                    DP = [s1 dataForColumn:@"dp"];
                                }
                                
                                NSString *base64_userThumbnail = [DP base64Encoding];
                                NSMutableDictionary *attachmentData = [[mediaExtra objectForKey:@"attachment"] mutableCopy];
                                
                                if ( attachmentData )
                                {
                                    [attachmentData setObject:base64_userThumbnail forKey:@"user_thumbnail"];
                                }
                                else
                                {
                                    attachmentData = [@{@"user_thumbnail": base64_userThumbnail} mutableCopy];
                                }
                                
                                [mediaExtra setObject:attachmentData forKey:@"attachment"];
                            }
                            
                            [s1 close];
                        }
                        
                        NSData *data = [NSJSONSerialization dataWithJSONObject:mediaExtra options:NSJSONWritingPrettyPrinted error:nil];
                        [messageData_mutable setObject:data forKey:@"media_extra"];
                    }
                    
                    [db executeUpdate:@"INSERT INTO sh_thread "
                                        @"(thread_id, thread_type, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                                        @"VALUES (:thread_id, :thread_type, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent, :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                            withParameterDictionary:messageData_mutable];
                    
                    [db executeUpdate:@"INSERT INTO sh_message_dispatch "
                                        @"(thread_id, sender_id, sender_type, recipient_id, timestamp) "
                                        @"VALUES (:thread_id, :owner_id, :owner_type, :recipient_id, :timestamp_sent)"
                            withParameterDictionary:messageData_mutable];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [appDelegate.contactManager addUser:ownerID]; // Just in case this was a message from a non-contact, follow this person.
                    });
                    
                    [self acknowledgeDeliveryForMessage:threadID toOwnerID:ownerID];
                    
                    if ( mediaExtraContainsDictionary )
                    {
                        NSDictionary *attachmentData = [NSJSONSerialization JSONObjectWithData:[messageData_mutable objectForKey:@"media_extra"] options:NSJSONReadingAllowFragments error:nil];
                        [messageData_mutable setObject:attachmentData forKey:@"media_extra"];
                    }
                    
                    [messages setObject:messageData_mutable atIndexedSubscript:i];
                    
                    // Count of all messages ever received.
                    FMResultSet *s1 = [db executeQuery:@"SELECT total_messages_received FROM sh_cloud WHERE sh_user_id = :user_id"
                               withParameterDictionary:@{@"user_id": ownerID}];
                    
                    int totalMessagesReceivedCount = 0;
                    
                    while ( [s1 next] )
                    {
                        totalMessagesReceivedCount = [s1 intForColumnIndex:0] + 1;
                    }
                    
                    [s1 close];
                    
                    s1 = [db executeQuery:@"SELECT total_messages_received FROM sh_current_user WHERE user_id = :user_id"
                                withParameterDictionary:@{@"user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
                    
                    int globalMessagesReceivedCount = 0;
                    
                    while ( [s1 next] )
                    {
                        globalMessagesReceivedCount = [s1 intForColumnIndex:0] + 1;
                    }
                    
                    [s1 close];
                    
                    // Update all counts.
                    [db executeUpdate:@"UPDATE sh_cloud "
                                        @"SET total_messages_received = :total_messages_received "
                                        @"WHERE sh_user_id = :user_id"
                            withParameterDictionary:@{@"total_messages_received": [NSNumber numberWithInt:totalMessagesReceivedCount],
                                        @"user_id": ownerID}];
                    
                    [db executeUpdate:@"UPDATE sh_current_user "
                                        @"SET total_messages_received = :total_messages_received"
                            withParameterDictionary:@{@"total_messages_received": [NSNumber numberWithInt:globalMessagesReceivedCount]}];
                    
                    [appDelegate.currentUser setObject:[NSNumber numberWithInt:globalMessagesReceivedCount] forKey:@"total_messages_received"];
                }];
            });
        }
    }
    
    [self messageManagerDidReceiveMessageBatch:messages];
}

- (void)parseReceivedAdHocMessage:(NSDictionary *)messageData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            NSMutableDictionary *messageData_mutable = [messageData mutableCopy];
            NSArray *originalParticipants = [messageData_mutable objectForKey:@"tag"];
            NSSet *tag = [NSSet setWithArray:originalParticipants];
            NSMutableArray *unknownParticipants = [NSMutableArray array];
            [messageData_mutable setObject:@"1" forKey:@"entry_type"];
            [messageData_mutable setObject:@"0" forKey:@"media_not_found"];
            [messageData_mutable setObject:@"-1" forKey:@"media_local_path"];
            [messageData_mutable setObject:@"-1" forKey:@"media_data"]; // Download & save this media when viewed in the conversation.
            
            if ( [[messageData_mutable objectForKey:@"media_extra"] isKindOfClass:NSDictionary.class] )
            {
                NSData *mediaExtraData = [NSJSONSerialization dataWithJSONObject:[messageData_mutable objectForKey:@"media_extra"] options:NSJSONWritingPrettyPrinted error:nil];
                [messageData_mutable setObject:mediaExtraData forKey:@"media_extra"];
            }
            
            // Use sorting to make the query order-insensitive.
            int original_user_1 = MIN([originalParticipants[0] intValue], [originalParticipants[1] intValue]);
            int original_user_2 = MAX([originalParticipants[0] intValue], [originalParticipants[1] intValue]);
            
            [messageData_mutable setObject:@"1" forKey:@"temp"];
            
            if ( [[originalParticipants objectAtIndex:0] intValue] == [[messageData_mutable objectForKey:@"owner_id"] intValue] ) // Don't set the sender as the receiver as well.
            {
                [messageData_mutable setObject:[originalParticipants objectAtIndex:1] forKey:@"recipient_id"];
            }
            else
            {
                [messageData_mutable setObject:[originalParticipants objectAtIndex:0] forKey:@"recipient_id"];
            }
            
            for ( NSString *participantID in [messageData_mutable objectForKey:@"participants"] )
            {
                // Check if the participant is already stored.
                FMResultSet *s1 = [db executeQuery:@"SELECT COUNT(sh_user_id) FROM sh_cloud WHERE sh_user_id = :sh_user_id"
                           withParameterDictionary:@{@"sh_user_id": participantID}];
                
                while ( [s1 next] )
                {
                    int count = [s1 intForColumnIndex:0];
                    
                    if ( count == 0 ) // If not, process them.
                    {
                        [unknownParticipants addObject:participantID];
                    }
                    else // Participant is a contact. Add them to the ad hoc table.
                    {
                        NSDictionary *argsDict_participant = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:original_user_1], @"original_user_1",
                                                              [NSNumber numberWithInt:original_user_2], @"original_user_2",
                                                              participantID, @"user_id", nil];
                        
                        [db executeUpdate:@"INSERT INTO sh_ad_hoc_conversation "
                                            @"(original_user_1, original_user_2, user_id) "
                                            @"VALUES (:original_user_1, :original_user_2, :user_id)"
                                withParameterDictionary:argsDict_participant];
                    }
                }
                
                [s1 close];
            }
            
            if ( unknownParticipants.count > 0 )
            {
                [appDelegate.contactManager downloadInfoForUsers:unknownParticipants conversationTag:tag];
            }
            
            [db executeUpdate:@"INSERT INTO sh_thread "
                                @"(thread_id, thread_type, temp, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                                @"VALUES (:thread_id, :thread_type, :temp, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent, :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                    withParameterDictionary:messageData_mutable];
            
            [db executeUpdate:@"INSERT INTO sh_message_dispatch "
                                @"(thread_id, sender_id, sender_type, recipient_id, timestamp) "
                                @"VALUES (:thread_id, :owner_id, :owner_type, :recipient_id, :timestamp_sent)"
                    withParameterDictionary:messageData_mutable];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self messageManagerDidReceiveAdHocMessage:messageData];
            });
        }];
    });
}

- (void)acknowledgeDeliveryForMessage:(NSString *)threadID toOwnerID:(NSString *)ownerID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDictionary *payload = @{@"thread_id": threadID,
                              @"owner_id": ownerID};
    
    NSMutableDictionary *message = [[NSMutableDictionary alloc] initWithObjects:@[@"IM_delivery",
                                                                                 payload]
                                                                       forKeys:@[@"messageType", @"messageValue"]];
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [appDelegate.networkManager sendServerMessageWithPayload:message];
    });
}

- (void)acknowledgeReadForMessage:(NSString *)threadID toOwnerID:(NSString *)ownerID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDictionary *payload = @{@"thread_id": threadID,
                              @"owner_id": ownerID};
    
    NSMutableDictionary *message = [[NSMutableDictionary alloc] initWithObjects:@[@"IM_read",
                                                                                  payload]
                                                                        forKeys:@[@"messageType", @"messageValue"]];
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [appDelegate.networkManager sendServerMessageWithPayload:message];
    });
}

- (void)dispatchMessage:(NSDictionary *)messageData forAudience:(SHUserPresenceAudience)audience
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSMutableDictionary *messageData_mutable = [messageData mutableCopy];
    NSString *threadID = [messageData_mutable objectForKey:@"thread_id"];
    NSString *recipientID = [messageData_mutable objectForKey:@"recipient_id"];
    
    // Check for an exisiting copy of this message still stuck in the outbox before attempting to resend it.
    if ( [self messageExistsInQueue:[messageData objectForKey:@"thread_id"]] )
    {
        return;
    }
    
    [messageData_mutable setObject:[NSNumber numberWithInt:audience] forKey:@"audience"];
    [messageData_mutable setObject:@"-1" forKey:@"media_data"]; // Don't fucking send this.
    [messageData_mutable removeObjectForKey:@"media_thumbnail"];
    
    if ( [[messageData_mutable objectForKey:@"media_extra"] isKindOfClass:NSData.class] )
    {
        NSMutableDictionary *mediaExtra = [[NSJSONSerialization JSONObjectWithData:[messageData_mutable objectForKey:@"media_extra"] options:NSJSONReadingAllowFragments error:nil] mutableCopy];
        
        if ( [[mediaExtra objectForKey:@"attachment_type"] isEqualToString:@"location"] )
        {
            NSMutableDictionary *attachmentData = [[mediaExtra objectForKey:@"attachment"] mutableCopy];
            
            if ( attachmentData )
            {
                [attachmentData setObject:@"" forKey:@"user_thumbnail"];
                [mediaExtra setObject:attachmentData forKey:@"attachment"];
            }
        }
        
        [messageData_mutable setObject:mediaExtra forKey:@"media_extra"];
    }
    
    SHMessageTimer *timer = [[SHMessageTimer alloc] initWithTimeout:MESSAGE_TIMEOUT repeat:NO completion:^
    {
        NSLog(@"Resending message...");
        [self resendMessage:threadID];
    } queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    [messageQueue addObject:messageData_mutable];
    [timer start];
    
    NSMutableDictionary *message = [[NSMutableDictionary alloc] initWithObjects:@[@"IM_send",
                                                                                  messageData_mutable]
                                                                        forKeys:@[@"messageType", @"messageValue"]];
    
    if ( appDelegate.networkManager.networkState == SHNetworkStateConnected )
    {
        [appDelegate.networkManager sendServerMessageWithPayload:message];
        
        // Count of all messages ever sent.
        FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT total_messages_sent FROM sh_cloud WHERE sh_user_id = :user_id"
                                         withParameterDictionary:@{@"user_id": recipientID}];
        
        int totalMessagesSentCount = 0;
        
        while ( [s1 next] )
        {
            totalMessagesSentCount = [s1 intForColumnIndex:0] + 1;
        }
        
        [s1 close];
        
        s1 = [appDelegate.modelManager executeQuery:@"SELECT total_messages_sent FROM sh_current_user WHERE user_id = :user_id"
                            withParameterDictionary:@{@"user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
        
        int globalMessagesSentCount = 0;
        
        while ( [s1 next] )
        {
            globalMessagesSentCount = [s1 intForColumnIndex:0] + 1;
        }
        
        [s1 close];
        [appDelegate.modelManager.results close];
        [appDelegate.modelManager.DB close];
        
        // Update all counts.
        [appDelegate.modelManager executeUpdate:@"UPDATE sh_cloud "
                                                @"SET total_messages_sent = :total_messages_sent "
                                                @"WHERE sh_user_id = :user_id"
                        withParameterDictionary:@{@"total_messages_sent": [NSNumber numberWithInt:totalMessagesSentCount],
                                                  @"user_id": recipientID}];
        
        [appDelegate.modelManager executeUpdate:@"UPDATE sh_current_user "
                                                @"SET total_messages_sent = :total_messages_sent"
                        withParameterDictionary:@{@"total_messages_sent": [NSNumber numberWithInt:globalMessagesSentCount]}];
        
        [appDelegate.currentUser setObject:[NSNumber numberWithInt:globalMessagesSentCount] forKey:@"total_messages_sent"];
    }
}

- (void)resendMessage:(NSString *)messageID
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for ( int i = 0; i < messageQueue.count; i++ )
        {
            NSMutableDictionary *messageData = [messageQueue objectAtIndex:i];
            int64_t threadID = [[messageData objectForKey:@"thread_id"] intValue];
            NSString *recipientID = [messageData objectForKey:@"recipient_id"];
            
            if ( threadID == messageID.intValue )
            {
                // We need to check with the server if it actually has a copy of this message before resending it.
                [self fetchLatestMessagesStateForUserID:recipientID withIDInQueue:threadID];
            }
        }
    });
}

- (void)dispatchStatus:(NSDictionary *)statusData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSMutableDictionary *statusData_mutable = [statusData mutableCopy];
    
    if ( [[statusData objectForKey:@"media_extra"] isKindOfClass:NSDictionary.class] )
    {
        // Convert the JSON dictionary into a string.
        NSData *jsonData_mediaExtra = [NSJSONSerialization dataWithJSONObject:[statusData objectForKey:@"media_extra"] options:kNilOptions error:nil];
        NSString *jsonString_mediaExtra = [[NSString alloc] initWithData:jsonData_mediaExtra encoding:NSUTF8StringEncoding];
        
        [statusData_mutable setObject:jsonString_mediaExtra forKey:@"media_extra"];
    }
    
    NSMutableDictionary *message = [[NSMutableDictionary alloc] initWithObjects:@[@"set_status",
                                                                                  statusData_mutable]
                                                                        forKeys:@[@"messageType", @"messageValue"]];
    
    [appDelegate.networkManager sendServerMessageWithPayload:message];
}

- (void)parseStatus:(NSDictionary *)statusData
{
    NSMutableDictionary *statusData_mutable = [statusData mutableCopy];
    [statusData_mutable setObject:@"1" forKey:@"entry_type"];
    
    [self messageManagerDidReceiveStatusUpdate:statusData_mutable];
}

- (void)updateThreadPrivacy:(SHThreadPrivacy)privacy forConversation:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDictionary *payload = @{@"privacy": [NSNumber numberWithInt:privacy],
                              @"recipient_id": userID};
    
    NSMutableDictionary *message = [[NSMutableDictionary alloc] initWithObjects:@[@"set_privacy",
                                                                                  payload]
                                                                        forKeys:@[@"messageType", @"messageValue"]];
    
    [appDelegate.networkManager sendServerMessageWithPayload:message];
}

- (void)conversation:(NSString *)userID privacyChanged:(SHThreadPrivacy)newPrivacy
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self conversation:userID privacyDidChange:newPrivacy];
    });
}

- (void)message:(NSDictionary *)messageData statusChanged:(SHThreadStatus)status
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            switch ( status )
            {
                case SHThreadStatusSent:
                {
                    NSMutableDictionary *message = [[NSMutableDictionary alloc] initWithObjects:@[[messageData objectForKey:@"owner_id"],
                                                                                                  [messageData objectForKey:@"generated_id"],
                                                                                                  [NSNumber numberWithInt:SHThreadStatusSent],
                                                                                                  [messageData objectForKey:@"thread_id"]]
                                                                                        forKeys:@[@"owner_id",
                                                                                                  @"generated_id",
                                                                                                  @"status_sent",
                                                                                                  @"thread_id"]];
                    
                    [db executeUpdate:@"UPDATE sh_thread "
                                        @"SET thread_id = :thread_id, status_sent = :status_sent "
                                        @"WHERE thread_id = :generated_id AND owner_id = :owner_id"
                            withParameterDictionary:message];
                    
                    [db executeUpdate:@"UPDATE sh_message_dispatch "
                                        @"SET thread_id = :thread_id "
                                        @"WHERE thread_id = :generated_id"
                            withParameterDictionary:message];
                    
                    for ( int i = 0; i < messageQueue.count; i++ )
                    {
                        NSMutableDictionary *targetDessageData = [messageQueue objectAtIndex:i];
                        int64_t generatedThreadID = [[targetDessageData objectForKey:@"thread_id"] intValue];
                        
                        if ( generatedThreadID == [[messageData objectForKey:@"generated_id"] intValue] )
                        {
                            [messageQueue removeObjectAtIndex:i];
                            
                            break;
                        }
                    }
                    
                    break;
                }
                    
                case SHThreadStatusDelivered:
                {
                    NSMutableDictionary *message = [[NSMutableDictionary alloc] initWithObjects:@[@"1",
                                                                                                  [messageData objectForKey:@"timestamp_delivered"],
                                                                                                  [messageData objectForKey:@"thread_id"]]
                                                                                        forKeys:@[@"status_delivered",
                                                                                                  @"timestamp_delivered",
                                                                                                  @"thread_id",]];
                    
                    [db executeUpdate:@"UPDATE sh_thread "
                                        @"SET status_delivered = :status_delivered, timestamp_delivered = :timestamp_delivered "
                                        @"WHERE thread_id = :thread_id"
                            withParameterDictionary:message];
                    
                    break;
                }
                    
                case SHThreadStatusRead:
                {
                    NSMutableDictionary *message = [[NSMutableDictionary alloc] initWithObjects:@[@"1",
                                                                                                  [messageData objectForKey:@"timestamp_read"],
                                                                                                  [messageData objectForKey:@"thread_id"]]
                                                                                        forKeys:@[@"status_read",
                                                                                                  @"timestamp_read",
                                                                                                  @"thread_id",]];
                    
                    [db executeUpdate:@"UPDATE sh_thread "
                                        @"SET status_read = :status_read, timestamp_read = :timestamp_read "
                                        @"WHERE thread_id = :thread_id"
                            withParameterDictionary:message];
                    
                    break;
                }
                    
                case SHThreadStatusSendingFailed:
                {
                    
                    break;
                }
                    
                case SHThreadStatusDeleted:
                {
                    
                    break;
                }
                    
                default:
                    break;
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self message:messageData statusDidChange:status];
        });
    });
}

#pragma mark -
#pragma mark SHMessageManagerDelegate methods.

- (void)messageManagerDidReceiveMessage:(NSDictionary *)messageData
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if ( [_delegate respondsToSelector:@selector(messageManagerDidReceiveMessage:)] )
        {
            [_delegate messageManagerDidReceiveMessage:messageData];
        }
    });
}

- (void)messageManagerDidReceiveMessageBatch:(NSMutableArray *)messages
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if ( [_delegate respondsToSelector:@selector(messageManagerDidReceiveMessageBatch:)] )
        {
            [_delegate messageManagerDidReceiveMessageBatch:messages];
        }
    });
}

- (void)messageManagerDidReceiveAdHocMessage:(NSDictionary *)messageData
{
    if ( [_delegate respondsToSelector:@selector(messageManagerDidReceiveAdHocMessage:)] )
    {
        [_delegate messageManagerDidReceiveAdHocMessage:messageData];
    }
}

- (void)messageManagerDidReceiveStatusUpdate:(NSDictionary *)statusData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSMutableDictionary *statusData_mutable = [statusData mutableCopy];
    NSString *statusID = [statusData objectForKey:@"thread_id"];
    NSString *ownerID = [statusData objectForKey:@"owner_id"];
    NSString *location_latitude = [statusData objectForKey:@"location_latitude"];
    NSString *location_longitude = [statusData objectForKey:@"location_longitude"];
    
    if ( [[NSNull null] isEqual:[statusData_mutable objectForKey:@"location_latitude"]] )
    {
        location_latitude = @"";
        location_longitude = @"";
        
        [statusData_mutable setObject:location_latitude forKey:@"location_latitude"];
        [statusData_mutable setObject:location_longitude forKey:@"location_longitude"];
    }
    
    [statusData_mutable setObject:@"" forKey:@"media_local_path"];
    [statusData_mutable setObject:@"" forKey:@"media_data"];
    
    if ( [[statusData_mutable objectForKey:@"media_extra"] isKindOfClass:NSDictionary.class] )
    {
        NSData *mediaExtraData = [NSJSONSerialization dataWithJSONObject:[statusData_mutable objectForKey:@"media_extra"] options:NSJSONWritingPrettyPrinted error:nil];
        [statusData_mutable setObject:mediaExtraData forKey:@"media_extra"];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [db executeUpdate:@"INSERT INTO sh_thread "
                                @"(thread_id, thread_type, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                                @"VALUES (:thread_id, :thread_type, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent, :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                    withParameterDictionary:statusData_mutable];
            
            [db executeUpdate:@"UPDATE sh_cloud SET last_status_id = :status_id "
                                @"WHERE sh_user_id = :user_id"
                    withParameterDictionary:@{@"status_id": statusID,
                                              @"user_id": ownerID}];
        }];
    });
    
    if ( [_delegate respondsToSelector:@selector(messageManagerDidReceiveStatusUpdate:)] )
    {
        [_delegate messageManagerDidReceiveStatusUpdate:statusData_mutable];
    }
}

- (void)messageManagerDidFetchMessageState:(NSMutableArray *)messages forUserID:(NSString *)userID
{
    if ( [_delegate respondsToSelector:@selector(messageManagerDidFetchMessageState:forUserID:)] )
    {
        [_delegate messageManagerDidFetchMessageState:messages forUserID:userID];
    }
}

- (void)message:(NSDictionary *)messageData statusDidChange:(SHThreadStatus)status
{
    if ( [_delegate respondsToSelector:@selector(message:statusDidChange:)] )
    {
        [_delegate message:messageData statusDidChange:status];
    }
}

- (void)conversation:(NSString *)userID privacyDidChange:(SHThreadPrivacy)newPrivacy
{
    if ( [_delegate respondsToSelector:@selector(conversation:privacyDidChange:)] )
    {
        [_delegate conversation:userID privacyDidChange:newPrivacy];
    }
}

- (void)deleteThread:(NSString *)threadID withIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[threadID]
                                                                          forKeys:@[@"thread_id"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/deletethread", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        if ( responseData )
        {
            int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
            
            if ( errorCode == 0 )
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    for ( int i = 0; i < messageQueue.count; i++ ) // Remove any copy of the deleted message from the queue.
                    {
                        NSMutableDictionary *messageData = [messageQueue objectAtIndex:i];
                        int64_t targetThreadID = [[messageData objectForKey:@"thread_id"] intValue];
                        
                        if ( targetThreadID == threadID.intValue )
                        {
                            [messageQueue removeObjectAtIndex:i];
                            
                            break;
                        }
                    }
                });
                
                if ( indexPath ) // If an index path has been set, that means it was sent from the Messages window.
                {
                    [appDelegate.mainMenu.messagesView deleteThreadAtIndexPath:indexPath deletionConfirmed:YES];
                }
                
                FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT * FROM sh_thread "
                                                                        @"WHERE thread_id = :thread_id"
                                                 withParameterDictionary:@{@"thread_id": threadID}];
                
                SHMediaType mediaType;
                NSString *mediaPath = @"";
                
                while ( [s1 next] )
                {
                    mediaType = [s1 intForColumn:@"media_type"];
                    mediaPath = [s1 stringForColumn:@"media_local_path"];
                }
                
                [s1 close];
                [appDelegate.modelManager.results close];
                [appDelegate.modelManager.DB close];
                
                if ( mediaType == SHMediaTypePhoto )
                {
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSError *error;
                    
                    if ( [fileManager fileExistsAtPath:mediaPath] )
                    {
                        if ( ![fileManager removeItemAtPath:mediaPath error:&error] )
                        {
                            NSLog(@"Error deleting image of thread: %@", error);
                        }
                    }
                }
                
                [appDelegate.modelManager executeUpdate:@"DELETE FROM sh_thread "
                                                        @"WHERE thread_id = :thread_id"
                                withParameterDictionary:@{@"thread_id": threadID}];
                
                [appDelegate.modelManager executeUpdate:@"DELETE FROM sh_message_dispatch "
                                                        @"WHERE thread_id = :thread_id"
                                withParameterDictionary:@{@"thread_id": threadID}];
            }
        }
        else // Some error occurred...
        {
            [appDelegate.strobeLight negativeStrobeLight];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [appDelegate.strobeLight negativeStrobeLight];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)deleteConversationHistoryWithUser:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.modelManager executeUpdate:@"UPDATE sh_thread SET hidden = 1 "
                                            @"WHERE thread_id IN (SELECT thread_id FROM sh_message_dispatch WHERE sender_id = :user_id OR recipient_id = :user_id)"
                    withParameterDictionary:@{@"user_id": userID}];
    
    [appDelegate.modelManager executeUpdate:@"DELETE FROM sh_message_dispatch "
                                            @"WHERE sender_id = :user_id OR recipient_id = :user_id"
                    withParameterDictionary:@{@"user_id": userID}];
}

- (void)updateUnreadThreadCount
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *s1 = [db executeQuery:@"SELECT COUNT(*) FROM sh_cloud WHERE unread_thread_count > 0 AND hidden = 0"
                   withParameterDictionary:nil];
        
        while ( [s1 next] )
        {
            _unreadThreadCount = [s1 intForColumnIndex:0];
            
            // Update the app's icon badge count.
            [appDelegate.currentUser setObject:[NSNumber numberWithInt:_unreadThreadCount] forKey:@"unread_thread_count"];
        }
        
        [s1 close];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:_unreadThreadCount];
            
            [appDelegate.mainMenu updateUnreadBadge:_unreadThreadCount];
            [appDelegate.mainMenu.messagesView updateMenuButtonBadgeCount:_unreadThreadCount];
            [appDelegate.mainMenu.profileView updateMenuButtonBadgeCount:_unreadThreadCount];
        });
    }];
}

- (void)startUnreadMessageCheckTimer
{
    if ( timer_unreadMessageCheck )
    {
        [self pauseUnreadMessageCheckTimer];
    }
    
    timer_unreadMessageCheck = [NSTimer scheduledTimerWithTimeInterval:7 target:self selector:@selector(fetchUnreadMessages) userInfo:nil repeats:NO];
}

- (void)pauseUnreadMessageCheckTimer
{
    [timer_unreadMessageCheck invalidate];
    timer_unreadMessageCheck = nil;
}

@end
