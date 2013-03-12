//
//  FFPEAGLView.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/1/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "FFControllable.h"
#import "FFTimingProtocols.h"
#import "FFPictureQueue.h"
//enum {
//    kFFScreenStateON,
//    kFFVideoScreenStateOFF,
//    kFFVideoScreenStateLinked,
//    kFFVideoScreenStateUnlinked
//};
enum {
    kFFScreenStateUnknown,   //= 0,
    kFFScreenStateStopped,   //= 1 << 0,
    kFFScreenStateRunning,   //= 1 << 2,
    kFFScreenStatePaused     //= 1 << 3
};
typedef NSInteger FFVideoScreenState;

@class FFVideoScreen;
@protocol FFVideoScreenDelegate <NSObject>
- (void) screenWillShow: (FFVideoScreen*) screen;
- (void) screenDidShow:(FFVideoScreen*) screen;
@end


@class FFVideoScreen;
//---------------------------------------------------------------------
/**
 This protocol define interface a class should comply to feed video to 
 FFVideoScreen object
 */
@protocol FFVideoScreenSource <NSObject>
@required
- (CGSize) videoFrameSize;
- (int) pixelFormat;
- (FFVideoPicture*) getPictureForScreen: (FFVideoScreen*) screen
                            screenClock: (NSTimeInterval) scrPts;
- (void) finishFrameForScreen: (FFVideoScreen*) screen;
@optional
@end
#pragma mark -
//---------------------------------------------------------------------
@protocol FFVideoScreen <NSObject>
@required
- (id<EAGLDrawable>) viewPort;
- (NSInteger) scalingMode;
@end

#pragma mark - FFVideoScreen 
/**
 FFVideo public interface
 */
@interface FFVideoScreen : UIView <FFControllable, FFVideoScreen, FFClock>
@property (nonatomic)           NSInteger frameInterval;      // default 1
@property (nonatomic, readonly) FFVideoScreenState state;
@property (nonatomic, readonly) BOOL supportDisplayLink;
@property (nonatomic, weak)     id<FFVideoScreenSource> source;
@property (nonatomic)   NSInteger scalingMode;
@property (nonatomic, weak) id<FFVideoScreenDelegate> delegate;

- (id) initWithSource: (id<FFVideoScreenSource>) source
             delegate: (id<FFVideoScreenDelegate>) delegate;
- (id) initWithSource: (id<FFVideoScreenSource>) source
             delegate: (id<FFVideoScreenDelegate>) delegate
          scalingMode: (NSInteger) scalingMode;

@end
