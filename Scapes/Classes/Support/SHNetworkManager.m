//
//  SHNetworkManager.m
//  Scapes
//
//  Created by MachOSX on 9/2/13.
//
//

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <dns_sd.h>
#import "SHNetworkManager.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "Base64.h"

@implementation SHNetworkManager

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        _masterServerSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        shouldAutoReconnect = NO;
        didShowConnectionErrorAlert = NO;
        connectionAttempts = 0;
        
        Reachability *reachability = [Reachability reachabilityWithHostName: @"www.scapehouse.com"];
        [reachability startNotifier];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    }
    
    return self;
}

- (NSString *)localIPAddress
{
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    NSString *wifiAddress = nil;
    NSString *cellAddress = nil;
    
    // Retrieve the current interfaces - returns 0 on success.
    if ( !getifaddrs(&interfaces) )
    {
        // Loop through linked list of interfaces.
        temp_addr = interfaces;
        
        while ( temp_addr != NULL )
        {
            sa_family_t sa_type = temp_addr->ifa_addr->sa_family;
            
            if ( sa_type == AF_INET || sa_type == AF_INET6 )
            {
                NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
                NSString *address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]; // pdp_ip0
                //NSLog(@"NAME: \"%@\" addr: %@", name, addr); // see for yourself.
                
                if ( [name isEqualToString:@"en0"] )
                {
                    wifiAddress = address; // Interface is the wifi connection on the iPhone.
                }
                else
                {
                    if ( [name isEqualToString:@"pdp_ip0"] )
                    {
                        cellAddress = address; // Interface is the cellular connection on the iPhone.
                    }
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
        
        // Free memory.
        freeifaddrs(interfaces);
    }
    
    return wifiAddress ? wifiAddress : cellAddress;
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    Reachability *reachability = [notification object];
    
    if ( [reachability isKindOfClass:[Reachability class]] && _networkState == SHNetworkStateConnected )
    {
        _reachabilityStatus = [reachability currentReachabilityStatus];
        
        if ( shouldAutoReconnect )
        {
            [self reconnect:NO];
        }
        
        switch( _reachabilityStatus )
        {
            case NotReachable:
                NSLog(@"Not Reachable.");
                
                break;
                
            case ReachableViaWiFi:
                NSLog(@"Reachable via Wi-Fi.");
                
                break;
                
            case ReachableViaWWAN:
                NSLog(@"Reachable via cellular.");
                
                break;
                
            default:
                NSLog(@"Unknown reachability.");
                
                break;
        }
    }
}

- (void)connect
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    connectionAttempts++;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        
        shouldAutoReconnect = YES;
        NSLog(@"Connecting to server...");
        
        if ( !appDelegate.appIsLocked )
        {
            if ( ![_masterServerSocket connectToHost:@"178.79.166.153" onPort:SH_PORT viaInterface:nil withTimeout:NETWORK_CONNECTION_TIMEOUT error:&error] )
            {
                NSLog(@"Error connecting to master server: %@", error);
            }
        }
        
        _networkState = SHNetworkStateConnecting;
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [appDelegate.presenceManager currentUserPresenceChanged];
        });
    });
}

- (void)disconnect
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    connectionAttempts = 0;
    shouldAutoReconnect = NO;
    
    [_masterServerSocket disconnect];
    
    _networkState = SHNetworkStateOffline;
    [appDelegate.presenceManager currentUserPresenceChanged];
}

- (void)reconnect:(BOOL)manually
{
    if ( _masterServerSocket.isConnected )
    {
        [_masterServerSocket disconnect];
    }
    
    // Normally, we don't connect here. The socket will automatically attempt to reconnect (unless it timed out).
    if ( manually )
    {
        [self connect];
    }
}

/*
 *  This method can be used to send any type of command to the server.
 *  It's not limited to instant messages only.
 */
