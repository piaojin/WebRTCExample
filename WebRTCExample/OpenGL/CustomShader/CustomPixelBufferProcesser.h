//
//  CustomPixelBufferProcesser.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/23.
//

#import <Foundation/Foundation.h>
#import "ProcessPixelBufferProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class CustomVideoFrame;

NS_EXTENSION_UNAVAILABLE_IOS("Rendering not available in app extensions.")
@interface CustomPixelBufferProcesser : NSObject<ProcessPixelBufferProtocol>

- (instancetype)init;

/// Note: This function pass ownership of return value(CVPixelBufferRef) to the caller.
- (CVPixelBufferRef _Nullable)processBuffer:(CustomVideoFrame *_Nullable)frame CF_RETURNS_RETAINED;

- (BOOL)shouldProcessFrameBuffer;

@end

NS_ASSUME_NONNULL_END
