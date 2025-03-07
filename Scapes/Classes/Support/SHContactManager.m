//
//  SHContactManager.m
//  Scapes
//
//  Created by MachOSX on 10/11/13.
//
//

#import "SHContactManager.h"

#import "AFHTTPRequestOperationManager.h"
#import "NBPhoneMetaData.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberDesc.h"
#import "NBNumberFormat.h"

@implementation SHContactManager

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        phoneUtil = [NBPhoneNumberUtil sharedInstance];
        
        _contactCount = 0;
        _countryListIsFresh = NO;
        _countryListDidDownload = NO;
        _countryListDidFailToDownload = NO;
        contactsDownloading = NO;
        
        _allRecommendations = [[NSMutableArray alloc] init];
        _freshContacts = [[NSMutableArray alloc] init];
        _freshBoards = [[NSMutableArray alloc] init];
        _allContacts = [[NSMutableArray alloc] init];
        _allBoards = [[NSMutableArray alloc] init];
        _allFollowing = [[NSMutableArray alloc] init];
        _countryList = [[NSMutableArray alloc] init];
        recommendedContacts = [[NSMutableArray alloc] init];
        recommendedBoards = [[NSMutableArray alloc] init];
        
        if ( appDelegate.SHToken && appDelegate.SHToken.length > 0 ) // Only if a user is logged in.
        {
            [self setup];
        }
    }
    
    return self;
}

- (void)setup
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [self updateContactCount];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            // Delete any stale ad hoc messages & contacts.
            [db executeUpdate:@"DELETE FROM sh_cloud "
                                @"WHERE temp = 1"
                    withParameterDictionary:nil];
        }];
    });
}

- (NSDictionary *)formatPhoneNumber:(NSString *)thePhoneNumber mobileOnly:(BOOL)mobileOnly
{
    NSMutableDictionary *phoneNumberPack = [NSMutableDictionary dictionary];
    NSError *phoneUtilError = nil;
    NBPhoneNumber *parsedPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:thePhoneNumber error:&phoneUtilError];
    
    if ( phoneUtilError != nil || ![phoneUtil isValidNumber:parsedPhoneNumber] )
    {
        // Should check error.
        return nil;
    }
    
    NBEPhoneNumberType numberType = [phoneUtil getNumberType:parsedPhoneNumber];
    
    @autoreleasepool
    {
        if ( mobileOnly )
        {
            if ( numberType == NBEPhoneNumberTypeMOBILE || numberType == NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE )
            {
                NSString *countryCallingCode = [NSString stringWithFormat:@"%@", parsedPhoneNumber.countryCode];
                
                NSString *prefix = [phoneUtil format:parsedPhoneNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:&phoneUtilError];
                prefix = [prefix stringByReplacingOccurrencesOfString:@"-" withString:@" "];
                prefix = [prefix stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"+%@ ", countryCallingCode] withString:@""];
                NSScanner *scanner = [[NSScanner alloc] initWithString:prefix];
                [scanner scanUpToString:@" " intoString:&prefix];
                
                NSString *phoneNumber = [phoneUtil format:parsedPhoneNumber numberFormat:NBEPhoneNumberFormatE164 error:&phoneUtilError];
                phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"+%@%@", countryCallingCode, prefix] withString:@""];
                
                [phoneNumberPack setObject:countryCallingCode forKey:@"country_calling_code"];
                [phoneNumberPack setObject:prefix forKey:@"prefix"];
                [phoneNumberPack setObject:phoneNumber forKey:@"phone_number"];
            }
            else
            {
                return nil;
            }
        }
        else
        {
            NSString *countryCallingCode = [NSString stringWithFormat:@"%@", parsedPhoneNumber.countryCode];
            
            NSString *prefix = [phoneUtil format:parsedPhoneNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:&phoneUtilError];
            prefix = [prefix stringByReplacingOccurrencesOfString:@"-" withString:@" "];
            prefix = [prefix stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"+%@ ", countryCallingCode] withString:@""];
            NSScanner *scanner = [[NSScanner alloc] initWithString:prefix];
            [scanner scanUpToString:@" " intoString:&prefix];
            
            NSString *phoneNumber = [phoneUtil format:parsedPhoneNumber numberFormat:NBEPhoneNumberFormatE164 error:&phoneUtilError];
            phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"+%@%@", countryCallingCode, prefix] withString:@""];
            
            [phoneNumberPack setObject:countryCallingCode forKey:@"country_calling_code"];
            [phoneNumberPack setObject:prefix forKey:@"prefix"];
            [phoneNumberPack setObject:phoneNumber forKey:@"phone_number"];
        }
    }
    
    return phoneNumberPack;
}

- (NSString *)formatPhoneNumberForDisplay:(NSString *)thePhoneNumber
{
    NSError *phoneUtilError = nil;
    NBPhoneNumber *parsedPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:thePhoneNumber error:&phoneUtilError];
    
    if ( phoneUtilError != nil || ![phoneUtil isValidNumber:parsedPhoneNumber] )
    {
        // Should check error.
        return nil;
    }
    
    return [phoneUtil format:parsedPhoneNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:&phoneUtilError];
}

/*
 *  This method should only be called once per app launch.
 */
- (void)fetchCountryList
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            // See if we have an old copy of the list.
            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_country"
                       withParameterDictionary:nil];
            
            while ( [s1 next] )
            {
                NSString *countryCallingCode = [s1 stringForColumn:@"calling_code"];
                NSString *countryCode = [s1 stringForColumn:@"country_code"];
                NSString *countryID = [s1 stringForColumn:@"country_id"];
                NSString *countryName = [s1 stringForColumn:@"name"];
                
                NSDictionary *country = [NSDictionary dictionaryWithObjectsAndKeys:countryID, @"countryID",
                                         countryName, @"countryName",
                                         countryCode, @"countryCode",
                                         countryCallingCode, @"countryCallingCode", nil];
                
                [_countryList addObject:country];
                
                _countryListDidDownload = YES;
                _countryListDidFailToDownload = NO;
            }
            
            [s1 close];
        }];
    });
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSDictionary *parameters = @{@"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]};
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/getcountrylist", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
                    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                        // Clear out the old country data.
                        [db executeUpdate:@"DELETE FROM sh_country;"
                                            @"DELETE FROM SQLITE_SEQUENCE WHERE name = 'sh_country';"
                            withParameterDictionary:nil];
                        
                        [_countryList removeAllObjects];
                        
                        for ( NSDictionary *country in [responseData objectForKey:@"response"] )
                        {
                            [db executeUpdate:@"INSERT INTO sh_country "
                                                @"(country_id, name, country_code, calling_code) "
                                                @"VALUES (:country_id, :name, :country_code, :calling_code)"
                                withParameterDictionary:country];
                            
                            [_countryList addObject:country];
                        }
                        
                        _countryListIsFresh = YES;
                        [self contactManagerDidFetchCountryList];
                    }];
                });
            }
        }
        
        //NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // See if we have an old copy of the list.
        FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT COUNT(*) FROM sh_country"
                                         withParameterDictionary:nil];
        
        while ( [s1 next] )
        {
            if ( [s1 intForColumnIndex:0] > 0 )
            {
                _countryListDidDownload = YES;
                _countryListDidFailToDownload = NO;
            }
            else
            {
                _countryListDidDownload = NO;
                _countryListDidFailToDownload = YES;
                [self contactManagerRequestDidFailWithError:error];
            }
        }
        
        [s1 close];
        [appDelegate.modelManager.results close];
        [appDelegate.modelManager.DB close];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)requestAddressBookAccess
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [appDelegate.strobeLight activateStrobeLight];
    });
    
    if ( ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined ||
        ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized )
    {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error){
            userDidGrantAddressBookAccess = granted;
            dispatch_semaphore_signal(sema);
        });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    else
    {
        if ( ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied ||
            ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted )
        {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                message:NSLocalizedString(@"SIGNUP_ERROR_ADDRESS_BOOK_PRIVACY", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil)
                                                      otherButtonTitles:nil];
                [alert show];
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                message:NSLocalizedString(@"SIGNUP_ERROR_ADDRESS_UNKNOWN_ERROR", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil)
                                                      otherButtonTitles:nil];
                [alert show];
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [appDelegate.strobeLight negativeStrobeLight];
        });
    }
    
    [self fetchAddressBookContacts];
}

- (void)fetchAddressBookContacts
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *currentUserPhoneNumbers = [appDelegate.currentUser objectForKey:@"phone_numbers"];
        
        while ( true ) // Wait till the country list downloads...
        {
            if ( _countryListIsFresh )
            {
                NSMutableDictionary *dataChunk;
                
                if ( userDidGrantAddressBookAccess && appDelegate.preference_UseAddressBook )
                {
                    contactsDownloading = YES;
                    
                    CFErrorRef addressBookError = NULL;
                    addressBook = ABAddressBookCreateWithOptions(NULL, &addressBookError);
                    allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
                    nPeople = ABAddressBookGetPersonCount(addressBook);
                    
                    NSMutableArray *countryCallingCodes = [NSMutableArray array];
                    NSMutableArray *prefixes = [NSMutableArray array];
                    NSMutableArray *phoneNumbers = [NSMutableArray array];
                    
                    for ( int i = 0; i < nPeople; i++ )
                    {
                        ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
                        
                        ABMultiValueRef *phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
                        
                        for ( int j = 0; j < ABMultiValueGetCount(phones); j++ )
                        {
                            CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, j);
                            NSString *phoneNumberString = (__bridge NSString *)phoneNumberRef;
                            
                            NSDictionary *phoneNumberPack = [self formatPhoneNumber:phoneNumberString mobileOnly:YES];
                            
                            if ( phoneNumberPack )
                            {
                                int countryCallingCode = [[phoneNumberPack objectForKey:@"country_calling_code"] intValue];
                                int prefix = [[phoneNumberPack objectForKey:@"prefix"] intValue];
                                int phoneNumber = [[phoneNumberPack objectForKey:@"phone_number"] intValue];
                                
                                // Stop at this point & check if we picked up our new user in their own address book.
                                BOOL shouldSkipNumber = NO;
                                
                                for ( NSMutableDictionary *phoneNumberPack in currentUserPhoneNumbers )
                                {
                                    int countryCallingCode_currentUser = [[phoneNumberPack objectForKey:@"country_calling_code"] intValue];
                                    int prefix_currentUser = [[phoneNumberPack objectForKey:@"prefix"] intValue];
                                    int phoneNumber_currentUser = [[phoneNumberPack objectForKey:@"phone_number"] intValue];
                                    
                                    if ( countryCallingCode == countryCallingCode_currentUser &&
                                        prefix == prefix_currentUser &&
                                        phoneNumber == phoneNumber_currentUser )
                                    {
                                        // Skip over them without sending them to the server.
                                        shouldSkipNumber = YES;
                                        break;
                                    }
                                }
                                
                                if ( shouldSkipNumber )
                                {
                                    CFRelease(phoneNumberRef);
                                    continue;
                                }
                                
                                [countryCallingCodes addObject:[NSNumber numberWithInt:countryCallingCode]];
                                [prefixes addObject:[NSNumber numberWithInt:prefix]];
                                [phoneNumbers addObject:[NSNumber numberWithInt:phoneNumber]];
                            }
                            
                            CFRelease(phoneNumberRef);
                        }
                        
                        CFRelease(phones);
                    }
                    
                    NSData *jsonData_countryCallingCodes = [NSJSONSerialization dataWithJSONObject:countryCallingCodes options:kNilOptions error:nil];
                    NSString *jsonString_countryCallingCodes = [[NSString alloc] initWithData:jsonData_countryCallingCodes encoding:NSUTF8StringEncoding];
                    
                    NSData *jsonData_prefixes = [NSJSONSerialization dataWithJSONObject:prefixes options:kNilOptions error:nil];
                    NSString *jsonString_prefixes = [[NSString alloc] initWithData:jsonData_prefixes encoding:NSUTF8StringEncoding];
                    
                    NSData *jsonData_phoneNumbers = [NSJSONSerialization dataWithJSONObject:phoneNumbers options:kNilOptions error:nil];
                    NSString *jsonString_phoneNumbers = [[NSString alloc] initWithData:jsonData_phoneNumbers encoding:NSUTF8StringEncoding];
                    
                    dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[jsonString_countryCallingCodes,
                                                                               jsonString_prefixes,
                                                                               jsonString_phoneNumbers]
                                                                     forKeys:@[@"country_calling_codes",
                                                                               @"prefixes",
                                                                               @"phone_numbers"]];
                }
                else if ( !userDidGrantAddressBookAccess && appDelegate.preference_UseAddressBook ) // User asked to use address book but denied access.
                {
                    NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
                    [errorDetails setValue:@"User denied address book access." forKey:NSLocalizedDescriptionKey];
                    NSError *error = [NSError errorWithDomain:@"AddressBookAccessDenied" code:1 userInfo:errorDetails];
                    
                    [self contactManagerRequestDidFailWithError:error];
                    
                    break;
                }
                else // Fetch any previously added contacts from the cloud.
                {
                    contactsDownloading = YES;
                    
                    // Use blank JSON arrays.
                    dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[@"[]",
                                                                               @"[]",
                                                                               @"[]",
                                                                               @"[]"]
                                                                     forKeys:@[@"country_calling_codes",
                                                                               @"prefixes",
                                                                               @"phone_numbers",
                                                                               @"names"]];
                }
                
                NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
                
                NSDictionary *parameters = @{@"request": jsonString,
                                             @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                             @"scope": appDelegate.SHTokenID};
                
                NSLog(@"Fetching contacts...");
                
                AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
                manager.responseSerializer = [AFHTTPResponseSerializer serializer];
                
                [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/scanaddressbook", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSString *response = operation.responseString;
                    
                    if ( [response hasPrefix:@"while(1);"] )
                    {
                        response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
                    }
                    
                    NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
                    
                    NSLog(@"Loaded contacts!");
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [appDelegate.strobeLight deactivateStrobeLight];
                    });
                    
                    if ( responseData )
                    {
                        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
                        
                        if ( errorCode == 0 )
                        {
                            NSDictionary *response = [responseData objectForKey:@"response"];
                            
                            [self processFollowingList:[response objectForKey:@"users"]
                                             boardList:[response objectForKey:@"boards"]];
                        }
                        else if ( errorCode == 404 ) // No users found.
                        {
                            NSLog(@"No contacts using Nightboard. :(");
                            [self contactManagerDidFetchFollowing:_freshContacts];
                        }
                    }
                    else
                    {
                        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
                        [errorDetails setValue:@"Request response error." forKey:NSLocalizedDescriptionKey];
                        NSError *error = [NSError errorWithDomain:@"ResponseError" code:1 userInfo:errorDetails];
                        
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            [appDelegate.strobeLight negativeStrobeLight];
                        });
                        
                        [self contactManagerRequestDidFailWithError:error];
                        
                        CFRelease(addressBook);
                    }
                    
                    //NSLog(@"Response: %@", responseData);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    CFRelease(addressBook);
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [appDelegate.strobeLight negativeStrobeLight];
                    });
                    
                    [self contactManagerRequestDidFailWithError:error];
                    
                    NSLog(@"Error: %@", operation.responseString);
                }];
                
                break;
            }
            else if ( _countryListDidFailToDownload )
            {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [appDelegate.strobeLight negativeStrobeLight];
                });
                
                CFRelease(addressBook);
                
                break;
            }
        }
    });
}

- (void)requestFollowers
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDictionary *parameters = @{@"token": appDelegate.SHToken,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/getfollowers", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        if ( errorCode == 0 )
        {
            [self contactManagerDidFetchFollowers:[responseData objectForKey:@"response"]];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self contactManagerRequestDidFailWithError:error];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)requestFollowing
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDictionary *parameters = @{@"token": appDelegate.SHToken,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/getfollowing", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        if ( errorCode == 0 )
        {
            NSDictionary *response = [responseData objectForKey:@"response"];
            
            [self processFollowingList:[response objectForKey:@"users"]
                             boardList:[response objectForKey:@"boards"]];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self contactManagerRequestDidFailWithError:error];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)requestRecommendationListForced:(BOOL)forced
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSDate *timeNow = [NSDate date];
    
    int timeout = 5 * 60; // In minutes.
    
    if ( !forced && [timeNow timeIntervalSinceDate:_lastRefresh] < timeout ) // If timeout hasn't passed yet.
    {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            // You *should* send a list of any saved peers.
            NSMutableArray *savedPeers = [NSMutableArray array];
            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_peer"];
            
            while ( [s1 next] )
            {
                [savedPeers addObject:[s1 stringForColumn:@"sh_user_id"]];
            }
            
            [s1 close];
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:savedPeers options:kNilOptions error:nil];
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
            NSDictionary *parameters = @{@"token": appDelegate.SHToken,
                                         @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                         @"users": jsonString};
            
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            
            [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/getrecommendations", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSString *response = operation.responseString;
                
                if ( [response hasPrefix:@"while(1);"] )
                {
                    response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
                }
                
                response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
                NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
                
                int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
                
                if ( errorCode == 0 )
                {
                    NSDictionary *response = [responseData objectForKey:@"response"];
                    recommendedContacts = [[response objectForKey:@"users"] mutableCopy];
                    recommendedBoards = [[response objectForKey:@"boards"] mutableCopy];
                    
                    // Check if any of the recommendations are already being followed.
                    for ( int i = 0; i < recommendedContacts.count; i++ )
                    {
                        NSDictionary *contact = [recommendedContacts objectAtIndex:i];
                        
                        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :user_id"
                                   withParameterDictionary:@{@"user_id": [contact objectForKey:@"user_id"]}];
                        
                        // Check if the contact's already stored.
                        while ( [s1 next] )
                        {
                            [recommendedContacts removeObjectAtIndex:i];
                        }
                        
                        [s1 close];
                    }
                    
                    for ( int i = 0; i < recommendedBoards.count; i++ )
                    {
                        NSDictionary *board = [recommendedBoards objectAtIndex:i];
                        
                        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_board WHERE board_id = :board_id"
                                   withParameterDictionary:@{@"board_id": [board objectForKey:@"board_id"]}];
                        
                        // Check if the board's already stored.
                        while ( [s1 next] )
                        {
                            [recommendedBoards removeObjectAtIndex:i];
                        }
                        
                        [s1 close];
                    }
                    
                    [self processRecommendationsWithDB:db];
                }
                else if ( errorCode == 404 ) // No users found.
                {
                    NSLog(@"No contacts using the service. :(");
                    [self contactManagerDidFetchRecommendations:responseData];
                }
                
                _lastRefresh = [NSDate date];
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [appDelegate.peerManager clearFlaggedPeers];
                });
                
                //NSLog(@"Response: %@", responseData);
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [self contactManagerRequestDidFailWithError:error];
                
                if ( error.code == -1005 )
                {
                    [self requestRecommendationListForced:forced];
                }
                
                NSLog(@"Error: %@", operation.responseString);
            }];
        }];
    });
}

