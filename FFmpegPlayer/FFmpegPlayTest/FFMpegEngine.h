//
//  FFMpegEngine.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/14/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FFMpegEngine : NSObject
+ (FFMpegEngine*) shareInstance;
+ (UInt32) bitsForSampleFormat: (int) sampleFormat;
//+ (UInt32) AQFormatFlagFor
- (void) initFFmpegEngine;
- (BOOL) isInitialized;
@end
