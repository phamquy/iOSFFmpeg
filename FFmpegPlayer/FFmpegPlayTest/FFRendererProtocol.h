//
//  FFRendererProtocol.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/5/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGLDrawable.h>
#import "FFVideoScreen.h"
enum {
    kFFRendererRotate0,
    kFFRendererRotate90,
    kFFRendererRotate180,
    kFFRendererRotate270,
    kFFRendererRotateDefault = kFFRendererRotate0
};
typedef NSInteger FFRendererRotate;

enum {
    kFFRendererScaleModeNon,
    kFFRendererScaleModeScale,
    kFFRendererScaleModeAspectFit,
    kFFRendererScaleModeAspectFill,
    kFFRendererScaleModeDefault = kFFRendererScaleModeAspectFit
};
typedef NSInteger FFRendererScaleMode;

//-----------------------------------------------------------------------------
@protocol FFRenderer;
#pragma mark - FFRendererDelegate
@protocol FFRendererDelegate <NSObject>
@required
- (void) finishFrameByRenderer: (id<FFRenderer>) renderer;
@optional
@end

//-----------------------------------------------------------------------------
#pragma mark - FFRenderer Protocol
@protocol FFRenderer <NSObject>
@required
@property (nonatomic, weak) id<FFRendererDelegate> delegate;
@property (nonatomic, weak) id<FFVideoScreen> videoScreen;
@property (nonatomic, weak) id<FFVideoScreenSource> videoSource;
- (void) render: (FFVideoPicture*) picture;
- (BOOL) prepareTexture;
- (BOOL) prepareTextureForVideoForSource: (id<FFVideoScreenSource>) videoSource
                                  screen: (id<FFVideoScreen>) viewScreen;

@optional
// ....
@end
