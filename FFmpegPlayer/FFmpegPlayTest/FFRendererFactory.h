//
//  FFRendererFactory.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/6/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRendererProtocol.h"
#import <QuartzCore/CAEAGLLayer.h>
#import <OpenGLES/EAGLDrawable.h>
#import "FFVideoScreen.h"

@interface FFRendererFactory : NSObject
+ (id<FFRenderer>) createRenderer;

+ (id<FFRenderer>) createRendererWithDelegate: (id<FFRendererDelegate>) delegate;

+ (id<FFRenderer>) createRendererWithDelegate: (id<FFRendererDelegate>)delegate
                                  videoSource: (id<FFVideoScreenSource>) source
                                       screen: (id<FFVideoScreen>) screen;
@end
