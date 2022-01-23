//
//  CustomRTCI420TextureCache.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/23.
//

#import "CustomOpenGLDefines.h"
#import <WebRTC/RTCVideoFrame.h>

@interface CustomRTCI420TextureCache : NSObject

@property(nonatomic, readonly) GLuint yTexture;
@property(nonatomic, readonly) GLuint uTexture;
@property(nonatomic, readonly) GLuint vTexture;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithContext:(GlContextType *)context NS_DESIGNATED_INITIALIZER;

- (void)uploadFrameToTextures:(RTC_OBJC_TYPE(RTCVideoFrame) *)frame;

@end
