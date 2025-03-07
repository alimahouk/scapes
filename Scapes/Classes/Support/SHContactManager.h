//
//  SHContactManager.h
//  Scapes
//
//  Created by MachOSX on 10/11/13.
//
//

#import <AddressBook/AddressBook.h>

#import "FMDatabase.h"
#import "NBPhoneNumberUtil.h"

@class SHContactManager;

@protocol SHContactManagerDelegate<NSObject>
@optional

- (void)contactManagerDidFetchCountryList;
- (void)contactManagerDidFetchRecommendations:(NSMutableArray *)list;
- (void)contactManagerDidFetchFollowing:(NSMutableArray *)list;
- (void)contactManagerDidFetchFollowers:(NSArray *)list;
- (void)contactManagerDidAddNewContact:(NSMutableDictionary *)userData;
- (void)contactManagerDidHideContact:(NSString *)userID;
- (void)contactManagerDidRemoveContact:(NSString *)userID;
- (void)contactManagerDidBlockContact:(NSString *)userID;
- (void)contactManagerDidUnblockContact:(NSString *)userID;
- (void)contactManagerRequestDidFailWithError:(NSError *)error;

@end

@interface SHContactManager : NSObject
{
    NSMutableArray *recommendedContacts;
    NSMutableArray *recommendedBoards;
    NSDate *lastMagicRunTime;
    NSDate *dateToday;
    NBPhoneNumberUtil *phoneUtil;
    NSString *currentUserMostRecurringCountryCode;
    ABAddressBookRef addressBook;
    CFArrayRef allPeople;
    CFIndex nPeople;
    BOOL userDidGrantAddressBookAccess;
    BOOL contactsDownloading;
    
    int globalViewCount;
    int globalMessagesSentCount;
    int globalMessagesReceivedCount;
    int globalMediaSentCount;
    int globalMediaReceivedCount;
}

@property (nonatomic, weak) id <SHContactManagerDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *countryList;
@property (nonatomic, strong) NSMutableArray *freshContacts;
@property (nonatomic, strong) NSMutableArray *freshBoards;
@property (nonatomic, strong) NSMutableArray *allRecommendations;
@property (nonatomic, strong) NSMutableArray *allContacts;
@property (nonatomic, strong) NSMutableArray *allBoards;
@property (nonatomic, strong) NSMutableArray *allFollowing; // freshContacts + freshBoards + allContacts + allBoards merged together.
@property (nonatomic) NSDate *lastRefresh;
@property (nonatomic) BOOL countryListIsFresh;
@property (nonatomic) BOOL countryListDidDownload;
@property (nonatomic) BOOL countryListDidFailToDownload;
@property (nonatomic) int contactCount;

- (void)setup;

- (NSDictionary *)formatPhoneNumber:(NSString *)thePhoneNumber mobileOnly:(BOOL)mobileOnly;
- (NSString *)formatPhoneNumberForDisplay:(NSString *)thePhoneNumber;

- (void)fetchCountryList;

// Address Book
- (void)requestAddressBookAccess;
- (void)fetchAddressBookContacts;

- (void)requestFollowers;
- (void)requestFollowing;
- (void)requestRecommendationListForced:(BOOL)forced;

- (void)downloadInfoForUsers:(NSArray *)userIDs temporary:(BOOL)temp;
- (void)downloadInfoForUsers:(NSArray *)userIDs conversationTag:(NSSet *)tag;

- (void)updateContactCount;
- (void)incrementViewCountForUser:(NSString *)userID;
- (void)incrementViewCountForBoard:(NSString *)boardID;

- (void)processFollowingList:(NSArray *)followingList boardList:(NSArray *)boardList;
- (void)processRecommendationsWithDB:(FMDatabase *)db;
- (void)processNewContactsWithDB:(FMDatabase *)db;
- (void)refreshContactsStateWithDB:(FMDatabase *)db;
- (void)refreshMagicNumbersWithDB:(FMDatabase *)db callback:(BOOL)callback;
- (float)magicNumberForContact:(NSMutableDictionary *)contact withDB:(FMDatabase *)db;
- (void)magicNumberRunInternalsWithDB:(FMDatabase *)db;
- (void)coordinatesForMagicNumbersWithDB:(FMDatabase *)db saveLocally:(BOOL)shouldSave callback:(NSString *)callback;

- (BOOL)numberExistsInAddressBook:(NSString *)thePhoneNumber withCountryCallingCode:(NSString *)theCallingCode prefix:(NSString *)thePrefix;
- (id)addressBookInfoForNumber:(NSString *)thePhoneNumber withCountryCallingCode:(NSString *)theCallingCode prefix:(NSString *)thePrefix;
- (NSMutableDictionary *)infoForUser:(NSString *)userID;

- (void)addUser:(NSString *)userID;
- (void)addUsername:(NSString *)username;
- (void)hideUser:(NSString *)userID;
- (void)removeUser:(NSString *)userID;
- (void)blockContact:(NSString *)userID;
- (void)unblockContact:(NSString *)userID;
- (BOOL)isBlocked:(NSString *)userID withDB:(FMDatabase *)db;
- (void)unhideContact:(NSString *)userID;

- (void)downloadLatestCurrentUserData;

@end
