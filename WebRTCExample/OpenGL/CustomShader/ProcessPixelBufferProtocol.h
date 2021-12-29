//
//  ProcessPixelBufferProtocol.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/28.
//

#ifndef ProcessPixelBufferProtocol_h
#define ProcessPixelBufferProtocol_h

#import <AVFoundation/AVFoundation.h>
@class CustomVideoFrame;

@protocol ProcessPixelBufferProtocol <NSObject>

/// Note: This function pass ownership of return value(CVPixelBufferRef) to the caller.
- (CVPixelBufferRef _Nullable)processBuffer:(CustomVideoFrame *_Nullable)frame CF_RETURNS_RETAINED;

- (BOOL)shouldProcessFrameBuffer;

@end

#endif /* ProcessPixelBufferProtocol_h */
