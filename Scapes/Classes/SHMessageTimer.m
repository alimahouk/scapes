//
//  SHMessageTimer.m
//  Scapes
//
//  Created by MachOSX on 3/21/14.
//
//

#import "SHMessageTimer.h"

@interface SHMessageTimer ()

@property (nonatomic) dispatch_source_t timer;
@property (nonatomic) NSTimeInterval timeout;
@property (nonatomic) bool repeat;
@property (nonatomic, copy) dispatch_block_t completion;
@property (nonatomic) dispatch_queue_t queue;

@end

@implementation SHMessageTimer

@synthesize timeoutDate = _timeoutDate;

@synthesize timer = _timer;
@synthesize timeout = _timeout;
@synthesize repeat = _repeat;
@synthesize completion = _completion;
@synthesize queue = _queue;

- (id)initWithTimeout:(NSTimeInterval)timeout repeat:(bool)repeat completion:(dispatch_block_t)completion queue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self != nil)
    {
        _timeoutDate = INT_MAX;
        
        _timeout = timeout;
        _repeat = repeat;
        self.completion = completion;
        self.queue = queue;
    }
    return self;
}

- (void)dealloc
{
    if (_timer != nil)
    {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
}

- (void)start
{
    _timeoutDate = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970 + _timeout;
    
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
    dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_timeout * NSEC_PER_SEC)), _repeat ? (int64_t)(_timeout * NSEC_PER_SEC) : DISPATCH_TIME_FOREVER, 0);
    
    dispatch_source_set_event_handler(_timer, ^
                                      {
                                          if (self.completion)
                                              self.completion();
                                          if (!_repeat)
                                          {
                                              [self invalidate];
                                          }
                                      });
    dispatch_resume(_timer);
}

- (void)fireAndInvalidate
{
    if (self.completion)
        self.completion();
    
    [self invalidate];
}

- (void)invalidate
{
    _timeoutDate = 0;
    
    if (_timer != nil)
    {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
}

- (bool)isScheduled
{
    return _timer != nil;
}

- (void)resetTimeout:(NSTimeInterval)timeout
{
    [self invalidate];
    
    _timeout = timeout;
    [self start];
}

- (NSTimeInterval)remainingTime
{
    if (_timeoutDate < FLT_EPSILON)
        return DBL_MAX;
    else
        return _timeoutDate - (CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970);
}

@end
