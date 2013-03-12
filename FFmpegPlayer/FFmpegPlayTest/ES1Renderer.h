//
//  FFES1Renderer.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/2/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRendererProtocol.h"


@interface ES1Renderer : NSObject <FFRenderer>
{
@private
    
    EAGLContext* context;
    GLint backingWidth;
    GLint backingHeight;
    
    GLuint defaultFrameBuffer;
    GLuint colorRenderBuffer;
    GLuint frameTexture;
    
    GLuint mTexW, mTexH, mFrameW, mFrameH;
    
    GLfloat *agVert, *agCoord;
    GLuint agCount;
}
@end
