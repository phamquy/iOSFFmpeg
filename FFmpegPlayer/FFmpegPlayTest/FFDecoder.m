//
//  FFPDecoder.m
//  FFmpegPlayTest
//
//  Created by Jack on 11/2/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <CoreAudio/CoreAudioTypes.h>
#import "FFDecoder.h"


#ifdef DEBUG_DECODER
#define JLogDec JLog
#else
#define JLogDec(...)
#endif


#ifdef DEBUG_AUDIO
#define JLogAudio JLog
#else
#define JLogAudio(...)
#endif

#ifdef DEBUG_VIDEO
#define JLogVideo JLog
#else
#define JLogVideo(...)
#endif

#ifdef DEBUG_DEMUX
#define JLogDmx JLog
#else
#define JLogDmx(...)
#endif


/// Use another thread to decode audio and add it to
/// the audio buffer
//#define USE_AUDIO_THREAD

//#define _cplusplus

#define kFFMaxVideoQueueSize (5 * 256 * 1024) // ~ 1MB
#define kFFMaxAudioQueueSize (5 * 16 * 1024)
#define AUDIO_DIFF_AVG_NB 20
#define SDL_AUDIO_BUFFER_SIZE 1024
#define SAMPLE_CORRECTION_PERCENT_MAX 10.0
#define AV_NOSYNC_THRESHOLD 10.0
#define AV_SYNC_THRESHOLD 0.01
#define AV_SYNC_VIDEO_THRESHOLD 0.01
#define AUDIO_DIFF_AVG_NB 20
#define kFFDecodeKeyVideoPktPts @"videoPacketPts"

/**
 This function should return TRUE (1) if the decode process is quited
 otherwise return FALSE (0)
 
 Usage: check status to see if "quit signal" has sent, if so return 1 
 to interupt IO process.
 */
static int decodeInteruptCallback(void * ctx) {
    int* status = (int*) ctx;
    return (*status == FFDecodeStateStopped);
}

double global_video_pkt_pts;
int our_get_buffer(struct AVCodecContext *c, AVFrame *pic) {
    int ret = avcodec_default_get_buffer(c, pic);
    uint64_t *pts = av_malloc(sizeof(uint64_t));
    *pts = global_video_pkt_pts;
    pic->opaque = pts;
    return ret;
}
//---------------------------------------------------------------------
void our_release_buffer(struct AVCodecContext *c, AVFrame *pic) {
    if(pic) av_freep(&pic->opaque);
    avcodec_default_release_buffer(c, pic);
}

#pragma mark - FFDecoder Extension
@interface FFDecoder ()
{
}
@end

#pragma mark - FFDecoder Implementation

@implementation FFDecoder
@synthesize clockMode=_clockMode;

#pragma mark Init and utilities
- (id) initWithContentURL: (NSURL*) url
{
    self = [super init];
    if (self) {
        [[FFMpegEngine shareInstance] initFFmpegEngine];
        
        // Assign callback to check status of decode process
        AVIOInterruptCB interuptCallback;
        interuptCallback.callback = decodeInteruptCallback;
        interuptCallback.opaque = &decodeStatus;
        decodeStatus = FFDecodeStateUnknown;

        // Open video file and assign ffmpeg io interupt callback
        _video = [[FFVideo alloc] initWithUrl: url
                             interuptCallback: interuptCallback];
        
        if (!_video) {
            JLogDec(@"Failed init decoder");
            return nil;
        }
        
        [_video videoCodecContext]->get_buffer  = our_get_buffer;
        [_video videoCodecContext]->release_buffer = our_release_buffer;
        
        // Using ffmpeg for audio decoding
         decodeAudioMode = FFDecodeAudioModeFFmpeg;
        //decodeAudioMode = FFDecodeAudioModeNative; // TEST
        
        
        _clockMode = FFDecodeMasterClockExternal;
        // For the current version, we force output of decoder
        // to be RGB_565, for the later update this value should
        // be set via a public accessor
        glPixelFormat = GL_UNSIGNED_SHORT_5_6_5;
        
        // [JACK] Test directly render YUV420
//        ffPixelFormat = PIX_FMT_RGB565;
        ffPixelFormat = PIX_FMT_YUV420P;
        
        
        // TODO: remmeber to release swsScale
        // Init software scale context
        swsContext = sws_getContext([_video videoCodecContext]->width,
                                    [_video videoCodecContext]->height,
                                    [_video videoCodecContext]->pix_fmt,
                                    [_video videoCodecContext]->width,
                                    [_video videoCodecContext]->height,
                                    ffPixelFormat,     // match with outputPixelFormat
                                    SWS_FAST_BILINEAR,
                                    NULL, NULL, NULL);
        
        
        if (![self initDecoder])
        {
            JLogDec(@"Failed init decoder");
            return nil;
        }
        
        videoOn = YES;
        audioOn = YES;
        decodeStatus |= FFDecodeStateInited;
    }
    return self;
}


