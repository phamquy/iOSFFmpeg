//
//  FFVideo.m
//  FFmpegPlayTest
//
//  Created by Jack on 11/12/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import "FFVideo.h"
#import "FFMpegEngine.h"

#ifdef DEBUG_VFILE
#define JLogVFile JLog
#else
#define JLogVFile(...)
#endif

#pragma mark - FFVideo Extension
@interface FFVideo ()
{
    AVIOInterruptCB interuptCB;
}
@end


#pragma mark - FFVideo Implementation
@implementation FFVideo
@synthesize status=_status;
@synthesize videoStreamIndex=_videoStreamIndex;
@synthesize audioStreamIndex=_audioStreamIndex;
#pragma mark  Init and dealloc
//---------------------------------------------------------------------
- (id) initWithUrl: (NSURL *)url
  interuptCallback: (AVIOInterruptCB) callback
{
    self = [self initWithUrl:url];
    if (self) {
        interuptCB = callback;
        [self openVideoWithCallback:callback];
    }
    return self;
}
//---------------------------------------------------------------------
- (id) initWithUrl: (NSURL*) url
{
    self = [super init];
    if (self) {
        /// Using path for local file
        _fileUrl = [url path];
        _formatContext = nil;
        _videoStreamIndex = -1;
        _audioStreamIndex = -1;
        _videoStream = nil;
        _audioStream = nil;
    }
    return self;
}

- (void) dealloc
{
    if (_formatContext) {
        avcodec_close(_videoCodecCtx);
        avcodec_close(_audioCodecCtx);
        avformat_close_input(&_formatContext);
    }
}

#pragma mark Utilites methods
//---------------------------------------------------------------------
- (void) close
{
    if (_formatContext)
    {
        if (_videoCodecCtx) {
            avcodec_close(_videoCodecCtx);
            _videoCodecCtx  = NULL;
        }
        
        if (_audioCodecCtx) {
            avcodec_close(_audioCodecCtx);
            _audioCodecCtx = NULL;
        }
        avformat_close_input(&_formatContext);
    }
    _formatContext = NULL;
    _videoStreamIndex = -1;
    _audioStreamIndex = -1;
    _videoStream = NULL;
    _audioStream = NULL;
}
//---------------------------------------------------------------------
- (BOOL) openVideoStream
{
    JLogVFile(@"Opening video stream");
    BOOL ret = YES;
    AVCodecContext* codecContext = nil;
    AVCodec* codec = nil;
    if (_videoStreamIndex < 0 || _videoStreamIndex >= _formatContext->nb_streams)
    {
        return NO;
    }
    codecContext = _formatContext->streams[_videoStreamIndex]->codec;
    codec = avcodec_find_decoder(codecContext->codec_id);
    if (!codec || (avcodec_open2(codecContext, codec, NULL) < 0)) {
        JLogVFile(@"Unsupported codec!");
        return NO;
    }
    _videoCodecCtx = codecContext;
    _videoStream = _formatContext->streams[_videoStreamIndex];
    
    //TODO: Need to wired up custom frame buffer allocation and release
    
    return ret;
}

//---------------------------------------------------------------------
- (BOOL) openAudioStream
{
    JLogVFile(@"Opening audio stream");
    BOOL ret = YES;
    AVCodecContext* codecContext = nil;
    AVCodec* codec = nil;
    if (_audioStreamIndex < 0 || _audioStreamIndex >= _formatContext->nb_streams)
    {
        return NO;
    }
    codecContext = _formatContext->streams[_audioStreamIndex]->codec;
    codec = avcodec_find_decoder(codecContext->codec_id);
    if (!codec || (avcodec_open2(codecContext, codec, NULL) < 0)) {
        JLogVFile(@"Unsupported codec!");
        return NO;
    }
    _audioCodecCtx = codecContext;
    _audioStream = _formatContext->streams[_audioStreamIndex];
    
    //TODO: Need to wired up custom frame buffer allocation and release
    
    return ret;
}

//---------------------------------------------------------------------
- (BOOL) openVideoWithCallback: (AVIOInterruptCB) interuptCallback;
{
    JLogVFile(@"Opening video: %@", _fileUrl);
    
    if (![[FFMpegEngine shareInstance] isInitialized]) {
        [[FFMpegEngine shareInstance] initFFmpegEngine];
    }
    
    interuptCB = interuptCallback;
    
    BOOL ret = YES;
    _formatContext = avformat_alloc_context();
    _formatContext->interrupt_callback = interuptCB;
    
    
    // Init I/O Context
    if (avio_open2(&_formatContext->pb,
                   [_fileUrl UTF8String],
                   AVIO_FLAG_READ,
                   &_formatContext->interrupt_callback,
                   NULL)) {
        JLogVFile(@"Couldnt init IO context.");
        ret = NO;
        goto doneOpen;
    }
    
    
    // Open video file
    if (avformat_open_input(&_formatContext,
                            [_fileUrl UTF8String],
                            NULL,
                            NULL)) {
        JLogVFile(@"Couldnt open input file");
        ret = NO;
        goto doneOpen;
    }
    
    //NSLog(@"File media info:\n----------------");
    //av_dump_format(_formatContext, 0, [_fileUrl UTF8String], 0);
    
    if (avformat_find_stream_info(_formatContext, NULL) < 0) {
        JLogVFile(@"Couldn't find stream info in input file");
        ret = NO;
        goto doneOpen;
    }
        
    NSLog(@"File media info:\n----------------");
    av_dump_format(_formatContext, 0, [_fileUrl UTF8String], 0);
    
    
    //Find video stream
    for (int i = 0; i < _formatContext->nb_streams; i++) {
        if (_formatContext->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO
            && _videoStreamIndex < 0)
        {
            _videoStreamIndex = i;
        }

        if (_formatContext->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO
            && _audioStreamIndex < 0)
        {
            _audioStreamIndex = i;
        }
    }
    
    if (_videoStreamIndex >= 0) {
        if (![self openVideoStream]) {
            JLogVFile(@"Couldn't open video stream");
            ret = NO;
            goto doneOpen;
        }
    }
    
    if (_audioStreamIndex >= 0) {
        if (![self openAudioStream]) {
            JLogVFile(@"Couldn't open audio stream");
            ret = NO;
            goto doneOpen;
        }
    }
    
doneOpen:
    if(!ret){
        [self close];
    }
    
    return ret;
}

//--------------------------------------------------------------------
- ( AVCodecContext  * const) audioCodecContext
{
    return _audioCodecCtx;
}
//--------------------------------------------------------------------
- ( AVCodecContext  * const) videoCodecContext
{
    return _videoCodecCtx;
}
//--------------------------------------------------------------------
- ( AVFormatContext * const) formatContext
{
    return _formatContext;
}
//--------------------------------------------------------------------
- ( AVStream  * const) audioStream
{
    return _audioStream;
}
//--------------------------------------------------------------------
- ( AVStream  * const) videoStream
{
    return _videoStream;
}


@end
