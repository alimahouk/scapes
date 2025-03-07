//
//  SHNetworkManager.h
//  Scapes
//
//  Created by MachOSX on 9/2/13.
//
//

#import "GCDAsyncSocket.h"
#import "Reachability.h"

@interface SHNetworkManager : NSObject
{
    BOOL shouldAutoReconnect;
    BOOL didShowConnectionErrorAlert;
    int connectionAttempts;
}

@property (nonatomic, strong) GCDAsyncSocket *masterServerSocket;
@property (nonatomic) SHNetworkState networkState;
@property (nonatomic) NetworkStatus reachabilityStatus;

- (NSString *)localIPAddress;
- (void)connect;
- (void)disconnect;
- (void)reconnect:(BOOL)manually;
- (void)sendServerMessageWithPayload:(NSMutableDictionary *)payload;

@end

/*
 *  MESSAGING PROTOCOL
 *  ==================
 *  A message is constituted of a header identified as "MessageType".
 *  The header is basically a command that tells the server what to do.
 *  The body of the message contains the main payload as a dictionary.
 *  ---------------------------------------------------------------------------
 *  Commands:
 *  Send these to the server.
 *
 *  1) server_connect/server_connect_masked
 *  Use this to connect to the server. It only requires an access token.
 *
 *  2) notif_presence
 *  To set the online presence of the user.
 *
 *  3) IM_send
 *  To send an instant message.
 *
 *  4) IM_ad_hoc
 *  To send an instant message to an ad hoc group.
 *
 *  5) IM_delivered
 *  To acknowledge message delivery.
 *
 *  6) IM_read
 *  To acknowledge that a message has been read.
 *
 *  7) IM_delete
 *  To delete a thread.
 *  
 *  8) set_privacy
 *  To change a thread's privacy status.
 *
 *  9) set_status
 *  To post a status update.
 *
 *  10) To disconnect the client, simply disconnect the socket.
 *  ---------------------------------------------------------------------------
 *  Event Notifications:
 *  These are fired off by peers. All clients need to be able to read them.
 *
 *  1) presence
 *  Notifies you about the presence change of a contact.
 *
 *  2) notif_IM
 *  Notifies you about a new instant message.
 *
 *  2) notif_ad_hoc
 *  Notifies you about a new instant message in an ad hoc group.
 *
 *  3) notif_messageStatus
 *  Notifies you when a message has been delivered or read.
 *
 *  4) notif_privacy
 *  Notifies you when a thread's privacy has been changed.
 *
 *  5) notif_status
 *  Notifies you when a status update has been posted.
 *  ---------------------------------------------------------------------------
 *  Presence Key:
 *  1 = offline
 *  2 = online
 *  3 = online - masked
 *  4 = away
 *  5 = typing
 *  6 = stopped typing
 *  7 = sending photo
 *  8 = sending video
 *  9 = sending audio
 *  10 = sending location
 *  11 = sending contact
 *  12 = sending file
 *  13 = checking link
 *  14 = offline - masked
 *
 *  Message Status Key:
 *  1 = sent
 *  2 = delivered
 *  3 = read
 */