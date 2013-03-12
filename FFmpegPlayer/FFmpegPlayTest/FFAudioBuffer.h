//
//  FFAudioBuffer.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/27/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FFAudioBuffer : NSObject

/**
 Number of samples in buffer, return 0 if invalid
 */
@property (nonatomic, readonly) NSUInteger sampleCount;

/**
 Duration in seconds, return 0 if invalid
 */
@property (nonatomic, readonly) NSTimeInterval duration;

/**
 Size in bytes of stored samples
 */
@property (nonatomic, readonly) NSUInteger  dataByteSize;

/**
 Capacity of buffer in bytes
 */
@property (nonatomic, readonly) NSUInteger dataByteCapacity;

/**
 pts of first sample (sample at read idx)
 */
@property (nonatomic, readonly) NSTimeInterval currentPts;

- (id) initBufferForDuration: (float) duration //second
              bytesPerSample: (int) bytesPerSample
                  sampleRate: (int) sampleRate;
/**
 Push audio samples in to audio buffer
 
 @param pPushData pointer to buffer that contain data to be pushed
 @param pushSize size of buffer pointed by pPushData
 @param blocked bloking mode
 
 @return return number of bytes have been pushed 
 
 @note if blocked set TRUE, the functino will try to push all the 
 samples by blocking thread and wait until there is space avaiable.
 If blocked set to FALSE, the method will push until buffer full, 
 no blocking wait.
 */
- (int) pushSample: (void*) pPushData
               size: (UInt32) pushSize
            blocked: (BOOL) blocked;


/**
 pop audio samples in to audio buffer
 
 @param pPopData pointer to buffer that contain popped data
 @param popSize size of buffer pointed by pPopData
 @param blocked bloking mode
 
 @return return number of bytes have been popped
 
 @note if blocked set TRUE, the function will try to fully fill
 pPopData by blocking thread and wait until it fullly filled.
 If blocked set to FALSE, the method will fill pPopData util there
 no more samples.
 */

- (int) popSampleTo: (void*) pPopData
               size: (UInt32) popSize
             outPts: (NSTimeInterval*) outPts
            blocked: (BOOL) blocked;

/**
 pop audio samples in to audio buffer. It will read buffer from
 position of given *pts*, and it will read a mount of samples that
 make up *duration*. A mount of sample still limite by *popSize*
 if popped samples dont fully fill *pPopData* the rest of it will
 be set to 0.
 
 @param pPopData pointer to buffer that contain popped data
 @param popSize size of buffer pointed by pPopData
 @param blocked bloking mode
 
 @return return number of bytes have been popped
 
 @note *blocked* still work the same way as previous methods. Only 
 different in BLOCKED mode is that function will atempt to fill 
 *pPopData* until it full or enough for the *duration*, depend on 
 what come first.
 */

- (int) popSampleTo:(void *)pPopData
               size:(UInt32)popSize
              atPts:(NSTimeInterval)inPts
           duration:(float)duration
            blocked:(BOOL)blocked;

- (BOOL) isFull;

@end
