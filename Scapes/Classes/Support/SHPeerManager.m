//
//  SHPeerManager.m
//  Nightboard
//
//  Created by MachOSX on 2/8/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import "SHPeerManager.h"

#import "AppDelegate.h"

@implementation SHPeerManager

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        identifier =  [CBUUID UUIDWithString:SH_UUID];
        
        centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        
        discoveredPeripherals = [NSMutableArray array];
        _discoveredPeers = [NSMutableArray array];
        
        easedProximity = [[EasedValue alloc] init];
        
        // Use to track changes to this value.
        bluetoothIsEnabledAndAuthorized = [self hasBluetooth];
    }
    
    return  self;
}

- (BOOL)canBroadcast
{
    // iOS 6 can't detect peripheral authorization so just assume it works.
    // ARC complains if we use @selector because `authorizationStatus` is ambiguous.
    SEL selector = NSSelectorFromString(@"authorizationStatus");
    
    if ( ![[CBPeripheralManager class] respondsToSelector:selector] )
    {
        return YES;
    }
    
    CBPeripheralManagerAuthorizationStatus status = [CBPeripheralManager authorizationStatus];
    
    BOOL enabled = ( status == CBPeripheralManagerAuthorizationStatusAuthorized ||
                    status == CBPeripheralManagerAuthorizationStatusNotDetermined );
    
    if ( !enabled )
    {
        NSLog(@"Bluetooth is not authorized!");
    }
    
    return enabled;
}

- (SHPeerRange)convertRSSItoINProximity:(NSInteger)proximity
{
    // Eased value doesn't support negative values.
    easedProximity.value = labs(proximity);
    [easedProximity update];
    proximity = easedProximity.value * -1.0f;
    
    NSLog(@"proximity: %ld", (long)proximity);
    
    if (proximity < -70)
    {
        return SHPeerRangeFar;
    }
    
    if (proximity < -55)
    {
        return SHPeerRangeNear;
    }
    
    if (proximity < 0)
    {
        return SHPeerRangeImmediate;
    }
    
    return SHPeerRangeUnknown;
}

- (BOOL)hasBluetooth
{
    return [self canBroadcast] && peripheralManager.state == CBPeripheralManagerStatePoweredOn;
}

- (void)startAdvertising
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( appDelegate.SHToken && appDelegate.SHToken.length > 0 && appDelegate.preference_UseBluetooth )
    {
        NSString *ID = [appDelegate.currentUser objectForKey:@"user_id"];
        NSData *IDData = [ID dataUsingEncoding:NSUTF8StringEncoding];
        CBMutableCharacteristic *myCharacteristic = [[CBMutableCharacteristic alloc] initWithType:identifier
                                                                                       properties:CBCharacteristicPropertyRead
                                                                                            value:IDData permissions:CBAttributePermissionsReadable];
        CBMutableService *myService = [[CBMutableService alloc] initWithType:identifier primary:YES];
        myService.characteristics = @[myCharacteristic];
        [peripheralManager addService:myService];
        
        /*CBUUID *userDescriptionUUID = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
        CBMutableDescriptor *yourDescriptor = [[CBMutableDescriptor alloc] initWithType:userDescriptionUUID value:IDData];
        myCharacteristic.descriptors = @[yourDescriptor];*/
        
        NSDictionary *advertisingData = @{CBAdvertisementDataLocalNameKey:@"nightboard-peripheral",
                                          CBAdvertisementDataServiceUUIDsKey:@[myService.UUID]};
        
        // Start advertising over BLE
        [peripheralManager startAdvertising:advertisingData];
        
        _isAdvertising = YES;
    }
}

- (void)startScanning
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( appDelegate.SHToken && appDelegate.SHToken.length > 0 && appDelegate.preference_UseBluetooth )
    {
        NSDictionary *scanOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@(YES)};
        
        _isScanning = YES;
        [centralManager scanForPeripheralsWithServices:@[identifier] options:scanOptions];
        
        NSLog(@"Scanning...");
    }
}

- (void)stopAdvertising
{
    _isAdvertising = NO;
    
    [peripheralManager stopAdvertising];
}

- (void)stopScanning
{
    _isScanning = NO;
    
    [centralManager stopScan];
}

- (void)removePeripheral:(CBPeripheral *)peripheral
{
    for ( int i = 0; i < discoveredPeripherals.count; i++ )
    {
        CBPeripheral *p = [discoveredPeripherals objectAtIndex:i];
        
        if ( p == peripheral )
        {
            [discoveredPeripherals removeObjectAtIndex:i];
        }
    }
}