//----------------------------------------------------------------
- (BOOL) initDecoder
{
    BOOL ret = TRUE;
    
    // >> VIDEO <<<
    // Initialize video queue buffer
    _videoPktQueue = [[FFAVPacketQueue alloc] initWithSize:kFFMaxVideoQueueSize];
    _videoPicQueue = [[FFPictureQueue alloc] init]; // using fixed size queue
    
    if(!_videoPicQueue || !_videoPktQueue)
    {
        ret = FALSE;
        goto finish;
    }
    
    startTime = CACurrentMediaTime();
    // Initialize timer variable
    videoFrameTimer = CACurrentMediaTime();
    videoFrameLastDelay = 40e-3;
    videoFrameLastPts = 0;
    
    videoClock = 0;
    videoCurrentPts = 0;
    videoCurrentPtsTime = CACurrentMediaTime();
    
    // >>> AUDIO <<<
    // Initialize audio buffer queue
    _audioPktQueue = [[FFAVPacketQueue alloc] initWithSize:kFFMaxAudioQueueSize];
    if (!_audioPktQueue) {
        ret = FALSE;
        goto finish;
    }
    
    UInt32 bitPerChannel   = [FFMpegEngine bitsForSampleFormat: [_video audioCodecContext]->sample_fmt];
    BOOL isNonInterleaved       = NO;
    UInt32 channelsPerSample     = [_video audioCodecContext]->channels;
    Float64 sampleRate          = [_video audioCodecContext]->sample_rate;
    
    UInt32 mBytesPerFrame    = (isNonInterleaved ? 1 : channelsPerSample) * (bitPerChannel/8);
    
    // Init audio buffer for decoded audio frames
    _audioBuffer = [[FFAudioBuffer alloc] initBufferForDuration: 1
                                                 bytesPerSample: mBytesPerFrame
                                                     sampleRate: sampleRate];
    
    // Initialize audio clock
    audioClock = 0;
    
    // TODO: define when decoder connect to audio speaker
    audioHWBufferSpec = 0;
    
    // Initialize audio sync accumulator
    audioDiffCum = 0;
    audioDiffAverageCoef = exp(log(0.01 / AUDIO_DIFF_AVG_NB));
    audioDiffAverageCount = 0;
    audioDiffThreshold= 2.0 * SDL_AUDIO_BUFFER_SIZE / [_video audioCodecContext]->sample_rate;
    memset(&pktFromQueue, 0, sizeof(pktFromQueue));
    memset(&pktTemp, 0, sizeof(pktTemp));
    
finish:
    if (!ret){
        JLogDec(@"Failed to init decoder");
    }
    else{
        JLogDec(@"Finished init decoder");
    }
    
    return ret;
}

//----------------------------------------------------------------
#pragma mark FFControllable Protocol
//----------------------------------------------------------------
- (void) pause
{
    //TODO: Implement
    JLogDec(@"Decoder Paused");
}
- (void) resume
{
    JLogDec(@"Decoder Resumed");
}
//----------------------------------------------------------------
- (BOOL) isReady
{
    return ((decodeStatus & FFDecodeStateInited) | (decodeStatus & FFDecodeStatePaused)) != 0 ;
}
//----------------------------------------------------------------
- (void) start
{
    
    //[self performSelectorInBackground:@selector(demuxVideo:) withObject:self];
    demuxThread = [[NSThread alloc] initWithTarget:self
                                          selector:@selector(demuxVideo:)
                                            object:self];

    decodeVideoThread = [[NSThread alloc] initWithTarget:self
                                                selector:@selector(decodeVideo:)
                                                  object:self];
    
    decodeAudioThread = [[NSThread alloc] initWithTarget:self
                                                selector:@selector(decodeAudio:)
                                                  object:self];
    
    [demuxThread start];

    if (videoOn) {
        [decodeVideoThread start];
    }
    
    if (audioOn) {
        [decodeAudioThread start];
    }

    startTime = CACurrentMediaTime();;
    decodeStatus = FFDecodeStateDecoding;
    JLogDec(@"Decoder started");
}
//----------------------------------------------------------------
- (void) stop
{
    //TODO: Implement
    if (demuxThread) {
        [demuxThread cancel];
    }
    
    if (decodeVideoThread && [decodeVideoThread isExecuting]) {
        [decodeVideoThread cancel];
    }
    if (decodeAudioThread && [decodeAudioThread isExecuting]) {
        [decodeAudioThread cancel];
    }
    
    JLogDec(@"Decoder Stopped");
}
//----------------------------------------------------------------
- (BOOL) isRuning
{
    //TODO: Implement
    return NO;
}

#pragma mark Decoding Threads