- (void)downloadInfoForUsers:(NSArray *)userIDs temporary:(BOOL)temp
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( userIDs.count == 0 )
    {
        return;
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userIDs options:kNilOptions error:nil];
    NSString *jsonString_IDs = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[jsonString_IDs]
                                                                          forKeys:@[@"users"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"request": jsonString,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"scope": appDelegate.SHTokenID};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/getuserinfo", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        if ( errorCode == 0 )
        {
            // TODO: download their DPs!
            // ====
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
                [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    for ( NSDictionary *contact in [responseData objectForKey:@"response"] )
                    {
                        [_freshContacts addObject:[contact mutableCopy]];
                    }
                    
                    [self processNewContactsWithDB:db];
                }];
            });
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self contactManagerRequestDidFailWithError:error];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)downloadInfoForUsers:(NSArray *)userIDs conversationTag:(NSSet *)tag
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( userIDs.count == 0 )
    {
        return;
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userIDs options:kNilOptions error:nil];
    NSString *jsonString_IDs = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[jsonString_IDs]
                                                                          forKeys:@[@"users"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"request": jsonString,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"scope": appDelegate.SHTokenID};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/getuserinfo", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        if ( errorCode == 0 )
        {
            // TODO: download their DPs!
            // ====
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
                [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    NSArray *originalParticipants = [tag allObjects];
                    int original_user_1 = MIN([originalParticipants[0] intValue], [originalParticipants[1] intValue]);
                    int original_user_2 = MAX([originalParticipants[0] intValue], [originalParticipants[1] intValue]);
                    
                    for ( NSDictionary *contact in [responseData objectForKey:@"response"] )
                    {
                        NSMutableDictionary *contact_mutable = [contact mutableCopy];
                        [contact_mutable setObject:@"1" forKey:@"temp"];
                        
                        [_freshContacts addObject:contact_mutable];
                        
                        NSDictionary *argsDict_participant = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:original_user_1], @"original_user_1",
                                                              [NSNumber numberWithInt:original_user_2], @"original_user_2",
                                                              [contact objectForKey:@"user_id"], @"user_id", nil];
                        
                        [db executeUpdate:@"INSERT INTO sh_ad_hoc_conversation "
                                            @"(original_user_1, original_user_2, user_id) "
                                            @"VALUES (:original_user_1, :original_user_2, :user_id)"
                                withParameterDictionary:argsDict_participant];
                    }
                    
                    [self processNewContactsWithDB:db];
                }];
            });
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self contactManagerRequestDidFailWithError:error];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)updateContactCount
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT COUNT(*) FROM sh_cloud WHERE sh_user_id <> :current_user_id AND temp = 0"
                                    withParameterDictionary:@{@"current_user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
    
    while ( [s1 next] )
    {
        _contactCount = [s1 intForColumnIndex:0];
    }
    
    [s1 close];
    [appDelegate.modelManager.results close];
    [appDelegate.modelManager.DB close];
}

- (void)incrementViewCountForUser:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [db executeUpdate:@"UPDATE sh_cloud "
                                @"SET view_count = view_count + 1 "
                                @"WHERE sh_user_id = :user_id"
                    withParameterDictionary:@{@"user_id": userID}];
        }];
    });
}

- (void)incrementViewCountForBoard:(NSString *)boardID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [db executeUpdate:@"UPDATE sh_board "
                                @"SET view_count = view_count + 1 "
                                @"WHERE board_id = :board_id"
                    withParameterDictionary:@{@"board_id": boardID}];
        }];
    });
}

- (void)processFollowingList:(NSArray *)followingList boardList:(NSArray *)boardList
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for ( NSDictionary *contact in followingList )
            {
                NSMutableDictionary *contact_mutable = [contact mutableCopy];
                [contact_mutable setObject:@"0" forKey:@"temp"];
                
                NSMutableDictionary *contactPackage = [@{@"entry_type": [NSNumber numberWithInt:SHChatBubbleTypeUser],
                                                         @"entry_data": contact_mutable} mutableCopy];
                
                FMResultSet *s1 = [db executeQuery:@"SELECT sh_user_id FROM sh_cloud WHERE sh_user_id = :user_id"
                           withParameterDictionary:@{@"user_id": [contact_mutable objectForKey:@"user_id"]}];
                
                BOOL exists = NO;
                
                // Check if the contact's already stored.
                while ( [s1 next] )
                {
                    exists = YES;
                }
                
                [s1 close]; // Very important that you close this!
                
                if ( exists )
                {
                    [_allContacts addObject:contactPackage];
                }
                else
                {
                    [_freshContacts addObject:contactPackage];
                }
            }
            
            for ( NSDictionary *board in boardList )
            {
                NSMutableDictionary *board_mutable = [board mutableCopy];
                [board_mutable setObject:@"0" forKey:@"temp"];
                
                NSMutableDictionary *boardPackage = [@{@"entry_type": [NSNumber numberWithInt:SHChatBubbleTypeBoard],
                                                       @"entry_data": board_mutable} mutableCopy];
                
                FMResultSet *s1 = [db executeQuery:@"SELECT name FROM sh_board WHERE board_id = :board_id"
                           withParameterDictionary:@{@"board_id": [board_mutable objectForKey:@"board_id"]}];
                
                BOOL exists = NO;
                
                // Check if the contact's already stored.
                while ( [s1 next] )
                {
                    exists = YES;
                }
                
                [s1 close]; // Very important that you close this!
                
                if ( exists )
                {
                    [_allBoards addObject:boardPackage];
                }
                else
                {
                    [_freshBoards addObject:boardPackage];
                }
            }
            
            [self processNewContactsWithDB:db];
        }];
    });
}

- (void)processRecommendationsWithDB:(FMDatabase *)db;
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    for ( int i = 0; i < recommendedContacts.count; i++ )
    {
        NSMutableDictionary *contact = [[recommendedContacts objectAtIndex:i] mutableCopy];
        [contact setObject:@"1" forKey:@"temp"];
        
        NSString *userID = [contact objectForKey:@"user_id"];
        BOOL userExists = NO;
        
        // Check if this person is already in the cloud.
        for ( int j = 0; j < appDelegate.mainMenu.contactCloud.cloudBubbles.count; j++ )
        {
            SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:j];
            
            if ( bubble.bubbleType == SHChatBubbleTypeUser )
            {
                int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                
                if ( bubbleID == userID.intValue )
                {
                    userExists = YES;
                    
                    break;
                }
            }
        }
        
        if ( userExists )
        {
            [recommendedContacts removeObjectAtIndex:i];
            i--; // Backtrack!
            
            continue;
        }
        
        NSString *userHandle = @"";
        NSString *DPHash = @"";
        NSString *email = @"";
        NSString *gender = @"";
        NSString *location_country = @"";
        NSString *location_state = @"";
        NSString *location_city = @"";
        NSString *website = @"";
        NSString *bio = @"";
        NSString *birthday = @"";
        NSString *facebookHandle = @"";
        NSString *twitterHandle = @"";
        NSString *instagramHandle = @"";
        
        NSString *lastStatusID = [NSString stringWithFormat:@"%@", [contact objectForKey:@"thread_id"]];
        NSString *lastStatusLocation_latitude = @"";
        NSString *lastStatusLocation_longitude = @"";
        
        [contact setObject:lastStatusID forKey:@"last_status_id"]; // Some things rely on this key or they'll break.
        
        if ( ![[NSNull null] isEqual:[contact objectForKey:@"user_handle"]] )
        {
            userHandle = [contact objectForKey:@"user_handle"];
        }
        else
        {
            [contact setObject:@"" forKey:@"user_handle"];
        }
        
        if ( ![[NSNull null] isEqual:[contact objectForKey:@"dp_hash"]] )
        {
            DPHash = [contact objectForKey:@"dp_hash"];
        }
        else
        {
            [contact setObject:@"" forKey:@"dp_hash"];
        }
        
        if ( ![[NSNull null] isEqual:[contact objectForKey:@"email_address"]] )
        {
            email = [contact objectForKey:@"email_address"];
        }
        else
        {
            [contact setObject:@"" forKey:@"email_address"];
        }
        
        if ( ![[NSNull null] isEqual:[contact objectForKey:@"gender"]] )
        {
            gender = [contact objectForKey:@"gender"];
        }
        else
        {
            [contact setObject:@"" forKey:@"gender"];
        }
        
        if ( ![[NSNull null] isEqual:[contact objectForKey:@"location_country"]] )
        {
            location_country = [contact objectForKey:@"location_country"];
        }
        else
        {
            [contact setObject:@"" forKey:@"location_country"];
        }
        
        if ( ![[NSNull null] isEqual:[contact objectForKey:@"location_state"]] )
        {
            location_state = [contact objectForKey:@"location_state"];
        }
        else
        {
            [contact setObject:@"" forKey:@"location_state"];
        }
        
        if ( ![[NSNull null] isEqual:[contact objectForKey:@"location_city"]] )
        {
            location_city = [contact objectForKey:@"location_city"];
        }
        else
        {
            [contact setObject:@"" forKey:@"location_city"];
        }
        
        if ( ![[NSNull null] isEqual:[contact objectForKey:@"website"]] )
        {
            website = [contact objectForKey:@"website"];
        }
        else
        {
            [contact setObject:@"" forKey:@"website"];
        }
        
        if ( ![[NSNull null] isEqual:[contact objectForKey:@"bio"]] )
        {
            bio = [contact objectForKey:@"bio"];
        }
        else
        {
            [contact setObject:@"" forKey:@"bio"];
        }
        
        if ( ![[NSNull null] isEqual:[contact objectForKey:@"facebook_id"]] )
        {
            facebookHandle = [contact objectForKey:@"facebook_id"];
        }
        else
        {
            [contact setObject:@"" forKey:@"facebook_id"];
        }
        
        if ( ![[NSNull null] isEqual:[contact objectForKey:@"twitter_id"]] )
        {
            twitterHandle = [contact objectForKey:@"twitter_id"];
        }
        else
        {
            [contact setObject:@"" forKey:@"twitter_id"];
        }
        
        if ( ![[NSNull null] isEqual:[contact objectForKey:@"instagram_id"]] )
        {
            instagramHandle = [contact objectForKey:@"instagram_id"];
        }
        else
        {
            [contact setObject:@"" forKey:@"instagram_id"];
        }
        
        if ( ![[NSNull null] isEqual:[contact objectForKey:@"location_latitude"]] )
        {
            lastStatusLocation_latitude = [contact objectForKey:@"location_latitude"];
            lastStatusLocation_longitude = [contact objectForKey:@"location_longitude"];
        }
        else
        {
            [contact setObject:@"" forKey:@"location_latitude"];
            [contact setObject:@"" forKey:@"location_longitude"];
        }
        
        if ( ![[NSNull null] isEqual:[contact objectForKey:@"birthday"]] )
        {
            birthday = [contact objectForKey:@"birthday"];
        }
        else
        {
            [contact setObject:@"" forKey:@"birthday"];
        }
        
        if ( [contact objectForKey:@"user_handle"] && ![[NSNull null] isEqual:[contact objectForKey:@"user_handle"]] )
        {
            userHandle = [contact objectForKey:@"user_handle"];
        }
        else
        {
            [contact setObject:@"" forKey:@"user_handle"];
        }
        
        if ( [contact objectForKey:@"dp_hash"] && ![[NSNull null] isEqual:[contact objectForKey:@"dp_hash"]] )
        {
            DPHash = [contact objectForKey:@"dp_hash"];
        }
        else
        {
            [contact setObject:@"" forKey:@"dp_hash"];
        }
        
        if ( [contact objectForKey:@"email_address"] && ![[NSNull null] isEqual:[contact objectForKey:@"email_address"]] )
        {
            email = [contact objectForKey:@"email_address"];
        }
        else
        {
            [contact setObject:@"" forKey:@"email_address"];
        }
        
        if ( [contact objectForKey:@"gender"] && ![[NSNull null] isEqual:[contact objectForKey:@"gender"]] )
        {
            gender = [contact objectForKey:@"gender"];
        }
        else
        {
            [contact setObject:@"" forKey:@"gender"];
        }
        
        if ( [contact objectForKey:@"location_country"] && ![[NSNull null] isEqual:[contact objectForKey:@"location_country"]] )
        {
            location_country = [contact objectForKey:@"location_country"];
        }
        else
        {
            [contact setObject:@"" forKey:@"location_country"];
        }
        
        if ( [contact objectForKey:@"location_state"] && ![[NSNull null] isEqual:[contact objectForKey:@"location_state"]] )
        {
            location_state = [contact objectForKey:@"location_state"];
        }
        else
        {
            [contact setObject:@"" forKey:@"location_state"];
        }
        
        if ( [contact objectForKey:@"location_city"] && ![[NSNull null] isEqual:[contact objectForKey:@"location_city"]] )
        {
            location_city = [contact objectForKey:@"location_city"];
        }
        else
        {
            [contact setObject:@"" forKey:@"location_city"];
        }
        
        if ( [contact objectForKey:@"website"] && ![[NSNull null] isEqual:[contact objectForKey:@"website"]] )
        {
            website = [contact objectForKey:@"website"];
        }
        else
        {
            [contact setObject:@"" forKey:@"website"];
        }
        
        if ( [contact objectForKey:@"bio"] && ![[NSNull null] isEqual:[contact objectForKey:@"bio"]] )
        {
            bio = [contact objectForKey:@"bio"];
        }
        else
        {
            [contact setObject:@"" forKey:@"bio"];
        }
        
        if ( [contact objectForKey:@"location_latitude"] && ![[NSNull null] isEqual:[contact objectForKey:@"location_latitude"]] )
        {
            lastStatusLocation_latitude = [contact objectForKey:@"location_latitude"];
            lastStatusLocation_longitude = [contact objectForKey:@"location_longitude"];
        }
        else
        {
            [contact setObject:@"" forKey:@"location_latitude"];
            [contact setObject:@"" forKey:@"location_longitude"];
        }
        
        if ( [contact objectForKey:@"birthday"] && ![[NSNull null] isEqual:[contact objectForKey:@"birthday"]] )
        {
            birthday = [contact objectForKey:@"birthday"];
        }
        else
        {
            [contact setObject:@"" forKey:@"birthday"];
        }
        
        [contact setObject:UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0) forKey:@"dp"];
        
        NSMutableDictionary *contactPackage = [@{@"entry_type": [NSNumber numberWithInt:SHChatBubbleTypeUser],
                                                 @"entry_data": contact} mutableCopy];
        
        [recommendedContacts setObject:contactPackage atIndexedSubscript:i];
        
        // DP loading.
        if ( DPHash && DPHash.length > 0 )
        {
            NSURL *DPURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/userphotos/%@/profile/f_%@.jpg", SH_DOMAIN, userID, DPHash]];
            
            NSURLRequest *request = [NSURLRequest requestWithURL:DPURL];
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                UIImage *testDP = [UIImage imageWithData:data];
                
                if ( testDP )
                {
                    [contact setObject:data forKey:@"dp"];
                    
                    NSMutableDictionary *entry = [recommendedContacts objectAtIndex:i];
                    
                    [entry setObject:contact forKey:@"entry_data"];
                    [recommendedContacts setObject:entry atIndexedSubscript:i];
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        for ( int j = 0; j < _allRecommendations.count; j++ )
                        {
                            NSMutableDictionary *entry = [_allRecommendations objectAtIndex:j];
                            NSMutableDictionary *entryData = [entry objectForKey:@"entry_data"];
                            SHChatBubbleType entryType = [[entry objectForKey:@"entry_type"] intValue];
                            
                            if ( entryType == SHChatBubbleTypeUser )
                            {
                                int entryID = [[entryData objectForKey:@"user_id"] intValue];
                                
                                if ( entryID == userID.intValue )
                                {
                                    [entry setObject:contact forKey:@"entry_data"];
                                    [_allRecommendations setObject:entry atIndexedSubscript:j];
                                    
                                    break;
                                }
                            }
                        }
                        
                        // Now we update the user's Cloud directly.
                        for ( int j = 0; j < appDelegate.mainMenu.contactCloud.cloudBubbles.count; j++ )
                        {
                            SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:j];
                            
                            if ( bubble.bubbleType == SHChatBubbleTypeUser )
                            {
                                int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                                
                                if ( bubbleID == userID.intValue )
                                {
                                    dispatch_async(dispatch_get_main_queue(), ^(void){
                                        [bubble.metadata setObject:[contact objectForKey:@"dp"] forKey:@"dp"];
                                        [bubble setImage:[UIImage imageWithData:[contact objectForKey:@"dp"]]];
                                    });
                                    
                                    [appDelegate.mainMenu.contactCloud.cloudBubbles setObject:bubble atIndexedSubscript:j];
                                    
                                    break;
                                }
                            }
                        }
                    });
                }
            }];
        }
    }
    
    for ( int i = 0; i < recommendedBoards.count; i++ )
    {
        NSMutableDictionary *board = [[recommendedBoards objectAtIndex:i] mutableCopy];
        [board setObject:@"1" forKey:@"temp"];
        
        NSString *boardID = [board objectForKey:@"board_id"];
        BOOL boardExists = NO;
        
        // Check if this board is already in the Cloud.
        for ( int j = 0; j < appDelegate.mainMenu.contactCloud.cloudBubbles.count; j++ )
        {
            SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:j];
            
            if ( bubble.bubbleType == SHChatBubbleTypeBoard )
            {
                int bubbleID = [[bubble.metadata objectForKey:@"board_id"] intValue];
                
                if ( bubbleID == boardID.intValue )
                {
                    boardExists = YES;
                    
                    break;
                }
            }
        }
        
        if ( boardExists )
        {
            [recommendedBoards removeObjectAtIndex:i];
            i--; // Backtrack!
            
            continue;
        }
        
        NSString *description = @"";
        NSString *DPHash = @"";
        
        [board setObject:@"" forKey:@"owner_id"];
        [board setObject:@"" forKey:@"cover_hash"]; // Set the actual hash once the image is downloaded.
        
        if ( [board objectForKey:@"description"] && ![[NSNull null] isEqual:[board objectForKey:@"description"]] )
        {
            description = [board objectForKey:@"description"];
        }
        else
        {
            [board setObject:@"" forKey:@"description"];
        }
        
        if ( [board objectForKey:@"cover_hash"] && ![[NSNull null] isEqual:[board objectForKey:@"cover_hash"]] )
        {
            DPHash = [board objectForKey:@"cover_hash"];
        }
        
        [board setObject:UIImageJPEGRepresentation([UIImage imageNamed:@"board_placeholder"], 1.0) forKey:@"dp"];
        
        NSMutableDictionary *boardPackage = [@{@"entry_type": [NSNumber numberWithInt:SHChatBubbleTypeBoard],
                                               @"entry_data": board} mutableCopy];
        
        [recommendedBoards setObject:boardPackage atIndexedSubscript:i];
        
        // Cover photo loading.
        if ( DPHash && DPHash.length > 0 )
        {
            NSURL *DPURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/userphotos/nightboard/boards/%@/photos/f_%@.jpg", SH_DOMAIN, boardID, DPHash]];
            
            NSURLRequest *request = [NSURLRequest requestWithURL:DPURL];
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                UIImage *testDP = [UIImage imageWithData:data];
                
                if ( testDP )
                {
                    [board setObject:data forKey:@"dp"];
                    
                    [board setObject:DPHash forKey:@"cover_hash"];
                    
                    NSMutableDictionary *entry = [recommendedBoards objectAtIndex:i];
                    
                    [entry setObject:board forKey:@"entry_data"];
                    [recommendedBoards setObject:entry atIndexedSubscript:i];
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        for ( int j = 0; j < _allRecommendations.count; j++ )
                        {
                            NSMutableDictionary *entry = [_allRecommendations objectAtIndex:j];
                            NSMutableDictionary *entryData = [entry objectForKey:@"entry_data"];
                            SHChatBubbleType entryType = [[entry objectForKey:@"entry_type"] intValue];
                            
                            if ( entryType == SHChatBubbleTypeBoard )
                            {
                                int entryID = [[entryData objectForKey:@"board_id"] intValue];
                                
                                if ( entryID == boardID.intValue )
                                {
                                    [entry setObject:board forKey:@"entry_data"];
                                    [_allRecommendations setObject:entry atIndexedSubscript:j];
                                    
                                    break;
                                }
                            }
                        }
                        
                        // Now we update the user's Cloud directly.
                        for ( int j = 0; j < appDelegate.mainMenu.contactCloud.cloudBubbles.count; j++ )
                        {
                            if ( appDelegate.mainMenu.contactCloud.cloudBubbles.count > j )
                            {
                                SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:j];
                                
                                if ( bubble.bubbleType == SHChatBubbleTypeBoard )
                                {
                                    int bubbleID = [[bubble.metadata objectForKey:@"board_id"] intValue];
                                    
                                    if ( bubbleID == boardID.intValue )
                                    {
                                        dispatch_async(dispatch_get_main_queue(), ^(void){
                                            [bubble.metadata setObject:[board objectForKey:@"dp"] forKey:@"dp"];
                                            [bubble setImage:[UIImage imageWithData:[board objectForKey:@"dp"]]];
                                        });
                                        
                                        [appDelegate.mainMenu.contactCloud.cloudBubbles setObject:bubble atIndexedSubscript:j];
                                        
                                        break;
                                    }
                                }
                            }
                        }
                    });
                }
            }];
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        // Merge the recommended boards with the recommended contacts.
        NSMutableSet *set = [NSMutableSet setWithArray:recommendedContacts];
        [set addObjectsFromArray:recommendedBoards];
        
        _allRecommendations = [[set allObjects] mutableCopy];
        
        if ( _allRecommendations.count > 0 )
        {
            [self coordinatesForMagicNumbersWithDB:db saveLocally:NO callback:@"recommendations"];
        }
        else
        {
            [self contactManagerDidFetchRecommendations:_allRecommendations];
        }
    });
}

