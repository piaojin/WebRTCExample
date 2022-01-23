//
//  CustomVideoFrame.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/27.
//

#import <CoreVideo/CVPixelBuffer.h>
#import <Foundation/Foundation.h>
#import "CustomTypes.h"


NS_ASSUME_NONNULL_BEGIN

@interface CustomVideoFrame : NSObject

/** Width without rotation applied. */
@property(nonatomic, readonly) int width;

/** Height without rotation applied. */
@property(nonatomic, readonly) int height;
@property(nonatomic, readonly) CustomVideoRotation rotation;

/** Timestamp in nanoseconds. */
@property(nonatomic, readonly) int64_t timeStampNs;

@property(nonatomic, readonly) CVPixelBufferRef buffer;

/** Initialize an RTCVideoFrame from a frame buffer, rotation, and timestamp.
 */
- (instancetype)initWithBuffer:(CVPixelBufferRef _Nullable)buffer
                      rotation:(CustomVideoRotation)rotation
                   timeStampNs:(int64_t)timeStampNs;

@end

NS_ASSUME_NONNULL_END
