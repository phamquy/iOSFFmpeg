//
//  FFRendererFactory.m
//  FFmpegPlayTest
//
//  Created by Jack on 11/6/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import "FFRendererFactory.h"
#import "ES1Renderer.h"
#import "ES2Renderer.h"


@implementation FFRendererFactory


//------------------------------------------------------------------------------
+ (id<FFRenderer>) createRenderer
{
    id<FFRenderer> renderer = nil;
    renderer = [[ES2Renderer alloc] init];
    
    if (!renderer) {
        renderer = [[ES1Renderer alloc] init];
    }
    
    return renderer;
}

//------------------------------------------------------------------------------
+ (id<FFRenderer>) createRendererWithDelegate:(id<FFRendererDelegate>)delegate
{
    id<FFRenderer> renderer = [FFRendererFactory createRenderer];
    [renderer setDelegate:delegate];
    
    return renderer;
}

//------------------------------------------------------------------------------
+ (id<FFRenderer>) createRendererWithDelegate: (id<FFRendererDelegate>)delegate
                                  videoSource: (id<FFVideoScreenSource>) source
                                       screen: (id<FFVideoScreen>) screen
{
    id<FFRenderer> renderer = [FFRendererFactory createRendererWithDelegate:delegate];
    [renderer setVideoScreen:screen];
    [renderer setVideoSource:source];
    return renderer;
}

@end
