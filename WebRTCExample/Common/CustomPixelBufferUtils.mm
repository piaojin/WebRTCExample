//
//  CustomPixelBufferUtils.mm
//  WebRTCExample
//
//  Created by rcadmin on 2022/1/12.
//

#import "CustomPixelBufferUtils.h"

@implementation CustomPixelBufferUtils

+ (nullable CVPixelBufferRef) createEmptyPixelBuffer:(OSType)pixelFormatType targetSize:(CGSize)targetSize CF_RETURNS_RETAINED {
    CVPixelBufferRef pixelBuffer = nil;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          targetSize.width,
                                          targetSize.height,
                                          pixelFormatType,
                                          (__bridge CFDictionaryRef _Nullable)(@{(id)kCVPixelBufferIOSurfacePropertiesKey: @{}}),
                                          &pixelBuffer);
    if (status != kCVReturnSuccess) {
        DLog(@"Can't create pixelBuffer");
        return nil;
    }
    return pixelBuffer;
}

+ (nullable CVPixelBufferRef) createEmptyPixelBuffer: (nonnull NSDictionary *)attributes pixelFormatType:(OSType)pixelFormatType targetSize:(CGSize)targetSize CF_RETURNS_RETAINED {
    CVPixelBufferRef pixelBuffer = nil;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          targetSize.width,
                                          targetSize.height,
                                          pixelFormatType,
                                          (__bridge CFDictionaryRef _Nullable)(attributes),
                                          &pixelBuffer);
    if (status != kCVReturnSuccess) {
        DLog(@"Can't create pixelBuffer");
        return nil;
    }
    return pixelBuffer;
}

+ (nullable CVPixelBufferRef) createEmptyPixelBuffer: (CFAllocatorRef __nullable)allocator attributes:(NSDictionary *)attributes pixelFormatType:(OSType)pixelFormatType targetSize:(CGSize)targetSize CF_RETURNS_RETAINED {
    CVPixelBufferRef pixelBuffer = nil;
    CVReturn status = CVPixelBufferCreate(allocator,
                                          targetSize.width,
                                          targetSize.height,
                                          pixelFormatType,
                                          (__bridge CFDictionaryRef _Nullable)(attributes),
                                          &pixelBuffer);
    if (status != kCVReturnSuccess) {
        DLog(@"Can't create pixelBuffer");
        return nil;
    }
    return pixelBuffer;
}

///目前会有一些绿屏问题: webrtc/api/video/i420_buffer.cc 中有各个分量取值的代码
+ (nullable CVPixelBufferRef) convertBGRAToI420:(nonnull CVPixelBufferRef) pixelBufferBGRA CF_RETURNS_RETAINED {
    CVPixelBufferLockBaseAddress(pixelBufferBGRA, kCVPixelBufferLock_ReadOnly);
    const uint8_t *src_argb = static_cast<uint8_t*>(CVPixelBufferGetBaseAddress(pixelBufferBGRA));
    size_t src_stride_argb = CVPixelBufferGetBytesPerRow(pixelBufferBGRA);
    size_t width  = CVPixelBufferGetWidth(pixelBufferBGRA);
    size_t height = CVPixelBufferGetHeight(pixelBufferBGRA);

    // Create empty I420 pixelBuffer for convert.
    CVPixelBufferRef pixelBufferI420 = [self createEmptyPixelBuffer:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange targetSize:CGSizeMake(width, height)];

    if (!pixelBufferI420) {
        return nil;
    }

    CVPixelBufferLockBaseAddress(pixelBufferI420, kCVPixelBufferLock_ReadOnly);
    uint8_t *dst_y = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixelBufferI420,0);
    width  = CVPixelBufferGetWidth(pixelBufferI420); // dst_stride_y
    height = CVPixelBufferGetHeight(pixelBufferI420);
    
    size_t dst_stride_y = width;
    size_t dst_stride_u = (width + 1) / 2;
    size_t dst_stride_v = (width + 1) / 2;
    
    uint8_t *dst_u = dst_y + width * height;
    uint8_t *dst_v = dst_y + dst_stride_y * height + dst_stride_u * ((height + 1) / 2);
