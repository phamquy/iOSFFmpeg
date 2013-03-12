//
//  FFES1Renderer.m
//  FFmpegPlayTest
//
//  Created by Jack on 11/2/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import "ES1Renderer.h"
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
@implementation ES1Renderer 

- (id) init
{
    self = [super init];
    if (self) {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!context || ![EAGLContext setCurrentContext:context]) {
            return nil;
        }
        
        NSLog(@"ES1Renderer created");
        
        glGenFramebuffersOES(1, &defaultFrameBuffer);
        glGenRenderbuffersOES(1, &colorRenderBuffer);
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFrameBuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderBuffer);
        
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES,
                                     GL_COLOR_ATTACHMENT0_OES,
                                     GL_RENDERBUFFER_OES,
                                     colorRenderBuffer);
    }
    return self;
}

- (void) dealloc
{
    if (defaultFrameBuffer) {
        glDeleteFramebuffers(1, &defaultFrameBuffer);
        defaultFrameBuffer = 0;
    }
    
    if (colorRenderBuffer) {
        glDeleteRenderbuffers(1, &colorRenderBuffer);
        colorRenderBuffer = 0;
    }
    
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
    context = nil;
    
    if (agVert){
        free(agVert);
    }
    
    if (agCoord) {
        free(agCoord);
    }
}

#pragma mark FFRenderer Protocol

@synthesize delegate = _delegate;
@synthesize videoScreen = _videoScreen;
@synthesize videoSource = _videoSource;

- (void) render: (FFVideoPicture*) picture
{
    
}

- (BOOL) prepareTextureForVideoFrameSize:(CGSize) frameSize
                                 scaling:(FFRendererScaleMode)scaleMode
{
    return NO;
}

@end
