//
//  ProcessPixelBufferProtocol.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/28.
//

#ifndef ProcessPixelBufferProtocol_h
#define ProcessPixelBufferProtocol_h

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
@class CustomVideoFrame;

NS_ASSUME_NONNULL_BEGIN

@protocol ProcessPixelBufferProtocol <NSObject>

/// Note: This function pass ownership of return value(CVPixelBufferRef) to the caller.
- (CVPixelBufferRef _Nullable)processBuffer:(CVPixelBufferRef _Nullable)pixelBuffer orientation:(UIInterfaceOrientation)orientation timeStampNs:(int64_t)timeStampNs CF_RETURNS_RETAINED;

- (BOOL)shouldProcessFrameBuffer;

@end

NS_ASSUME_NONNULL_END

#endif /* ProcessPixelBufferProtocol_h */
