//
//  FFAVPacket.m
//  FFmpegPlayTest
//
//  Created by Jack on 11/13/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import "FFAVPacket.h"

@interface FFAVPacket ()
{
    AVPacket* _avPacket;
}
@end
@implementation FFAVPacket


#pragma mark Class Construction
- (id) init
{
    self = [super init];
    if (self)
    {
        _avPacket = nil;
    }
    return self;
}


- (id) initWithAVPacketNoCopy: (AVPacket*) packet
{
    self = [super init];
    if (self)
    {
        _avPacket = packet;
        // the hack, to make packet allocate correctly
        if (av_dup_packet(_avPacket)  < 0) {
            return nil;
        }
    }
    return self;
}


- (id) initWithAVPacket:(AVPacket *)packet
{
    self = [super init];
    if (self) {
        _avPacket = (AVPacket*) av_malloc(sizeof(AVPacket));
        av_init_packet(_avPacket);
        if (av_copy_packet(_avPacket, packet) < 0){
            free(_avPacket);
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
    if (_avPacket) {
        // Free packet held data
        av_free_packet(_avPacket);
        // Free packet itself
        av_free(_avPacket);
        _avPacket = nil;
    }
}
@end
