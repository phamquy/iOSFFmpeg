//
//  ES2Renderer.m
//  FFmpegPlayTest
//
//  Created by Jack on 11/2/12.
//  Copyright (c) 2012 Jack. All rights reserved.
//

#import "ES2Renderer.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#define kGLShaderNameRGB @"rgb_render"
#define kGLShaderNameYUV @"yuv_render"

#define kGLShaderAttributePosition  @"position"
#define kGLShaderAttributeTexCoords @"texCoords"
#define kGLShaderUniformSampler0    @"sampler0"
#define kGLShaderUniformSampler1    @"sampler1"
#define kGLShaderUniformSampler2    @"sampler2"
#define kGLShaderUniformMvp         @"viewProjectionMatrix"

#pragma mark -
@implementation ES2Renderer

//------------------------------------------------------------------------------
- (id) init
{
    self = [super init];
    if (self) {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (!context || ![EAGLContext setCurrentContext:context]) {
            self = nil;
            return self;
        }
                

        

        glGenFramebuffers(1, &defaultFrameBuffer);
        glGenRenderbuffers(1, &colorRenderBuffer);
        
/*
        glGenRenderbuffers(1, &depthBuffer);
        
        glBindRenderbuffer(GL_RENDERBUFFER, depthBuffer);
        glRenderbufferStorage(GL_RENDERBUFFER,
                              GL_DEPTH_COMPONENT16,
                              backingWidth,
                              backingHeight);
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, 
                                  GL_DEPTH_ATTACHMENT, 
                                  GL_RENDERBUFFER,
                                  depthBuffer);
 */
        
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFrameBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, 
                                  GL_COLOR_ATTACHMENT0, 
                                  GL_RENDERBUFFER,
                                  colorRenderBuffer);
        
        /// We dont need to check framebuffer completeness here because we havent bind
        /// colorbUffer to backingStorage (an EADrawable obj) yet.
        NSLog(@"ES2Renderer created");
        
    }
    return self;
}


//------------------------------------------------------------------------------
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
    
    if(frameTextures) {
        glDeleteTextures(3, frameTextures);
    }
//    if(shader) {
//        [shader release];
//    }
    shader = nil;

    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    context = nil;
}

#pragma mark Utilities
- (NSString*) shaderNameOfPixelType: (int) pixelType
{
    
    /// [Jack] test direct render YUV
    return kGLShaderNameYUV;
//    return kGLShaderNameRGB;
    /// TODO: detect appropriate shader base on pixeltype
//    if ( /* it was rgb format*/) {
//        // return RGB
//    }
}

//------------------------------------------------------------------------------
- (BOOL) setupTextureRGBWidth: (int) texW height: (int) texH
{
    if (!shader) {
        shader = [[GLShader alloc] initWithFileName: kGLShaderNameRGB
                                         attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     [NSNumber numberWithInt:0], kGLShaderAttributePosition,
                                                     [NSNumber numberWithInt:1], kGLShaderAttributeTexCoords, nil]
                                           uniforms:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     [NSNumber numberWithInt:0], kGLShaderUniformSampler0,
                                                     [NSNumber numberWithInt:0], kGLShaderUniformMvp,nil]];
        
    }
    
    if (!shader) {
        return NO;
    }
    
    /// Create texture
    if(frameTextures[0])
        glDeleteTextures(1, &frameTextures[0]);
    
    glEnable(GL_TEXTURE_2D);
    glGenTextures(1, &frameTextures[0]);
    glBindTexture(GL_TEXTURE_2D, frameTextures[0]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
    
    // Create texture space, the videop pictures will be rendered as subtexture
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, texW, texH, 0, GL_RGB,
                 GL_UNSIGNED_SHORT_5_6_5, NULL);
    
    
    glUseProgram(shader.program);
    glUniformMatrix4fv([shader getUniform:kGLShaderUniformMvp], 1, FALSE, (GLfloat*)&mvp.m[0]);
    glUniform1i([shader getUniform:kGLShaderUniformSampler0], 0);
    
    glVertexAttribPointer([shader getAttribute:kGLShaderAttributePosition], 2, GL_FLOAT, 0, 0, verts);
    glEnableVertexAttribArray([shader getAttribute:kGLShaderAttributePosition]);
    
    glVertexAttribPointer([shader getAttribute:kGLShaderAttributeTexCoords], 2, GL_FLOAT, 0, 0, texCoords);
    glEnableVertexAttribArray([shader getAttribute:kGLShaderAttributeTexCoords]);
    return YES;

}
//------------------------------------------------------------------------------
- (void) renderRGBPicture: (FFVideoPicture*) picture
{
    glPixelStorei(GL_UNPACK_ALIGNMENT, 2);
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, frameTextures[0]);
    // OpenGL loads textures lazily so accessing the buffer is deferred until
    // draw; notify the movie player that we're done with the texture after glDrawArrays.
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0,
                    mFrameW, mFrameH,
                    GL_RGB,
                    [_videoSource pixelFormat],
                    [picture pdata]);

}