- (void) demuxVideo: (id) data
{
    @autoreleasepool {
       
        NSThread* currentThread = [NSThread currentThread];
        AVPacket readPkt, *pReadPkt = &readPkt;
        AVFormatContext* pContext = [_video formatContext];
        for (;;) {
            /// Check if thread is cancelled, OR ***decode finish***
            if ([currentThread isCancelled]) {
                JLogDmx(@"Demux thread cancelled");
                // TODO: release resource and allocated memory here
                break;
            }
            
            // TODO: Handle seeking stuff here
            // flush queue, push the flush pkt to queue
            
            
            // Check if pkt queue data size is exceed the limit,
            // if so delay, than continue to next loop
//            if ([_videoPktQueue dataSize] > kFFMaxVideoQueueSize||
//                [_audioPktQueue dataSize] > kFFMaxAudioQueueSize)
//            {
//                JLogDmx(@"Waiting for space in packet queue");
//                usleep(10000); // delay for 10 miliseconds
//                continue;
//            }
 
            if (av_read_frame(pContext, pReadPkt) < 0) {
                if (&pContext->pb && &pContext->pb->error) {
                    // NO Error, wait for user input to interrupt.
                    usleep(10000);
                    continue;
                }else{
                    break;
                }
            }
            
            // Push packet into corresponding queue
            if (pReadPkt->stream_index == [_video videoStreamIndex]) {
                if(videoOn){
                    JLogDmx(@"Push packet to video queue");
                    //NSLog(@"V---");
                    [_videoPktQueue pushPacket:pReadPkt blocked:YES];
                }else{
                    av_free_packet(pReadPkt);
                }
            }else if(pReadPkt->stream_index == [_video audioStreamIndex]){
                if (audioOn) {
                    JLogDmx(@"Push packet to audio queue");
                    //NSLog(@"---A");
                    //NSLog(@"Pkt'size: %d, duration: %d, dts: %lld", pReadPkt->size, pReadPkt->duration, pReadPkt->pts);
                    [_audioPktQueue pushPacket:pReadPkt blocked:YES];
                }else{
                    av_free_packet(pReadPkt);
                }
            }else{
                av_free_packet(pReadPkt);
            }
        }
        
        /// ???: Why do have to wait for cancelled signal, why dont just finish
        /// the thread routine?
        // Wait for the quit signal
        while (![currentThread isCancelled]) {
            usleep(100000);
        }
    }
    JLogDec(@"Demux thread finished");
}

//----------------------------------------------------------------
- (void) decodeVideo: (id) data
{
    JLogDec(@"Decoding video stream");
    
    @autoreleasepool {

        
        AVCodecContext* pVideoCodecCtx  = [_video videoCodecContext];
        NSThread* currentThread = [NSThread currentThread];
        
        AVPacket readPkt, *pReadPkt = &readPkt;
        AVFrame* pFrame;
        int frameFinished;
        NSTimeInterval pts;
        int videoWidth = [_video videoCodecContext]->width;
        int videoHeight = [_video videoCodecContext]->height;
        
        JLogVideo(@"Video width: %d, height: %d", videoWidth, videoHeight);
        
        pFrame = avcodec_alloc_frame();
        
        
        for (;;) {
            /// Check if thread is cancelled
            if ([currentThread isCancelled]) {
                JLogVideo(@"Decode video thread cancelled");
                break;
            }
            
            /// Get pkt from queue
            if (![_videoPktQueue popPacket:pReadPkt blocked:YES]) {
                JLogVideo(@"Get no packet from video queue");
                continue;
            }
            
            /* TODO: Handle seeking packet
            if(packet->data == flush_pkt.data) {
                avcodec_flush_buffers(vidState->video_st->codec);
                continue;
            }
            */
            
            pts = 0;
            global_video_pkt_pts = pReadPkt->pts;
            
            // Decode video frame, memory will be allocate automatically for pFrame
            avcodec_decode_video2(pVideoCodecCtx, pFrame, &frameFinished, pReadPkt);

            if(pReadPkt->dts == AV_NOPTS_VALUE
               && pFrame->opaque && *(uint64_t*)pFrame->opaque != AV_NOPTS_VALUE) {
                pts = *(uint64_t *)pFrame->opaque;
            } else if(pReadPkt->dts != AV_NOPTS_VALUE) {
                pts = pReadPkt->dts;
            } else {
                pts = 0;
            }


            pts *= av_q2d([_video videoStream]->time_base);

            //JLogVideo(@"Picture pts before sync: %f", pts);
            // Decoded a frame?
            if (frameFinished) {
                JLogVideo(@"Got a frame");
                
                // [TEST] Dont adjust video pts
                pts = [self synchronizeVideoFrame:pFrame
                                         framePts:pts];
                
                //JLogVideo(@"Picture pts after sync: %f", pts);

                // Reuse picture in the queue
                FFVideoPicture* picture = [_videoPicQueue pictureToWriteWithBlock:YES];
                
                // If it NULL, reallocate the new one
                if (!picture) {
                    picture = [[FFVideoPicture alloc] initWithPixelFormat:ffPixelFormat
                                                                    width:videoWidth
                                                                   height:videoHeight];
                }
                

//                JLogVideo(@"Source video pix format: %d", [_video videoCodecContext]->pix_fmt);

                
                /// Convert frame data format to picture's format
                // get AVPicture instance of the picture which using the same
                // picture data
//                AVPicture* avPict  = [picture avPicture];
//                JLogVideo(@"avPict data: %p", avPict->data);
//                JLogVideo(@"avPict data 0: %p", avPict->data[0]);
//                JLogVideo(@"avPict data 1: %p", avPict->data[1]);
//                JLogVideo(@"avPict data 2: %p", avPict->data[2]);
                
                /// [JACK] Test no sws pixel convert
//                sws_scale(swsContext,
//                          (const uint8_t * const *)pFrame->data,
//                          pFrame->linesize,
//                          0,
//                          videoHeight,
//                          avPict->data,
//                          avPict->linesize);
                av_picture_copy([picture avPicture],
                                (const AVPicture*) pFrame, 
                                [_video videoCodecContext]->pix_fmt,
                                videoWidth,
                                videoHeight);
                
                // Update picture pts
                [picture setPts:pts];
                
                /// Push frame to picture queue
                [_videoPicQueue pushPicture:picture blockingMode:YES];
            }
            
            av_free_packet(pReadPkt);
            
        }
        av_free(pFrame);
        JLogVideo(@"Decode video finished");
        while (![currentThread isCancelled]) {
            usleep(100000);
        }
    }
}

