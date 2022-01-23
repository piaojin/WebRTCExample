//
//  CustomRTCNV12TextureCache.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/23.
//

#import <GLKit/GLKit.h>

#import <WebRTC/RTCMacros.h>

@class RTC_OBJC_TYPE(RTCVideoFrame);

NS_ASSUME_NONNULL_BEGIN

@interface CustomRTCNV12TextureCache : NSObject

@property(nonatomic, readonly) GLuint yTexture;
@property(nonatomic, readonly) GLuint uvTexture;

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithContext:(EAGLContext *)context NS_DESIGNATED_INITIALIZER;

- (BOOL)uploadFrameToTextures:(RTC_OBJC_TYPE(RTCVideoFrame) *)frame;

- (void)releaseTextures;

@end

NS_ASSUME_NONNULL_END

