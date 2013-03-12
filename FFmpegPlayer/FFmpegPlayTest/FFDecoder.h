//
//  FFPDecoder.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/2/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFVideoScreen.h"
#import "FFAQHandler.h"
#import "FFControllable.h"
#import "FFDecoder.h"
#import "FFVideo.h"
#import "FFMpegEngine.h"
#import "FFAVPacketQueue.h"
#import "FFPictureQueue.h"
#import "FFAudioBuffer.h"

// TODO: static AVPacket avPacketFlush;

enum {
    FFDecodeStateUnknown            = 0,
    FFDecodeStateInited             = 1 << 0,
    FFDecodeStateStopped            = 1 << 1,
    FFDecodeStateDecoding           = 1 << 2,
    FFDecodeStatePaused             = 1 << 3,
    FFDecodeStateInterrupted        = 1 << 4,
    FFDecodeStateSeekingForward     = 1 << 5,
    FFDecodestateSeekingBackward    = 1 << 6
};
typedef NSInteger FFDecodeState;

enum {
    FFDecodeMasterClockAudio,
    FFDecodeMasterClockVideo,
    FFDecodeMasterClockExternal
};
typedef NSInteger FFDecodeMasterClock;


enum {
    FFDecodeAudioModeFFmpeg,
    FFDecodeAudioModeNative
};
typedef NSInteger FFDecodeAudioMode;

//----------------------------------------------------------------
@class FFDecoder;
@protocol FFDecoderDelegate <NSObject>

@end

#define FFDecodeMaxAudioBufferSize ((AVCODEC_MAX_AUDIO_FRAME_SIZE * 3) / 2)
//----------------------------------------------------------------
@interface FFDecoder : NSObject
<FFVideoScreenSource, FFAudioQueueSource, FFControllable>
{
@private
    /**
     TODO: declare threads objects to manage threads
     including: packet reading, decoding threads (for
     both video and audio).
     */
    BOOL videoOn;
    BOOL audioOn;
    FFDecodeState   decodeStatus;
    FFDecodeAudioMode decodeAudioMode;
    FFVideo         *_video;
    NSThread*       demuxThread;
    NSThread*       decodeVideoThread;
    NSThread*       decodeAudioThread;
#pragma mark Connection to display and speaker
    // TODO: declare reference to AudioQueueHande and Dislay
    
    
    double startTime;
    
#pragma mark Video
    
    FFAVPacketQueue *_videoPktQueue;
    FFPictureQueue  *_videoPicQueue;
    
    // video pkt pts
    //NSTimeInterval  videoPktPts;
    
    // Context to scale and convert image format
    struct SwsContext *swsContext;
    
    
    // Pixel format for output frame
    int             glPixelFormat;
    int             ffPixelFormat;
    
    // For video clock
    double          videoClock;
    double          videoCurrentPts;
    int64_t         videoCurrentPtsTime; // In micro seconds
    
    /**
     These variables are used to determine when to display the next
     video picture (see Dranger's tutorial 05) since there is no such
     timer like Display Link or Screen timer.
     
     NOTE: Probably will be unused in this version
     */
    double          videoFrameTimer;  // in seconds
    double          videoFrameLastPts;
    double          videoFrameLastDelay;
    
#pragma mark Audio
    FFAVPacketQueue *_audioPktQueue;
    FFAudioBuffer   *_audioBuffer; // Buffer for decoded audio frame
    double          audioClock;
    
    // to hold reference to a pkt read from queue, use in audio decode process
    AVPacket        pktFromQueue;             // to contain packet read from queue
    AVPacket        pktTemp;
    int             audioHWBufferSpec;      // size of audio buffer, defined by sys
    
    uint8_t         audioBuffer[FFDecodeMaxAudioBufferSize];
    unsigned int    audioBufSize;
    unsigned int    audioBufIndex;
    
    // For Audio synchronization
    double          audioDiffCum;
    double          audioDiffAverageCoef;
    double          audioDiffThreshold;
    int             audioDiffAverageCount;
    
#pragma mark AV Synchronization Variables
    int             avSyncType;
    double          externalClock;
    int64_t         externalClockTime;
    
}


@property (nonatomic)  FFDecodeMasterClock clockMode;
- (id) initWithContentURL: (NSURL*) url;
@end

//----------------------------------------------------------------
@interface FFDecoder (VideoProperties)
@property (nonatomic) int mediaSourceType;

- (double) currentPlaybackTime;
- (float) currentPlaybackRate;
- (int) mediaTypes;
- (float) duration;
- (float) playableDuration;
- (CGSize) videoSize; //CGSizeZero if not known/applicable.
- (float) startTime; // return NaN indicates the natural start time
- (float) endTime; // return NaN indicates the natural end time
@end
