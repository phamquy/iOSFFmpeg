/*
 *  GLShader.h/.m - Manages a shader program.
 *  jamesghurley<at>gmail.com
 */
#import "GLShader.h"

@interface GLShader (Private)
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
- (BOOL)loadShaders: (NSString*) shaderFileName;
@end

@implementation GLShader
@synthesize program;
//---------------------------------------------------------------------------
-(GLuint) getUniform: (NSString*) uniformName{
    NSNumber * val = [uniforms objectForKey:uniformName];
    if(val != nil){
         
        return (GLuint) [val unsignedIntValue];
    }
    return -1;
}
//---------------------------------------------------------------------------
-(GLuint) getAttribute: (NSString*) attributeName{
    NSNumber * val = [attributes objectForKey:attributeName];
    if(val != nil){
        
        return (GLuint) [val unsignedIntValue];
    }
    return -1;
}
//---------------------------------------------------------------------------
- (void) dealloc{
    if (program)
    {
        glDeleteProgram(program);
        program = 0;
    }
//    [uniforms release];
//    [attributes release];
//   [super dealloc];
}
//---------------------------------------------------------------------------
-(id) initWithFileName: (NSString*) shaderFileName
            attributes: (NSDictionary*) attribs
              uniforms: (NSDictionary*) unis
{
    self = [super init];
    uniforms = [[NSMutableDictionary alloc] initWithDictionary:unis];
    attributes = [[NSMutableDictionary alloc] initWithDictionary:attribs];
    if(![self loadShaders:shaderFileName])
    {
//        [self release];
        return nil;
    }

    return self;
}
//---------------------------------------------------------------------------
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}
//---------------------------------------------------------------------------
- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}
//---------------------------------------------------------------------------
- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}
//---------------------------------------------------------------------------
- (BOOL)loadShaders: (NSString*) shaderFileName
{
    NSString *vertShaderPathname= nil, *fragShaderPathname=nil;
    NSEnumerator *uni_keys = [uniforms keyEnumerator];
    NSEnumerator *attrib_keys = [attributes keyEnumerator];
    NSMutableDictionary *uniTemp = [NSMutableDictionary dictionary];
    
    NSString* key;
    
    // Create shader program
    program = glCreateProgram();
    
    // Create and compile vertex shader
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:shaderFileName ofType:@"vsh"];
    if (![self compileShader:&vertex type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:shaderFileName ofType:@"fsh"];
    if (![self compileShader:&fragment type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    glAttachShader(program, vertex);
    
    glAttachShader(program, fragment);
    

    while(key = [attrib_keys nextObject]){
        glBindAttribLocation(program, [[attributes objectForKey:key] unsignedIntValue], [key UTF8String]);
    }
    
    
    // Link program
    if (![self linkProgram:program])
    {
        NSLog(@"Failed to link program: %d", program);
        
        if (vertex)
        {
            glDeleteShader(vertex);
            vertex = 0;
        }
        if (fragment)
        {
            glDeleteShader(fragment);
            fragment = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
        
        return FALSE;
    }
    
    
    while(key = [uni_keys nextObject]){
        GLuint val = glGetUniformLocation(program, [key UTF8String]);
        [uniTemp setObject:[NSNumber numberWithUnsignedInt:val] forKey:key];
    }
    
//    [uniforms release];
    uniforms = [[NSMutableDictionary alloc] initWithDictionary:uniTemp];
    
    if (vertex)
        glDeleteShader(vertex);
    if (fragment)
        glDeleteShader(fragment);
    
    return TRUE;
}

@end