- (void)sendServerMessageWithPayload:(NSMutableDictionary *)payload
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // This class automatically bundles a token with every message.
        NSMutableDictionary *messageValue = [[payload objectForKey:@"messageValue"] mutableCopy];
        [messageValue setObject:appDelegate.SHToken forKey:@"access_token"];
        [payload setObject:messageValue forKey:@"messageValue"];
        
        NSMutableData *jsonData = [[NSJSONSerialization dataWithJSONObject:payload options:kNilOptions error:nil] mutableCopy];
        //NSLog(@"sending: %@", payload);
        
        // Encrypt the payload.
        /*NSError *error;
        NSData *encryptedData = [RNEncryptor encryptData:jsonData
                                             withSettings:kRNCryptorAES256Settings
                                                 password:appDelegate.SHToken
                                                    error:&error];
         
        NSMutableDictionary *finalChunk = [[NSMutableDictionary alloc] initWithObjects:@[appDelegate.SHTokenID,
                                                                                        [encryptedData base64Encoding]]
                                                                               forKeys:@[@"scope",
                                                                                         @"payload"]];
         
        jsonData = [[NSJSONSerialization dataWithJSONObject:finalChunk options:kNilOptions error:nil] mutableCopy];*/
        [jsonData appendData:[GCDAsyncSocket CRLFData]];
        
        // Send it off.
        if ( [[messageValue objectForKey:@"presence"] intValue] == SHUserPresenceAway ) // Presence: away. This is executed in the background & therefore requires special handling.
        {
            [_masterServerSocket writeData:jsonData withTimeout:-1 tag:2];
        }
        else
        {
            [_masterServerSocket writeData:jsonData withTimeout:-1 tag:1];
        }
    });
}

