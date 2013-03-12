//
//  ES2Renderer.h
//  FFmpegPlayTest
//
//  Created by Jack on 11/2/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRendererProtocol.h"
#import "Matrix4x4.h"
#import "GLShader.h"

@interface ES2Renderer : NSObject <FFRenderer>
{
@private
    EAGLContext* context;
    GLint backingWidth;
    GLint backingHeight;
    
    GLuint defaultFrameBuffer;
    GLuint colorRenderBuffer;
    GLuint frameTextures[3];
    
    
    GLuint mTexW, mTexH, mFrameW, mFrameH;
    
    
    GLuint depthBuffer;
    GLfloat maxS, maxT;
    
    GLuint sampler0;
    
    GLfloat verts[8];
    GLfloat texCoords[8];
    
    Matrix4x4 proj, rot, mvp;
    GLShader *shader;
    
    GLuint program;
}
@end
