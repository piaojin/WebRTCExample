//
//  CustomTextureCache.m
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/27.
//

#import "CustomNV12TextureCache.h"

@interface CustomNV12TextureCache()

@property(nonatomic) CVOpenGLESTextureCacheRef textureCache;
@property(nonatomic) CVOpenGLESTextureRef yTextureRef;
@property(nonatomic) CVOpenGLESTextureRef uvTextureRef;

@end

@implementation CustomNV12TextureCache

- (GLenum)yTextureTarget {
    return CVOpenGLESTextureGetTarget(_yTextureRef);
}

- (GLenum)uvTextureTarget {
    return CVOpenGLESTextureGetTarget(_uvTextureRef);
}

- (GLuint)yTexture {
  return CVOpenGLESTextureGetName(_yTextureRef);
}

- (GLuint)uvTexture {
  return CVOpenGLESTextureGetName(_uvTextureRef);
}

- (instancetype)initWithContext:(EAGLContext *)context {
  if (self = [super init]) {
    CVReturn ret = CVOpenGLESTextureCacheCreate(
        kCFAllocatorDefault, NULL,
#if COREVIDEO_USE_EAGLCONTEXT_CLASS_IN_API
        context,
#else
        (__bridge void *)context,
#endif
        NULL, &_textureCache);
    if (ret != kCVReturnSuccess) {
      self = nil;
    }
  }
  return self;
}

- (BOOL)loadTexture:(CVOpenGLESTextureRef *)textureOut
        pixelBuffer:(CVPixelBufferRef)pixelBuffer
         planeIndex:(int)planeIndex
        pixelFormat:(GLenum)pixelFormat {
  const size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex);
  const size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex);
    
  if (*textureOut) {
    CFRelease(*textureOut);
    *textureOut = nil;
  }
    
  CVReturn ret = CVOpenGLESTextureCacheCreateTextureFromImage(
      kCFAllocatorDefault, _textureCache, pixelBuffer, NULL, GL_TEXTURE_2D, pixelFormat, (GLsizei)width,
      (GLsizei)height, pixelFormat, GL_UNSIGNED_BYTE, planeIndex, textureOut);
  if (ret != kCVReturnSuccess) {
    if (*textureOut) {
      CFRelease(*textureOut);
      *textureOut = nil;
    }
    return NO;
  }
  NSAssert(CVOpenGLESTextureGetTarget(*textureOut) == GL_TEXTURE_2D,
           @"Unexpected GLES texture target");
  glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(*textureOut));
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  return YES;
}

- (BOOL)uploadFrameToTextures:(CVPixelBufferRef)buffer {
  return [self loadTexture:&_yTextureRef
               pixelBuffer:buffer
                planeIndex:0
               pixelFormat:GL_LUMINANCE] &&
         [self loadTexture:&_uvTextureRef
               pixelBuffer:buffer
                planeIndex:1
               pixelFormat:GL_LUMINANCE_ALPHA];
}

- (void)releaseTextures {
  if (_uvTextureRef) {
    CFRelease(_uvTextureRef);
    _uvTextureRef = nil;
  }
    
  if (_yTextureRef) {
    CFRelease(_yTextureRef);
    _yTextureRef = nil;
  }
}

- (void)dealloc {
  [self releaseTextures];
    
  if (_textureCache) {
    CFRelease(_textureCache);
    _textureCache = nil;
  }
}

@end