//    uint8_t *dst_v = dst_u + (width + 1) / 2 * (height + 1) / 2;

    // 旋转问题通过修改纹理坐标系
    libyuv::ARGBToI420(src_argb, (int)src_stride_argb, dst_y, (int)dst_stride_y, dst_u, (int)dst_stride_u, dst_v, (int)dst_stride_v, (int)width, (int)height);

    CVPixelBufferUnlockBaseAddress(pixelBufferI420, kCVPixelBufferLock_ReadOnly);
    CVPixelBufferUnlockBaseAddress(pixelBufferBGRA, kCVPixelBufferLock_ReadOnly);
    return pixelBufferI420;
}

+ (nullable CVPixelBufferRef) convertBGRAToNV12:(nonnull CVPixelBufferRef)pixelBufferBGRA CF_RETURNS_RETAINED {
    size_t width  = CVPixelBufferGetWidth(pixelBufferBGRA);
    size_t height = CVPixelBufferGetHeight(pixelBufferBGRA);
    
    CVPixelBufferRef targetPixelBuffer = [self createEmptyPixelBuffer:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange targetSize:CGSizeMake(width, height)];
    
    if (!targetPixelBuffer) {
        return nil;
    }
    
    CVPixelBufferLockBaseAddress(pixelBufferBGRA, kCVPixelBufferLock_ReadOnly);
    CVPixelBufferLockBaseAddress(targetPixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    uint8_t *src_argb = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBufferBGRA);
    size_t src_stride_argb = CVPixelBufferGetBytesPerRow(pixelBufferBGRA);
    
    // yuv-stride
    const size_t dst_stride_y = width;
    const size_t dst_stride_uv = ((width + 1) / 2);
//    const size_t dst_stride_uv = CVPixelBufferGetBytesPerRowOfPlane(targetPixelBuffer, 1);

    // yuv-data
    uint8_t *dst_y = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(targetPixelBuffer, 0);
    uint8_t *dst_uv = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(targetPixelBuffer, 1);
    
    libyuv::ARGBToNV12(src_argb, (int)src_stride_argb,
                       dst_y, (int)dst_stride_y,
                       dst_uv, (int)(dst_stride_uv * 2),
                       (int)width, (int)height);
    
    CVPixelBufferUnlockBaseAddress(targetPixelBuffer, kCVPixelBufferLock_ReadOnly);
    CVPixelBufferUnlockBaseAddress(pixelBufferBGRA, kCVPixelBufferLock_ReadOnly);
    return targetPixelBuffer;
}

///目前旋转后的buffer拿去转成NV12/I420会花屏
+ (nullable CVPixelBufferRef) ARGBRotate:(nonnull CVPixelBufferRef)pixelBufferBGRA rotation:(libyuv::RotationMode)rotation CF_RETURNS_RETAINED {
    size_t src_width  = CVPixelBufferGetWidth(pixelBufferBGRA);
    size_t src_height = CVPixelBufferGetHeight(pixelBufferBGRA);

    size_t rotate_width = src_height;
    size_t rotate_height = src_width;

    CVPixelBufferLockBaseAddress(pixelBufferBGRA, kCVPixelBufferLock_ReadOnly);
    const uint8_t *src_argb = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBufferBGRA);
    size_t src_stride_argb = CVPixelBufferGetBytesPerRow(pixelBufferBGRA);

    // Create empty BGRA pixelBuffer for rotate.
    CVPixelBufferRef rotatePixelBufferBGRA = [self createEmptyPixelBuffer:kCVPixelFormatType_32BGRA targetSize:CGSizeMake(rotate_width, rotate_height)];

    if (!rotatePixelBufferBGRA) {
        return nil;
    }

    CVPixelBufferLockBaseAddress(rotatePixelBufferBGRA, kCVPixelBufferLock_ReadOnly);
    uint8_t *rotate_src_argb = (uint8_t *)CVPixelBufferGetBaseAddress(rotatePixelBufferBGRA);
    size_t rotate_src_stride_argb = CVPixelBufferGetBytesPerRow(rotatePixelBufferBGRA);

    libyuv::ARGBRotate(src_argb, (int)src_stride_argb, rotate_src_argb, (int)rotate_src_stride_argb, (int)src_width, (int)src_height, rotation);
    
    CVPixelBufferUnlockBaseAddress(rotatePixelBufferBGRA, kCVPixelBufferLock_ReadOnly);
    CVPixelBufferUnlockBaseAddress(pixelBufferBGRA, kCVPixelBufferLock_ReadOnly);
    return rotatePixelBufferBGRA;
}

@end