- (void)processNewContactsWithDB:(FMDatabase *)db
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    for ( int i = 0; i < _freshContacts.count; i++ )
    {
        NSMutableDictionary *entry = [_freshContacts objectAtIndex:i];
        NSMutableDictionary *contact = [entry objectForKey:@"entry_data"];
        
        NSString *userID = [NSString stringWithFormat:@"%@", [contact objectForKey:@"user_id"]];
        NSString *temp = [contact objectForKey:@"temp"];
        NSString *firstName = [contact objectForKey:@"name_first"];
        NSString *lastName = [contact objectForKey:@"name_last"];
        NSString *alias = @"";
        NSString *userHandle = @"";
        __block NSString *DPHash = @"";
        NSString *imageData_alias = @""; // Insert this as a blank string instead of NSData, since the alias pic is only set & available locally.
        NSString *email = @"";
        NSString *gender = @"";
        NSString *location_country = @"";
        NSString *location_state = @"";
        NSString *location_city = @"";
        NSString *website = @"";
        NSString *bio = @"";
        NSString *facebookHandle = @"";
        NSString *twitterHandle = @"";
        NSString *instagramHandle = @"";
        NSString *joinDate = [contact objectForKey:@"join_date"];
        NSString *birthday = @"";
        NSString *hidden = [contact objectForKey:@"removed_by_user"];
        NSString *blocked = [contact objectForKey:@"blocked"];
        
        NSString *lastStatus = [contact objectForKey:@"message"];
        NSString *lastStatusID = [NSString stringWithFormat:@"%@", [contact objectForKey:@"thread_id"]];
        NSString *lastStatusTimestamp = [contact objectForKey:@"timestamp_sent"];
        NSString *lastStatusPrivacy = [contact objectForKey:@"privacy"];
        NSString *lastStatusType = [contact objectForKey:@"thread_type"];
        NSString *lastStatusOwnerType = [contact objectForKey:@"owner_type"];
        NSString *lastStatusLocation_latitude = @"";
        NSString *lastStatusLocation_longitude = @"";
        NSString *lastStatusRootItemID = [contact objectForKey:@"root_item_id"];
        NSString *lastStatusChildCount = [contact objectForKey:@"child_count"];
        NSString *lastStatusUnreadMessageCount = [contact objectForKey:@"unread_message_count"];
        NSString *lastStatusGroupID = [contact objectForKey:@"group_id"];
        NSString *lastStatusStatus_sent = [contact objectForKey:@"status_sent"];
        NSString *lastStatusStatus_delivered = [contact objectForKey:@"status_delivered"];
        NSString *lastStatusStatus_read = [contact objectForKey:@"status_read"];
        NSString *lastStatusTimestamp_delivered = [contact objectForKey:@"timestamp_delivered"];
        NSString *lastStatusTimestamp_read = [contact objectForKey:@"timestamp_read"];
        NSString *lastStatusMediaType = @"";
        NSString *lastStatusMediaFileSize = @"";
        NSString *lastStatusMediaLocalPath = @"";
        NSString *lastStatusMediaHash = @"";
        NSString *lastStatusMediaData = @"";
        NSDictionary *lastStatusMediaExtra = [contact objectForKey:@"media_extra"];
        
        NSString *presence = [contact objectForKey:@"presence"];
        NSString *presenceTarget = [contact objectForKey:@"presence_target"];
        NSString *presenceAudience = [contact objectForKey:@"presence_audience"];
        NSString *presenceTimestamp = [contact objectForKey:@"presence_timestamp"];
        
        [contact setObject:lastStatusID forKey:@"last_status_id"]; // Some things rely on this key or they'll break.
        
        if ( [contact objectForKey:@"user_handle"] && ![[NSNull null] isEqual:[contact objectForKey:@"user_handle"]] )
        {
            userHandle = [contact objectForKey:@"user_handle"];
        }
        else
        {
            [contact setObject:@"" forKey:@"user_handle"];
        }
        
        if ( [contact objectForKey:@"dp_hash"] && ![[NSNull null] isEqual:[contact objectForKey:@"dp_hash"]] )
        {
            DPHash = [contact objectForKey:@"dp_hash"];
        }
        else
        {
            [contact setObject:@"" forKey:@"dp_hash"];
        }
        
        if ( [contact objectForKey:@"email_address"] && ![[NSNull null] isEqual:[contact objectForKey:@"email_address"]] )
        {
            email = [contact objectForKey:@"email_address"];
        }
        else
        {
            [contact setObject:@"" forKey:@"email_address"];
        }
        
        if ( [contact objectForKey:@"gender"] && ![[NSNull null] isEqual:[contact objectForKey:@"gender"]] )
        {
            gender = [contact objectForKey:@"gender"];
        }
        else
        {
            [contact setObject:@"" forKey:@"gender"];
        }
        
        if ( [contact objectForKey:@"location_country"] && ![[NSNull null] isEqual:[contact objectForKey:@"location_country"]] )
        {
            location_country = [contact objectForKey:@"location_country"];
        }
        else
        {
            [contact setObject:@"" forKey:@"location_country"];
        }
        
        if ( [contact objectForKey:@"location_state"] && ![[NSNull null] isEqual:[contact objectForKey:@"location_state"]] )
        {
            location_state = [contact objectForKey:@"location_state"];
        }
        else
        {
            [contact setObject:@"" forKey:@"location_state"];
        }
        
        if ( [contact objectForKey:@"location_city"] && ![[NSNull null] isEqual:[contact objectForKey:@"location_city"]] )
        {
            location_city = [contact objectForKey:@"location_city"];
        }
        else
        {
            [contact setObject:@"" forKey:@"location_city"];
        }
        
        if ( [contact objectForKey:@"website"] && ![[NSNull null] isEqual:[contact objectForKey:@"website"]] )
        {
            website = [contact objectForKey:@"website"];
        }
        else
        {
            [contact setObject:@"" forKey:@"website"];
        }
        
        if ( [contact objectForKey:@"bio"] && ![[NSNull null] isEqual:[contact objectForKey:@"bio"]] )
        {
            bio = [contact objectForKey:@"bio"];
        }
        else
        {
            [contact setObject:@"" forKey:@"bio"];
        }
        
        if ( [contact objectForKey:@"facebook_id"] && ![[NSNull null] isEqual:[contact objectForKey:@"facebook_id"]] )
        {
            facebookHandle = [contact objectForKey:@"facebook_id"];
        }
        else
        {
            [contact setObject:@"" forKey:@"facebook_id"];
        }
        
        if ( [contact objectForKey:@"twitter_id"] && ![[NSNull null] isEqual:[contact objectForKey:@"twitter_id"]] )
        {
            twitterHandle = [contact objectForKey:@"twitter_id"];
        }
        else
        {
            [contact setObject:@"" forKey:@"twitter_id"];
        }
        
        if ( [contact objectForKey:@"instagram_id"] && ![[NSNull null] isEqual:[contact objectForKey:@"instagram_id"]] )
        {
            instagramHandle = [contact objectForKey:@"instagram_id"];
        }
        else
        {
            [contact setObject:@"" forKey:@"instagram_id"];
        }
        
        if ( [contact objectForKey:@"location_latitude"] && ![[NSNull null] isEqual:[contact objectForKey:@"location_latitude"]] )
        {
            lastStatusLocation_latitude = [contact objectForKey:@"location_latitude"];
            lastStatusLocation_longitude = [contact objectForKey:@"location_longitude"];
        }
        else
        {
            [contact setObject:@"" forKey:@"location_latitude"];
            [contact setObject:@"" forKey:@"location_longitude"];
        }
        
        if ( [contact objectForKey:@"birthday"] && ![[NSNull null] isEqual:[contact objectForKey:@"birthday"]] )
        {
            birthday = [contact objectForKey:@"birthday"];
        }
        else
        {
            [contact setObject:@"" forKey:@"birthday"];
        }
        
        NSDictionary *argsDict_contact = [NSDictionary dictionaryWithObjectsAndKeys:userID, @"user_id",
                                          temp, @"temp",
                                          hidden, @"hidden",
                                          firstName, @"name_first",
                                          lastName, @"name_last",
                                          alias, @"alias",
                                          userHandle, @"user_handle",
                                          DPHash, @"dp_hash",
                                          @"", @"dp",
                                          imageData_alias, @"alias_dp",
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
                                          lastStatusID, @"last_status_id",
                                          blocked, @"blocked",
                                          [NSNumber numberWithInt:0], @"total_messages_sent",
                                          [NSNumber numberWithInt:0], @"total_messages_received",
                                          [NSNumber numberWithInt:0], @"view_count",
                                          [NSNumber numberWithInt:0], @"coordinate_x",
                                          [NSNumber numberWithInt:0], @"coordinate_y",
                                          @"0", @"rank_score", nil];
        
        [db executeUpdate:@"INSERT INTO sh_cloud "
                            @"(sh_user_id, temp, hidden, blocked, name_first, name_last, alias, user_handle, dp_hash, alias_dp, email_address, gender, birthday, location_country, location_state, location_city, website, bio, facebook_id, twitter_id, instagram_id, join_date, last_status_id, total_messages_sent, total_messages_received, view_count, coordinate_x, coordinate_y, rank_score) "
                            @"VALUES (:user_id, :temp, :hidden, :blocked, :name_first, :name_last, :alias, :user_handle, :dp_hash, :alias_dp, :email_address, :gender, :birthday, :location_country, :location_state, :location_city, :website, :bio, :facebook_id, :twitter_id, :instagram_id, :join_date, :last_status_id, :total_messages_sent, :total_messages_received, :view_count, :coordinate_x, :coordinate_y, :rank_score)"
                withParameterDictionary:argsDict_contact];
        
        // Insert their phone numbers.
        for ( NSDictionary *phoneNumberPack in [contact objectForKey:@"phone_numbers"] )
        {
            NSString *countryCallingCode = [phoneNumberPack objectForKey:@"country_calling_code"];
            NSString *prefix = [phoneNumberPack objectForKey:@"prefix"];
            NSString *phoneNumber = [phoneNumberPack objectForKey:@"phone_number"];
            
            NSDictionary *argsDict_phoneNumber = [NSDictionary dictionaryWithObjectsAndKeys:countryCallingCode, @"country_calling_code",
                                                  prefix, @"prefix",
                                                  phoneNumber, @"phone_number",
                                                  userID, @"user_id", nil];
            
            [db executeUpdate:@"INSERT INTO sh_phone_numbers "
                                @"(country_calling_code, prefix, phone_number, sh_user_id) "
                                @"VALUES (:country_calling_code, :prefix, :phone_number, :user_id)"
                    withParameterDictionary:argsDict_phoneNumber];
        }
        
        // Store their latest status update.
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
        
        // Store the presence values.
        NSDictionary *argsDict_presence = [NSDictionary dictionaryWithObjectsAndKeys:userID, @"user_id",
                                           presence, @"status",
                                           presenceTarget, @"target_id",
                                           presenceAudience, @"audience",
                                           presenceTimestamp, @"timestamp", nil];
        
        [db executeUpdate:@"INSERT INTO sh_user_online_status "
                            @"(user_id, status, target_id, audience, timestamp) "
                            @"VALUES (:user_id, :status, :target_id, :audience, :timestamp)"
                withParameterDictionary:argsDict_presence];
        
        [contact setObject:UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0) forKey:@"dp"];
        
        NSMutableDictionary *contactPackage = [@{@"entry_type": [NSNumber numberWithInt:SHChatBubbleTypeUser],
                                                 @"entry_data": contact} mutableCopy];
        
        [_freshContacts setObject:contactPackage atIndexedSubscript:i];
        
        // DP loading.
        if ( DPHash.length > 0 )
        {
            NSURL *DPURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/userphotos/%@/profile/f_%@.jpg", SH_DOMAIN, userID, DPHash]];
            
            NSURLRequest *request = [NSURLRequest requestWithURL:DPURL];
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                UIImage *testDP = [UIImage imageWithData:data];
                
                if ( testDP )
                {
                    [contact setObject:data forKey:@"dp"];
                }
                else // Download failed.
                {
                    DPHash = @""; // Clear the hash out so the manager attempts to redownload the image during the next round.
                    
                    [contact setObject:UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0) forKey:@"dp"];
                }
                
                if ( _freshContacts.count > i )
                {
                    [entry setObject:contact forKey:@"entry_data"];
                    [_freshContacts setObject:entry atIndexedSubscript:i];
                }
                
                [db executeUpdate:@"UPDATE sh_cloud "
                                    @"SET dp = :dp, dp_hash = :dp_hash "
                                    @"WHERE sh_user_id = :user_id"
                        withParameterDictionary:@{@"user_id": userID,
                                                  @"dp": [contact objectForKey:@"dp"],
                                                  @"dp_hash": DPHash}];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    // Now we update the user's Cloud directly.
                    for ( int j = 0; j < appDelegate.mainMenu.contactCloud.cloudBubbles.count; j++ )
                    {
                        if ( appDelegate.mainMenu.contactCloud.cloudBubbles.count > j )
                        {
                            SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:j];
                            
                            if ( bubble.bubbleType == SHChatBubbleTypeUser )
                            {
                                int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                                
                                if ( bubbleID == userID.intValue )
                                {
                                    dispatch_async(dispatch_get_main_queue(), ^(void){
                                        [bubble.metadata setObject:[contact objectForKey:@"dp"] forKey:@"dp"];
                                        [bubble setImage:[UIImage imageWithData:data]];
                                    });
                                    
                                    [appDelegate.mainMenu.contactCloud.cloudBubbles setObject:bubble atIndexedSubscript:j];
                                    
                                    break;
                                }
                            }
                        }
                    }
                });
            }];
        }
        else // If the user has no pic on the server, pull one from the local address book.
        {
            BOOL foundUserInAddressBook = NO;
            for ( NSDictionary *phoneNumberPack in [contact objectForKey:@"phone_numbers"] ) // Keep going thru all their phone numbers till we find a pic.
            {
                NSString *countryCallingCode = [phoneNumberPack objectForKey:@"country_calling_code"];
                NSString *prefix = [phoneNumberPack objectForKey:@"prefix"];
                NSString *phoneNumber = [phoneNumberPack objectForKey:@"phone_number"];
                
                ABRecordRef user = (__bridge ABRecordRef)([self addressBookInfoForNumber:phoneNumber withCountryCallingCode:countryCallingCode prefix:prefix]);
                
                if ( user )
                {
                    if ( ABPersonHasImageData(user) )
                    {
                        NSData *imageData = (__bridge_transfer NSData *)ABPersonCopyImageDataWithFormat(user, kABPersonImageFormatThumbnail);
                        [contact setObject:imageData forKey:@"dp"];
                    }
                    else
                    {
                        NSLog(@"no pic.");
                        [contact setObject:UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0) forKey:@"dp"];
                    }
                    
                    [db executeUpdate:@"UPDATE sh_cloud "
                                        @"SET dp = :dp "
                                        @"WHERE sh_user_id = :user_id"
                            withParameterDictionary:@{@"user_id": userID,
                                                      @"dp": [contact objectForKey:@"dp"]}];
                    
                    CFRelease(user);
                    
                    foundUserInAddressBook = YES;
                    
                    break;
                }
            }
            
            if ( !foundUserInAddressBook )
            {
                [db executeUpdate:@"UPDATE sh_cloud "
                                    @"SET dp = :dp "
                                    @"WHERE sh_user_id = :user_id"
                        withParameterDictionary:@{@"user_id": userID,
                                                  @"dp": [contact objectForKey:@"dp"]}];
            }
            
            if ( [hidden boolValue] )
            {
                [_freshContacts removeObjectAtIndex:i];
            }
            else
            {
                // Update the array entry.
                [entry setObject:contact forKey:@"entry_data"];
                [_freshContacts setObject:entry atIndexedSubscript:i];
            }
        }
    }
    
    for ( int i = 0; i < _freshBoards.count; i++ )
    {
        NSMutableDictionary *entry = [_freshBoards objectAtIndex:i];
        NSMutableDictionary *board = [entry objectForKey:@"entry_data"];
        
        NSString *boardID = [NSString stringWithFormat:@"%@", [board objectForKey:@"board_id"]];
        NSString *name = [board objectForKey:@"name"];
        NSString *privacy = [NSString stringWithFormat:@"%@", [board objectForKey:@"privacy"]];
        NSString *dateCreated = [board objectForKey:@"date_created"];
        NSString *description = @"";
        __block NSString *DPHash = @"";
        
        [board setObject:@"" forKey:@"owner_id"]; // This property is for a proposed individual user boards idea.
        
        if ( [board objectForKey:@"description"] && ![[NSNull null] isEqual:[board objectForKey:@"description"]] )
        {
            description = [board objectForKey:@"description"];
        }
        else
        {
            [board setObject:@"" forKey:@"description"];
        }
        
        if ( [board objectForKey:@"cover_hash"] && ![[NSNull null] isEqual:[board objectForKey:@"cover_hash"]] )
        {
            DPHash = [board objectForKey:@"cover_hash"];
        }
        else
        {
            [board setObject:@"" forKey:@"cover_hash"];
        }
        
        NSDictionary *argsDict_board = @{@"board_id": boardID,
                                         @"name": name,
                                         @"description": description,
                                         @"privacy": privacy,
                                         @"cover_hash": DPHash,
                                         @"date_created": dateCreated,
                                         @"view_count": @"0",
                                         @"coordinate_x": @"0",
                                         @"coordinate_y": @"0",
                                         @"rank_score": @"0"};
        
        [db executeUpdate:@"INSERT INTO sh_board "
                            @"(board_id, name, description, privacy, cover_hash, date_created, view_count, coordinate_x, coordinate_y, rank_score) "
                            @"VALUES (:board_id, :name, :description, :privacy, :cover_hash, :date_created, :view_count, :coordinate_x, :coordinate_y, :rank_score)"
                withParameterDictionary:argsDict_board];
        
        // Cover loading.
        if ( DPHash.length > 0 )
        {
            NSURL *DPURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/userphotos/nightboard/boards/%@/photos/f_%@.jpg", SH_DOMAIN, boardID, DPHash]];
            
            NSURLRequest *request = [NSURLRequest requestWithURL:DPURL];
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                UIImage *testDP = [UIImage imageWithData:data];
                
                if ( testDP )
                {
                    [board setObject:data forKey:@"dp"];
                }
                else // Download failed.
                {
                    DPHash = @""; // Clear the hash out so the manager attempts to redownload the image during the next round.
                    
                    [board setObject:UIImageJPEGRepresentation([UIImage imageNamed:@"board_placeholder"], 1.0) forKey:@"dp"];
                }
                
                if ( _freshBoards.count > i )
                {
                    [entry setObject:board forKey:@"entry_data"];
                    [_freshBoards setObject:entry atIndexedSubscript:i];
                }
                
                [db executeUpdate:@"UPDATE sh_board "
                                    @"SET dp = :dp, cover_hash = :cover_hash "
                                    @"WHERE board_id = :board_id"
                        withParameterDictionary:@{@"board_id": boardID,
                                                  @"dp": [board objectForKey:@"dp"],
                                                  @"cover_hash": DPHash}];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    // Now we update the user's Cloud directly.
                    for ( int j = 0; j < appDelegate.mainMenu.contactCloud.cloudBubbles.count; j++ )
                    {
                        if ( appDelegate.mainMenu.contactCloud.cloudBubbles.count > j )
                        {
                            SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:j];
                            
                            if ( bubble.bubbleType == SHChatBubbleTypeBoard )
                            {
                                int bubbleID = [[bubble.metadata objectForKey:@"board_id"] intValue];
                                
                                if ( bubbleID == boardID.intValue )
                                {
                                    dispatch_async(dispatch_get_main_queue(), ^(void){
                                        [bubble.metadata setObject:[board objectForKey:@"dp"] forKey:@"dp"];
                                        [bubble setImage:[UIImage imageWithData:[board objectForKey:@"dp"]]];
                                    });
                                    
                                    [appDelegate.mainMenu.contactCloud.cloudBubbles setObject:bubble atIndexedSubscript:j];
                                    
                                    break;
                                }
                            }
                        }
                    }
                });
            }];
        }
        else // No pic.
        {
            [board setObject:UIImageJPEGRepresentation([UIImage imageNamed:@"board_placeholder"], 1.0) forKey:@"dp"];
            [entry setObject:board forKey:@"entry_data"];
            [_freshBoards setObject:entry atIndexedSubscript:i];
        }
    }
    
    _contactCount += _freshContacts.count;
    _contactCount += _freshBoards.count;
    
    [self refreshContactsStateWithDB:db];
}

