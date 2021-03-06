//
//  CustomTargetShader.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/27.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <OpenGLES/ES3/glext.h>
#else
#import <OpenGL/gl3.h>
#endif
#import "CustomTypes.h"
#import "ShaderProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface CustomTargetShader : NSObject<ShaderProtocol>

@property(nonatomic, readonly) EAGLContext *glContext;

/// glContext used for creating texture cache and should the same as the one which used for process pixel buffer. And the glContext will set value by CustomPixelBufferProcesser.
- (void)setGLContext:(EAGLContext *)glContext;

/// Callback for I420 frames. Each plane is given as a texture.
- (nullable CVPixelBufferRef)applyShadingForTextureWithWidth:(int)width height:(int)height orientation:(UIInterfaceOrientation)orientation yPlane:(GLuint)yPlane uPlane:(GLuint)uPlane vPlane:(GLuint)vPlane CF_RETURNS_RETAINED;

/// Each plane is given as a texture. Process NV12 pixel buffer.
- (nullable CVPixelBufferRef)applyShadingForTextureWithWidth:(int)width height:(int)height orientation:(UIInterfaceOrientation)orientation
                               yPlane:(GLuint)yPlane
                              uvPlane:(GLuint)uvPlane CF_RETURNS_RETAINED;

@end

NS_ASSUME_NONNULL_END
