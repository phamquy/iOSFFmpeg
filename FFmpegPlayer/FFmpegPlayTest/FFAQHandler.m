//
//  AQHandler.m
//  FFmpegPlayTest
//
//  Created by Jack on 11/2/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import "FFAQHandler.h"

#ifdef DEBUG_AQHANDLE
#define JLogAQ JLog
#else
#define JLogAQ(...)
#endif

#define kBufferDuration 0.5f

/**
 Audio Queue Service Playback callback function
 */
static int buffCount = 0;
static void HandleOutputBuffer (void                 *data,
                                AudioQueueRef        inAQ,
                                AudioQueueBufferRef  inBuffer)
{
    FFAQHandler* aqHandler = (__bridge FFAQHandler*) data;
    if (!aqHandler) {
        return;
    }
    id<FFAudioQueueSource> aqSource = [aqHandler source];
    
    

#ifdef DEBUG_AQHANDLE
    AudioTimeStamp bufferStartTime;
	AudioQueueGetCurrentTime(inAQ, NULL, &bufferStartTime, NULL);
    JLogAQ(@"Current pts: %f", bufferStartTime.mSampleTime/48000);
#endif
    
    // ???: Should change the method signature
    [aqSource renderAudioBuffer:inBuffer
                         forPts:[aqHandler currentTimeSinceStart]];
    
    //usleep(2000000);
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, 0);
    return;
};


//--------------------------------------------------------------------
void DeriveBufferSize (
   AudioStreamBasicDescription ASBDesc,
   UInt32                      maxPacketSize,
   Float64                     seconds,
   UInt32                      *outBufferSize,
   UInt32                      *outNumPacketsToRead)
{
    /* An upper bound for the audio queue buffer size, in bytes. In this example,
     the upper bound is set to 320 KB. This corresponds to approximately five 
     seconds of stereo, 24 bit audio at a sample rate of 96 kHz. */
    static const int maxBufferSize = 0x50000;
    
    /* A lower bound for the audio queue buffer size, in bytes. In this example,
     the lower bound is set to 16 KB. */
    static const int minBufferSize = 0x4000;
    
    if (ASBDesc.mBytesPerPacket != 0) // LPCM
    {
        Float64 numPacketsForTime = ASBDesc.mSampleRate / ASBDesc.mFramesPerPacket * seconds;
        *outBufferSize = numPacketsForTime * maxPacketSize;
    }
    else // AAC or MP3
    {
        *outBufferSize = maxBufferSize > maxPacketSize ? maxBufferSize : maxPacketSize;
    }
    
    if (*outBufferSize > maxBufferSize && *outBufferSize > maxPacketSize )
        *outBufferSize = maxBufferSize;
    else if (*outBufferSize < minBufferSize)
        *outBufferSize = minBufferSize;
    
    *outNumPacketsToRead = *outBufferSize / maxPacketSize;           
};

//--------------------------------------------------------------------
@interface FFAQHandler ()
{
    AQPlayerState   aqData;
}

@end

//--------------------------------------------------------------------
#pragma mark 
@implementation FFAQHandler
@synthesize source=_source;

//--------------------------------------------------------------------
- (id) initWithSource: (id<FFAudioQueueSource>) source
{
    self = [super init];
    if (self) {
        
        aqData.mStatus = kFFAQStateUnknown;
        _source = source;
        
        if (![self initAudioQueue]) {
            JLogAQ(@"Failed to init AudioQueue Service");
            self = nil;
            return self;
        };
        
        // TODO: Check return, and handle error
        [self initSynchronizer];
        aqData.mStatus = kFFAQStateStopped;
        JLogAQ(@"Finished initialize Audio Queue");
    }
    return self;
}
//--------------------------------------------------------------------
#pragma mark Utilities
- (AQPlayerState*) audioQueueData
{
    return &aqData;
}

//--------------------------------------------------------------------
/**
 Init parameter used for synchronization
 */
- (void) initSynchronizer
{
    // TODO: need implementation
}