- (void)refreshContactsStateWithDB:(FMDatabase *)db
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( _contactCount == 0 ) // Without this check, the delegate would never know that there are no contacts.
    {
        [self contactManagerDidFetchFollowing:_freshContacts];
        
        return;
    }
    
    BOOL updatedRecipientBubble = NO;
    
    for ( int i = 0; i < _allContacts.count; i++ )
    {
        NSMutableDictionary *entry = [_allContacts objectAtIndex:i];
        NSMutableDictionary *contact = [entry objectForKey:@"entry_data"];
        
        NSString *userID = [NSString stringWithFormat:@"%@", [contact objectForKey:@"user_id"]];
        NSString *firstName = [contact objectForKey:@"name_first"];
        NSString *lastName = [contact objectForKey:@"name_last"];
        NSString *userHandle = @"";
        __block NSString *DPHash = @"";
        NSString *email = @"";
        NSString *gender = @"";
        NSString *location_country = @"";
        NSString *location_state = @"";
        NSString *location_city = @"";
        NSString *website = @"";
        NSString *bio = @"";
        NSString *birthday = @"";
        NSString *facebookHandle = @"";
        NSString *twitterHandle = @"";
        NSString *instagramHandle = @"";
        NSString *hidden = [contact objectForKey:@"removed_by_user"];
        NSString *blocked = [contact objectForKey:@"blocked"];
        BOOL blockedByUser = [[contact objectForKey:@"blocked_by"] boolValue];
        
        NSString *lastStatus = [contact objectForKey:@"message"];
        NSString *lastStatusID = [contact objectForKey:@"thread_id"];
        NSString *lastStatusTimestamp = [contact objectForKey:@"timestamp_sent"];
        NSString *lastStatusPrivacy = [contact objectForKey:@"privacy"];
        NSString *lastStatusType = [contact objectForKey:@"thread_type"];
        NSString *lastStatusOwnerType = [contact objectForKey:@"owner_type"];
        NSString *lastStatusLocation_latitude = @"";
        NSString *lastStatusLocation_longitude = @"";
        NSString *lastStatusRootItemID = [contact objectForKey:@"root_item_id"];
        NSString *lastStatusChildCount = [contact objectForKey:@"child_count"];
        NSString *lastStatusUnreadMessageCount = [contact objectForKey:@"unread_message_count"];
        NSString *lastStatusGroupID = [contact objectForKey:@"group_id"];
        NSString *lastStatusStatus_sent = [contact objectForKey:@"status_sent"];
        NSString *lastStatusStatus_delivered = [contact objectForKey:@"status_delivered"];
        NSString *lastStatusStatus_read = [contact objectForKey:@"status_read"];
        NSString *lastStatusTimestamp_delivered = [contact objectForKey:@"timestamp_delivered"];
        NSString *lastStatusTimestamp_read = [contact objectForKey:@"timestamp_read"];
        NSString *lastStatusMediaType = @"";
        NSString *lastStatusMediaFileSize = @"";
        NSString *lastStatusMediaLocalPath = @"";
        NSString *lastStatusMediaHash = @"";
        NSString *lastStatusMediaData = @"";
        NSDictionary *lastStatusMediaExtra = [contact objectForKey:@"media_extra"];
        
        NSString *presence = [contact objectForKey:@"presence"];
        NSString *presenceTarget = [contact objectForKey:@"presence_target"];
        NSString *presenceAudience = [contact objectForKey:@"presence_audience"];
        NSString *presenceTimestamp = [contact objectForKey:@"presence_timestamp"];
        
        if ( !blockedByUser ) // Only refresh this person's data if they haven't blocked the current user.
        {
            if ( [contact objectForKey:@"user_handle"] && ![[NSNull null] isEqual:[contact objectForKey:@"user_handle"]] )
            {
                userHandle = [contact objectForKey:@"user_handle"];
            }
            else
            {
                [contact setObject:@"" forKey:@"user_handle"];
            }
            
            if ( [contact objectForKey:@"dp_hash"] && ![[NSNull null] isEqual:[contact objectForKey:@"dp_hash"]] )
            {
                DPHash = [contact objectForKey:@"dp_hash"];
            }
            else
            {
                [contact setObject:@"" forKey:@"dp_hash"];
            }
            
            if ( [contact objectForKey:@"email_address"] && ![[NSNull null] isEqual:[contact objectForKey:@"email_address"]] )
            {
                email = [contact objectForKey:@"email_address"];
            }
            else
            {
                [contact setObject:@"" forKey:@"email_address"];
            }
            
            if ( [contact objectForKey:@"gender"] && ![[NSNull null] isEqual:[contact objectForKey:@"gender"]] )
            {
                gender = [contact objectForKey:@"gender"];
            }
            else
            {
                [contact setObject:@"" forKey:@"gender"];
            }
            
            if ( [contact objectForKey:@"location_country"] && ![[NSNull null] isEqual:[contact objectForKey:@"location_country"]] )
            {
                location_country = [contact objectForKey:@"location_country"];
            }
            else
            {
                [contact setObject:@"" forKey:@"location_country"];
            }
            
            if ( [contact objectForKey:@"location_state"] && ![[NSNull null] isEqual:[contact objectForKey:@"location_state"]] )
            {
                location_state = [contact objectForKey:@"location_state"];
            }
            else
            {
                [contact setObject:@"" forKey:@"location_state"];
            }
            
            if ( [contact objectForKey:@"location_city"] && ![[NSNull null] isEqual:[contact objectForKey:@"location_city"]] )
            {
                location_city = [contact objectForKey:@"location_city"];
            }
            else
            {
                [contact setObject:@"" forKey:@"location_city"];
            }
            
            if ( [contact objectForKey:@"website"] && ![[NSNull null] isEqual:[contact objectForKey:@"website"]] )
            {
                website = [contact objectForKey:@"website"];
            }
            else
            {
                [contact setObject:@"" forKey:@"website"];
            }
            
            if ( [contact objectForKey:@"bio"] && ![[NSNull null] isEqual:[contact objectForKey:@"bio"]] )
            {
                bio = [contact objectForKey:@"bio"];
            }
            else
            {
                [contact setObject:@"" forKey:@"bio"];
            }
            
            if ( [contact objectForKey:@"facebook_id"] && ![[NSNull null] isEqual:[contact objectForKey:@"facebook_id"]] )
            {
                facebookHandle = [contact objectForKey:@"facebook_id"];
            }
            else
            {
                [contact setObject:@"" forKey:@"facebook_id"];
            }
            
            if ( [contact objectForKey:@"twitter_id"] && ![[NSNull null] isEqual:[contact objectForKey:@"twitter_id"]] )
            {
                twitterHandle = [contact objectForKey:@"twitter_id"];
            }
            else
            {
                [contact setObject:@"" forKey:@"twitter_id"];
            }
            
            if ( [contact objectForKey:@"instagram_id"] && ![[NSNull null] isEqual:[contact objectForKey:@"instagram_id"]] )
            {
                instagramHandle = [contact objectForKey:@"instagram_id"];
            }
            else
            {
                [contact setObject:@"" forKey:@"instagram_id"];
            }
            
            if ( [contact objectForKey:@"location_latitude"] && ![[NSNull null] isEqual:[contact objectForKey:@"location_latitude"]] )
            {
                lastStatusLocation_latitude = [contact objectForKey:@"location_latitude"];
                lastStatusLocation_longitude = [contact objectForKey:@"location_longitude"];
            }
            else
            {
                [contact setObject:@"" forKey:@"location_latitude"];
                [contact setObject:@"" forKey:@"location_longitude"];
            }
            
            if ( [contact objectForKey:@"birthday"] && ![[NSNull null] isEqual:[contact objectForKey:@"birthday"]] )
            {
                birthday = [contact objectForKey:@"birthday"];
            }
            else
            {
                [contact setObject:@"" forKey:@"birthday"];
            }
            
            // Check if the contact's DP changed.
            // NOTE: this step needs to be done before updating the hash!
            FMResultSet *s1 = [db executeQuery:@"SELECT dp_hash FROM sh_cloud WHERE sh_user_id = :user_id"
                       withParameterDictionary:@{@"user_id": userID}];
            
            BOOL shouldUpdateDP = YES;
            
            while ( [s1 next] )
            {
                NSString *oldDPHash = [s1 stringForColumnIndex:0];
                
                if ( [oldDPHash isEqualToString:DPHash] && oldDPHash.length > 0 )
                {
                    shouldUpdateDP = NO;
                }
                else
                {
                    // Clear out the old DP to force a fresh download.
                    [db executeUpdate:@"UPDATE sh_cloud SET dp = :dp WHERE sh_user_id = :user_id"
                            withParameterDictionary:@{@"dp": @"",
                                                      @"user_id": userID}];
                }
            }
            
            [s1 close];
            
            // Check if the user even has a DP in the first place!
            s1 = [db executeQuery:@"SELECT dp FROM sh_cloud WHERE sh_user_id = :user_id"
                        withParameterDictionary:@{@"user_id": userID}];
            
            while ( [s1 next] )
            {
                UIImage *currentDP = [UIImage imageWithData:[s1 dataForColumnIndex:0]];
                
                if ( !currentDP )
                {
                    shouldUpdateDP = YES;
                }
            }
            
            [s1 close];
            
            NSDictionary *argsDict_contact = [NSDictionary dictionaryWithObjectsAndKeys:userID, @"user_id",
                                              hidden, @"hidden",
                                              firstName, @"name_first",
                                              lastName, @"name_last",
                                              userHandle, @"user_handle",
                                              DPHash, @"dp_hash",
                                              @"", @"dp",
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
                                              lastStatusID, @"last_status_id",
                                              blocked, @"blocked", nil];
            
            [db executeUpdate:@"UPDATE sh_cloud "
                                @"SET hidden = :hidden, name_first = :name_first, name_last = :name_last, user_handle = :user_handle, blocked = :blocked, dp_hash = :dp_hash, email_address = :email_address, gender = :gender, birthday = :birthday, location_country = :location_country, location_state = :location_state, location_city = :location_city, website = :website, bio = :bio, facebook_id = :facebook_id, twitter_id = :twitter_id, instagram_id = :instagram_id, last_status_id = :last_status_id "
                                @"WHERE sh_user_id = :user_id"
                    withParameterDictionary:argsDict_contact];
            
            // Update their phone numbers.
            for ( NSDictionary *phoneNumberPack in [contact objectForKey:@"phone_numbers"] )
            {
                NSString *countryCallingCode = [phoneNumberPack objectForKey:@"country_calling_code"];
                NSString *prefix = [phoneNumberPack objectForKey:@"prefix"];
                NSString *phoneNumber = [phoneNumberPack objectForKey:@"phone_number"];
                
                NSDictionary *argsDict_phoneNumber = [NSDictionary dictionaryWithObjectsAndKeys:countryCallingCode, @"country_calling_code",
                                                      prefix, @"prefix",
                                                      phoneNumber, @"phone_number",
                                                      userID, @"user_id", nil];
                
                // Delete all the old ones.
                [db executeUpdate:@"DELETE FROM sh_phone_numbers WHERE sh_user_id = :user_id AND sh_user_id <> :current_user_id"
                        withParameterDictionary:@{@"user_id": userID,
                                                  @"current_user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
                
                [db executeUpdate:@"INSERT INTO sh_phone_numbers "
                                    @"(country_calling_code, prefix, phone_number, sh_user_id) "
                                    @"VALUES (:country_calling_code, :prefix, :phone_number, :user_id)"
                        withParameterDictionary:argsDict_phoneNumber];
            }
            
            // Store their latest status update.
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
            
            // Delete the any old copy first.
            [db executeUpdate:@"DELETE FROM sh_thread WHERE thread_id = :thread_id"
                    withParameterDictionary:@{@"thread_id": lastStatusID}];
            
            [db executeUpdate:@"INSERT INTO sh_thread "
                                @"(thread_id, thread_type, root_item_id, child_count, owner_id, owner_type, unread_message_count, privacy, group_id, status_sent, status_delivered, status_read, timestamp_sent, timestamp_delivered, timestamp_read, message, location_longitude, location_latitude, media_type, media_file_size, media_local_path, media_hash, media_data, media_extra) "
                                @"VALUES (:thread_id, :thread_type, :root_item_id, :child_count, :owner_id, :owner_type, :unread_message_count, :privacy, :group_id, :status_sent, :status_delivered, :status_read, :timestamp_sent, :timestamp_delivered, :timestamp_read, :message, :location_longitude, :location_latitude, :media_type, :media_file_size, :media_local_path, :media_hash, :media_data, :media_extra)"
                    withParameterDictionary:argsDict_status];
            
            // Update the last status ID field.
            [db executeUpdate:@"UPDATE sh_cloud SET last_status_id = :thread_id WHERE sh_user_id = :user_id"
                    withParameterDictionary:@{@"thread_id": lastStatusID,
                                              @"user_id": userID}];
            
            // Update their presence values.
            NSDictionary *argsDict_presence = [NSDictionary dictionaryWithObjectsAndKeys:userID, @"user_id",
                                               presence, @"status",
                                               presenceTarget, @"target_id",
                                               presenceAudience, @"audience",
                                               presenceTimestamp, @"timestamp", nil];
            
            [db executeUpdate:@"UPDATE sh_user_online_status "
                                @"SET status = :status, target_id = :target_id, audience = :audience, timestamp = :timestamp "
                                @"WHERE user_id = :user_id"
                    withParameterDictionary:argsDict_presence];
            
            // Update the Chat Cloud.
            BOOL updatedChatCloud = NO;
            
            for ( int i = 0; i < appDelegate.mainMenu.contactCloud.cloudBubbles.count; i++ )
            {
                SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:i];
                
                if ( bubble.bubbleType == SHChatBubbleTypeUser )
                {
                    int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                    
                    if ( bubbleID == userID.intValue && !updatedChatCloud )
                    {
                        SHChatBubble *targetBubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:i];
                        
                        NSData *currentDPImageData = [targetBubble.metadata objectForKey:@"dp"]; // Save a copy before overwriting the metadata dictionary (the DP & alias data will be lost).
                        NSData *currentAliasDPImageData = [targetBubble.metadata objectForKey:@"alias_dp"];
                        NSString *currentAlias = [targetBubble.metadata objectForKey:@"alias"];
                        NSString *unreadThreadCount = [targetBubble.metadata objectForKey:@"unread_thread_count"];
                        
                        if ( currentDPImageData ) // This is a safeguard in case there's still no DP loaded (first login).
                        {
                            [contact setObject:currentDPImageData forKey:@"dp"];
                        }
                        
                        [contact setObject:lastStatusID forKey:@"last_status_id"]; // Some things rely on this key or they'll break.
                        [contact setObject:currentAlias forKey:@"alias"];
                        [contact setObject:unreadThreadCount forKey:@"unread_thread_count"];
                        [contact setObject:presence forKey:@"presence"];
                        [contact setObject:presenceTarget forKey:@"presence_target"];
                        [contact setObject:presenceAudience forKey:@"audience"];
                        [contact setObject:presenceTimestamp forKey:@"presence_timestamp"];
                        
                        UIImage *aliasDP = [UIImage imageWithData:currentAliasDPImageData];
                        
                        if ( aliasDP )
                        {
                            [contact setObject:currentAliasDPImageData forKey:@"alias_dp"];
                        }
                        
                        [targetBubble setMetadata:contact];
                        
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            [targetBubble setBadgeCount:[unreadThreadCount intValue]];
                            [targetBubble setBlocked:[blocked boolValue]];
                            [targetBubble setPresence:[[contact objectForKey:@"presence"] intValue] animated:YES];
                        });
                        
                        [appDelegate.mainMenu.contactCloud.cloudBubbles setObject:targetBubble atIndexedSubscript:i];
                        
                        updatedChatCloud = YES;
                    }
                    
                    if ( appDelegate.mainMenu.activeRecipientBubble.metadata && !updatedRecipientBubble )
                    {
                        int activeRecipientUserID = [[appDelegate.mainMenu.activeRecipientBubble.metadata objectForKey:@"user_id"] intValue];
                        
                        if ( bubbleID == userID.intValue && bubbleID == activeRecipientUserID )
                        {
                            [appDelegate.mainMenu.activeRecipientBubble setMetadata:contact];
                            
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                [appDelegate.mainMenu.activeRecipientBubble setPresence:[[contact objectForKey:@"presence"] intValue] animated:YES];
                            });
                            
                            updatedRecipientBubble = YES;
                        }
                    }
                    else // No active recipient.
                    {
                        updatedRecipientBubble = YES;
                    }
                }
                
                if ( updatedChatCloud && updatedRecipientBubble )
                {
                    break;
                }
            }
            
            // Update their DPs.
            if ( shouldUpdateDP )
            {
                if ( DPHash.length > 0 )
                {
                    NSURL *DPURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/userphotos/%@/profile/f_%@.jpg", SH_DOMAIN, userID, DPHash]];
                    
                    NSURLRequest *request = [NSURLRequest requestWithURL:DPURL];
                    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                        UIImage *customDP = [UIImage imageWithData:[contact objectForKey:@"alias_dp"]];
                        UIImage *testDP = [UIImage imageWithData:data];
                        
                        if ( testDP )
                        {
                            [db executeUpdate:@"UPDATE sh_cloud "
                                                @"SET dp = :dp, dp_hash = :dp_hash "
                                                @"WHERE sh_user_id = :user_id"
                                    withParameterDictionary:@{@"user_id": userID,
                                                              @"dp": data,
                                                              @"dp_hash": DPHash}];
                            
                            if ( !customDP ) // Only if no custom pic is set for this person.
                            {
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                    // Update the Chat Cloud.
                                    for ( int j= 0; j < appDelegate.mainMenu.contactCloud.cloudBubbles.count; j++ )
                                    {
                                        SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:j];
                                        
                                        if ( bubble.bubbleType == SHChatBubbleTypeUser )
                                        {
                                            int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                                            
                                            if ( bubbleID == userID.intValue )
                                            {
                                                dispatch_async(dispatch_get_main_queue(), ^(void){
                                                    [bubble.metadata setObject:data forKey:@"dp"];
                                                    [bubble setImage:[UIImage imageWithData:data]];
                                                });
                                                
                                                [appDelegate.mainMenu.contactCloud.cloudBubbles setObject:bubble atIndexedSubscript:j];
                                                
                                                break;
                                            }
                                        }
                                    }
                                });
                            }
                        }
                        else // Download failed.
                        {
                            DPHash = @""; // Clear the hash out so the manager attempts to redownload the image during the next round.
                            
                            [db executeUpdate:@"UPDATE sh_cloud "
                                                @"SET dp = :dp, dp_hash = :dp_hash "
                                                @"WHERE sh_user_id = :user_id"
                                    withParameterDictionary:@{@"user_id": userID,
                                                              @"dp": UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0),
                                                              @"dp_hash": DPHash}];
                            
                            if ( !customDP ) // Only if no custom pic is set for this person.
                            {
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                    // Update the Cloud.
                                    for ( int j = 0; j < appDelegate.mainMenu.contactCloud.cloudBubbles.count; j++ )
                                    {
                                        SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:j];
                                        
                                        if ( bubble.bubbleType == SHChatBubbleTypeUser )
                                        {
                                            int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                                            
                                            if ( bubbleID == userID.intValue )
                                            {
                                                dispatch_async(dispatch_get_main_queue(), ^(void){
                                                    [bubble.metadata setObject:UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0) forKey:@"dp"];
                                                    [bubble setImage:[UIImage imageNamed:@"user_placeholder"]];
                                                });
                                                
                                                [appDelegate.mainMenu.contactCloud.cloudBubbles setObject:bubble atIndexedSubscript:j];
                                                
                                                break;
                                            }
                                        }
                                    }
                                });
                            }
                        }
                    }];
                }
                else // If the user has no pic on the server, pull one from the local address book.
                {
                    UIImage *customDP = [UIImage imageWithData:[contact objectForKey:@"alias_dp"]];
                    
                    if ( !customDP ) // Only if no custom pic is set for this person.
                    {
                        for ( NSDictionary *phoneNumberPack in [contact objectForKey:@"phone_numbers"] ) // Keep going thru all his phone numbers till we find a pic.
                        {
                            NSString *countryCallingCode = [phoneNumberPack objectForKey:@"country_calling_code"];
                            NSString *prefix = [phoneNumberPack objectForKey:@"prefix"];
                            NSString *phoneNumber = [phoneNumberPack objectForKey:@"phone_number"];
                            
                            ABRecordRef user = (__bridge ABRecordRef)([self addressBookInfoForNumber:phoneNumber withCountryCallingCode:countryCallingCode prefix:prefix]);
                            
                            if ( user )
                            {
                                if ( ABPersonHasImageData(user) )
                                {
                                    NSData *imageData = (__bridge_transfer NSData *)ABPersonCopyImageDataWithFormat(user, kABPersonImageFormatThumbnail);
                                    [contact setObject:imageData forKey:@"dp"];
                                }
                                else
                                {
                                    [contact setObject:UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0) forKey:@"dp"];
                                }
                                
                                [db executeUpdate:@"UPDATE sh_cloud "
                                                    @"SET dp = :dp "
                                                    @"WHERE sh_user_id = :user_id"
                                        withParameterDictionary:@{@"user_id": userID,
                                                    @"dp": [contact objectForKey:@"dp"]}];
                                
                                CFRelease(user);
                                
                                break;
                            }
                            else
                            {
                                [contact setObject:UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0) forKey:@"dp"];
                            }
                            
                            [db executeUpdate:@"UPDATE sh_cloud "
                                                @"SET dp = :dp "
                                                @"WHERE sh_user_id = :user_id"
                                    withParameterDictionary:@{@"user_id": userID,
                                                              @"dp": [contact objectForKey:@"dp"]}];
                            
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                // Update the Cloud.
                                for ( int j = 0; j < appDelegate.mainMenu.contactCloud.cloudBubbles.count; j++ )
                                {
                                    SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:j];
                                    
                                    if ( bubble.bubbleType == SHChatBubbleTypeUser )
                                    {
                                        int bubbleID = [[bubble.metadata objectForKey:@"user_id"] intValue];
                                        
                                        if ( bubbleID == userID.intValue )
                                        {
                                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                                [bubble.metadata setObject:[contact objectForKey:@"dp"] forKey:@"dp"];
                                                [bubble setImage:[UIImage imageNamed:@"user_placeholder"]];
                                            });
                                            
                                            [appDelegate.mainMenu.contactCloud.cloudBubbles setObject:bubble atIndexedSubscript:j];
                                            
                                            break;
                                        }
                                    }
                                }
                            });
                        }
                    }
                }
            }
            
            // Update the array entry.
            // Update the array entry.
            [entry setObject:contact forKey:@"entry_data"];
            [_allContacts setObject:entry atIndexedSubscript:i];
        }
    }
    
    for ( int i = 0; i < _allBoards.count; i++ )
    {
        NSMutableDictionary *entry = [_allBoards objectAtIndex:i];
        NSMutableDictionary *board = [entry objectForKey:@"entry_data"];
        
        NSString *boardID = [NSString stringWithFormat:@"%@", [board objectForKey:@"board_id"]];
        NSString *name = [board objectForKey:@"name"];
        NSString *privacy = [NSString stringWithFormat:@"%@", [board objectForKey:@"privacy"]];
        NSString *description = @"";
        __block NSString *DPHash = @"";
        
        [board setObject:@"" forKey:@"owner_id"]; // This property is for a proposed individual user boards idea.
        
        if ( [board objectForKey:@"description"] && ![[NSNull null] isEqual:[board objectForKey:@"description"]] )
        {
            description = [board objectForKey:@"description"];
        }
        else
        {
            [board setObject:@"" forKey:@"description"];
        }
        
        if ( [board objectForKey:@"cover_hash"] && ![[NSNull null] isEqual:[board objectForKey:@"cover_hash"]] )
        {
            DPHash = [board objectForKey:@"cover_hash"];
        }
        else
        {
            [board setObject:@"" forKey:@"cover_hash"];
        }
        
        // Check if the contact's DP changed.
        // NOTE: this step needs to be done before updating the hash!
        FMResultSet *s1 = [db executeQuery:@"SELECT cover_hash FROM sh_board WHERE board_id = :board_id"
                   withParameterDictionary:@{@"board_id": boardID}];
        
        BOOL shouldUpdateDP = YES;
        
        while ( [s1 next] )
        {
            NSString *oldDPHash = [s1 stringForColumnIndex:0];
            
            if ( [oldDPHash isEqualToString:DPHash] && oldDPHash.length > 0 )
            {
                shouldUpdateDP = NO;
            }
            else
            {
                // Clear out the old DP to force a fresh download.
                [db executeUpdate:@"UPDATE sh_board SET dp = :dp WHERE board_id = :board_id"
                    withParameterDictionary:@{@"dp": @"",
                                              @"board_id": boardID}];
            }
        }
        
        [s1 close];
        
        // Check if the board even has a cover image in the first place!
        s1 = [db executeQuery:@"SELECT dp FROM sh_board WHERE board_id = :board_id"
                    withParameterDictionary:@{@"board_id": boardID}];
        
        while ( [s1 next] )
        {
            UIImage *currentDP = [UIImage imageWithData:[s1 dataForColumnIndex:0]];
            
            if ( !currentDP )
            {
                shouldUpdateDP = YES;
            }
        }
        
        [s1 close];
        
        NSDictionary *argsDict_board = @{@"board_id": boardID,
                                         @"name": name,
                                         @"description": description,
                                         @"privacy": privacy};
        
        [db executeUpdate:@"UPDATE sh_board "
                            @"SET name = :name, description = :description, privacy = :privacy "
                            @"WHERE board_id = :board_id"
            withParameterDictionary:argsDict_board];
        
        // Update the Cloud.
        for ( int i = 0; i < appDelegate.mainMenu.contactCloud.cloudBubbles.count; i++ )
        {
            SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:i];
            
            if ( bubble.bubbleType == SHChatBubbleTypeBoard )
            {
                int bubbleID = [[bubble.metadata objectForKey:@"board_id"] intValue];
                
                if ( bubbleID == boardID.intValue )
                {
                    SHChatBubble *targetBubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:i];
                    NSData *currentDPImageData = [targetBubble.metadata objectForKey:@"dp"]; // Save a copy before overwriting the metadata dictionary (the DP & alias data will be lost).
                    
                    if ( currentDPImageData ) // This is a safeguard in case there's still no DP loaded (first login).
                    {
                        [board setObject:currentDPImageData forKey:@"dp"];
                    }
                    
                    [targetBubble setMetadata:board];
                    
                    [appDelegate.mainMenu.contactCloud.cloudBubbles setObject:targetBubble atIndexedSubscript:i];
                    
                    break;
                }
            }
        }
        
        // Update their DPs.
        if ( shouldUpdateDP )
        {
            if ( DPHash.length > 0 )
            {
                NSURL *DPURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/userphotos/nightboard/boards/%@/photos/f_%@.jpg", SH_DOMAIN, boardID, DPHash]];
                
                NSURLRequest *request = [NSURLRequest requestWithURL:DPURL];
                [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                    UIImage *testDP = [UIImage imageWithData:data];
                    
                    if ( testDP )
                    {
                        [db executeUpdate:@"UPDATE sh_board "
                                            @"SET dp = :dp, cover_hash = :cover_hash "
                                            @"WHERE board_id = :board_id"
                                        withParameterDictionary:@{@"board_id": boardID,
                                                                  @"dp": data,
                                                                  @"cover_hash": DPHash}];
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            // Update the Chat Cloud.
                            for ( int j= 0; j < appDelegate.mainMenu.contactCloud.cloudBubbles.count; j++ )
                            {
                                SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:j];
                                
                                if ( bubble.bubbleType == SHChatBubbleTypeBoard )
                                {
                                    int bubbleUserID = [[bubble.metadata objectForKey:@"board_id"] intValue];
                                    
                                    if ( bubbleUserID == boardID.intValue )
                                    {
                                        dispatch_async(dispatch_get_main_queue(), ^(void){
                                            [bubble.metadata setObject:data forKey:@"dp"];
                                            [bubble setImage:[UIImage imageWithData:data]];
                                        });
                                        
                                        [appDelegate.mainMenu.contactCloud.cloudBubbles setObject:bubble atIndexedSubscript:j];
                                        
                                        break;
                                    }
                                }
                            }
                        });
                    }
                    else // Download failed.
                    {
                        DPHash = @""; // Clear the hash out so the manager attempts to redownload the image during the next round.
                        
                        [db executeUpdate:@"UPDATE sh_board "
                                            @"SET dp = :dp, cover_hash = :cover_hash "
                                            @"WHERE board_id = :board_id"
                                withParameterDictionary:@{@"board_id": boardID,
                                                          @"dp": UIImageJPEGRepresentation([UIImage imageNamed:@"board_placeholder"], 1.0),
                                                          @"cover_hash": DPHash}];
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            // Update the Cloud.
                            for ( int j = 0; j < appDelegate.mainMenu.contactCloud.cloudBubbles.count; j++ )
                            {
                                SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:j];
                                
                                if ( bubble.bubbleType == SHChatBubbleTypeBoard )
                                {
                                    int bubbleUserID = [[bubble.metadata objectForKey:@"board_id"] intValue];
                                    
                                    if ( bubbleUserID == boardID.intValue )
                                    {
                                        dispatch_async(dispatch_get_main_queue(), ^(void){
                                            [bubble.metadata setObject:UIImageJPEGRepresentation([UIImage imageNamed:@"board_placeholder"], 1.0) forKey:@"dp"];
                                            [bubble setImage:[UIImage imageNamed:@"board_placeholder"]];
                                        });
                                        
                                        [appDelegate.mainMenu.contactCloud.cloudBubbles setObject:bubble atIndexedSubscript:j];
                                        
                                        break;
                                    }
                                }
                            }
                        });
                    }
                }];
            }
        }
        
        // Update the array entry.
        [entry setObject:board forKey:@"entry_data"];
        [_allBoards setObject:entry atIndexedSubscript:i];
    }
    
    // Merge the old & new contacts.
    NSMutableSet *set = [NSMutableSet setWithArray:_allContacts];
    [set addObjectsFromArray:_freshContacts];
    
    _allContacts = [[set allObjects] mutableCopy];
    
    // Merge the old & new boards.
    set = [NSMutableSet setWithArray:_allBoards];
    [set addObjectsFromArray:_freshBoards];
    
    _allBoards = [[set allObjects] mutableCopy];
    
    // Now merge the contacts & the boards.
    set = [NSMutableSet setWithArray:_allBoards];
    [set addObjectsFromArray:_allContacts];
    
    _allFollowing = [[set allObjects] mutableCopy];
    
    contactsDownloading = NO;
    
    [self refreshMagicNumbersWithDB:db callback:YES];
}

