//
//  CustomTargetShader.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/27.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <OpenGLES/ES3/gl.h>
#else
#import <OpenGL/gl3.h>
#endif
#import "CustomTypes.h"
#import "ShaderProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface CustomTargetShader : NSObject<ShaderProtocol>

@property(nonatomic, readonly) GLuint VBO;
@property(nonatomic, readonly) GLuint VAO;
@property(nonatomic, readonly) GLuint program;

/// 应用着色器. Each plane is given as a texture.
- (void)applyShadingForTextureWithRotation:(CustomVideoRotation)rotation
                               yPlane:(GLuint)yPlane
                              uvPlane:(GLuint)uvPlane;

@end

NS_ASSUME_NONNULL_END
