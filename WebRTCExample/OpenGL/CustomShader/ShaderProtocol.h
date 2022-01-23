//
//  ShaderProtocol.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/27.
//

#ifndef ShaderProtocol_h
#define ShaderProtocol_h

#import "CustomTypes.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ShaderProtocol <NSObject>

@property(nonatomic, readonly) EAGLContext *glContext;

/// glContext used for creating texture cache and should the same as the one which used for process pixel buffer. And the glContext will set value by CustomPixelBufferProcesser.
- (void)setGlContext:(EAGLContext *)glContext;

/// Apply shaders. Each plane is given as a texture. Process NV12 pixel buffer.
- (nullable CVPixelBufferRef)applyShadingForTextureWithRotation:(UIInterfaceOrientation)orientation
                               yPlane:(GLuint)yPlane
                              uvPlane:(GLuint)uvPlane textureSize:(CGSize)textureSize CF_RETURNS_RETAINED;

@end

NS_ASSUME_NONNULL_END

#endif /* ShaderProtocol_h */
