//
//  FFPictureQueue.m
//  FFmpegPlayTest
//
//  Created by Jack on 11/13/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import "FFPictureQueue.h"

#ifdef DEBUG_PICTURE
#define JLogPic JLog
#else
#define JLogPic(...)
#endif



//#########################################################################

#pragma mark - FFPictureQueue
@implementation FFPictureQueue
@synthesize size=_size;
//@synthesize capacity=_capacity;
//------------------------------------------------------------------------
- (id) init
{
    self = [super init];
    if (self) {
        _condition = [[NSCondition alloc] init];
        _size = 0;
        _readIndex=0;
        _writeIndex=0;
        _capacity=kFFVideoPictureQueueSize;
        
//        _capacity = capacity;
//        _pictures = malloc(_capacity* sizeof(FFVideoPicture));
//        memset(_pictures, 0, _capacity* sizeof(FFVideoPicture));
    }
    return self;
}
//------------------------------------------------------------------------
- (FFVideoPicture*) popPictureWithBlockingMode: (BOOL) blocked
{
    JLogPic(@"Popping pic");
    FFVideoPicture* pict = nil;
    [_condition lock];
    for (;;) {
        
        /// TODO: Add decode's status aware code in here
        /// to escape if decode stop (or quit).
        
        if (_size > 0) {
            pict = pictures[_readIndex];
            if (++_readIndex == kFFVideoPictureQueueSize) {
                _readIndex = 0;
            }
            _size--;
            JLogPic(@"Picture popped, size: %d, rIdx: %d, wIdx: %d", _size, _readIndex, _writeIndex);
            [_condition signal];
            break;
        }else if (!blocked){
            JLogPic(@"Return as unblocked pop");
            break;
        }else {
            JLogPic(@"Wait to pop...");
            [_condition wait];
        }
    }
    [_condition unlock];
    return  pict;
}
//------------------------------------------------------------------------
- (const FFVideoPicture* const) pictureToReadWithBlock:(BOOL)blocked
{
    JLogPic(@"Getting readable pic");
    FFVideoPicture* retPict = nil;
    [_condition lock];
    for (;;) {
        if (_size > 0) {
            retPict = pictures[_readIndex];
            JLogPic(@"Got a readable pic at idx %d", _readIndex);
            break;
        }else if(blocked){
            JLogPic(@"Wait for a readable pic avaiable");
            [_condition wait];
        }else{
            retPict = nil;
            JLogPic(@"No readable pict");
            break;
        }
    }
    [_condition unlock];
    return retPict;

}
//------------------------------------------------------------------------
- (BOOL) pushPicture: (FFVideoPicture*) inPicture
        blockingMode: (BOOL) block
{
    JLogPic(@"Pushing pic");
    BOOL ret = YES;
    [_condition lock];
    for (;;) {
        /// TODO: Add decode's status aware code in here
        /// to escape if decode stop (or quit).
        
        if (_size < kFFVideoPictureQueueSize) {
            pictures[_writeIndex] = inPicture;
            if(++_writeIndex == kFFVideoPictureQueueSize) {
                _writeIndex = 0;
            }
            _size++;
            JLogPic(@"Picture pushed, size: %d, rIdx: %d, wIdx: %d", _size, _readIndex, _writeIndex);
            ret = YES;
            [_condition signal];
            break;
        }else if (!block){
            JLogPic(@"Return as unblocked push");
            ret = NO;
            break;
        }else{
            JLogPic(@"Wait to push...");
            [_condition wait];
        }
    }
    [_condition unlock];
    return ret;
}
//------------------------------------------------------------------------
// TODO: need implement for the case that no reuseable pict available
// in unblocking mode
- (FFVideoPicture* const ) pictureToWriteWithBlock:(BOOL)__unused blocked
{
    JLogPic(@"Getting pic to write");
    FFVideoPicture* retPict = nil;
    [_condition lock];
    for (;;) {
        if (_size < kFFVideoPictureQueueSize) {
            retPict = pictures[_writeIndex];
            JLogPic(@"Got a writable pic at idx %d", _writeIndex);
            break;
        }else{
            JLogPic(@"Wait for a writable pic avaiable");
            [_condition wait];
        }
    }
    [_condition unlock];
    return retPict;
}
//------------------------------------------------------------------------
- (void) flush
{
    [_condition lock];
    _size = 0;
    _readIndex = 0;
    _writeIndex = 0;
    [_condition unlock];
    
    for (int i = 0; i < kFFVideoPictureQueueSize; i++) {
        pictures[i] = nil;
    }
}

@end
