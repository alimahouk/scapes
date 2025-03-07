//
//  SHPresenceManager.h
//  Scapes
//
//  Created by MachOSX on 9/17/13.
//
//

@class SHPresenceManager;

@protocol SHPresenceManagerDelegate<NSObject>

- (void)currentUserPresenceDidChange;

@optional

- (void)presenceDidChange:(SHUserPresence)presence forUserID:(NSString *)userID withTargetID:(NSString *)targetID forAudience:(SHUserPresenceAudience)audience;

@end

@interface SHPresenceManager : NSObject
{
    BOOL didNotifyDelegateOnlinePresence;
    BOOL didNotifyDelegateOfflinePresence;
}

@property (nonatomic, weak) id <SHPresenceManagerDelegate> delegate;

- (void)resetPresenceForAll;
- (void)refreshPresenceForAll;
- (void)fetchLatestPresenceForUserID:(NSString *)userID;
- (void)setAway;
- (void)setPresence:(SHUserPresence)presence withTargetID:(NSString *)targetID forAudience:(SHUserPresenceAudience)audience;
- (void)currentUserPresenceChanged;
- (void)presenceChanged:(SHUserPresence)presence forUserID:(NSString *)userID withTargetID:(NSString *)targetID forAudience:(SHUserPresenceAudience)audience;

@end
