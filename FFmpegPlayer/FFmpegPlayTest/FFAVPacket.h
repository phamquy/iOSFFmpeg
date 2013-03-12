//
//  FFAVPacket.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/13/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFmpeg.h"
@interface FFAVPacket : NSObject
/**
 @file FFACPacket.h
 This is wrapper class for FFmpeg AVPacket struct
 */

/**
 Init packet with a AVPacket and create a deep copy of input
 packet.
 @param packet The input packet
 */
- (id) initWithAVPacket: (AVPacket*) packet;

/**
 Init packet with a AVPacket with out copying the packet.
 @param packet The input packet
 */
- (id) initWithAVPacketNoCopy:(AVPacket *)packet;
@end
