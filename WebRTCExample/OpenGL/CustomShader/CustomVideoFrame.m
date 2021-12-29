//
//  CustomVideoFrame.m
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/27.
//

#import "CustomVideoFrame.h"

@interface CustomVideoFrame()

@property(nonatomic, assign) CustomVideoRotation rotation;

/** Timestamp in nanoseconds. */
@property(nonatomic, assign) int64_t timeStampNs;

@property(nonatomic) CVPixelBufferRef buffer;

@end

@implementation CustomVideoFrame

/** Initialize an RTCVideoFrame from a frame buffer, rotation, and timestamp.
 */
- (instancetype)initWithBuffer:(CVPixelBufferRef _Nullable)buffer
                      rotation:(CustomVideoRotation)rotation
                   timeStampNs:(int64_t)timeStampNs {
    if (self = [super init]) {
        _buffer = buffer;
        _rotation = rotation;
        _timeStampNs = timeStampNs;
    }
    return self;
}

- (int)width {
    return (int)CVPixelBufferGetWidth(_buffer);
}

- (int)height {
    return (int)CVPixelBufferGetHeight(_buffer);
}


@end
