//
//  CustomI420TextureCache.m
//  WebRTCExample
//
//  Created by rcadmin on 2022/1/23.
//

#import "CustomI420TextureCache.h"
#import "CustomOpenGLDefines.h"

#if TARGET_OS_IPHONE
#import <OpenGLES/ES3/gl.h>
#else
#import <OpenGL/gl3.h>
#endif

#include <vector>

// Two sets of 3 textures are used here, one for each of the Y, U and V planes. Having two sets
// alleviates CPU blockage in the event that the GPU is asked to render to a texture that is already
// in use.
static const GLsizei kNumTextureSets = 2;
static const GLsizei kNumTexturesPerSet = 3;
static const GLsizei kNumTextures = kNumTexturesPerSet * kNumTextureSets;

@interface CustomI420TextureCache()

@property(nonatomic, assign) BOOL hasUnpackRowLength;
@property(nonatomic, assign) GLint currentTextureSet;

@end

@implementation CustomI420TextureCache {
  // Handles for OpenGL constructs.
  GLuint _textures[kNumTextures];
  // Used to create a non-padded plane for GPU upload when we receive padded frames.
  std::vector<uint8_t> _planeBuffer;
}

- (GLuint)yTexture {
  return _textures[_currentTextureSet * kNumTexturesPerSet];
}

- (GLuint)uTexture {
  return _textures[_currentTextureSet * kNumTexturesPerSet + 1];
}

- (GLuint)vTexture {
  return _textures[_currentTextureSet * kNumTexturesPerSet + 2];
}

- (instancetype)initWithContext:(EAGLContext *)context {
  if (self = [super init]) {
#if TARGET_OS_IPHONE
    _hasUnpackRowLength = (context.API == kEAGLRenderingAPIOpenGLES3);
#else
    _hasUnpackRowLength = YES;
#endif
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    [self setupTextures];
  }
  return self;
}

- (void)dealloc {
  glDeleteTextures(kNumTextures, _textures);
}

- (void)setupTextures {
  glGenTextures(kNumTextures, _textures);
  // Set parameters for each of the textures we created.
  for (GLsizei i = 0; i < kNumTextures; i++) {
    glBindTexture(GL_TEXTURE_2D, _textures[i]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  }
}

- (void)uploadPlane:(const uint8_t *)plane
            texture:(GLuint)texture
              width:(size_t)width
             height:(size_t)height
             stride:(int32_t)stride {
  glBindTexture(GL_TEXTURE_2D, texture);

  const uint8_t *uploadPlane = plane;
  if ((size_t)stride != width) {
   if (_hasUnpackRowLength) {
      // GLES3 allows us to specify stride.
      glPixelStorei(GL_UNPACK_ROW_LENGTH, stride);
      glTexImage2D(GL_TEXTURE_2D,
                   0,
                   GL_LUMINANCE,
                   static_cast<GLsizei>(width),
                   static_cast<GLsizei>(height),
                   0,
                   GL_LUMINANCE,
                   GL_UNSIGNED_BYTE,
                   uploadPlane);
      glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
      return;
    } else {
      // Make an unpadded copy and upload that instead. Quick profiling showed
      // that this is faster than uploading row by row using glTexSubImage2D.
      uint8_t *unpaddedPlane = _planeBuffer.data();
      for (size_t y = 0; y < height; ++y) {
        memcpy(unpaddedPlane + y * width, plane + y * stride, width);
      }
      uploadPlane = unpaddedPlane;
    }
  }
  glTexImage2D(GL_TEXTURE_2D,
               0,
               GL_LUMINANCE,
               static_cast<GLsizei>(width),
               static_cast<GLsizei>(height),
               0,
               GL_LUMINANCE,
               GL_UNSIGNED_BYTE,
               uploadPlane);
}

- (void)uploadFrameToTextures:(CVPixelBufferRef)buffer {
  _currentTextureSet = (_currentTextureSet + 1) % kNumTextureSets;
    size_t width  = CVPixelBufferGetWidth(buffer);
    size_t height = CVPixelBufferGetHeight(buffer);
    
//    int chromaWidth = (width + 1) / 2;
//    int chromaHeight = (height + 1) / 2;
    
//    RTC_DCHECK_GE(stride_y, width);
//      RTC_DCHECK_GE(stride_u, (width + 1) / 2);
//      RTC_DCHECK_GE(stride_v, (width + 1) / 2);
//    data_(static_cast<uint8_t*>
    
//    const uint8_t* I420Buffer::DataY() const {
//      return data_.get();
//    }
//    const uint8_t* I420Buffer::DataU() const {
//      return data_.get() + stride_y_ * height_;
//    }
//    const uint8_t* I420Buffer::DataV() const {
//      return data_.get() + stride_y_ * height_ + stride_u_ * ((height_ + 1) / 2);
//    }
    
    const int chromaWidth = (int)((width + 1) / 2);
    const int chromaHeight = (int)((height + 1) / 2);
    const int strideY = (int)width;
    const int strideU = (int)((width + 1) / 2);
    const int strideV = (int)((width + 1) / 2);
  
//    if (strideY != width || strideU != chromaWidth ||
//      strideV != chromaWidth) {
//        _planeBuffer.resize(width * height);
//    }

    CVPixelBufferLockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
    uint8_t *dataY = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(buffer,0);
    uint8_t *dataU = dataY + strideY * height;
    uint8_t *dataV = dataY + strideY * height + strideU * ((height + 1) / 2);
    CVPixelBufferUnlockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
    
    [self uploadPlane:dataY
            texture:self.yTexture
              width:width
             height:height
             stride:strideY];

    [self uploadPlane:dataU
            texture:self.uTexture
              width:chromaWidth
             height:chromaHeight
             stride:strideU];

    [self uploadPlane:dataV
            texture:self.vTexture
              width:chromaWidth
             height:chromaHeight
             stride:strideV];
}

@end
