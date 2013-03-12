//
//  FFMpegEngine.m
//  FFmpegPlayTest
//
//  Created by Jack on 11/14/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import "FFMpegEngine.h"
#import "FFmpeg.h"

@interface FFMpegEngine ()
{
    BOOL _initialized;
}
@end
@implementation FFMpegEngine

static FFMpegEngine* _shareInstance = nil;

+ (FFMpegEngine*) shareInstance
{
    @synchronized([FFMpegEngine class])
    {
        if (!_shareInstance) {
            _shareInstance = [[FFMpegEngine alloc] init];
        }
        
        return _shareInstance;
    }
    return nil;
}

#pragma mark - Class Level Methods
+ (UInt32) bitsForSampleFormat: (int) sampleFormat
{
    switch (sampleFormat) {
        case AV_SAMPLE_FMT_U8:
        case AV_SAMPLE_FMT_U8P:
            return 8;
            break;
        case AV_SAMPLE_FMT_S16:
        case AV_SAMPLE_FMT_S16P:
            return 16;
            break;
        case AV_SAMPLE_FMT_S32:
        case AV_SAMPLE_FMT_S32P:
            return 32;
            break;
        case AV_SAMPLE_FMT_FLT:
        case AV_SAMPLE_FMT_FLTP:
            return sizeof(float);
            break;
        case AV_SAMPLE_FMT_DBL:
        case AV_SAMPLE_FMT_DBLP:
            return sizeof(double);
        default:
            break;
    }
    
    return 0;
};



- (id) init
{
    self = [super init];
    if (self) {
        _initialized = NO;
    }
    return self;
}

- (void) initFFmpegEngine
{
    if (!_initialized) {
        av_register_all();
        avcodec_register_all();
        _initialized = YES;
    }
}

- (BOOL) isInitialized
{
    return _initialized;
}
@end
