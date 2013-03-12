//
//  FFTimingProtocols.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/5/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FFClock <NSObject>
@required
/**
 It the time return by CACurrentMediaTime at the moment clock start
 */
@property (nonatomic, readonly) NSTimeInterval startTime;

/**
 return time last since the start time, return 0 if clock is not running
 */
@property (nonatomic, readonly) NSTimeInterval currentTimeSinceStart;

@optional
- (void) startClock;
- (void) resetClock;

@end