//----------------------------------------------------------------
/**
 Right now the audio is decoded immediately when it's requested from
 audio handler, so decodeAudio:data virtually does nothing. The code 
 is kept for reference.
 */
- (void) decodeAudio: (id) data
{
#ifdef USE_AUDIO_THREAD
    
    @autoreleasepool {
        AVCodecContext* pAudioCodecCtx  = [_video audioCodecContext];
        NSThread* currentThread = [NSThread currentThread];
        
        
        int decodedLen, decodedFrameSize;
        
        AVPacket readPkt;
        AVPacket *pReadPkt = &readPkt;
        
        AVPacket pktTemp;
        AVPacket *pPktTemp = &pktTemp; // hold data that is being process.
        
        AVFrame  *pDecodedFrame;
        pDecodedFrame = avcodec_alloc_frame();
        avcodec_get_frame_defaults(pDecodedFrame);
        
        // Zero out temporary packet
        memset(pPktTemp, 0, sizeof(AVPacket));
        memset(pReadPkt, 0, sizeof(AVPacket));
        
        
        // Loop that decode audio packets and push decode data to audio buffer
        JLogAudio(@"Decoding audio stream");
        for (;;) {
            
            
            // Check if thread is cancelled
            if ([currentThread isCancelled]) {
                JLogAudio(@"Decode audio thread cancelled");
                break;
            }
            
            // A packet may contain more than one frame, so to decode a packet
            // we need a loop
            while(pktTemp.size > 0){
                
                int gotFrame = 0;
                //avcodec_get_frame_defaults(&decodedFrame);
                
                // Decode audio data to decoded frame
                decodedLen = avcodec_decode_audio4(pAudioCodecCtx,
                                                   pDecodedFrame,
                                                   &gotFrame,
                                                   pPktTemp);
                // If error occur, we skip the packet
                if (decodedLen < 0) {
                    pPktTemp->size = 0;
                    break;
                }
                
                // Update pointer and length in temp packet
                pPktTemp->data += decodedLen;
                pPktTemp->size -= decodedLen;
                
                // If a frame is found
                if (gotFrame) {
                    
                    // Calculate size in bytes for decoded frames
                    decodedFrameSize = av_samples_get_buffer_size(NULL, pAudioCodecCtx->channels,
                                                                  pDecodedFrame->nb_samples,
                                                                  pAudioCodecCtx->sample_fmt, 1);
                    
                    /// FIXME: this push will be call so frequently so it will block access
                    /// to the audio buffer so often that will flicking noise in audio output
                    // Push those data to buffer
                    [_audioBuffer pushSample:pDecodedFrame->data[0]
                                        size:decodedFrameSize
                                     blocked:YES];
                }
            };
            
            // Free packet after decode it
            if(pReadPkt->data)
                av_free_packet(pReadPkt);
            
            // Get next pkt from queue
            if (![_audioPktQueue popPacket:pReadPkt blocked:YES]) {
                JLogAudio(@"Get no packet from audio queue");
                continue;
            }
            
            
            // TODO: Handleflush packets
            //if(pkt->data == flush_pkt.data) {
            //    avcodec_flush_buffers(vidState->audio_st->codec);
            //    continue;
            //}
            
            // Assign data to temporary packet
            pktTemp.data = pReadPkt->data;
            pktTemp.size = pReadPkt->size;
            
            /* if update, update the audio clock w/pts */
            //if(pkt->pts != AV_NOPTS_VALUE) {
            //    vidState->audio_clock = av_q2d(vidState->audio_st->time_base) * pkt->pts;
            //}        
        }
        
        avcodec_free_frame(&pDecodedFrame);
    }
    
    return;
#endif
}
//----------------------------------------------------------------
#pragma mark - Utilities Methods
- (NSTimeInterval) masterClock
{
    if (_clockMode == FFDecodeMasterClockVideo) {
        return [self videoClock];
    }else if (_clockMode == FFDecodeMasterClockAudio){
        return [self audioClock];
    }else{
        return [self externalClock];
    }
}
//-----------------------------------------------------------------
- (NSTimeInterval) audioClock
{
    double pts;
    int hw_buf_size, bytes_per_sec, n;
    
    pts = audioClock; /* maintained in the audio thread */
    hw_buf_size = audioBufSize - audioBufIndex;
    bytes_per_sec = 0;
    n = [_video audioCodecContext]->channels * 2;
    if([_video audioStream]) {
        bytes_per_sec = [_video audioCodecContext]->sample_rate * n;
    }
    if(bytes_per_sec) {
        pts -= (double)hw_buf_size / bytes_per_sec;
    }
    return pts;
}
//-----------------------------------------------------------------
- (NSTimeInterval) videoClock
{
    double delta;
    
    delta = CACurrentMediaTime() - videoCurrentPtsTime;
    return videoCurrentPts + delta;
}
//-----------------------------------------------------------------
- (NSTimeInterval) externalClock
{
    return CACurrentMediaTime() -startTime;
}
//-----------------------------------------------------------------
- (NSTimeInterval) synchronizeVideoFrame: (AVFrame*) srcFrame
                                framePts: (NSTimeInterval) pts
{
    
    NSTimeInterval frameDelay;
    
    if(pts != 0) {
        /* if we have pts, set video clock to it */
        videoClock = pts;
    } else {
        /* if we aren't given a pts, set it to the clock */
        pts = videoClock;
    }
    /* update the video clock */
    frameDelay = av_q2d([_video videoStream]->codec->time_base);
    /* if we are repeating a frame, adjust clock accordingly */
    frameDelay += srcFrame->repeat_pict * (frameDelay * 0.5);
    videoClock += frameDelay;
    return pts;
}