- (void)refreshMagicNumbersWithDB:(FMDatabase *)db callback:(BOOL)callback
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( appDelegate.SHToken && !contactsDownloading ) // Only if a user is logged in.
    {
        globalViewCount = 0;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        
        NSString *lastMagicRun = [appDelegate.currentUser objectForKey:@"last_magic_run"];
        
        if ( lastMagicRun.length > 0 )
        {
            lastMagicRunTime = [dateFormatter dateFromString:lastMagicRun];
        }
        
        dateToday = [NSDate date];
        
        if ( lastMagicRun.length == 0 ||
            [dateToday timeIntervalSinceDate:lastMagicRunTime] > 86400 ||
            _freshContacts.count > 0 ||
            _freshBoards.count > 0 ) // Perform a Magic Run every 24 hours.
        {
            if ( !db )
            {
                FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
                [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    [self magicNumberRunInternalsWithDB:db];
                }];
            }
            else
            {
                [self magicNumberRunInternalsWithDB:db];
            }
        }
        else
        {
            // The callback arg prevents the delegate from being called every time this method is invoked,
            // which happens to be every time the app becomes active.
            if ( callback )
            {
                // Merge the fresh boards with the fresh contacts.
                NSMutableSet *set = [NSMutableSet setWithArray:_freshContacts];
                [set addObjectsFromArray:_freshBoards];
                
                NSMutableArray *freshStuff = [[set allObjects] mutableCopy];
                
                [self contactManagerDidFetchFollowing:freshStuff];
                [_freshContacts removeAllObjects]; // Clear these out, or they'll get passed to the delegate every time the Magic Numbers are refreshed!
                [_freshBoards removeAllObjects];
            }
        }
    }
}