//------------------------------------------------------------------------------
- (BOOL) setupTextureYUVWidth: (int) texW height: (int) texH
{
    if (!shader) {
        shader = [[GLShader alloc] initWithFileName: kGLShaderNameYUV
                                         attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     [NSNumber numberWithInt:0], kGLShaderAttributePosition,
                                                     [NSNumber numberWithInt:1], kGLShaderAttributeTexCoords, nil]
                                           uniforms:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     [NSNumber numberWithInt:0], kGLShaderUniformSampler0,
                                                     [NSNumber numberWithInt:0], kGLShaderUniformSampler1,
                                                     [NSNumber numberWithInt:0], kGLShaderUniformSampler2,
                                                     [NSNumber numberWithInt:0], kGLShaderUniformMvp,nil]];
    }
    
    
    NSUInteger widths[3] = {texW, texW/2, texW/2};
    NSUInteger heights[3] = {texH, texH/2, texH/2};
    
    for (int i=0; i < 3; ++i) {
        if (frameTextures[i]) glDeleteTextures(1, &frameTextures[i]);
        glGenTextures(1, &frameTextures[i]);
        glBindTexture(GL_TEXTURE_2D, frameTextures[i]);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        // This is necessary for non-power-of-two textures
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_LUMINANCE,
                     widths[i],
                     heights[i],
                     0,
                     GL_LUMINANCE,
                     GL_UNSIGNED_BYTE,
                     NULL);
        
    }
    
    glUseProgram(shader.program);
    glUniformMatrix4fv([shader getUniform:kGLShaderUniformMvp], 1, FALSE, (GLfloat*)&mvp.m[0]);
    glUniform1i([shader getUniform:kGLShaderUniformSampler0], 0);
    glUniform1i([shader getUniform:kGLShaderUniformSampler1], 1);
    glUniform1i([shader getUniform:kGLShaderUniformSampler2], 2);
    
    glVertexAttribPointer([shader getAttribute:kGLShaderAttributePosition], 2, GL_FLOAT, 0, 0, verts);
    glEnableVertexAttribArray([shader getAttribute:kGLShaderAttributePosition]);

    glVertexAttribPointer([shader getAttribute:kGLShaderAttributeTexCoords], 2, GL_FLOAT, 0, 0, texCoords);
    glEnableVertexAttribArray([shader getAttribute:kGLShaderAttributeTexCoords]);
    
    
    return TRUE;
}

//------------------------------------------------------------------------------
- (void) renderYUVPicture: (FFVideoPicture*) picture
{
    // Y data
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D,frameTextures[0]);
    glTexSubImage2D(
                    GL_TEXTURE_2D,
                    0,
                    0,
                    0,
                    mFrameW,            // source width
                    mFrameH,            // source height
                    GL_LUMINANCE,
                    GL_UNSIGNED_BYTE,
                    [picture yData]);

    
    // U data
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, frameTextures[1]);
    glTexSubImage2D(
                    GL_TEXTURE_2D,
                    0,
                    0,
                    0,
                    mFrameW / 2,            // source width
                    mFrameH / 2,            // source height
                    GL_LUMINANCE,
                    GL_UNSIGNED_BYTE,
                    [picture uData]);
    
    // V data
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, frameTextures[2]);
    glTexSubImage2D(
                    GL_TEXTURE_2D,
                    0,
                    0,
                    0,
                    mFrameW / 2,            // source width
                    mFrameH / 2,            // source height
                    GL_LUMINANCE,
                    GL_UNSIGNED_BYTE,
                    [picture vData]);
    

}

//------------------------------------------------------------------------------
//- (BOOL) resizeRenderOutput:(id<EAGLDrawable>) layer
//{
//    // Allocate color buffer backing based on the current layer size
//    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
//    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
//    
//    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
//    {
//        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
//        return FALSE;
//    }
//    return YES;
//}

//------------------------------------------------------------------------------
#pragma mark FFRenderer Protocol
@synthesize delegate = _delegate;
@synthesize videoScreen = _videoScreen;
@synthesize videoSource = _videoSource;

