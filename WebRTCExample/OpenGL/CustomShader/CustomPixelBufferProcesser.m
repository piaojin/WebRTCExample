//
//  CustomPixelBufferProcesser.m
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/23.
//

#import "CustomPixelBufferProcesser.h"
#import <WebRTC/RTCVideoViewShading.h>
#import "CustomNV12TextureCache.h"
#import "CustomI420TextureCache.h"
#import "CustomDefaultShader.h"
#import <GLKit/GLKit.h>
#import <WebRTC/RTCLogging.h>
#import <WebRTC/RTCCVPixelBuffer.h>
#import <WebRTC/RTCVideoFrame.h>
#import <WebRTC/RTCVideoFrameBuffer.h>

@interface RTC_OBJC_TYPE (CustomPixelBufferProcesser) ()
    // |videoFrame| is set when we receive a frame from a worker thread and is read
    // from the display link callback so atomicity is required.
    @property(atomic, strong) RTC_OBJC_TYPE(RTCVideoFrame) * videoFrame;
@end

@implementation RTC_OBJC_TYPE (CustomPixelBufferProcesser) {
  EAGLContext *_glContext;
  // This flag should only be set and read on the main thread (e.g. by
  // setNeedsDisplay)
  BOOL _isDirty;
  id<RTC_OBJC_TYPE(RTCVideoViewShading)> _shader;
  CustomNV12TextureCache *_nv12TextureCache;
  CustomI420TextureCache *_i420TextureCache;
  // As timestamps should be unique between frames, will store last
  // drawn frame timestamp instead of the whole frame to reduce memory usage.
  int64_t _lastDrawnFrameTimeStampNs;
}

@synthesize videoFrame = _videoFrame;
@synthesize rotationOverride = _rotationOverride;

- (instancetype)init {
  return [self initWithShader:[[CustomDefaultShader alloc] init]];
}

- (instancetype)initWithShader:(id<RTC_OBJC_TYPE(RTCVideoViewShading)>)shader {
  if (self = [super init]) {
    _shader = shader;
    if (![self configure]) {
      return nil;
    }
  }
  return self;
}

- (BOOL)configure {
  EAGLContext *glContext =
    [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
  if (!glContext) {
    glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  }
  if (!glContext) {
    RTCLogError(@"Failed to create EAGLContext");
    return NO;
  }
  _glContext = glContext;

  // Listen to application state in order to clean up OpenGL before app goes
  // away.
  NSNotificationCenter *notificationCenter =
    [NSNotificationCenter defaultCenter];
  [notificationCenter addObserver:self
                         selector:@selector(willResignActive)
                             name:UIApplicationWillResignActiveNotification
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(didBecomeActive)
                             name:UIApplicationDidBecomeActiveNotification
                           object:nil];
    
    __weak RTC_OBJC_TYPE(CustomPixelBufferProcesser) *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        RTC_OBJC_TYPE(CustomPixelBufferProcesser) *strongSelf = weakSelf;
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
          [strongSelf setupGL];
        }
    });
  return YES;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    __weak RTC_OBJC_TYPE(CustomPixelBufferProcesser) *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        RTC_OBJC_TYPE(CustomPixelBufferProcesser) *strongSelf = weakSelf;
        UIApplicationState appState =
            [UIApplication sharedApplication].applicationState;
        if (appState == UIApplicationStateActive) {
          [strongSelf teardownGL];
        }
    });
  
  [self ensureGLContext];
  _shader = nil;
  if (_glContext && [EAGLContext currentContext] == _glContext) {
    [EAGLContext setCurrentContext:nil];
  }
}

- (void)processBuffer:(RTCVideoFrame *)frame {
  // The renderer will draw the frame to the framebuffer corresponding to the
  // one used by |view|.
  if (!frame || frame.timeStampNs == _lastDrawnFrameTimeStampNs) {
    return;
  }
  RTCVideoRotation rotation = frame.rotation;
  if(_rotationOverride != nil) {
    [_rotationOverride getValue: &rotation];
  }
  [self ensureGLContext];
  glClear(GL_COLOR_BUFFER_BIT);
  if ([frame.buffer isKindOfClass:[RTC_OBJC_TYPE(RTCCVPixelBuffer) class]]) {
    if (!_nv12TextureCache) {
      _nv12TextureCache = [[CustomNV12TextureCache alloc] initWithContext:_glContext];
    }
    if (_nv12TextureCache) {
      // 上传pixel buffer到OpenGL ES
      [_nv12TextureCache uploadFrameToTextures:frame];
      // 应用着色器(包含绘制)
      [_shader applyShadingForFrameWithWidth:frame.width
                                      height:frame.height
                                    rotation:rotation
                                      yPlane:_nv12TextureCache.yTexture
                                     uvPlane:_nv12TextureCache.uvTexture];
      [_nv12TextureCache releaseTextures];

      _lastDrawnFrameTimeStampNs = frame.timeStampNs;
    }
  } else {
    if (!_i420TextureCache) {
      _i420TextureCache = [[CustomI420TextureCache alloc] initWithContext:_glContext];
    }
    [_i420TextureCache uploadFrameToTextures:frame];
    [_shader applyShadingForFrameWithWidth:frame.width
                                    height:frame.height
                                  rotation:rotation
                                    yPlane:_i420TextureCache.yTexture
                                    uPlane:_i420TextureCache.uTexture
                                    vPlane:_i420TextureCache.vTexture];

    _lastDrawnFrameTimeStampNs = frame.timeStampNs;
  }
}

#pragma mark - Private

- (void)setupGL {
  [self ensureGLContext];
  glDisable(GL_DITHER);
}

- (void)teardownGL {
  [self ensureGLContext];
  _nv12TextureCache = nil;
  _i420TextureCache = nil;
}

- (void)didBecomeActive {
  [self setupGL];
}

- (void)willResignActive {
  [self teardownGL];
}

- (void)ensureGLContext {
  NSAssert(_glContext, @"context shouldn't be nil");
  if ([EAGLContext currentContext] != _glContext) {
    [EAGLContext setCurrentContext:_glContext];
  }
}

@end
