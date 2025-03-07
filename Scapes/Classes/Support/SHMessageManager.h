//
//  SHMessageManager.h
//  Scapes
//
//  Created by MachOSX on 9/17/13.
//
//

@class SHMessageManager;

@protocol SHMessageManagerDelegate<NSObject>
@optional

- (void)messageManagerDidReceiveMessage:(NSDictionary *)messageData;
- (void)messageManagerDidReceiveMessageBatch:(NSMutableArray *)messages;
- (void)messageManagerDidReceiveAdHocMessage:(NSDictionary *)messageData;
- (void)messageManagerDidReceiveStatusUpdate:(NSDictionary *)statusData;
- (void)messageManagerDidFetchMessageState:(NSMutableArray *)messages forUserID:(NSString *)userID;
- (void)message:(NSDictionary *)messageData statusDidChange:(SHThreadStatus)status;
- (void)conversation:(NSString *)userID privacyDidChange:(SHThreadPrivacy)newPrivacy;

@end

@interface SHMessageManager : NSObject
{
    NSMutableArray *messageQueue;
    NSTimer *timer_unreadMessageCheck;
}

@property (nonatomic, weak) id <SHMessageManagerDelegate> delegate;
@property (nonatomic) int unreadThreadCount;

- (void)setup;

- (void)fetchUnreadMessages;
- (void)fetchLatestMessagesStateForUserID:(NSString *)userID withIDInQueue:(int64_t)pendingThreadID;
- (void)acknowledgeLateDelivery;
- (void)dispatchAllMessagesForRecipient:(NSString *)recipientID;
- (BOOL)messageExistsInQueue:(NSString *)messageID;
- (void)clearMessageQueue;

- (void)parseReceivedMessage:(NSDictionary *)messageData shouldVibrate:(BOOL)vibrate withDB:(FMDatabase *)db;
- (void)parseReceivedMessageBatch:(NSMutableArray *)messages withDB:(FMDatabase *)db;
- (void)parseReceivedAdHocMessage:(NSDictionary *)messageData;
- (void)acknowledgeDeliveryForMessage:(NSString *)threadID toOwnerID:(NSString *)ownerID;
- (void)acknowledgeReadForMessage:(NSString *)threadID toOwnerID:(NSString *)ownerID;

- (void)dispatchMessage:(NSDictionary *)messageData forAudience:(SHUserPresenceAudience)audience;
- (void)resendMessage:(NSString *)messageID;
- (void)dispatchStatus:(NSDictionary *)statusData;
- (void)parseStatus:(NSDictionary *)statusData;

- (void)updateThreadPrivacy:(SHThreadPrivacy)privacy forConversation:(NSString *)userID;
- (void)conversation:(NSString *)userID privacyChanged:(SHThreadPrivacy)newPrivacy;
- (void)message:(NSDictionary *)messageData statusChanged:(SHThreadStatus)status;

- (void)deleteThread:(NSString *)threadID withIndexPath:(NSIndexPath *)indexPath;
- (void)deleteConversationHistoryWithUser:(NSString *)userID;

- (void)updateUnreadThreadCount;

- (void)startUnreadMessageCheckTimer;
- (void)pauseUnreadMessageCheckTimer;

@end