//----------------------------------------------------------------
/**
 decode audio to audio buffer and store audio of first sample of 
 new decoded audio sample
 */
- (int) decodeAudioOutBuff: (NSTimeInterval*) pts
{
    AVCodecContext* pAudioCodecCtx  = [_video audioCodecContext];
    AVStream* pAudioStream = [_video audioStream];
    
    int decodedLen =0 , decodedFrameSize =0 , n = 0;
    
    AVFrame  *pDecodedFrame = nil;
    pDecodedFrame = avcodec_alloc_frame();
    avcodec_get_frame_defaults(pDecodedFrame);
    
    // Loop that decode audio packets and push decode data to audio buffer
    JLogAudio(@"Decoding audio stream");
    for (;;) {
        
        // A packet may contain more than one frame, so to decode a packet
        // we need a loop
        while(pktTemp.size > 0){
            
            int gotFrame = 0;
            //avcodec_get_frame_defaults(&decodedFrame);
            
            // Decode audio data to decoded frame
            decodedLen = avcodec_decode_audio4(pAudioCodecCtx,
                                               pDecodedFrame,
                                               &gotFrame,
                                               &pktTemp);
            // If error occur, we skip the packet
            if (decodedLen < 0) {
                pktTemp.size = 0;
                break;
            }
            
            // Update pointer and length in temp packet
            pktTemp.data += decodedLen;
            pktTemp.size -= decodedLen;
            
            // If a frame is found
            if (gotFrame) {
                
                // Calculate size in bytes for decoded frames
                decodedFrameSize = av_samples_get_buffer_size(NULL, pAudioCodecCtx->channels,
                                                              pDecodedFrame->nb_samples,
                                                              pAudioCodecCtx->sample_fmt, 1);
                
                // we got decode data pointed by decodedFrame.data[0], with size
                // decodedFrameSize
                memcpy(audioBuffer, pDecodedFrame->data[0], decodedFrameSize);
            }else{
                decodedFrameSize = 0;
            }
            
            if (decodedFrameSize <= 0) {
                continue;
            }
            *pts = audioClock;
            n = 2 * pAudioCodecCtx->channels; // 16bits per sample per channel
            audioClock += (double)decodedFrameSize / (double)(n * pAudioCodecCtx->sample_rate);
            
            // decodedFrameSize > 0;
            break;
        }
        
        // If got data, break and return
        if (decodedFrameSize > 0) {
            break;
        }

        // Free packet after decode it
        if(pktFromQueue.data)
            av_free_packet(&pktFromQueue);
        
        // TODO: detect quit signal
        
        // Get next pkt from queue
        if (![_audioPktQueue popPacket:&pktFromQueue blocked:YES]) {
            JLogAudio(@"Get no packet from audio queue");
            return -1;
        }
        
        
        // TODO: Handleflush packets
        //if(pkt->data == flush_pkt.data) {
        //    avcodec_flush_buffers(vidState->audio_st->codec);
        //    continue;
        //}
        
        // Assign data to temporary packet
        pktTemp.data = pktFromQueue.data;
        pktTemp.size = pktFromQueue.size;
        
        /* if update, update the audio clock w/pts */
        if(pktFromQueue.pts != AV_NOPTS_VALUE) {
            audioClock = av_q2d(pAudioStream->time_base) * pktFromQueue.pts;
        }
    }
    
    avcodec_free_frame(&pDecodedFrame);
    return decodedFrameSize;
}
//----------------------------------------------------------------
- (int) synchronizeAudioBuff: (int16_t *) pBuf
                      OfSize: (int) auSize
                         pts: (double) pts
{
    AVCodecContext* pAudioCodecCtx  = [_video audioCodecContext];
    int n = 2 * pAudioCodecCtx->channels;
    double refClock;
    double diff, avg_diff;
    int wanted_size, min_size, max_size;
    
    
    if (_clockMode != FFDecodeMasterClockAudio) {
   
        refClock = [self masterClock];
        diff = [self audioClock] - refClock;
        JLogDec(@"A-Ref diff: %f", diff);
/*
        if (diff < AV_NOSYNC_THRESHOLD) {
            audioDiffCum = diff + audioDiffAverageCoef * audioDiffCum;
            
            JLogDec(@"DiffCum: %f, avgCount: %d", audioDiffCum, audioDiffAverageCount);
            
            if (audioDiffAverageCount < AUDIO_DIFF_AVG_NB) {
                audioDiffAverageCount++;
            }else{
                avg_diff = audioDiffCum * (1.0 - audioDiffAverageCoef);
                JLogDec(@"New avg: %f, threshold: %f", avg_diff, audioDiffThreshold);
                
                if (fabs(avg_diff) >= audioDiffThreshold) {
                    
                    wanted_size = auSize + ((int)(diff * pAudioCodecCtx->sample_rate) * n);

                    min_size = (float) auSize * ((100.0 - SAMPLE_CORRECTION_PERCENT_MAX) / 100.0);
                    max_size = (float) auSize * ((100.0 + SAMPLE_CORRECTION_PERCENT_MAX) / 100.0);

                    JLogDec(@"wanted size: %d, max: %d, min: %d", wanted_size, max_size, min_size);
                    if (wanted_size < min_size)
                    {
                        wanted_size = min_size;
                    }
                    else if(wanted_size > max_size)
                    {
                        wanted_size = max_size;
                    }
                    else if (wanted_size > auSize)
                    {
                        uint8_t *sampleEnd, *q;
                        int nb;
                        
                        nb = auSize - wanted_size;
                        sampleEnd = (uint8_t*) pBuf + auSize - n;
                        q = sampleEnd + n;
                        while(nb > 0) {
                            memcpy(q, sampleEnd, n);
                            q += n;
                            nb -= n;
                        }
                        auSize = wanted_size;
                    }
                }
             }
 
        }else{
            audioDiffAverageCount = 0;
            audioDiffCum = 0;
        }
 */
    }
    JLogDec(@"Return auSize: %d", auSize);
    return auSize;
}
//----------------------------------------------------------------
/**
 Decode audio samples to pBuffer, given size of buffer and pts of the
 buffer
 @param pBuffer Pointer to the buffer
 @param capacity size of buffer
 @param pts Presenting timestamp of the buffer
 
 @return return filled size
 */