- (BOOL)peripheralExists:(CBPeripheral *)peripheral
{
    for ( CBPeripheral *p in discoveredPeripherals )
    {
        if ( p == peripheral )
        {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)peerExists:(NSString *)userID
{
    for ( NSMutableDictionary *user in _discoveredPeers )
    {
        if ( [[user objectForKey:@"user_id"] intValue] == userID.intValue )
        {
            return YES;
        }
    }
    
    return NO;
}

- (void)terminateConnections
{
    [centralManager stopScan];
    [peripheralManager stopAdvertising];
    
    for ( CBPeripheral *p in discoveredPeripherals )
    {
        [centralManager cancelPeripheralConnection:p];
    }
}

- (void)dumpDiscoveredPeers
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            for ( int i = 0; i < _discoveredPeers.count; i++ )
            {
                NSMutableDictionary *peer = [_discoveredPeers objectAtIndex:i];
                [self dumpPeer:peer withDB:db];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [appDelegate.contactManager requestRecommendationListForced:NO];
            });
        }];
    });
}

- (void)dumpPeer:(NSDictionary *)peer withDB:(FMDatabase *)db
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    if ( db )
    {
        FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_peer WHERE sh_user_id = :peer_id "
                   withParameterDictionary:@{@"peer_id": [peer objectForKey:@"user_id"]}];
        NSString *timestamp;
        BOOL exists = NO;
        int count = 0;
        
        while ( [s1 next] )
        {
            exists = YES;
            timestamp = [s1 stringForColumn:@"timestamp"];
            count = [s1 intForColumn:@"count"];
        }
        
        [s1 close];
        
        if ( !exists )
        {
            [db executeUpdate:@"INSERT INTO sh_peer (sh_user_id, count, timestamp, flag) "
                            @"VALUES (:peer_id, :count, :timestamp, :flag)"
                withParameterDictionary:@{@"peer_id": [peer objectForKey:@"user_id"],
                                          @"count": @"1",
                                          @"timestamp": [appDelegate.modelManager dateTodayString],
                                          @"flag": @"1"}];
        }
        else
        {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
            NSDate *lastEncounterTime = [dateFormatter dateFromString:timestamp];
            
            if ( ![lastEncounterTime isEqualToDate:[NSDate date]] ) // You might run into the same person 20 times a day. That doesn't count.
            {
                count++;
            }
            
            [db executeUpdate:@"UPDATE sh_peer SET count = :count, timestamp = :timestamp, flag = :flag "
                            @"WHERE sh_user_id = :peer_id"
                withParameterDictionary:@{@"peer_id": [peer objectForKey:@"user_id"],
                                          @"count": [NSNumber numberWithInt:count],
                                          @"timestamp": [appDelegate.modelManager dateTodayString],
                                          @"flag": @"1"}];
        }
    }
    else
    {
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:appDelegate.modelManager.databasePath];
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            FMResultSet *s1 = [db executeQuery:@"SELECT * FROM sh_peer WHERE sh_user_id = :peer_id "
                       withParameterDictionary:@{@"peer_id": [peer objectForKey:@"user_id"]}];
            NSString *timestamp;
            BOOL exists = NO;
            int count = 0;
            
            while ( [s1 next] )
            {
                exists = YES;
                timestamp = [s1 stringForColumn:@"timestamp"];
                count = [s1 intForColumn:@"count"];
            }
            
            [s1 close];
            
            if ( !exists )
            {
                [db executeUpdate:@"INSERT INTO sh_peer (sh_user_id, count, timestamp, flag) "
                                @"VALUES (:peer_id, :count, :timestamp, :flag)"
                        withParameterDictionary:@{@"peer_id": [peer objectForKey:@"user_id"],
                                                  @"count": @"1",
                                                  @"timestamp": [appDelegate.modelManager dateTodayString],
                                                  @"flag": @"1"}];
            }
            else
            {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
                NSDate *lastEncounterTime = [dateFormatter dateFromString:timestamp];
                
                if ( ![lastEncounterTime isEqualToDate:[NSDate date]] ) // You might run into the same person 20 times a day. That doesn't count.
                {
                    count++;
                }
                
                [db executeUpdate:@"UPDATE sh_peer SET count = :count, timestamp = :timestamp, flag = :flag "
                                @"WHERE sh_user_id = :peer_id"
                        withParameterDictionary:@{@"peer_id": [peer objectForKey:@"user_id"],
                                                  @"count": [NSNumber numberWithInt:count],
                                                  @"timestamp": [appDelegate.modelManager dateTodayString],
                                                  @"flag": @"1"}];
            }
        }];
    }
}

