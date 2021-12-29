//
//  CustomTextureCache.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/27.
//

#import <GLKit/GLKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CustomVideoFrame;

@interface CustomTextureCache : NSObject

/// yTexture and uvTexture both are two texture. Use them to access texture.
@property(nonatomic, readonly) GLuint yTexture;
@property(nonatomic, readonly) GLuint uvTexture;
@property(nonatomic, readonly) GLenum yTextureTarget;
@property(nonatomic, readonly) GLenum uvTextureTarget;

- (nullable instancetype)initWithContext:(EAGLContext *)context;

- (BOOL)uploadFrameToTextures:(CVPixelBufferRef)buffer;

- (void)releaseTextures;

@end

NS_ASSUME_NONNULL_END
