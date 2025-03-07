//
//  SHModelManager.h
//  Scapes
//
//  Created by MachOSX on 8/3/13.
//
//

#import <sqlite3.h>
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMResultSet.h"

@interface SHModelManager : NSObject
{
    
}

@property (nonatomic, retain) NSString *databasePath;
@property (nonatomic, retain) FMDatabase *DB;
@property (nonatomic, retain) FMResultSet *results;

// This returns a SQLite-friendly timestamp.
- (NSString *)dateTodayString;
- (int)schemaVersion;
- (void)incrementSchemaVersion;
- (void)synchronizeLatestDB;
- (void)resetDB;
- (void)updateMetadataOfDB:(FMDatabase *)targetDB;
- (BOOL)executeUpdate:(NSString *)statement withParameterDictionary:argsDict;
- (FMResultSet *)executeQuery:(NSString *)statement withParameterDictionary:argsDict;

- (void)saveCurrentUserData:(NSDictionary *)userData;
- (NSMutableDictionary *)refreshCurrentUserData;

@end