- (void) fillPCMAudioIntoBuff:(void *) pBuffer
                  capacity:(UInt32) capacity
{
    int needRead = capacity;
    int audioSize, copySize;
    double pts;
    while (needRead > 0) {
        // if there is no samples in audio buffer, decode new samples
        if(audioBufIndex >= audioBufSize){
            audioSize = [self decodeAudioOutBuff:&pts];
            //JLogDec(@"Audio size before: %d", audioSize);
            if (audioSize < 0) {
                audioBufSize = 1024;
                memset(audioBuffer, 0, audioBufSize);
            }else{
//                audioSize = [self synchronizeAudioBuff: (int16_t*)audioBuffer
//                                                OfSize: audioSize
//                                                   pts: pts];
                //JLogDec(@"Audio size after: %d", audioSize);
                audioBufSize = audioSize;
            }
            audioBufIndex = 0;
        }
        
        
        copySize = audioBufSize - audioBufIndex;
        if (copySize > needRead) {
            copySize = needRead;
        }
        memcpy(pBuffer, audioBuffer + audioBufIndex, copySize);
        needRead -= copySize;
        pBuffer += copySize;
        audioBufIndex += copySize;
    }
}

//----------------------------------------------------------------
- (void) fillAudioPktToBuff: (AudioQueueBufferRef)aqBuffer
                     forPts: (NSTimeInterval) pts
{
    int ret = 0;
    while ((aqBuffer->mAudioDataByteSize < aqBuffer->mAudioDataBytesCapacity) &&
            aqBuffer->mPacketDescriptionCount < aqBuffer->mPacketDescriptionCapacity)
    {
        ret = [_audioPktQueue popPacket:&pktFromQueue blocked:YES];
        if (ret == 0) {
            break;
        }
        memcpy(aqBuffer->mAudioData + aqBuffer->mAudioDataByteSize, pktFromQueue.data, pktFromQueue.size);
        aqBuffer->mPacketDescriptions[aqBuffer->mPacketDescriptionCount].mStartOffset = aqBuffer->mAudioDataByteSize;
        aqBuffer->mPacketDescriptions[aqBuffer->mPacketDescriptionCount].mDataByteSize = pktFromQueue.size;
        aqBuffer->mPacketDescriptions[aqBuffer->mPacketDescriptionCount].mVariableFramesInPacket = [_video audioCodecContext]->frame_size; // TODO: need to calculate it, 0 mean constant frame in packet
        aqBuffer->mPacketDescriptionCount++;
        aqBuffer->mAudioDataByteSize += pktFromQueue.size;
    }
}
//----------------------------------------------------------------
#pragma mark - FFVideoScreenSource Protocol
- (void) finishFrameForScreen: (FFVideoScreen*) screen
{
    [_videoPicQueue popPictureWithBlockingMode:YES];
}

