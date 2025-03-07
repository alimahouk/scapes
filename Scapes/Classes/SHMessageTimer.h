//
//  SHMessageTimer.h
//  Scapes
//
//  Created by MachOSX on 3/21/14.
//
//


@interface SHMessageTimer : NSObject

@property (nonatomic) NSTimeInterval timeoutDate;

- (id)initWithTimeout:(NSTimeInterval)timeout repeat:(bool)repeat completion:(dispatch_block_t)completion queue:(dispatch_queue_t)queue;
- (void)start;
- (void)fireAndInvalidate;
- (void)invalidate;
- (bool)isScheduled;
- (void)resetTimeout:(NSTimeInterval)timeout;
- (NSTimeInterval)remainingTime;

@end