- (void)clearFlaggedPeers
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    [appDelegate.modelManager executeUpdate:@"UPDATE sh_peer SET flag = 0"
                    withParameterDictionary:nil];
}

#pragma mark -
#pragma mark CBCentralManagerDelegate methods.

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if ( central.state != CBCentralManagerStatePoweredOn )
    {
        NSLog(@"Central not on!");
        return;
    }
    
    if ( central.state == CBCentralManagerStatePoweredOn )
    {
        [self startScanning];
    }
    else
    {
        NSLog(@"Couldn't start scanning!");
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if ( ![self peripheralExists:peripheral] )
    {
        NSLog(@"Discovered peripheral: %@, data: %@, RSSI: %1.2f", [peripheral.identifier UUIDString], advertisementData, [RSSI floatValue]);
        
        [self stopScanning]; // Pause scanning till we're done adding the new peer.
        [discoveredPeripherals addObject:peripheral]; // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it.
        [centralManager connectPeripheral:[discoveredPeripherals lastObject] options:nil]; // And connect.
        
        NSLog(@"Connecting to peripheral %@", peripheral);
    }
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    for ( CBPeripheral *peripheral in peripherals )
    {
        if ( ![self peripheralExists:peripheral] )
        {
            [self stopScanning];
            [discoveredPeripherals addObject:peripheral];
            [centralManager connectPeripheral:[discoveredPeripherals lastObject] options:nil];
            
            NSLog(@"Reconnecting to peripheral %@", peripheral);
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connected!");
    
    peripheral.delegate = self;
    [peripheral discoverServices:@[identifier]];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    
    if ( error )
    {
        NSLog(@"Disconnecting with error: %@", error);
        [self removePeripheral:peripheral]; // Remove it so we can reconnect to it again.
    }
    else
    {
        NSLog(@"Disconnecting...");
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to peripheral: %@", error);
    [self removePeripheral:peripheral];
}

#pragma mark - 
#pragma mark CBPeripheralManagerDelegate methods.

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if (error)
        NSLog(@"error starting advertising: %@", [error localizedDescription]);
    else
        NSLog(@"Advertising...");
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if ( peripheral.state != CBPeripheralManagerStatePoweredOn )
    {
        NSLog(@"Peripheral not on!");
        return;
    }
    
    if ( peripheral.state == CBPeripheralManagerStatePoweredOn )
    {
        [self startAdvertising];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error)
    {
        NSLog(@"Error discovering services!");
        return;
    }
    
    NSLog(@"Discovering services...");
    
    for (CBService *service in peripheral.services)
    {
        [peripheral discoverCharacteristics:@[identifier] forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error discovering characteristics!");
        return;
    }
    
    NSLog(@"Discovering characteristics...");
    
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        if ([characteristic.UUID isEqual:identifier])
        {
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error reading characteristics: %@", [error localizedDescription]);
        
        return;
    }
    
    if (characteristic.value != nil)
    {
        NSString *discoveredPeer = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        
        if ( ![self peerExists:discoveredPeer] )
        {
            AppDelegate *appDelegate = [AppDelegate sharedDelegate];
            
            if ( discoveredPeer.intValue != [[appDelegate.currentUser objectForKey:@"user_id"] intValue] ) // Make sure we don't pick up the same user from a different device.
            {
                NSMutableDictionary *peerData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                 discoveredPeer, @"user_id",
                                                 [appDelegate.modelManager dateTodayString],@"timestamp", nil];
                
                /*dispatch_async(dispatch_get_main_queue(), ^(void){
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"Discovered peer: %@", discoveredPeer] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
                    [alert show];
                });*/
                
                [_discoveredPeers addObject:peerData];
                [centralManager cancelPeripheralConnection:peripheral];
                [self dumpPeer:[_discoveredPeers lastObject] withDB:nil];
                
                if ( [[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground &&
                    [[UIApplication sharedApplication] applicationState] != UIApplicationStateInactive )
                {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [appDelegate.mainMenu showNewPeerNotification];
                    });
                }
            }
        }
        
        NSLog(@"Discovered peer: %@", discoveredPeer);
        
        [self startScanning]; // Resume.
    }
}

@end
