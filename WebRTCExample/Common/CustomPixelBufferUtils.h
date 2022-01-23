//
//  CustomPixelBufferUtils.h
//  WebRTCExample
//
//  Created by rcadmin on 2022/1/12.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include <libyuv-iOS/libyuv.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomPixelBufferUtils : NSObject

+ (nullable CVPixelBufferRef) createEmptyPixelBuffer:(OSType)pixelFormatType targetSize:(CGSize)targetSize CF_RETURNS_RETAINED;

+ (nullable CVPixelBufferRef) createEmptyPixelBuffer: (nonnull NSDictionary *)attributes pixelFormatType:(OSType)pixelFormatType targetSize:(CGSize)targetSize CF_RETURNS_RETAINED;

+ (nullable CVPixelBufferRef) createEmptyPixelBuffer: (CFAllocatorRef __nullable)allocator attributes:(NSDictionary *)attributes pixelFormatType:(OSType)pixelFormatType targetSize:(CGSize)targetSize CF_RETURNS_RETAINED;

///目前会有一些绿屏问题
+ (nullable CVPixelBufferRef) convertBGRAToI420:(nonnull CVPixelBufferRef) pixelBufferBGRA CF_RETURNS_RETAINED;

+ (nullable CVPixelBufferRef) convertBGRAToNV12:(nonnull CVPixelBufferRef)pixelBufferBGRA CF_RETURNS_RETAINED;

///目前旋转后的buffer拿去转成NV12/I420会花屏
+ (nullable CVPixelBufferRef) ARGBRotate:(nonnull CVPixelBufferRef)pixelBufferBGRA rotation:(libyuv::RotationMode)rotation CF_RETURNS_RETAINED;

@end

NS_ASSUME_NONNULL_END
