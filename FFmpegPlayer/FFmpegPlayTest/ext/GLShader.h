/*
 *  GLShader.h/.m - Manages a shader program.
 *  jamesghurley<at>gmail.com
 */
#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>


@interface GLShader : NSObject {
    GLuint fragment, vertex, program;
 
    NSMutableDictionary *uniforms;
    NSMutableDictionary *attributes;
}
@property (readonly) GLuint program;

-(id) initWithFileName: (NSString*) shaderFileName attributes: (NSDictionary*) attribs uniforms: (NSDictionary*) unis ;
-(GLuint) getUniform: (NSString*) uniformName;
-(GLuint) getAttribute: (NSString*) attributeName;
@end