- (void)magicNumberRunInternalsWithDB:(FMDatabase *)db
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    int globalContactViewCount = 0;
    int globalBoardViewCount = 0;
    
    // View count for all contacts
    FMResultSet *s1 = [db executeQuery:@"SELECT SUM(view_count) FROM sh_cloud WHERE sh_user_id <> :user_id"
               withParameterDictionary:@{@"user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
    
    while ( [s1 next] )
    {
        globalContactViewCount = [s1 intForColumnIndex:0];
    }
    
    s1 = [db executeQuery:@"SELECT SUM(view_count) FROM sh_board"
  withParameterDictionary:nil];
    
    while ( [s1 next] )
    {
        globalBoardViewCount = [s1 intForColumnIndex:0];
    }
    
    [s1 close];
    
    globalViewCount = globalContactViewCount + globalBoardViewCount;
    
    // Count of all messages ever sent.
    s1 = [db executeQuery:@"SELECT total_messages_sent FROM sh_current_user WHERE user_id = :user_id"
                withParameterDictionary:@{@"user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
    
    while ( [s1 next] )
    {
        globalMessagesSentCount = [s1 intForColumnIndex:0];
    }
    
    [s1 close];
    
    // Count of all messages ever received.
    s1 = [db executeQuery:@"SELECT total_messages_received FROM sh_current_user WHERE user_id = :user_id"
                withParameterDictionary:@{@"user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
    
    while ( [s1 next] )
    {
        globalMessagesReceivedCount = [s1 intForColumnIndex:0];
    }
    
    [s1 close];
    
    // Count of all media ever sent.
    s1 = [db executeQuery:@"SELECT COUNT(*) FROM sh_thread WHERE owner_id = :user_id AND media_hash <> -1 AND media_data <> ''"
                withParameterDictionary:@{@"user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
    
    while ( [s1 next] )
    {
        globalMediaSentCount = [s1 intForColumnIndex:0];
    }
    
    [s1 close];
    
    // Count of all media ever received.
    s1 = [db executeQuery:@"SELECT COUNT(*) FROM sh_thread WHERE media_hash <> -1 AND media_data <> '' AND thread_id IN (SELECT thread_id FROM sh_message_dispatch WHERE sender_id = :sender_id)"
                withParameterDictionary:@{@"sender_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
    
    while ( [s1 next] )
    {
        globalMediaReceivedCount = [s1 intForColumnIndex:0];
    }
    
    [s1 close];
    
    for ( int i = 0; i < _allFollowing.count; i++ )
    {
        NSMutableDictionary *entry = [_allFollowing objectAtIndex:i];
        NSMutableDictionary *entryData = [entry objectForKey:@"entry_data"];
        float magicNumber = [self magicNumberForContact:entry withDB:db];
        
        [entryData setObject:[NSNumber numberWithFloat:magicNumber] forKey:@"rank_score"];
        [entry setObject:entryData forKey:@"entry_data"];
        [_allFollowing setObject:entry atIndexedSubscript:i];
    }
    
    NSSortDescriptor *brandDescriptor = [[NSSortDescriptor alloc] initWithKey:@"rank_score" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:brandDescriptor];
    NSArray *sortedArray = [_allFollowing sortedArrayUsingDescriptors:sortDescriptors];
    
    _allFollowing = [sortedArray mutableCopy];
    
    if ( _allFollowing.count > 0 )
    {
        [self coordinatesForMagicNumbersWithDB:db saveLocally:YES callback:@"following"];
    }
    
    // Save the time again.
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    
    __block NSString *lastMagicRun = [appDelegate.currentUser objectForKey:@"last_magic_run"];
    
    if ( lastMagicRun.length > 0 )
    {
        lastMagicRunTime = [dateFormatter dateFromString:[appDelegate.currentUser objectForKey:@"last_magic_run"]];
    }
    
    lastMagicRun = [dateFormatter stringFromDate:dateToday];
    
    [appDelegate.currentUser setObject:lastMagicRun forKey:@"last_magic_run"];
    
    [db executeUpdate:@"UPDATE sh_current_user SET last_magic_run = :last_magic_run"
        withParameterDictionary:@{@"last_magic_run": lastMagicRun}];
}

- (float)magicNumberForContact:(NSMutableDictionary *)contact withDB:(FMDatabase *)db
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    float magicNumber;
    
    SHChatBubbleType entryType = [[contact objectForKey:@"entry_type"] intValue];
    NSMutableDictionary *entryData = [contact objectForKey:@"entry_data"];
    
    // Algorithm Factors
    NSString *ID = @"";
    int viewCount = 0;                // • The number of times the user viewed this contact's profile/conversations.
    int totalMessagesSent = 0;        // • The total number of messages sent to this contact.
    int totalMessagesReceived = 0;    // • The total number of messages received from this contact.
    int totalMediaSent = 0;           // • Photos/videos, etc.
    int totalMediaReceived = 0;
    NSString *lastViewTimestamp;
    NSString *lastMessageTimestamp;
    
    FMResultSet *s1;
    
    if ( entryType == SHChatBubbleTypeUser )
    {
        ID = [entryData objectForKey:@"user_id"];
        
        s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :user_id"
                withParameterDictionary:@{@"user_id": ID}];
        
        while ( [s1 next] )
        {
            viewCount = [s1 intForColumn:@"view_count"];
            lastViewTimestamp = [s1 stringForColumn:@"last_view_timestamp"];
            lastMessageTimestamp = [s1 stringForColumn:@"last_message_timestamp"];
        }
        
        [s1 close];
        
        // Total messages sent to this contact.
        s1 = [db executeQuery:@"SELECT COUNT(*) FROM sh_message_dispatch WHERE sender_id = :user_id AND recipient_id = :recipient_id"
      withParameterDictionary:@{@"recipient_id": [appDelegate.currentUser objectForKey:@"user_id"],
                                @"user_id": ID}];
        
        while ( [s1 next] )
        {
            totalMessagesSent = [s1 intForColumnIndex:0];
        }
        
        [s1 close];
        
        // Total messages received from this contact.
        s1 = [db executeQuery:@"SELECT COUNT(*) FROM sh_message_dispatch WHERE sender_id = :recipient_id AND recipient_id = :user_id"
      withParameterDictionary:@{@"recipient_id": [appDelegate.currentUser objectForKey:@"user_id"],
                                @"user_id": ID}];
        
        while ( [s1 next] )
        {
            totalMessagesReceived = [s1 intForColumnIndex:0];
        }
        
        [s1 close];
        
        // Total media sent to this contact.
        s1 = [db executeQuery:@"SELECT COUNT(*) FROM sh_thread WHERE media_hash <> -1 AND media_data <> '' AND thread_id IN (SELECT thread_id FROM sh_message_dispatch WHERE sender_id = :user_id AND recipient_id = :recipient_id)"
      withParameterDictionary:@{@"recipient_id": [appDelegate.currentUser objectForKey:@"user_id"],
                                @"user_id": ID}];
        
        while ( [s1 next] )
        {
            totalMediaSent = [s1 intForColumnIndex:0];
        }
        
        [s1 close];
        
        // Total media received from this contact.
        s1 = [db executeQuery:@"SELECT COUNT(*) FROM sh_thread WHERE media_hash <> -1 AND media_data <> '' AND thread_id IN (SELECT thread_id FROM sh_message_dispatch WHERE sender_id = :recipient_id AND recipient_id = :user_id)"
      withParameterDictionary:@{@"user_id": ID,
                                @"recipient_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
        
        while ( [s1 next] )
        {
            totalMediaReceived = [s1 intForColumnIndex:0];
        }
        
        [s1 close];
    }
    else
    {
        ID = [entryData objectForKey:@"board_id"];
        
        s1 = [db executeQuery:@"SELECT * FROM sh_board WHERE board_id = :board_id"
                withParameterDictionary:@{@"board_id": ID}];
        
        while ( [s1 next] )
        {
            viewCount = [s1 intForColumn:@"view_count"];
            lastViewTimestamp = [s1 stringForColumn:@"last_view_timestamp"];
        }
        
        [s1 close];
    }
    
    // Now, we need the relative frequencies to calculate an affinity score.
    float rf_views;
    float rf_messagesSent;
    float rf_messagesReceived;
    float rf_mediaSent;
    float rf_mediaReceived;
    
    if ( globalViewCount == 0 )
    {
        rf_views = viewCount;
    }
    else
    {
        rf_views = viewCount / (float)globalViewCount;
    }
    
    if ( globalMessagesSentCount == 0 )
    {
        rf_messagesSent = totalMessagesSent;
    }
    else
    {
        rf_messagesSent = totalMessagesSent / (float)globalMessagesSentCount;
    }
    
    if ( globalMessagesReceivedCount == 0 )
    {
        rf_messagesReceived = totalMessagesReceived;
    }
    else
    {
        rf_messagesReceived = totalMessagesReceived / (float)globalMessagesReceivedCount;
    }
    
    if ( globalMediaSentCount == 0 )
    {
        rf_mediaSent = totalMediaSent;
    }
    else
    {
        rf_mediaSent = totalMediaSent / (float)globalMediaSentCount;
    }
    
    if ( globalMediaReceivedCount == 0 )
    {
        rf_mediaReceived = totalMediaReceived;
    }
    else
    {
        rf_mediaReceived = totalMediaReceived / (float)globalMediaReceivedCount;
    }
    
    // Next, prepare the timestamps for time decay computations.
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    
    NSDate *lastViewTime = [dateFormatter dateFromString:lastViewTimestamp];
    NSDate *lastMessageTime = [dateFormatter dateFromString:lastMessageTimestamp];
    
    int currentMinutes = [dateToday timeIntervalSinceReferenceDate] / 60;
    float lastViewTimeMinutes = [lastViewTime timeIntervalSinceReferenceDate] / 60;
    float lastMessageTimeMinutes = [lastMessageTime timeIntervalSinceReferenceDate] / 60;
    
    float timeDecay = ((currentMinutes - lastMessageTimeMinutes) + (currentMinutes - lastViewTimeMinutes)) / 60; // Time is in hours now.
    timeDecay = timeDecay / 24; // Unit should be in days.
    
    timeDecay = 1 / timeDecay;
    
    float score_views = WEIGHT_VIEWS * rf_views * timeDecay;
    float score_messagesSent = WEIGHT_MESSAGES_SENT * rf_messagesSent * timeDecay;
    float score_messagesReceived = WEIGHT_MESSAGES_RECEIVED * rf_messagesReceived * timeDecay;
    float score_mediaSent = WEIGHT_MEDIA_SENT * rf_mediaSent * timeDecay;
    float score_mediaReceived = WEIGHT_MEDIA_RECEIVED * rf_mediaReceived * timeDecay;
    
    magicNumber = score_views + score_messagesSent + score_messagesReceived + score_mediaSent + score_mediaReceived;
    
    if ( magicNumber < 0 )
    {
        magicNumber = 0;
    }
    
    return magicNumber;
}

- (void)coordinatesForMagicNumbersWithDB:(FMDatabase *)db saveLocally:(BOOL)shouldSave callback:(NSString *)callback
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    int bubbleWidth = CHAT_CLOUD_BUBBLE_SIZE + CHAT_CLOUD_BUBBLE_PADDING * 2;
    int bubbleHeight = CHAT_CLOUD_BUBBLE_SIZE + CHAT_CLOUD_BUBBLE_PADDING * 2;
    int fullBubbleWidth = CHAT_CLOUD_BUBBLE_SIZE + CHAT_CLOUD_BUBBLE_PADDING * 2 + 10;
    int fullBubbleHeight = CHAT_CLOUD_BUBBLE_SIZE + CHAT_CLOUD_BUBBLE_PADDING * 2 + 10;
    
    int screenHeightAsBubbles = bubbleHeight * (appDelegate.screenBounds.size.height / bubbleWidth);
    int screenWidthAsBubbles = bubbleHeight * (appDelegate.screenBounds.size.width / bubbleWidth);
    
    CGSize gridSize = CGSizeMake(MAX(bubbleHeight * _contactCount, screenWidthAsBubbles), MAX(bubbleWidth * _contactCount, screenHeightAsBubbles));
    CGPoint origin = CGPointMake(gridSize.width / 2, gridSize.height / 2);
    
    NSMutableArray *placedContactCoordinates = [NSMutableArray array];
    NSMutableArray *activeArray;
    
    if ( [callback isEqualToString:@"recommendations"] )
    {
        activeArray = _allRecommendations;
    }
    else
    {
        activeArray = _allFollowing;
    }
    
    //NSLog(@"Grid size: %d x %d", (int)gridSize.width, (int)gridSize.height);
    
    // Initial starting point is the center of the cloud.
    int start_x = origin.x - (bubbleWidth / 4);  // Move each bubble back a quarter of its width.
    int start_y = origin.y - (bubbleHeight / 4); // They appear slightly off-centered otherwise.
    int i = 0;
    
    if ( appDelegate.mainMenu.contactCloud.cloudBubbles.count == 0 ) // Empty cloud. Just drop the top entry in the middle.
    {
        if ( [callback isEqualToString:@"recommendations"] )
        {
            NSMutableDictionary *entry = [_allRecommendations objectAtIndex:0];
            NSMutableDictionary *entryData = [entry objectForKey:@"entry_data"];
            //NSLog(@"Using x=%d y=%d for center: %@", start_x, start_y, [entryData objectForKey:@"name_first"]);
            
            [entryData setObject:[NSNumber numberWithInt:start_x] forKey:@"coordinate_x"];
            [entryData setObject:[NSNumber numberWithInt:start_y] forKey:@"coordinate_y"];
            [entry setObject:entryData forKey:@"entry_data"];
            
            [_allRecommendations setObject:entry atIndexedSubscript:0];
        }
        else
        {
            NSMutableDictionary *entry = [_allFollowing objectAtIndex:0];
            NSMutableDictionary *entryData = [entry objectForKey:@"entry_data"];
            SHChatBubbleType entryType = [[entry objectForKey:@"entry_type"] intValue];
            //NSLog(@"Using x=%d y=%d for center: %@", start_x, start_y, [entryData objectForKey:@"name_first"]);
            
            [entryData setObject:[NSNumber numberWithInt:start_x] forKey:@"coordinate_x"];
            [entryData setObject:[NSNumber numberWithInt:start_y] forKey:@"coordinate_y"];
            [entry setObject:entryData forKey:@"entry_data"];
            
            [_allContacts setObject:entry atIndexedSubscript:0];
            
            if ( shouldSave )
            {
                if ( entryType == SHChatBubbleTypeUser )
                {
                    NSDictionary *argsDict_magicData = [NSDictionary dictionaryWithObjectsAndKeys:
                                                        [NSNumber numberWithFloat:start_x], @"coordinate_x",
                                                        [NSNumber numberWithFloat:start_y], @"coordinate_y",
                                                        [entryData objectForKey:@"user_id"], @"sh_user_id", nil];
                    
                    [db executeUpdate:@"UPDATE sh_cloud "
                                        @"SET coordinate_x = :coordinate_x, coordinate_y = :coordinate_y "
                                        @"WHERE sh_user_id = :sh_user_id"
                        withParameterDictionary:argsDict_magicData];
                }
                else
                {
                    NSDictionary *argsDict_magicData = [NSDictionary dictionaryWithObjectsAndKeys:
                                                        [NSNumber numberWithFloat:start_x], @"coordinate_x",
                                                        [NSNumber numberWithFloat:start_y], @"coordinate_y",
                                                        [entryData objectForKey:@"board_id"], @"board_id", nil];
                    
                    [db executeUpdate:@"UPDATE sh_board "
                                        @"SET coordinate_x = :coordinate_x, coordinate_y = :coordinate_y "
                                        @"WHERE board_id = :board_id"
                        withParameterDictionary:argsDict_magicData];
                }
            }
        }
        
        i++;
    }
    
    // We move up one full bubble length, plus some random extra padding value.
    start_y += fullBubbleHeight + 20 + (int)arc4random_uniform(10);
    
    int angle = 1;
    int radius = fabs(origin.y - start_y);
    int x = (origin.x - (bubbleWidth / 4)) + radius * cos(DEGREES_TO_RADIANS(angle)); // Init these.
    int y = (origin.y - (bubbleHeight / 4)) + radius * sin(DEGREES_TO_RADIANS(angle));
    
    for ( ; i < activeArray.count; i++ )
    {
        NSMutableDictionary *entry = [activeArray objectAtIndex:i];
        NSMutableDictionary *entryData = [entry objectForKey:@"entry_data"];
        SHChatBubbleType entryType = [[entry objectForKey:@"entry_type"] intValue];
        
        // Next, we traverse a circular path (counter-clockwise) till we find an empty spot to drop the object in the Cloud.
        for ( int j = 0; j < appDelegate.mainMenu.contactCloud.cloudBubbles.count; j++ )
        {
            SHChatBubble *bubble = [appDelegate.mainMenu.contactCloud.cloudBubbles objectAtIndex:j];
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
        
        // Now, compare against objects that were assigned during this run, but are still not placed in the Cloud.
        for ( int j = 0; j < placedContactCoordinates.count; j++ )
        {
            CGPoint placedContact = [[placedContactCoordinates objectAtIndex:j] CGPointValue];
            
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
        
        // Loop completed without collisions. Place the object.
        //NSLog(@"Using x=%d y=%d for %@", x, y, [entryData objectForKey:@"name_first"]);
        [entryData setObject:[NSNumber numberWithInt:x] forKey:@"coordinate_x"];
        [entryData setObject:[NSNumber numberWithInt:y] forKey:@"coordinate_y"];
        [entry setObject:entryData forKey:@"entry_data"];
        
        [placedContactCoordinates addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]]; // Add their new co-ordinates for checking against next object.
        
        [activeArray setObject:entry atIndexedSubscript:i];
        
        if ( shouldSave )
        {
            if ( entryType == SHChatBubbleTypeUser )
            {
                NSDictionary *argsDict_magicData = [NSDictionary dictionaryWithObjectsAndKeys:
                                                    [NSNumber numberWithFloat:x], @"coordinate_x",
                                                    [NSNumber numberWithFloat:y], @"coordinate_y",
                                                    [entryData objectForKey:@"user_id"], @"sh_user_id", nil];
                
                [db executeUpdate:@"UPDATE sh_cloud "
                                    @"SET coordinate_x = :coordinate_x, coordinate_y = :coordinate_y "
                                    @"WHERE sh_user_id = :sh_user_id"
                    withParameterDictionary:argsDict_magicData];
            }
            else
            {
                NSDictionary *argsDict_magicData = [NSDictionary dictionaryWithObjectsAndKeys:
                                                    [NSNumber numberWithFloat:x], @"coordinate_x",
                                                    [NSNumber numberWithFloat:y], @"coordinate_y",
                                                    [entryData objectForKey:@"board_id"], @"board_id", nil];
                
                [db executeUpdate:@"UPDATE sh_board "
                                    @"SET coordinate_x = :coordinate_x, coordinate_y = :coordinate_y "
                                    @"WHERE board_id = :board_id"
                    withParameterDictionary:argsDict_magicData];
            }
        }
    }
    
    if ( [callback isEqualToString:@"recommendations"] )
    {
        [self contactManagerDidFetchRecommendations:_allRecommendations];
    }
    else
    {
        // Merge the fresh boards with the fresh contacts.
        NSMutableSet *set = [NSMutableSet setWithArray:_freshContacts];
        [set addObjectsFromArray:_freshBoards];
        
        NSMutableArray *freshStuff = [[set allObjects] mutableCopy];
        
        [self contactManagerDidFetchFollowing:freshStuff];
    }
}

- (BOOL)numberExistsInAddressBook:(NSString *)thePhoneNumber withCountryCallingCode:(NSString *)theCallingCode prefix:(NSString *)thePrefix
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined ||
        ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized )
    {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error){
            userDidGrantAddressBookAccess = granted;
            dispatch_semaphore_signal(sema);
        });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [appDelegate.strobeLight negativeStrobeLight];
        });
    }
    
    if ( userDidGrantAddressBookAccess )
    {
        CFErrorRef addressBookError = NULL;
        addressBook = ABAddressBookCreateWithOptions(NULL, &addressBookError);
        allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
        nPeople = ABAddressBookGetPersonCount(addressBook);
        
        for ( int i = 0; i < nPeople; i++ )
        {
            ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
            ABMultiValueRef *phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
            
            for ( int j = 0; j < ABMultiValueGetCount(phones); j++ )
            {
                CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, j);
                NSString *phoneNumberString = (__bridge NSString *)phoneNumberRef;
                
                NSDictionary *phoneNumberPack = [self formatPhoneNumber:phoneNumberString mobileOnly:YES];
                
                if ( phoneNumberPack )
                {
                    int countryCallingCode = [[phoneNumberPack objectForKey:@"country_calling_code"] intValue];
                    int prefix = [[phoneNumberPack objectForKey:@"prefix"] intValue];
                    int phoneNumber = [[phoneNumberPack objectForKey:@"phone_number"] intValue];
                    
                    // Stop at this point & check if we picked up the user.
                    if ( countryCallingCode == theCallingCode.intValue &&
                        prefix == thePrefix.intValue &&
                        phoneNumber == thePhoneNumber.intValue )
                    {
                        CFRelease(phoneNumberRef);
                        CFRelease(phones);
                        CFRelease(person);
                        
                        return YES;
                    }
                }
                
                
                CFRelease(phoneNumberRef);
            }
            
            CFRelease(phones);
            CFRelease(person);
        }
    }
    
    return NO;
}

- (id)addressBookInfoForNumber:(NSString *)thePhoneNumber withCountryCallingCode:(NSString *)theCallingCode prefix:(NSString *)thePrefix
{
    if ( ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined ||
        ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized )
    {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error){
            userDidGrantAddressBookAccess = granted;
            dispatch_semaphore_signal(sema);
        });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        if ( userDidGrantAddressBookAccess )
        {
            CFErrorRef addressBookError = NULL;
            addressBook = ABAddressBookCreateWithOptions(NULL, &addressBookError);
            allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
            nPeople = ABAddressBookGetPersonCount(addressBook);
            
            for ( int i = 0; i < nPeople; i++ )
            {
                ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
                ABMultiValueRef *phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
                
                for ( int j = 0; j < ABMultiValueGetCount(phones); j++ )
                {
                    CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, j);
                    NSString *phoneNumberString = (__bridge NSString *)phoneNumberRef;
                    
                    NSDictionary *phoneNumberPack = [self formatPhoneNumber:phoneNumberString mobileOnly:YES];
                    
                    if ( phoneNumberPack )
                    {
                        int countryCallingCode = [[phoneNumberPack objectForKey:@"country_calling_code"] intValue];
                        int prefix = [[phoneNumberPack objectForKey:@"prefix"] intValue];
                        int phoneNumber = [[phoneNumberPack objectForKey:@"phone_number"] intValue];
                        
                        // Stop at this point & check if we picked up the user.
                        if ( countryCallingCode == theCallingCode.intValue &&
                            prefix == thePrefix.intValue &&
                            phoneNumber == thePhoneNumber.intValue )
                        {
                            CFRelease(phoneNumberRef);
                            CFRelease(phones);
                            
                            return (__bridge id)(person);
                        }
                    }
                    
                    CFRelease(phoneNumberRef);
                }
                
                CFRelease(phones);
                CFRelease(person);
            }
        }
    }
        
    // No match found!
    return nil;
}

