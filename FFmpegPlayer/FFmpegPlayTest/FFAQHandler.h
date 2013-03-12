//
//  AQHandler.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/2/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioToolbox.h>
#import "FFControllable.h"
#import "FFTimingProtocols.h"

enum {
    kFFAQStateUnknown,   //= 0,
    kFFAQStateStopped,   //= 1 << 0,
    kFFAQStateRunning,   //= 1 << 1,
    kFFAQStatePaused     //= 1 << 2,
};

typedef NSInteger FFAQState;


static const int kNumberBuffers = 3;
typedef struct  {
    AudioStreamBasicDescription   mDataFormat;
    AudioQueueRef                 mQueue;
    AudioQueueBufferRef           mBuffers[kNumberBuffers];
    //  AudioFileID                   mAudioFile;
    UInt32                        bufferByteSize;
    UInt32                        mNumPacketsToRead;
    SInt64                        mCurrentPacket;
    AudioStreamPacketDescription  *mPacketDescs;
    FFAQState                     mStatus;
} AQPlayerState;


//----------------------------------------------------------------
@protocol FFAudioQueueSource <NSObject>

@required
- (BOOL) fillAudioStreamDescription: (AudioStreamBasicDescription*) pASBD;
- (UInt32) maxAudioPacketSize;
- (void) renderAudioBuffer:(AudioQueueBufferRef) aqBuffer
                    forPts:(NSTimeInterval) pts;

@optional

- (int) sampleRate;
@end
//----------------------------------------------------------------

@protocol FFAQHandlerDelegate <NSObject>

@end

//----------------------------------------------------------------
@interface FFAQHandler : NSObject <FFControllable, FFClock>
//@property (nonatomic, readonly) AQPlayerState* pAQdata;
- (AQPlayerState*) audioQueueData;
@property (nonatomic, weak) id<FFAudioQueueSource> source;
@property (nonatomic, weak) id<FFAQHandlerDelegate> delegate;
- (id) initWithSource: (id<FFAudioQueueSource>) source;
@end