//----------------------------------------------------------------
- (CGSize) videoFrameSize
{
    if (!_video) {
        return CGSizeMake(0, 0);
    }
    
    return CGSizeMake([_video videoCodecContext]->width,
                      [_video videoCodecContext]->height);
}

//----------------------------------------------------------------
- (int) pixelFormat
{
    return glPixelFormat;
}

//----------------------------------------------------------------
/**
 This function called by Video screen object get the next video 
 picture to display.
 
 @param screen screen that call this function
 @param lastPts last present time stamp (since start time) of last shown frame
 
 @return picture to render
 */
-(const FFVideoPicture* const) getPictureForScreen: (FFVideoScreen*) screen
                                       screenClock:(NSTimeInterval)scrPts
{

//    const FFVideoPicture* const picture = [_videoPicQueue pictureToReadWithBlock:NO];

//    double actual_delay, delay, sync_threshold;
//    delay = videoCurrentPts - videoFrameLastPts;
//    if (delay <=0 || delay >= 1) {
//        delay = videoFrameLastDelay;
//    }
    
//    videoFrameLastDelay = delay;
    double diff, ref_clock, aclk;
    const FFVideoPicture* picture = nil;
    
    ref_clock = [self masterClock];
    aclk = [self audioClock];
    //ref_clock = scrPts;
    for(;;){
        picture = [_videoPicQueue pictureToReadWithBlock:YES];
        if(_clockMode  != FFDecodeMasterClockVideo ) {
            diff = [picture pts] - scrPts ;
            JLogDec(@"Delay: %f, rendering time: %f",diff, [screen renderingTime]);
//            JLogDec(@"video picture: pts: %f; ref_clk: %f; diff: %f, videoclk: %f, audioClk: %f, exClk: %f",
//                    [picture pts],ref_clock,diff, [self videoClock],[self audioClock], [self externalClock]);
            JLogDec(@"vpts-aclk: %f, vpts-ref-clk: %f, refClk: %f, aclk: %f",[picture pts]-aclk, [picture pts] - ref_clock, ref_clock, aclk);
            
            // TEST, just break here, so video will ouput at max speed
            //JLog(@"Packet size %d, pic queue: %d", [_videoPktQueue count],[_videoPicQueue size]);

            //break;

            if (diff > AV_SYNC_VIDEO_THRESHOLD){
                usleep(diff* 1000000.0);
                break;
            }
            else if (diff < (-AV_SYNC_VIDEO_THRESHOLD))
            {
                if(![_videoPicQueue size])
                    continue;
                break;
            }
            break;
        }
    }

    videoFrameLastPts = videoCurrentPts;
    videoCurrentPts = [picture pts];
    videoCurrentPtsTime = CACurrentMediaTime();

    return picture;
}

//----------------------------------------------------------------
#pragma mark - FFAudioQueueSource Protocol
/**
 There are two options for audio decoding: (1) using ffmpeg as external soft 
 decoder, (2) using native ios decoder (nativ and soft).
 
 (1) If ffmpeg is used as decoder, AudioStreamBasicDescription (ASBD) should be 
 formated as uncompressed LPCM format.
 
 (2) If ios decoder is used, ASBD should be formated to conform the codec of 
 audio strem (often used: mp3, and aac)
 
 In this current version, we use ffmpeg as audio decoder, so ASBD is filled as
 uncompressed LPCM.
 */
// TODO: Need improvment
//  Implement fillAudioStream for general case that includes iOS decoder (AAC, MP3).
//  Check output from ffmpeg for this value
- (BOOL) fillAudioStreamDescription: (AudioStreamBasicDescription*) pASBD
{
    if (!_video){
        JLogDec(@"Video has not loaded yet!");
        return FALSE;
    }
    
    if (decodeAudioMode == FFDecodeAudioModeFFmpeg) {
        /**
         Fill ASBD for LPCM case (ref: FillOutASBDForLPCM inline function in CoreAudioTypes
         
         */
        UInt32 validBitPerChannel   = [FFMpegEngine bitsForSampleFormat: [_video audioCodecContext]->sample_fmt];
        UInt32 totalBitPerChannel   = validBitPerChannel;
        

        BOOL isFloat                = NO;
        BOOL isBigEndian            = NO;
        BOOL isNonInterleaved       = NO;
        
        UInt32 channelsPerFrame     = [_video audioCodecContext]->channels;
        Float64 sampleRate          = [_video audioCodecContext]->sample_rate;
        
        pASBD->mSampleRate       = sampleRate;
        pASBD->mFormatID         = kAudioFormatLinearPCM;
        
        pASBD->mFormatFlags      =
        (isFloat ? kAudioFormatFlagIsFloat : kAudioFormatFlagIsSignedInteger) |
        (isBigEndian ? ((UInt32)kAudioFormatFlagIsBigEndian) : 0) |
        ((!isFloat && (validBitPerChannel == totalBitPerChannel)) ? kAudioFormatFlagIsPacked : kAudioFormatFlagIsAlignedHigh)|
        (isNonInterleaved ? ((UInt32)kAudioFormatFlagIsNonInterleaved) : 0);
        
        pASBD->mBytesPerPacket   = (isNonInterleaved ? 1 : channelsPerFrame) * (totalBitPerChannel/8);
        pASBD->mFramesPerPacket  = 1;
        
        pASBD->mBytesPerFrame    = (isNonInterleaved ? 1 : channelsPerFrame) * (totalBitPerChannel/8);
        pASBD->mChannelsPerFrame = channelsPerFrame;
        pASBD->mBitsPerChannel   = validBitPerChannel;
        pASBD->mReserved         = 0;
        
    }else{ // decodeAudioMode == FFDecodeAudioNative
        
        pASBD->mSampleRate = [_video audioCodecContext]->sample_rate;
        pASBD->mFormatID = kAudioFormatMPEG4AAC;
        pASBD->mFormatFlags = kMPEG4Object_AAC_Main;
        
        // It's VBR, dont need to set these value
        pASBD->mBytesPerPacket = 0;
        pASBD->mFramesPerPacket = [_video audioCodecContext]->frame_size;
        
        
        pASBD->mBitsPerChannel = [FFMpegEngine bitsForSampleFormat: [_video audioCodecContext]->sample_fmt];
        pASBD->mChannelsPerFrame = [_video audioCodecContext]->channels;
        //pASBD->mBytesPerFrame = pASBD->mChannelsPerFrame * pASBD->mBitsPerChannel / 8;
        pASBD->mBytesPerFrame = 0;
        
    }
    
    return TRUE;
}

