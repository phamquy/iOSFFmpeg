//
//  FFControllable.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/7/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FFControllable <NSObject>

- (void) pause;
- (void) start;
- (void) stop;
- (void) resume;
- (BOOL) isReady;
- (BOOL) isRuning;

@end
