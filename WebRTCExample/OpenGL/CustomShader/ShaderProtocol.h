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
- (void)setGLContext:(EAGLContext *)glContext;

/// Callback for I420 frames. Each plane is given as a texture.
- (nullable CVPixelBufferRef)applyShadingForTextureWithWidth:(int)width height:(int)height orientation:(UIInterfaceOrientation)orientation yPlane:(GLuint)yPlane uPlane:(GLuint)uPlane vPlane:(GLuint)vPlane CF_RETURNS_RETAINED;

/// Each plane is given as a texture. Process NV12 pixel buffer.
- (nullable CVPixelBufferRef)applyShadingForTextureWithWidth:(int)width height:(int)height orientation:(UIInterfaceOrientation)orientation
                               yPlane:(GLuint)yPlane
                              uvPlane:(GLuint)uvPlane CF_RETURNS_RETAINED;

@end

NS_ASSUME_NONNULL_END

#endif /* ShaderProtocol_h */