//----------------------------------------------------------------
/**
 In case of LCPM, p1 packet contain 1 frame so maximum packet size is size of 
 one frame. 
 */
// TODO: Need improvment
//  - Implement fillAudioStream for general case that includes iOS decoder (AAC, MP3).
//  - Check output from ffmpeg for interleave value
- (UInt32) maxAudioPacketSize
{
     if (decodeAudioMode == FFDecodeAudioModeFFmpeg) {
         UInt32 channelsPerFrame     = [_video audioCodecContext]->channels;
         BOOL isNonInterleaved       = NO;
         UInt32 totalBitPerChannel   = [FFMpegEngine bitsForSampleFormat: [_video audioCodecContext]->sample_fmt];
         
         return (isNonInterleaved ? 1 : channelsPerFrame) * (totalBitPerChannel/8);
     }else{
         return [_video audioCodecContext]->frame_size;
         //return 300;
     }
}

//----------------------------------------------------------------
/**
 Render audio buffer with output data from decoder
 @param aqBuffer the buffer that decode need to fill audio samples in
 @param pts the time reference, indicate what set of sample should be filled in
 */
// TODO: Implement for both ffmpeg-decoder and iOS decoder
//#define USE_AUDIO_THREAD
- (void) renderAudioBuffer:(AudioQueueBufferRef) aqBuffer
                    forPts:(NSTimeInterval)pts
{
    //JLog(@"Rendering AQ buffer");
    if (decodeAudioMode == FFDecodeAudioModeFFmpeg) {
        
/*
        // Generate sine noise sound for test
        double amplitude = 0.25 * 0x3FFF;
        for (int n = 0; n < aqBuffer->mAudioDataBytesCapacity; n+=2)
        {
            SInt16* pSample = (aqBuffer->mAudioData  + n);
            *pSample = (short)(amplitude * ((double)rand()/(double)(RAND_MAX - 1)));
        }
        aqBuffer->mAudioDataByteSize = aqBuffer->mAudioDataBytesCapacity;
//*/

#ifdef USE_AUDIO_THREAD
        NSTimeInterval bufferPts;
        int readBytes = [_audioBuffer popSampleTo:aqBuffer->mAudioData
                             size:aqBuffer->mAudioDataBytesCapacity
                           outPts:&bufferPts
                          blocked:YES];
        
        aqBuffer->mAudioDataByteSize = readBytes;
        JLogDec(@"Fill audio buffer");
#else
        [self fillPCMAudioIntoBuff:aqBuffer->mAudioData
                       capacity:aqBuffer->mAudioDataBytesCapacity];
        aqBuffer->mAudioDataByteSize = aqBuffer->mAudioDataBytesCapacity;
        
#endif
        
    }else{// decodeAudioMode == FFDecodeAudioNative
        // TODO: Implementation
        [self fillAudioPktToBuff: aqBuffer forPts: (NSTimeInterval) pts];
    }
}


- (int) sampleRate
{
    return [_video audioCodecContext]->sample_rate;
}


@end

//----------------------------------------------------------------
#pragma mark - FFDecoder's Video Properties
@implementation FFDecoder (VideoProperties)
@dynamic mediaSourceType;

- (int) mediaSourceType
{
    return 0;
}

- (void) setMediaSourceType:(int)mediaSourceType
{
    
}

- (double) currentPlaybackTime
{
    return  0;
}

- (float) currentPlaybackRate
{
    return  0;
}

- (int) mediaTypes
{
    return  0;
}

- (float) duration
{
    return  0;
}

- (float) playableDuration
{
    return  0;
}

// CGSizeZero if not known/applicable.
- (CGSize) videoSize
{
    return CGSizeMake(0, 0);
}

// return NaN indicates the natural start time
- (float) startTime
{
    return NAN;
}

// return NaN indicates the natural end time
- (float) endTime
{
    return NAN;
}


@end