- (NSMutableDictionary *)infoForUser:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT * FROM sh_cloud "
                                                                @"WHERE sh_user_id = :user_id"
                                     withParameterDictionary:@{@"user_id": userID}];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    while ( [s1 next] )
    {
        NSString *userHandle = [s1 stringForColumn:@"user_handle"];
        NSString *blocked = [s1 stringForColumn:@"blocked"];
        NSString *alias = [s1 stringForColumn:@"alias"];
        NSString *DPHash = [s1 stringForColumn:@"dp_hash"];
        NSData *DP = [s1 dataForColumn:@"dp"];
        id aliasDP = [s1 dataForColumn:@"alias_dp"];
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
        
        UIImage *currentDP = [UIImage imageWithData:DP];
        
        if ( !currentDP )
        {
            DP = UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0);
        }
        
        if ( !aliasDP )
        {
            aliasDP = @"";
        }
        
        if ( !userHandle )
        {
            userHandle = @"";
        }
        
        if ( !alias )
        {
            alias = @"";
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
        
        [data setObject:[s1 stringForColumn:@"sh_user_id"] forKey:@"user_id"];
        [data setObject:[s1 stringForColumn:@"name_first"] forKey:@"name_first"];
        [data setObject:[s1 stringForColumn:@"name_last"] forKey:@"name_last"];
        [data setObject:alias forKey:@"alias"];
        [data setObject:userHandle forKey:@"user_handle"];
        [data setObject:blocked forKey:@"blocked"];
        [data setObject:DPHash forKey:@"dp_hash"];
        [data setObject:DP forKey:@"dp"];
        [data setObject:aliasDP forKey:@"alias_dp"];
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
        [data setObject:[NSNumber numberWithInt:[s1 intForColumn:@"unread_thread_count"]] forKey:@"unread_thread_count"];
        
        // Total messages sent to this contact.
        FMResultSet *s2 = [appDelegate.modelManager executeQuery:@"SELECT COUNT(*) FROM sh_message_dispatch WHERE sender_id = :user_id AND recipient_id = :recipient_id"
                                         withParameterDictionary:@{@"recipient_id": userID,
                                                                   @"user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
        
        while ( [s2 next] )
        {
            [data setObject:[NSNumber numberWithInt:[s2 intForColumnIndex:0]] forKey:@"total_messages_sent"];
        }
        
        [s2 close];
        
        // Total messages received from this contact.
        s2 = [appDelegate.modelManager executeQuery:@"SELECT COUNT(*) FROM sh_message_dispatch WHERE sender_id = :user_id AND recipient_id = :recipient_id"
                            withParameterDictionary:@{@"recipient_id": [appDelegate.currentUser objectForKey:@"user_id"],
                                                      @"user_id": userID}];
        
        while ( [s2 next] )
        {
            [data setObject:[NSNumber numberWithInt:[s2 intForColumnIndex:0]] forKey:@"total_messages_received"];
        }
        
        [s2 close];
        
        // Phone numbers.
        s2 = [appDelegate.modelManager executeQuery:@"SELECT * FROM sh_phone_numbers WHERE sh_user_id = :user_id"
                            withParameterDictionary:@{@"user_id": userID}];
        
        NSMutableArray *phoneNumbers = [NSMutableArray array];
        
        while ( [s2 next] )
        {
            NSDictionary *phoneNumberPack = @{@"country_calling_code": [s2 stringForColumn:@"country_calling_code"],
                                              @"prefix": [s2 stringForColumn:@"prefix"],
                                              @"phone_number": [s2 stringForColumn:@"phone_number"]};
            
            [phoneNumbers addObject:phoneNumberPack];
        }
        
        [data setObject:phoneNumbers forKey:@"phone_numbers"];
        
        [s2 close];
        
        // Presence.
        s2 = [appDelegate.modelManager executeQuery:@"SELECT * FROM sh_user_online_status WHERE user_id = :sh_user_id"
                            withParameterDictionary:@{@"sh_user_id": [data objectForKey:@"user_id"]}];
        
        while ( [s2 next] )
        {
            NSString *presenceTargetID = [s2 stringForColumn:@"target_id"];
            NSString *presence = [s2 stringForColumn:@"status"];
            NSString *audience = [s2 stringForColumn:@"audience"];
            NSString *presenceTimestamp = [s2 stringForColumn:@"timestamp"];
            
            if ( !presence )
            {
                presence = @"";
            }
            
            if ( !presenceTargetID )
            {
                presenceTargetID = @"";
            }
            
            if ( !audience )
            {
                audience = @"";
            }
            
            if ( !presenceTimestamp )
            {
                presenceTimestamp = @"";
            }
            
            [data setObject:presence forKey:@"presence"];
            [data setObject:presenceTargetID forKey:@"presence_target"];
            [data setObject:audience forKey:@"audience"];
            [data setObject:presenceTimestamp forKey:@"presence_timestamp"];
        }
        
        [s2 close];
    }
    
    [s1 close];
    [appDelegate.modelManager.results close];
    [appDelegate.modelManager.DB close];
    
    return data;
}

- (void)addUser:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    // Fail-safe check. In case the user is already in our contacts, just unhide them.
    FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT sh_user_id FROM sh_cloud WHERE sh_user_id = :user_id"
                                     withParameterDictionary:@{@"user_id": userID}];
    
    BOOL contactAlreadyExists = NO;
    
    while ( [s1 next] )
    {
        contactAlreadyExists = YES;
    }
    
    [s1 close];
    [appDelegate.modelManager.results close];
    [appDelegate.modelManager.DB close];
    
    if ( contactAlreadyExists )
    {
        return;
    }
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[userID]
                                                                          forKeys:@[@"user_id"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/adduser", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        if ( errorCode == 0 )
        {
            NSMutableDictionary *userData = [[responseData objectForKey:@"response"] mutableCopy];
            
            if ( userData )
            {
                [userData setObject:@"0" forKey:@"temp"];
                
                NSMutableDictionary *contactPackage = [@{@"entry_type": [NSNumber numberWithInt:SHChatBubbleTypeUser],
                                                         @"entry_data": userData} mutableCopy];
                
                [appDelegate.contactManager.freshContacts addObject:contactPackage];
                
                FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
                [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    [appDelegate.contactManager processNewContactsWithDB:db];
                }];
                
                [self contactManagerDidAddNewContact:userData];
            }
            else
            {
                NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
                [errorDetails setValue:@"User data error" forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:@"ResponseError" code:500 userInfo:errorDetails];
                
                [self contactManagerRequestDidFailWithError:error];
            }
        }
        else
        {
            NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
            [errorDetails setValue:@"User does not exist" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"ResponseError" code:404 userInfo:errorDetails];
            
            [self contactManagerRequestDidFailWithError:error];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self contactManagerRequestDidFailWithError:error];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)addUsername:(NSString *)username
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    // Fail-safe check. In case the user is already in our contacts, just unhide them.
    FMResultSet *s1 = [appDelegate.modelManager executeQuery:@"SELECT sh_user_id FROM sh_cloud WHERE user_handle = :user_handle COLLATE NOCASE"
                                     withParameterDictionary:@{@"user_handle": username}];
    
    BOOL contactAlreadyExists = NO;
    
    while ( [s1 next] )
    {
        contactAlreadyExists = YES;
    }
    
    [s1 close];
    [appDelegate.modelManager.results close];
    [appDelegate.modelManager.DB close];
    
    if ( contactAlreadyExists )
    {
        return;
    }
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[username]
                                                                          forKeys:@[@"username"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/addbyusername", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        if ( errorCode == 0 )
        {
            NSMutableDictionary *userData = [[responseData objectForKey:@"response"] mutableCopy];
            
            if ( userData )
            {
                [userData setObject:@"0" forKey:@"temp"];
                
                NSMutableDictionary *contactPackage = [@{@"entry_type": [NSNumber numberWithInt:SHChatBubbleTypeUser],
                                                         @"entry_data": userData} mutableCopy];
                
                [appDelegate.contactManager.freshContacts addObject:contactPackage];
                
                FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
                [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    [appDelegate.contactManager processNewContactsWithDB:db];
                }];
                
                [self contactManagerDidAddNewContact:userData];
            }
            else
            {
                NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
                [errorDetails setValue:@"User data error" forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:@"ResponseError" code:500 userInfo:errorDetails];
                
                [self contactManagerRequestDidFailWithError:error];
            }
        }
        else
        {
            NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
            [errorDetails setValue:@"User does not exist" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"ResponseError" code:404 userInfo:errorDetails];
            
            [self contactManagerRequestDidFailWithError:error];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self contactManagerRequestDidFailWithError:error];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)hideUser:(NSString *)userID
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
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/removerecommendeduser", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        if ( errorCode == 0 )
        {
            [self contactManagerDidHideContact:userID];
        }
        else
        {
            NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
            [errorDetails setValue:@"Request response error." forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"ResponseError" code:1 userInfo:errorDetails];
            
            [self contactManagerRequestDidFailWithError:error];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self contactManagerRequestDidFailWithError:error];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)removeUser:(NSString *)userID
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
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/removeuser", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        if ( errorCode == 0 )
        {
            [appDelegate.modelManager executeUpdate:@"DELETE FROM sh_cloud "
                                                    @"WHERE sh_user_id = :user_id"
                            withParameterDictionary:@{@"user_id": userID}];
            
            [appDelegate.modelManager executeUpdate:@"DELETE FROM sh_thread "
                                                    @"WHERE owner_id = :user_id"
                            withParameterDictionary:@{@"user_id": userID}];
            
            [self contactManagerDidRemoveContact:userID];
        }
        else
        {
            NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
            [errorDetails setValue:@"Request response error." forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"ResponseError" code:1 userInfo:errorDetails];
            
            [self contactManagerRequestDidFailWithError:error];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self contactManagerRequestDidFailWithError:error];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)blockContact:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( [self isBlocked:userID withDB:nil] )
    {
        [self contactManagerDidBlockContact:userID];
        
        return;
    }
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[userID]
                                                                          forKeys:@[@"user_id"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/blockuser", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        if ( errorCode == 0 )
        {
            [appDelegate.modelManager executeUpdate:@"UPDATE sh_cloud "
                                                    @"SET blocked = 1 WHERE sh_user_id = :user_id"
                            withParameterDictionary:@{@"user_id": userID}];
            
            [self contactManagerDidBlockContact:userID];
        }
        else
        {
            NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
            [errorDetails setValue:@"Request response error." forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"ResponseError" code:1 userInfo:errorDetails];
            
            [self contactManagerRequestDidFailWithError:error];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self contactManagerRequestDidFailWithError:error];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)unblockContact:(NSString *)userID
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( ![self isBlocked:userID withDB:nil] )
    {
        [self contactManagerDidUnblockContact:userID];
        
        return;
    }
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[userID]
                                                                          forKeys:@[@"user_id"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/unblockuser", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        if ( errorCode == 0 )
        {
            [appDelegate.modelManager executeUpdate:@"UPDATE sh_cloud "
             @"SET blocked = 0 WHERE sh_user_id = :user_id"
                            withParameterDictionary:@{@"user_id": userID}];
            
            [self contactManagerDidUnblockContact:userID];
        }
        else
        {
            NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
            [errorDetails setValue:@"Request response error." forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"ResponseError" code:1 userInfo:errorDetails];
            
            [self contactManagerRequestDidFailWithError:error];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self contactManagerRequestDidFailWithError:error];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (BOOL)isBlocked:(NSString *)userID withDB:(FMDatabase *)db
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    __block BOOL found = NO;
    
    if ( db )
    {
        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :user_id AND blocked = 1"
                   withParameterDictionary:@{@"user_id": userID}];
        
        while ( [s1 next] )
        {
            found = YES;
        }
        
        [s1 close];
    }
    else
    {
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_cloud WHERE sh_user_id = :user_id AND blocked = 1"
                       withParameterDictionary:@{@"user_id": userID}];
            
            while ( [s1 next] )
            {
                found = YES;
            }
            
            [s1 close];
        }];
    }
    
    return found;
}

