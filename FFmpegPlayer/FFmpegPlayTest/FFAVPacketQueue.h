//
//  FFAVPacketQueue.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/12/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//
/*
 TODO: Implement queue as fixed size queue
 in current version, the size of queue is automatically increase if the writing
 process is faster than reading process. It may cause the increasement of memory
 usage if there is a problem that blocks reading thread.
 
 To implement fixed size queue,  there should be condition wait inside putPacket
 method waiting for a signal from reading process.
 */

#import <Foundation/Foundation.h>
#import "FFmpeg.h"


@interface FFAVPacketQueue : NSObject
{
    
@private
    AVPacketList *_firstPacket;
    AVPacketList *_lastPacket;
    int _count;
    
    /**
     Total size of all the packets' data
     */
    int _dataSize;
    
    /**
     Maximum dataSize
     */
    int _maxDataSize;
    
    /**
     Maximum of total size of all packets' data,
     when _dataSize > _queueSize, writing to queue should
     be disabled.
     */
    int _queueSize;
    
    
    // Thread-safe
    //pthread_mutex_t mutex;
    //pthread_cond_t  condition;
    NSCondition*   _condition;
}

@property (nonatomic, readonly) NSInteger count;
@property (nonatomic, readonly) NSInteger dataSize;
@property (nonatomic) NSInteger queueSize;

- (id) initWithSize: (NSInteger) size;
/**
 Get packet from queue thread-safely
 outPacket: output packet
 block    : should block the process to wait until there is packet available.
 */
- (int) popPacket: (AVPacket*) outPacket
          blocked: (BOOL) blocked;
/**
 Get packet from queue thread-safely
 inPacket : input packet
 block    : should block the process to wait until there is space for new packet.
 */
- (int) pushPacket: (AVPacket*) inPacket
          blocked:(BOOL) blocked;

/**
 Flush all the packets in the queue.
 */
- (void) flush;

@end
