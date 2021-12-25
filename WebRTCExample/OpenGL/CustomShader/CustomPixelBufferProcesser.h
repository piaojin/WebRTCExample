//
//  CustomPixelBufferProcesser.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/23.
//

#import <Foundation/Foundation.h>

#import <WebRTC/RTCMacros.h>
#import <WebRTC/RTCVideoRenderer.h>

NS_ASSUME_NONNULL_BEGIN

@class RTC_OBJC_TYPE(CustomPixelBufferProcesser);

/**
 * RTCEAGLVideoView is an RTCVideoRenderer which renders video frames
 * in its bounds using OpenGLES 2.0 or OpenGLES 3.0.
 */
RTC_OBJC_EXPORT
NS_EXTENSION_UNAVAILABLE_IOS("Rendering not available in app extensions.")
@interface RTC_OBJC_TYPE (CustomPixelBufferProcesser) : NSObject

- (instancetype)init;

- (void)processBuffer:(RTCVideoFrame *)frame;

/** @abstract Wrapped RTCVideoRotation, or nil.
 */
@property(nonatomic, nullable) NSValue *rotationOverride;
@end

NS_ASSUME_NONNULL_END