- (void)unhideContact:(NSString *)userID
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
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/adduser", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = operation.responseString;
        
        if ( [response hasPrefix:@"while(1);"] )
        {
            response = [response stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
        }
        
        response = [appDelegate decryptedJSONStringForEncryptedString:response withKey:appDelegate.SHToken];
        NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        
        int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
        
        if ( errorCode == 0 )
        {
            NSMutableDictionary *userData = [[responseData objectForKey:@"response"] mutableCopy];
            [userData setObject:@"0" forKey:@"temp"];
            
            [appDelegate.modelManager executeUpdate:@"UPDATE sh_cloud "
                                                    @"SET hidden = 0 WHERE sh_user_id = :user_id"
                            withParameterDictionary:@{@"user_id": [userData objectForKey:@"user_id"]}];
            
            [self contactManagerDidAddNewContact:userData];
        }
        else if ( errorCode == 404 )
        {
            NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
            [errorDetails setValue:@"User does not exist" forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"ResponseError" code:404 userInfo:errorDetails];
            
            [self contactManagerRequestDidFailWithError:error];
        }
        
        NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self contactManagerRequestDidFailWithError:error];
        
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)downloadLatestCurrentUserData
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( !appDelegate.SHToken || appDelegate.SHToken.length == 0 )
    {
        return;
    }
    
    [NSTimeZone resetSystemTimeZone];
    float timezoneoffset = ([[NSTimeZone systemTimeZone] secondsFromGMT] / 3600.0);
    
    NSMutableDictionary *dataChunk = [[NSMutableDictionary alloc] initWithObjects:@[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                                                                                    [[NSLocale preferredLanguages] objectAtIndex:0],
                                                                                    [NSNumber numberWithFloat:timezoneoffset],
                                                                                    @"ios",
                                                                                    [[UIDevice currentDevice] systemVersion],
                                                                                    [[UIDevice currentDevice] name],
                                                                                    appDelegate.device_token]
                                                                          forKeys:@[@"app_version",
                                                                                    @"locale",
                                                                                    @"timezone",
                                                                                    @"os_name",
                                                                                    @"os_version",
                                                                                    @"device_name",
                                                                                    @"device_token"]];
    
    NSString *jsonString = [appDelegate encryptedJSONStringForDataChunk:dataChunk withKey:appDelegate.SHToken];
    
    NSDictionary *parameters = @{@"scope": appDelegate.SHTokenID,
                                 @"app_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                 @"request": jsonString};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:[NSString stringWithFormat:@"http://%@/scapes/api/pokeserver", SH_DOMAIN] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                NSDictionary *userData = [[responseData objectForKey:@"response"] objectForKey:@"user_data"];
                
                NSString *criticalMessage = [[responseData objectForKey:@"response"] objectForKey:@"critical_message"];
                
                // Sometimes, we send a critical message over from the server. Display it here.
                if ( ![criticalMessage isEqualToString:@"nada"] )
                {
                    if ( [criticalMessage isEqualToString:@"update"] )
                    {
                        [appDelegate lockdownApp];
                    }
                    else
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GENERIC_ALERT", nil)
                                                                        message:criticalMessage
                                                                       delegate:nil
                                                              cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil)
                                                              otherButtonTitles:nil];
                        [alert show];
                    }
                }
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                    NSString *userID = [NSString stringWithFormat:@"%@", [userData objectForKey:@"user_id"]];
                    NSString *firstName = [userData objectForKey:@"name_first"];
                    NSString *lastName = [userData objectForKey:@"name_last"];
                    NSString *userHandle = @"";
                    __block NSString *DPHash = @"";
                    NSString *email = @"";
                    NSString *gender = @"";
                    NSString *birthday = @"";
                    NSString *location_country = @"";
                    NSString *location_state = @"";
                    NSString *location_city = @"";
                    NSString *website = @"";
                    NSString *bio = @"";
                    NSString *joinDate = [userData objectForKey:@"join_date"];
                    NSString *facebookHandle = @"";
                    NSString *twitterHandle = @"";
                    NSString *instagramHandle = @"";
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
                    NSDictionary *lastStatusMediaExtra = [userData objectForKey:@"media_extra"];
                    
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
                    
                    if ( ![[NSNull null] isEqual:[userData objectForKey:@"license"]] )
                    {
                        NSDictionary *licenseData = [userData objectForKey:@"license"];
                        SHLicense licenseType = [[licenseData objectForKey:@"license_type"] intValue];
                        
                        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:licenseType] forKey:@"SHBDLicenseType"];
                        
                        if ( licenseType != SHLicenseLifetime )
                        {
                            NSDate *purchaseDate = [dateFormatter dateFromString:[licenseData objectForKey:@"timestamp"]];
                            
                            if ( [dateToday timeIntervalSinceDate:purchaseDate] > 31536000 ) // Check if a year has passed since the subscription.
                            {
                                dispatch_async(dispatch_get_main_queue(), ^(void){
                                    [appDelegate disableApp];
                                });
                                
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
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                [appDelegate disableApp];
                            });
                            
                            return;
                        }
                    }
                    
                    if ( ![[NSNull null] isEqual:[userData objectForKey:@"user_handle"]] )
                    {
                        userHandle = [userData objectForKey:@"user_handle"];
                    }
                    
                    if ( ![[NSNull null] isEqual:[userData objectForKey:@"dp_hash"]] )
                    {
                        DPHash = [userData objectForKey:@"dp_hash"];
                    }
                    
                    if ( ![[NSNull null] isEqual:[userData objectForKey:@"email_address"]] )
                    {
                        email = [userData objectForKey:@"email_address"];
                    }
                    
                    if ( ![[NSNull null] isEqual:[userData objectForKey:@"gender"]] )
                    {
                        gender = [userData objectForKey:@"gender"];
                    }
                    
                    if ( ![[NSNull null] isEqual:[userData objectForKey:@"location_country"]] )
                    {
                        location_country = [userData objectForKey:@"location_country"];
                    }
                    
                    if ( ![[NSNull null] isEqual:[userData objectForKey:@"location_state"]] )
                    {
                        location_state = [userData objectForKey:@"location_state"];
                    }
                    
                    if ( ![[NSNull null] isEqual:[userData objectForKey:@"location_city"]] )
                    {
                        location_city = [userData objectForKey:@"location_city"];
                    }
                    
                    if ( ![[NSNull null] isEqual:[userData objectForKey:@"website"]] )
                    {
                        website = [userData objectForKey:@"website"];
                    }
                    
                    if ( ![[NSNull null] isEqual:[userData objectForKey:@"bio"]] )
                    {
                        bio = [userData objectForKey:@"bio"];
                    }
                    
                    if ( ![[NSNull null] isEqual:[userData objectForKey:@"location_latitude"]] )
                    {
                        lastStatusLocation_latitude = [userData objectForKey:@"location_latitude"];
                        lastStatusLocation_longitude = [userData objectForKey:@"location_longitude"];
                    }
                    
                    if ( ![[NSNull null] isEqual:[userData objectForKey:@"birthday"]] )
                    {
                        birthday = [userData objectForKey:@"birthday"];
                    }
                    
                    if ( ![[NSNull null] isEqual:[userData objectForKey:@"facebook_id"]] )
                    {
                        facebookHandle = [userData objectForKey:@"facebook_id"];
                    }
                    
                    if ( ![[NSNull null] isEqual:[userData objectForKey:@"twitter_id"]] )
                    {
                        twitterHandle = [userData objectForKey:@"twitter_id"];
                    }
                    
                    if ( ![[NSNull null] isEqual:[userData objectForKey:@"instagram_id"]] )
                    {
                        instagramHandle = [userData objectForKey:@"instagram_id"];
                    }
                    
                    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
                    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                        
                        BOOL shouldUpdateDP = YES;
                        
                        // Check if the user even has a DP in the first place!
                        FMResultSet *s1 = [db executeQuery:@"SELECT dp FROM sh_current_user"
                                   withParameterDictionary:nil];
                        
                        __block NSData *imageData;
                        
                        while ( [s1 next] )
                        {
                            imageData = [s1 dataForColumnIndex:0];
                            UIImage *currentDP = [UIImage imageWithData:imageData];
                            
                            if ( !currentDP )
                            {
                                shouldUpdateDP = YES;
                            }
                        }
                        
                        [s1 close];
                        
                        s1 = [db executeQuery:@"SELECT dp_hash FROM sh_current_user"
                                    withParameterDictionary:nil];
                        
                        // Check if the contact's DP changed.
                        while ( [s1 next] )
                        {
                            NSString *oldDPHash = [s1 stringForColumnIndex:0];
                            
                            if ( [oldDPHash isEqualToString:DPHash] && oldDPHash.length > 0 )
                            {
                                shouldUpdateDP = NO;
                            }
                            else
                            {
                                // Clear out the old DP to force a fresh download.
                                [db executeUpdate:@"UPDATE sh_current_user SET dp = :dp"
                                    withParameterDictionary:@{@"dp": @""}];
                                
                                [db executeUpdate:@"UPDATE sh_cloud SET dp = :dp WHERE sh_user_id = :sh_user_id"
                                    withParameterDictionary:@{@"dp": @"",
                                                              @"sh_user_id": userID}];
                            }
                        }
                        
                        [s1 close];
                        
                        if ( shouldUpdateDP )
                        {
                            if ( DPHash.length > 0 )
                            {
                                NSURL *DPURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/userphotos/%@/profile/f_%@.jpg", SH_DOMAIN, userID, DPHash]];
                                
                                NSURLRequest *request = [NSURLRequest requestWithURL:DPURL];
                                [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                    UIImage *testDP = [UIImage imageWithData:data];
                                    
                                    if ( testDP )
                                    {
                                        imageData = data;
                                        
                                        // Now, we might not need all the data we're inserting here, but it's necessary to make an exact copy
                                        // of what any of the other users might look like, or else everything breaks...
                                        NSDictionary *argsDict_currentUser = [NSDictionary dictionaryWithObjectsAndKeys:userID, @"user_id",
                                                                              firstName, @"name_first",
                                                                              lastName, @"name_last",
                                                                              userHandle, @"user_handle",
                                                                              DPHash, @"dp_hash",
                                                                              imageData, @"dp",
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
                                                                              [appDelegate.currentUser objectForKey:@"last_magic_run"], @"last_magic_run",
                                                                              [appDelegate.currentUser objectForKey:@"last_location_check"], @"last_location_check",
                                                                              [appDelegate.currentUser objectForKey:@"last_mini_feed_refresh"], @"last_mini_feed_refresh",
                                                                              [appDelegate.currentUser objectForKey:@"last_passcode_unlock"], @"last_passcode_unlock", nil];
                                        
                                        // Insert the fresh stuff.
                                        [db executeUpdate:@"UPDATE sh_current_user "
                                                            @"SET name_first = :name_first, name_last = :name_last, user_handle = :user_handle, dp_hash = :dp_hash, dp = :dp, email_address = :email_address, gender = :gender, birthday = :birthday, location_country = :location_country, location_state = :location_state, location_city = :location_city, website = :website, bio = :bio, facebook_id = :facebook_id, twitter_id = :twitter_id, instagram_id = :instagram_id, join_date = :join_date, last_status_id = :last_status_id, total_messages_sent = :total_messages_sent, total_messages_received = :total_messages_received, last_magic_run = :last_magic_run, last_location_check = :last_location_check, last_mini_feed_refresh = :last_mini_feed_refresh, last_passcode_unlock = :last_passcode_unlock "
                                            withParameterDictionary:argsDict_currentUser];
                                        
                                        [db executeUpdate:@"UPDATE sh_cloud "
                                                            @"SET name_first = :name_first, name_last = :name_last, user_handle = :user_handle, dp_hash = :dp_hash, dp = :dp, last_status_id = :last_status_id, email_address = :email_address, gender = :gender, birthday = :birthday, location_country = :location_country, location_state = :location_state, location_city = :location_city, website = :website, bio = :bio, facebook_id = :facebook_id, twitter_id = :twitter_id, instagram_id = :instagram_id, total_messages_sent = :total_messages_sent, total_messages_received = :total_messages_received "
                                                            @"WHERE sh_user_id = :user_id"
                                            withParameterDictionary:argsDict_currentUser];
                                        
                                        // Update the local info.
                                        [appDelegate.currentUser setObject:DPHash forKey:@"dp_hash"];
                                        [appDelegate.currentUser setObject:imageData forKey:@"dp"];
                                    }
                                    else // Download failed.
                                    {
                                        DPHash = @""; // Clear the hash out so the manager attempts to redownload the image during the next round.
                                        
                                        imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0);
                                        
                                        // Now, we might not need all the data we're inserting here, but it's necessary to make an exact copy
                                        // of what any of the other users might look like, or else everything breaks...
                                        NSDictionary *argsDict_currentUser = [NSDictionary dictionaryWithObjectsAndKeys:userID, @"user_id",
                                                                              firstName, @"name_first",
                                                                              lastName, @"name_last",
                                                                              userHandle, @"user_handle",
                                                                              DPHash, @"dp_hash",
                                                                              @"", @"dp",
                                                                              lastStatusID, @"last_status_id",
                                                                              email, @"email_address",
                                                                              gender, @"gender",
                                                                              birthday, @"birthday",
                                                                              location_country, @"location_country",
                                                                              location_state, @"location_state",
                                                                              location_city, @"location_city",
                                                                              website, @"website",
                                                                              bio, @"bio",
                                                                              joinDate, @"join_date",
                                                                              [NSNumber numberWithInt:totalMessagesSent], @"total_messages_sent",
                                                                              [NSNumber numberWithInt:totalMessagesReceived], @"total_messages_received",
                                                                              [appDelegate.currentUser objectForKey:@"last_magic_run"], @"last_magic_run",
                                                                              [appDelegate.currentUser objectForKey:@"last_location_check"], @"last_location_check",
                                                                              [appDelegate.currentUser objectForKey:@"last_mini_feed_refresh"], @"last_mini_feed_refresh",
                                                                              [appDelegate.currentUser objectForKey:@"last_passcode_unlock"], @"last_passcode_unlock", nil];
                                        
                                        // Insert the fresh stuff.
                                        [db executeUpdate:@"UPDATE sh_current_user "
                                                            @"SET name_first = :name_first, name_last = :name_last, user_handle = :user_handle, dp_hash = :dp_hash, dp = :dp, email_address = :email_address, gender = :gender, birthday = :birthday, location_country = :location_country, location_state = :location_state, location_city = :location_city, website = :website, bio = :bio, join_date = :join_date, last_status_id = :last_status_id, total_messages_sent = :total_messages_sent, total_messages_received = :total_messages_received, last_magic_run = :last_magic_run, last_location_check = :last_location_check, last_mini_feed_refresh = :last_mini_feed_refresh, last_passcode_unlock = :last_passcode_unlock "
                                            withParameterDictionary:argsDict_currentUser];
                                        
                                        [db executeUpdate:@"UPDATE sh_cloud "
                                                            @"SET name_first = :name_first, name_last = :name_last, user_handle = :user_handle, dp_hash = :dp_hash, dp = :dp, last_status_id = :last_status_id, email_address = :email_address, gender = :gender, birthday = :birthday, location_country = :location_country, location_state = :location_state, location_city = :location_city, website = :website, bio = :bio, total_messages_sent = :total_messages_sent, total_messages_received = :total_messages_received "
                                                            @"WHERE sh_user_id = :user_id"
                                            withParameterDictionary:argsDict_currentUser];
                                        
                                        [appDelegate.currentUser setObject:DPHash forKey:@"dp_hash"];
                                        [appDelegate.currentUser setObject:imageData forKey:@"dp"];
                                    }
                                }];
                            }
                            else // There's no hash so the user probably deleted their DP.
                            {
                                imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"user_placeholder"], 1.0);
                                
                                // Now, we might not need all the data we're inserting here, but it's necessary to make an exact copy
                                // of what any of the other users might look like, or else everything breaks...
                                NSDictionary *argsDict_currentUser = [NSDictionary dictionaryWithObjectsAndKeys:userID, @"user_id",
                                                                      firstName, @"name_first",
                                                                      lastName, @"name_last",
                                                                      userHandle, @"user_handle",
                                                                      DPHash, @"dp_hash",
                                                                      @"", @"dp",
                                                                      lastStatusID, @"last_status_id",
                                                                      email, @"email_address",
                                                                      gender, @"gender",
                                                                      birthday, @"birthday",
                                                                      location_country, @"location_country",
                                                                      location_state, @"location_state",
                                                                      location_city, @"location_city",
                                                                      website, @"website",
                                                                      bio, @"bio",
                                                                      joinDate, @"join_date",
                                                                      [NSNumber numberWithInt:totalMessagesSent], @"total_messages_sent",
                                                                      [NSNumber numberWithInt:totalMessagesReceived], @"total_messages_received",
                                                                      [appDelegate.currentUser objectForKey:@"last_magic_run"], @"last_magic_run",
                                                                      [appDelegate.currentUser objectForKey:@"last_location_check"], @"last_location_check",
                                                                      [appDelegate.currentUser objectForKey:@"last_mini_feed_refresh"], @"last_mini_feed_refresh",
                                                                      [appDelegate.currentUser objectForKey:@"last_passcode_unlock"], @"last_passcode_unlock", nil];
                                
                                // Insert the fresh stuff.
                                [db executeUpdate:@"UPDATE sh_current_user "
                                                    @"SET name_first = :name_first, name_last = :name_last, user_handle = :user_handle, dp_hash = :dp_hash, dp = :dp, email_address = :email_address, gender = :gender, birthday = :birthday, location_country = :location_country, location_state = :location_state, location_city = :location_city, website = :website, bio = :bio, join_date = :join_date, last_status_id = :last_status_id, total_messages_sent = :total_messages_sent, total_messages_received = :total_messages_received, last_magic_run = :last_magic_run, last_location_check = :last_location_check, last_mini_feed_refresh = :last_mini_feed_refresh, last_passcode_unlock = :last_passcode_unlock "
                                    withParameterDictionary:argsDict_currentUser];
                                
                                [db executeUpdate:@"UPDATE sh_cloud "
                                                    @"SET name_first = :name_first, name_last = :name_last, user_handle = :user_handle, dp_hash = :dp_hash, dp = :dp, last_status_id = :last_status_id, email_address = :email_address, gender = :gender, birthday = :birthday, location_country = :location_country, location_state = :location_state, location_city = :location_city, website = :website, bio = :bio, total_messages_sent = :total_messages_sent, total_messages_received = :total_messages_received "
                                                    @"WHERE sh_user_id = :user_id"
                                    withParameterDictionary:argsDict_currentUser];
                                
                                [appDelegate.currentUser setObject:DPHash forKey:@"dp_hash"];
                                [appDelegate.currentUser setObject:imageData forKey:@"dp"];
                            }
                        }
                        else
                        {
                            // Now, we might not need all the data we're inserting here, but it's necessary to make an exact copy
                            // of what any of the other users might look like, or else everything breaks...
                            NSDictionary *argsDict_currentUser = [NSDictionary dictionaryWithObjectsAndKeys:userID, @"user_id",
                                                                  firstName, @"name_first",
                                                                  lastName, @"name_last",
                                                                  userHandle, @"user_handle",
                                                                  lastStatusID, @"last_status_id",
                                                                  email, @"email_address",
                                                                  gender, @"gender",
                                                                  birthday, @"birthday",
                                                                  location_country, @"location_country",
                                                                  location_state, @"location_state",
                                                                  location_city, @"location_city",
                                                                  website, @"website",
                                                                  bio, @"bio",
                                                                  joinDate, @"join_date",
                                                                  [NSNumber numberWithInt:totalMessagesSent], @"total_messages_sent",
                                                                  [NSNumber numberWithInt:totalMessagesReceived], @"total_messages_received",
                                                                  [appDelegate.currentUser objectForKey:@"last_magic_run"], @"last_magic_run",
                                                                  [appDelegate.currentUser objectForKey:@"last_location_check"], @"last_location_check",
                                                                  [appDelegate.currentUser objectForKey:@"last_mini_feed_refresh"], @"last_mini_feed_refresh",
                                                                  [appDelegate.currentUser objectForKey:@"last_passcode_unlock"], @"last_passcode_unlock", nil];
                            
                            // Insert the fresh stuff.
                            [db executeUpdate:@"UPDATE sh_current_user "
                                            @"SET name_first = :name_first, name_last = :name_last, user_handle = :user_handle, email_address = :email_address, gender = :gender, birthday = :birthday, location_country = :location_country, location_state = :location_state, location_city = :location_city, website = :website, bio = :bio, join_date = :join_date, last_status_id = :last_status_id, total_messages_sent = :total_messages_sent, total_messages_received = :total_messages_received, last_magic_run = :last_magic_run, last_location_check = :last_location_check, last_mini_feed_refresh = :last_mini_feed_refresh, last_passcode_unlock = :last_passcode_unlock "
                                withParameterDictionary:argsDict_currentUser];
                            
                            [db executeUpdate:@"UPDATE sh_cloud "
                                                @"SET name_first = :name_first, name_last = :name_last, user_handle = :user_handle, last_status_id = :last_status_id, email_address = :email_address, gender = :gender, birthday = :birthday, location_country = :location_country, location_state = :location_state, location_city = :location_city, website = :website, bio = :bio, total_messages_sent = :total_messages_sent, total_messages_received = :total_messages_received "
                                                @"WHERE sh_user_id = :user_id"
                                withParameterDictionary:argsDict_currentUser];
                        }
                        
                        // Delete the old data first.
                        [db executeUpdate:@"DELETE FROM sh_phone_numbers WHERE sh_user_id = :current_user_id"
                            withParameterDictionary:@{@"current_user_id": [appDelegate.currentUser objectForKey:@"user_id"]}];
                        
                        // Insert the phone numbers.
                        for ( NSDictionary *phoneNumberPack in [userData objectForKey:@"phone_numbers"] )
                        {
                            NSString *countryCallingCode = [phoneNumberPack objectForKey:@"country_calling_code"];
                            NSString *prefix = [phoneNumberPack objectForKey:@"prefix"];
                            NSString *phoneNumber = [phoneNumberPack objectForKey:@"phone_number"];
                            NSString *userPhoneNumberTimestamp = [phoneNumberPack objectForKey:@"timestamp"];
                            
                            NSDictionary *argsDict_phoneNumber = [NSDictionary dictionaryWithObjectsAndKeys:countryCallingCode, @"country_calling_code",
                                                                  prefix, @"prefix",
                                                                  phoneNumber, @"phone_number",
                                                                  userPhoneNumberTimestamp, @"timestamp",
                                                                  userID, @"user_id", nil];
                            
                            [db executeUpdate:@"INSERT INTO sh_phone_numbers "
                                                @"(country_calling_code, prefix, phone_number, timestamp, sh_user_id) "
                                                @"VALUES (:country_calling_code, :prefix, :phone_number, :timestamp, :user_id)"
                                withParameterDictionary:argsDict_phoneNumber];
                        }
                        
                        // Store the latest status update.
                        [db executeUpdate:@"DELETE FROM sh_thread WHERE thread_id = :last_status_id"
                            withParameterDictionary:@{@"last_status_id": [appDelegate.currentUser objectForKey:@"last_status_id"]}]; // Delete the old one first!
                        
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
                    }];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [appDelegate refreshCurrentUserData];
                        [appDelegate.mainMenu refreshContacts];
                    });
                });
            }
            else if ( errorCode == 404 ) // Invalid token. Throw the user out.
            {
                
            }
        }
        
        //NSLog(@"Response: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", operation.responseString);
    }];
}

- (void)contactManagerDidFetchCountryList
{
    _countryListDidDownload = YES;
    _countryListDidFailToDownload = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if ( [_delegate respondsToSelector:@selector(contactManagerDidFetchCountryList)] )
        {
            [_delegate contactManagerDidFetchCountryList];
        }
    });
}

- (void)contactManagerDidFetchRecommendations:(NSMutableArray *)list
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if ( [_delegate respondsToSelector:@selector(contactManagerDidFetchRecommendations:)] )
        {
            [_delegate contactManagerDidFetchRecommendations:list];
        }
    });
}

- (void)contactManagerDidFetchFollowing:(NSMutableArray *)list
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if ( [_delegate respondsToSelector:@selector(contactManagerDidFetchFollowing:)] )
        {
            [_delegate contactManagerDidFetchFollowing:list];
        }
    });
}

- (void)contactManagerDidFetchFollowers:(NSArray *)list
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if ( [_delegate respondsToSelector:@selector(contactManagerDidFetchFollowers:)] )
        {
            [_delegate contactManagerDidFetchFollowers:list];
        }
    });
}

- (void)contactManagerDidAddNewContact:(NSMutableDictionary *)userData
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if ( [_delegate respondsToSelector:@selector(contactManagerDidAddNewContact:)] )
        {
            [_delegate contactManagerDidAddNewContact:userData];
        }
    });
}

- (void)contactManagerDidHideContact:(NSString *)userID
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if ( [_delegate respondsToSelector:@selector(contactManagerDidHideContact:)] )
        {
            [_delegate contactManagerDidHideContact:userID];
        }
    });
}

- (void)contactManagerDidRemoveContact:(NSString *)userID
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if ( [_delegate respondsToSelector:@selector(contactManagerDidRemoveContact:)] )
        {
            [_delegate contactManagerDidRemoveContact:userID];
        }
    });
}

- (void)contactManagerDidBlockContact:(NSString *)userID
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if ( [_delegate respondsToSelector:@selector(contactManagerDidBlockContact:)] )
        {
            [_delegate contactManagerDidBlockContact:userID];
        }
    });
}

- (void)contactManagerDidUnblockContact:(NSString *)userID
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if ( [_delegate respondsToSelector:@selector(contactManagerDidUnblockContact:)] )
        {
            [_delegate contactManagerDidUnblockContact:userID];
        }
    });
}

- (void)contactManagerRequestDidFailWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if ( [_delegate respondsToSelector:@selector(contactManagerRequestDidFailWithError:)] )
        {
            [_delegate contactManagerRequestDidFailWithError:error];
        }
    });
}

@end