//--------------------------------------------------------------------
- (BOOL) initAudioQueue
{
    JLogAQ(@"Initializing Audio Queue");
    BOOL ret = TRUE;
    OSStatus osStatus = 0;
    buffCount = 0;
    // Ask source to fil information about data format
    if ([_source respondsToSelector:@selector(fillAudioStreamDescription:)]) {
        if (![_source fillAudioStreamDescription:&aqData.mDataFormat]) {
            return FALSE;
        }
    }else{
        return FALSE;
    }
    
    UInt32 maxPktSize;
    if ([_source respondsToSelector:@selector(maxAudioPacketSize)]) {
        maxPktSize = [_source maxAudioPacketSize];
    }else{
        return FALSE;
    }
    
    // Calculate buffer size
    DeriveBufferSize(aqData.mDataFormat,
                     maxPktSize,
                     kBufferDuration,
                     &aqData.bufferByteSize,
                     &aqData.mNumPacketsToRead);
    
    
    osStatus = AudioQueueNewOutput(&aqData.mDataFormat,
                                   HandleOutputBuffer,
                                   (__bridge void *)(self),
                                   NULL,
                                   NULL,
                                   0,
                                   &aqData.mQueue);
    
    if (osStatus != 0) {
        return FALSE;
    }
    
    for (int i = 0; i < kNumberBuffers; i++) {
        // Fixed size packet, no packet description need
        if (aqData.mDataFormat.mBytesPerPacket)
        {
            osStatus = AudioQueueAllocateBuffer(aqData.mQueue,
                                                aqData.bufferByteSize,
                                                &aqData.mBuffers[i]);

        }
        else
        {
            osStatus = AudioQueueAllocateBufferWithPacketDescriptions(aqData.mQueue,
                                                                      //aqData.bufferByteSize,
                                                                      aqData.mDataFormat.mSampleRate * kBufferDuration / 8,
                                                                      aqData.mDataFormat.mSampleRate * kBufferDuration / maxPktSize + 1,
                                                                      //aqData.mNumPacketsToRead,
                                                                      &aqData.mBuffers[i]);
//            // We will supply the packet description when enqueuing the
//            // the data, so we dont need to use above function
//            osStatus = AudioQueueAllocateBuffer(aqData.mQueue,
//                                                aqData.bufferByteSize,
//                                                &aqData.mBuffers[i]);

        }

        // If there is error, dispose queue and
        if (osStatus != 0) {
            ret = FALSE;
            AudioQueueDispose(aqData.mQueue, YES);
            break;
        }
    }
    return ret;
}


#pragma mark FFControlable Protocol
//------------------------------------------------------------------
- (BOOL) isReady
{
    return (aqData.mStatus != kFFAQStateUnknown) != 0;
}

//------------------------------------------------------------------
- (void) start
{
    
    /**
     TODO: Check if it source is up and runnig
     IF source is not runing 
     THEN return
     ELSE Go on
     */
    
    if ((aqData.mStatus != kFFAQStatePaused) && (aqData.mStatus != kFFAQStateRunning)) {
        for (int i = 0; i < kNumberBuffers; i++) {
            
            // TODO: Figure out what wrong when we fill three buffer before stat queue
            // Need to fill buffer first time, and enqueue buffer
//            HandleOutputBuffer ((__bridge void *)(self),
//                                aqData.mQueue,
//                                aqData.mBuffers[i]);
            
            memset(aqData.mBuffers[i]->mAudioData, 1, aqData.mBuffers[i]->mAudioDataBytesCapacity);
            aqData.mBuffers[i]->mAudioDataByteSize = aqData.mBuffers[i]->mAudioDataBytesCapacity;
            AudioQueueEnqueueBuffer(aqData.mQueue, aqData.mBuffers[i], 0, 0);
        }
        
        Float32 gain = 1.0;

        AudioQueueSetParameter (aqData.mQueue,kAudioQueueParam_Volume,gain);

        OSStatus err = AudioQueueStart(aqData.mQueue, NULL);
        if (err) {
            JLogAQ(@"Could not start audio queue");
            aqData.mStatus = kFFAQStateStopped;
            return;
        }
        
        aqData.mStatus = kFFAQStateRunning;
        JLogAQ(@"AQHandler started");
    }
}

//------------------------------------------------------------------
- (void) pause
{
    AudioQueuePause(aqData.mQueue);
    aqData.mStatus = kFFAQStatePaused;
    JLogAQ(@"AQHandler Paused");
}

//------------------------------------------------------------------
- (void) resume
{
    AudioQueueStart(aqData.mQueue, NULL);
    aqData.mStatus = kFFAQStateRunning;
    JLogAQ(@"AQHandler Paused");
}

//------------------------------------------------------------------
- (void) stop
{
    //TEST
    AudioQueueStop(aqData.mQueue, YES);
    aqData.mStatus = kFFAQStateStopped;
    JLogAQ(@"AQHandler Stopped");
}

//------------------------------------------------------------------
- (BOOL) isRuning
{
    return NO;
}


#pragma mark - FFClock Protocol
- (NSTimeInterval) startTime
{
    return 0;
}

- (NSTimeInterval) currentTimeSinceStart
{
    if (aqData.mQueue) {
        
        AudioTimeStamp bufferStartTime;
        AudioQueueGetCurrentTime(aqData.mQueue, NULL, &bufferStartTime, NULL);

        return bufferStartTime.mSampleTime / [_source sampleRate];
    }
    return 0;
}
@end
