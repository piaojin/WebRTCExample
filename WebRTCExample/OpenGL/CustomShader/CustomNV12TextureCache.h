//
//  CustomNV12TextureCache.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/27.
//

#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomNV12TextureCache : NSObject

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
