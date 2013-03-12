//
//  FFPictureQueue.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/13/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFmpeg.h"
#import "FFVideoPicture.h"
//typedef struct {
//    uint8_t*    pictData;
//    int         width;
//    int         height;
//    double      pts;
//} FFVideoPicture;



// TODO: Done use fixed size for picture queue
#define kFFVideoPictureQueueSize 4
@interface FFPictureQueue : NSObject
{
@private
    int _capacity;
    int _size;
    FFVideoPicture* pictures[kFFVideoPictureQueueSize];
    int _readIndex;
    int _writeIndex;
    NSCondition* _condition;
}

//@property (nonatomic, readonly) int capacity;
@property (nonatomic, readonly) int size;

//- (int) popPicture: (FFVideoPicture*) outPicture
//             block: (BOOL) blocked;

/**
 Pop a picture from the queue
 @param blocked if yes, block the thread and wait until a picture is read
 @return a picture pointer, return nil if there is no picture to read.
 */
- (FFVideoPicture*) popPictureWithBlockingMode: (BOOL) blocked;

//- (int) pushPicture: (FFVideoPicture*) inPicture
//             block: (BOOL) block;


/**
 Push a picture to the queue
 @param blocked if yes, block the thread and wait until picture is pushed inn
 to the queue
 
 @return Yes: picture is push, No: picture is not pushed
 */
- (BOOL) pushPicture: (FFVideoPicture*) inPicture
        blockingMode: (BOOL) blocked;

- (void) flush;

/**
 return pointer to the picture at writeIndex
 */
- (FFVideoPicture* const) pictureToWriteWithBlock: (BOOL) blocked;

/**
 return pointer to the picture at readIndex
 */
- (const FFVideoPicture* const) pictureToReadWithBlock: (BOOL) blocked;

@end
