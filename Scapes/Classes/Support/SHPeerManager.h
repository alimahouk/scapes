//
//  SHPeerManager.h
//  Nightboard
//
//  Created by MachOSX on 2/8/15.
//  Copyright (c) 2015 Scapehouse. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

#import "Constants.h"
#import "EasedValue.h"
#import "FMDB.h"

@interface SHPeerManager : NSObject <CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate>
{
    CBCentralManager *centralManager;
    CBPeripheralManager *peripheralManager;
    CBPeripheral *discoveredPeripheral;
    CBUUID *identifier;
    SHPeerRange identifierRange;
    EasedValue *easedProximity;
    NSMutableArray *discoveredPeripherals;
    BOOL bluetoothIsEnabledAndAuthorized;
}

@property (nonatomic) NSMutableArray *discoveredPeers;
@property (nonatomic) BOOL isScanning;
@property (nonatomic) BOOL isAdvertising;

- (BOOL)canBroadcast;
- (SHPeerRange)convertRSSItoINProximity:(NSInteger)proximity;
- (BOOL)hasBluetooth;
- (void)startAdvertising;
- (void)startScanning;
- (void)stopAdvertising;
- (void)stopScanning;
- (void)removePeripheral:(CBPeripheral *)peripheral;
- (BOOL)peripheralExists:(CBPeripheral *)peripheral;
- (BOOL)peerExists:(NSString *)userID;
- (void)terminateConnections;
- (void)dumpDiscoveredPeers;
- (void)dumpPeer:(NSDictionary *)peer withDB:(FMDatabase *)db;
- (void)clearFlaggedPeers;

@end
