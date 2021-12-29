//
//  RTCDefaultShader.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/23.
//

#import <Foundation/Foundation.h>

#import <WebRTC/RTCVideoViewShading.h>

NS_ASSUME_NONNULL_BEGIN

/** Default RTCVideoViewShading that will be used in RTCNSGLVideoView
 *  and RTCEAGLVideoView if no external shader is specified. This shader will render
 *  the video in a rectangle without any color or geometric transformations.
 */
@interface CustomDefaultShader : NSObject <RTC_OBJC_TYPE (RTCVideoViewShading)>

@end

NS_ASSUME_NONNULL_END

