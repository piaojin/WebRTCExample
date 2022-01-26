//
//  CustomI420TextureCache.h
//  WebRTCExample
//
//  Created by rcadmin on 2022/1/23.
//

#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomI420TextureCache : NSObject

@property(nonatomic, readonly) GLuint yTexture;
@property(nonatomic, readonly) GLuint uTexture;
@property(nonatomic, readonly) GLuint vTexture;

- (instancetype)initWithContext:(EAGLContext *)context;

- (void)uploadFrameToTextures:(CVPixelBufferRef)buffer;

@end

NS_ASSUME_NONNULL_END
