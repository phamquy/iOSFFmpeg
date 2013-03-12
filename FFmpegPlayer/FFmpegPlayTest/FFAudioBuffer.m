//
//  FFAudioBuffer.m
//  FFmpegPlayTest
//
//  Created by Jack on 11/27/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#ifdef DEBUG_ABUFFER
#define JLogABuf JLog
#else
#define JLogABuf(...)
#endif

#import "FFAudioBuffer.h"
#import "FFmpeg.h"
@interface FFAudioBuffer()
{
    uint8_t* _pData;
    NSUInteger  _bytePerSample;
    NSUInteger _sampleRate;
    NSUInteger _dataByteCapacity;
    NSUInteger _dataByteSize;
    NSTimeInterval _currentPts;
    NSUInteger _wIdx;
    NSUInteger _rIdx;
    NSCondition* _condition;
}
@end


@implementation FFAudioBuffer
@synthesize dataByteSize=_dataByteSize;
@synthesize dataByteCapacity=_dataByteCapacity;
@synthesize currentPts=_currentPts;

//------------------------------------------------------------------
- (NSUInteger) sampleCount
{
    if (_bytePerSample > 0) {
        return _dataByteSize / _bytePerSample;
    }
    return 0;
}


//------------------------------------------------------------------
- (NSTimeInterval) duration
{
    if (_sampleRate > 0) {
        return [self sampleCount]/_sampleRate;
    }
    
    return 0;
}

//------------------------------------------------------------------
- (BOOL) isFull
{
    if (_dataByteCapacity == _dataByteSize) {
        return YES;
    }
    return NO;
}

//------------------------------------------------------------------
- (id) initBufferForDuration: (float) duration
              bytesPerSample: (int) bytesPerSample
                  sampleRate: (int) sampleRate
{
    
    self = [super init];
    if (self) {
        _bytePerSample = bytesPerSample;
        _sampleRate = sampleRate;
        _dataByteCapacity = sampleRate * duration * bytesPerSample;
        _dataByteSize = 0;
        _pData = av_malloc(_dataByteCapacity);
        
        _wIdx = 0;
        _rIdx = 0;
        
        _condition = [[NSCondition alloc] init];
    }
    return self;
}
//------------------------------------------------------------------
- (int) pushSample: (void*) pPushData
              size: (UInt32) pushSize
           blocked: (BOOL) blocked
{
    JLogABuf(@"Pushing audio sample to buffer");
    int pushedBytes = 0;

    [_condition lock];
    for (;;) {
        if (_dataByteCapacity > _dataByteSize) {
            
            int toPush = pushSize;
            while (toPush > 0) {
                
                if (_dataByteCapacity <= _dataByteSize) {
                    if (!blocked) {
                        break;
                    }
                    JLogABuf(@"Waiting to push audio samples");
                    [_condition wait];
                }
                
                int canWriteSize = (_rIdx > _wIdx)? (_rIdx - _wIdx) : ( _dataByteCapacity - _wIdx );
                int writeNow = MIN(canWriteSize, toPush);
                memcpy(_pData + _wIdx, pPushData, writeNow);
                pushedBytes += writeNow;
                toPush -= writeNow;
                _dataByteSize += writeNow;
                _wIdx += writeNow;
                if (_wIdx >= _dataByteCapacity) {
                    _wIdx = 0;
                }
                [_condition signal];
            }
            JLogABuf(@"Finish pushing audio sample");
            break;
        }else if(!blocked){
            JLogABuf(@"No sample pushed");
            pushedBytes = 0;
            break;
        }else{
            JLogABuf(@"Waiting to push audio samples");
            [_condition wait];
        }
    }
    [_condition unlock];
    return pushedBytes;
}

//------------------------------------------------------------------
- (int) popSampleTo: (void*) pPopData
               size: (UInt32) popSize
             outPts: (NSTimeInterval*) outPts
            blocked: (BOOL) blocked
{
    int readBytes = 0;
    int toRead = popSize;
    [_condition lock];
    for (;; ) {
        if (_dataByteSize > 0) {
            *outPts = _currentPts;
            while (toRead > 0) {
                
                if (_dataByteSize <= 0) {
                    if (!blocked) {
                        break;
                    }
                    JLogABuf(@"Waiting to pop more audio samples");
                    [_condition wait];
                }
                
                int canReadSize = (_wIdx > _rIdx)? (_wIdx - _rIdx) : ( _dataByteCapacity - _wIdx );
                int readNow = MIN(canReadSize, toRead);
                memcpy(pPopData, _pData + _rIdx,readNow);
                readBytes += readNow;
                toRead -= readNow;
                _dataByteSize -= readNow;
                _rIdx += readNow;
                
                if (_rIdx >= _dataByteCapacity) {
                    _rIdx = 0;
                }
                [_condition signal];
            }
            
            
            // FIXME: divide by zero safy check needed
            _currentPts += (double)readBytes / (double)(_sampleRate * _bytePerSample);
            JLogABuf(@"Popped audio sample");
            break;
        }else if (!blocked){
            JLogABuf(@"NO samples popped");
            readBytes = 0;
            break;
        }else{
            JLogABuf(@"Waiting to pop audio samples");
            [_condition wait];
        }
    }
    
    [_condition unlock];
    return readBytes;
}

//------------------------------------------------------------------
// TODO: Need implementation
- (int) popSampleTo:(void *)pPopData
               size:(UInt32)popSize
              atPts:(NSTimeInterval)pts
           duration:(float)duration
            blocked:(BOOL)blocked
{
    int ret = 0;
    int byteForDuration =  _bytePerSample * (int) (duration * _sampleRate);
    int toRead = MIN(popSize, byteForDuration);
    
    
    return ret;
}

//------------------------------------------------------------------
- (void)dealloc
{
    av_free(_pData);
    _pData = 0;
}

@end