#ifndef next_powerof2
#define next_powerof2(x) \
x--;\
x |= x >> 1;\
x |= x >> 2;\
x |= x >> 4;\
x |= x >> 8;\
x |= x >> 16;\
x++;
#endif // !next_powerof2

- (BOOL) prepareTexture
{
    
    if (!_videoSource || !_videoScreen) {
        return FALSE;
    }
    
    
    // Make videoScreen as output
    /// [Jack] This part should be separated from prepareTexture method because we dont need
    /// to re-bind output if only video source changes.
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:[_videoScreen viewPort]];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return FALSE;
    }

    /// TODO: validate video source frame size and video screen frame size
    /// before any calculation (prevent devide-by-zero)
    
    /// TODO: take scaling mode into account for texture calculation
    
    int scalingMode = [_videoScreen scalingMode];
    int pixelType = [_videoSource pixelFormat];
    
    
    int texW, texH, frameW, frameH;
    texW = [_videoSource videoFrameSize].width;
    texH = [_videoSource videoFrameSize].height;
    frameW = texW;
    frameH = texH;

    // Adjust size for texture to be "Power Of Two"
    next_powerof2(texH);
    next_powerof2(texW);
    
    float videoAspect = (float) frameW / (float) frameH;
    float backHeight = backingHeight;
    float backWidth = backingWidth;
    float screenAspect = backWidth / backHeight;
    
    float minX=-1.f, minY=-1.f, maxX=1.f, maxY=1.f;
    float scale;
    
    //This calculate the scaling for AspectFit
    
    if(videoAspect >= screenAspect)
    {
        // Aspect ratio will retain width.
        scale = (float)backWidth / (float) frameW;
        maxY = ((float)frameH * scale) / (float) backHeight ;
        minY = -maxY;
    }
    else
    {
        // Retain height.
        scale = (float) backHeight / (float) frameW;
        maxX = ((float) frameW * scale) / (float) backWidth;
        minX = -maxX;
    }
    
   
    verts[0] = minX;
    verts[1] = minY;
    
    verts[2] = maxX;
    verts[3] = minY;
    
    verts[4] = minX;
    verts[5] = maxY;
    
    verts[6] = maxX;
    verts[7] = maxY;
    
    float s = (float) frameW / (float) texW;
    float t = (float) frameH / (float) texH;
    
    texCoords[0] = s;
    texCoords[1] = 0.f;
    
    texCoords[2] = 0.f;
    texCoords[3] = 0.f;
    
    texCoords[4] = s;
    texCoords[5] = t;
    
    texCoords[6] = 0;
    texCoords[7] = t;
    
    mFrameH = frameH;
    mFrameW = frameW;
    mTexH = texH;
    mTexW = texW;
    maxS = s;
    maxT = t;

    matSetPerspective(&proj, -1, 1, 1,-1, -1, 1);
    // Just supporting one rotation direction, landscape left.  Rotate Z by 90 degrees.
    //    matSetRotZ(&rot,M_PI_2);
    matSetRotZ(&rot,M_PI);
    
	matMul(&mvp, &rot, &proj);
    
    NSString* shaderName = [self shaderNameOfPixelType:pixelType];
    if ([shaderName isEqualToString:kGLShaderNameRGB]) {
        [self setupTextureRGBWidth:texW height:texH];
    }else{
        [self setupTextureYUVWidth:texW height:texH];
    }

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }

    return YES;
}
//------------------------------------------------------------------------------
- (BOOL) prepareTextureForVideoForSource: (id<FFVideoScreenSource>) videoSource
                                  screen: (id<FFVideoScreen>)viewScreen
{
    [self setVideoSource:videoSource];
    [self setVideoScreen:viewScreen];
    return [self prepareTexture];
}

//------------------------------------------------------------------------------
- (void) render:(FFVideoPicture *)picture
{
    // TODO: need to check if render is correctly settup
    [EAGLContext setCurrentContext:context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFrameBuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    glClearColor(0.3f, 0.2f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    if ([[self shaderNameOfPixelType:[_videoSource pixelFormat]] isEqualToString:kGLShaderNameYUV]) {
        [self renderYUVPicture: (FFVideoPicture*) picture];
    }else {
        [self renderRGBPicture: (FFVideoPicture*) picture];
    }
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  
    if ([_delegate respondsToSelector:@selector(finishFrameByRenderer:)]) {
        [_delegate finishFrameByRenderer:self];
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}
@end