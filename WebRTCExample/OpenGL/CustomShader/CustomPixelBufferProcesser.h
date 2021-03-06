//
//  CustomPixelBufferProcesser.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/23.
//

#import <Foundation/Foundation.h>
#import "ProcessPixelBufferProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ShaderProtocol;

NS_EXTENSION_UNAVAILABLE_IOS("Rendering not available in app extensions.")
@interface CustomPixelBufferProcesser : NSObject<ProcessPixelBufferProtocol>

@property(nonatomic, readonly) EAGLContext *glContext;

/// Will use default shader
- (instancetype)init;

/// Use custom shader.
- (instancetype)initWithShader:(id<ShaderProtocol>)shader;

/// Note: This function pass ownership of return value(CVPixelBufferRef) to the caller.
- (CVPixelBufferRef _Nullable)processBuffer:(CVPixelBufferRef _Nullable)pixelBuffer orientation:(UIInterfaceOrientation)orientation timeStampNs:(int64_t)timeStampNs CF_RETURNS_RETAINED;

- (BOOL)shouldProcessFrameBuffer;

@end

NS_ASSUME_NONNULL_END
