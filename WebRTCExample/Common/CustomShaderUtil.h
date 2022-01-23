//
//  CustomShaderUtil.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/26.
//

#import <Foundation/Foundation.h>
#import "CustomTypes.h"
#if TARGET_OS_IPHONE
#import <OpenGLES/ES3/gl.h>
#else
#import <OpenGL/gl3.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CustomShaderUtil : NSObject

/// Compiles a shader of the given |type| with GLSL source |source| and returns
/// the shader handle or 0 on error.
+ (GLuint) createShader:(GLenum)type source:(const GLchar *)source;

/// Links a shader program with the given vertex and fragment shaders and
/// returns the program handle or 0 on error.
+ (GLuint) createProgramWithVertexShader:(GLuint)vertexShader fragmentShader:(GLuint)fragmentShader;

///e.g: 手机竖屏时的顶点数据,x,y是顶点坐标,u,v是纹理坐标.
///const GLfloat gVertices[] = {
///     X, Y, U, V.
///      -1, -1, 0, 1,
///       1, -1, 1, 1,
///       1,  1, 1, 0,
///      -1,  1, 0, 0,
///};
///
/// VBO
/// pos = position(x,y), tex = texcoord(u,v)
/// | pos1 | tex1 | pos2 | tex2 | pos3 | tex3 | pos4 | tex4 |
/// Creates and links a shader program with the given fragment shader source and
/// a plain vertex shader. Returns the program handle or 0 on error.
+ (GLuint) createProgramWithVertexShaderSource:(const char [_Nonnull])vertexShaderSource fragmentShaderSource:(const char [_Nonnull])fragmentShaderSource;

/// Create VAB and VBO and bind them.
+ (BOOL) createVertexBuffer: (GLuint *)VBO VAO:(GLuint *)VAO;

/// 上传顶点数据,包括顶点坐标和纹理坐标数据
/// Set vertex data to the currently bound vertex buffer.
+ (void) setVertexDataWithRotation:(CustomVideoRotation)rotation;

@end

NS_ASSUME_NONNULL_END