#pragma mark -
#pragma mark GCDAsyncSocketDelegate methods

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    NSLog(@"socket didConnectToHost:%@ port:%hu", host, port);
    
    // Reset these.
    didShowConnectionErrorAlert = NO;
    connectionAttempts = 0;
    
    NSMutableDictionary *connectCommand;
    
    if ( !appDelegate.preference_LastSeen )
    {
        connectCommand = [[NSMutableDictionary alloc] initWithObjects:@[@"server_connect_masked", @{}]
                                                              forKeys:@[@"messageType", @"messageValue"]];
    }
    else
    {
        connectCommand = [[NSMutableDictionary alloc] initWithObjects:@[@"server_connect", @{}]
                                                              forKeys:@[@"messageType", @"messageValue"]];
    }
    
    [self sendServerMessageWithPayload:connectCommand];
    
    #if ENABLE_BACKGROUNDING && !TARGET_IPHONE_SIMULATOR
    {
        // Backgrounding doesn't seem to be supported on the simulator yet.
        [sock performBlock:^{
            if ( [sock enableBackgroundingOnSocket] )
            {
                NSLog(@"Enabled backgrounding on socket");
            }
            else
            {
                NSLog(@"Enabling backgrounding failed!");
            }
        }];
    }
    #endif
    
    [sock readDataWithTimeout:-1 tag:0]; // Wait for incoming messages.
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	NSLog(@"socket:%p didWriteDataWithTag:%ld", sock, tag);
    
    if ( tag == 2 ) // Done setting presence as away!  End the background task.
    {
        AppDelegate *appDelegate = [AppDelegate sharedDelegate];
        
        [appDelegate endBackgroundUpdateTask];
    }
    
    [sock readDataWithTimeout:-1 tag:0]; // Wait for incoming messages.
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
	//NSLog(@"socket:%p didReadData:withTag:%ld", sock, tag);
	
    NSError *error;
	NSString *HTTPResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if ( [HTTPResponse hasPrefix:@"while(1);"] ) // This handles non-encrypted messages.
    {
        HTTPResponse = [HTTPResponse stringByReplacingCharactersInRange:NSMakeRange(0, 9) withString:@""];
    }
    else
    {
        data = [NSData dataWithBase64EncodedString:HTTPResponse];
        
        NSData *decryptedData = [RNDecryptor decryptData:data
                                            withPassword:appDelegate.SHToken
                                                   error:&error];
        
        HTTPResponse = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    }
    
    NSError *jsonError;
	NSDictionary *responseData = [NSJSONSerialization JSONObjectWithData:[HTTPResponse dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:&jsonError];
    NSString *messageType = [responseData objectForKey:@"messageType"];
    NSDictionary *messageValue = [responseData objectForKey:@"messageValue"];
    int errorCode = [[responseData objectForKey:@"errorCode"] intValue];
    
    if ( [messageType isEqualToString:@"server_connect"] || [messageType isEqualToString:@"server_connect_masked"] )
    {
        if ( !errorCode ) // Connection established & confirmed.
        {
            _networkState = SHNetworkStateConnected;
            [appDelegate.presenceManager currentUserPresenceChanged];
            
            // In case the app reconnects in the background, set this user as away.
            if ( [[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground )
            {
                [appDelegate.presenceManager setAway];
            }
        }
        else // The server refused the connection due to a bad token.
        {
            _networkState = SHNetworkStateOffline;
            [appDelegate.presenceManager currentUserPresenceChanged];
        }
    }
    else if ( [messageType isEqualToString:@"IM_send"] || [messageType isEqualToString:@"IM_ad_hoc"]  )
    {
        if ( !errorCode ) // The server successfully received the message.
        {
            [appDelegate.messageManager message:messageValue statusChanged:SHThreadStatusSent];
        }
        else // Message sending failed.
        {
            [appDelegate.messageManager message:messageValue statusChanged:SHThreadStatusSendingFailed];
        }
    }
    else if ( [messageType isEqualToString:@"IM_delivery"] )
    {
        if ( !errorCode ) // The peer acknowledged that they received the message.
        {
            [appDelegate.messageManager message:messageValue statusChanged:SHThreadStatusDelivered];
        }
    }
    else if ( [messageType isEqualToString:@"IM_read"] )
    {
        if ( !errorCode )  // The peer acknowledged that they read the message.
        {
            [appDelegate.messageManager message:messageValue statusChanged:SHThreadStatusRead];
        }
    }
    else if ( [messageType isEqualToString:@"set_privacy"] )
    {
        if ( !errorCode )  // The peer acknowledged that the privacy of a conversation changed.
        {
            SHThreadPrivacy privacy = [[messageValue objectForKey:@"privacy"] intValue];
            [appDelegate.messageManager conversation:[messageValue objectForKey:@"recipient_id"] privacyChanged:privacy];
        }
    }
    else if ( [messageType isEqualToString:@"notif_presence"] )
    {
        NSString *userID = [messageValue objectForKey:@"user_id"];
        NSString *targetID = [messageValue objectForKey:@"target_id"];
        SHUserPresence presence = [[messageValue objectForKey:@"presence"] intValue];
        SHUserPresenceAudience audience = [[messageValue objectForKey:@"audience"] intValue];
        
        [appDelegate.presenceManager presenceChanged:presence forUserID:userID withTargetID:targetID forAudience:audience];
    }
    else if ( [messageType isEqualToString:@"notif_IM"] )
    {
        [appDelegate.messageManager parseReceivedMessage:messageValue shouldVibrate:YES withDB:nil];
    }
    else if ( [messageType isEqualToString:@"notif_ad_hoc"] )
    {
        [appDelegate.messageManager parseReceivedAdHocMessage:messageValue];
    }
    else if ( [messageType isEqualToString:@"notif_messageStatus"] )
    {
        if ( !errorCode )
        {
            if ( [[messageValue objectForKey:@"status"] isEqualToString:@"delivered"] ) // The recipient successfully received the message.
            {
                [appDelegate.messageManager message:messageValue statusChanged:SHThreadStatusDelivered];
            }
            else if ( [[messageValue objectForKey:@"status"] isEqualToString:@"read"] ) // The recipient read the message.
            {
                [appDelegate.messageManager message:messageValue statusChanged:SHThreadStatusRead];
            }
        }
    }
    else if ( [messageType isEqualToString:@"notif_privacy"] )
    {
        SHThreadPrivacy privacy = [[messageValue objectForKey:@"privacy"] intValue];
        [appDelegate.messageManager conversation:[messageValue objectForKey:@"recipient_id"] privacyChanged:privacy];
    }
    else if ( [messageType isEqualToString:@"notif_status"] )
    {
        [appDelegate.messageManager parseStatus:messageValue];
    }
    
	NSLog(@"\nHTTP Response:\n==\n%@\n==\n", HTTPResponse);
    
    [sock readDataWithTimeout:-1 tag:0]; // Wait for more incoming messages.
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    AppDelegate *appDelegate = [AppDelegate sharedDelegate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"socketDidDisconnect:%@ withError: %@", sock, err);
        _networkState = SHNetworkStateOffline;
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [appDelegate.presenceManager currentUserPresenceChanged];
            
            if ( shouldAutoReconnect )
            {
                [self connect];
            }
        });
        
        if ( !didShowConnectionErrorAlert && connectionAttempts == NETWORK_CONNECTION_ATTEMPT_TIMEOUT )
        {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GENERIC_NETWORK_ERROR_TITLE", nil)
                                                                message:NSLocalizedString(@"GENERIC_NETWORK_ERROR_MESSAGE", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"GENERIC_OK", nil)
                                                      otherButtonTitles:nil];
                
                didShowConnectionErrorAlert = YES; // The client might make multiple reconnection attempts. We don't want this alert showing each & every time.
                [alert show];
                [appDelegate.strobeLight negativeStrobeLight];
            });
        }
    });
}

@end