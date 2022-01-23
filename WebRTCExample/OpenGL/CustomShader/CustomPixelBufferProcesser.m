//
//  CustomPixelBufferProcesser.m
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/23.
//

#import "CustomPixelBufferProcesser.h"
#import "CustomNV12TextureCache.h"
#import "CustomTargetShader.h"
#import <GLKit/GLKit.h>
#import "ShaderProtocol.h"

@interface CustomPixelBufferProcesser()

@property(nonatomic, strong) EAGLContext *glContext;
@property(nonatomic, strong) CustomNV12TextureCache *nv12TextureCache;
@property(nonatomic, assign) int64_t lastDrawnFrameTimeStampNs;
@property(nonatomic) id<ShaderProtocol> shader;

@end

@implementation CustomPixelBufferProcesser

/// Will use default shader
- (instancetype)init {
    if (self = [super init]) {
        if (![self configure]) {
            return nil;
        }
        _shader = [[CustomTargetShader alloc] init];
        [_shader setGlContext:_glContext];
    }
    return self;
}

/// Use custom shader.
- (instancetype)initWithShader:(id<ShaderProtocol>)shader {
    if (self = [super init]) {
        if (![self configure]) {
            return nil;
        }
        _shader = shader;
        [_shader setGlContext:_glContext];
    }
    return self;
}

/// Used for init.
- (BOOL)configure {
    EAGLContext *glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!glContext) {
        glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
  
    if (!glContext) {
        DLog(@"Failed to create EAGLContext");
        return NO;
    }
    _glContext = glContext;

    // Listen to application state in order to clean up OpenGL before app goes away.
    [[NSNotificationCenter defaultCenter] addObserver:self
                         selector:@selector(willResignActive)
                             name:UIApplicationWillResignActiveNotification
                           object:nil];
  
    [[NSNotificationCenter defaultCenter] addObserver:self
                         selector:@selector(didBecomeActive)
                             name:UIApplicationDidBecomeActiveNotification
                           object:nil];
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
          [strongSelf setupGL];
        }
    });
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
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

/// Note: This function pass ownership of return value(CVPixelBufferRef) to the caller.
- (CVPixelBufferRef _Nullable)processBuffer:(CVPixelBufferRef _Nullable)pixelBuffer orientation:(UIInterfaceOrientation)orientation timeStampNs:(int64_t)timeStampNs CF_RETURNS_RETAINED {
    // The renderer will draw the frame to the framebuffer corresponding to the
    // one used by |view|.
    if (!pixelBuffer || timeStampNs == _lastDrawnFrameTimeStampNs) {
        return nil;
    }
  
    [self ensureGLContext];
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 上传pixel buffer到OpenGL ES
    [self.nv12TextureCache uploadFrameToTextures:pixelBuffer];
    
    CGSize textureSize = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer),
                                    CVPixelBufferGetHeight(pixelBuffer));
    // 应用着色器(包含绘制)
    CVPixelBufferRef resPixelBuffer = [_shader applyShadingForTextureWithRotation:orientation yPlane:_nv12TextureCache.yTexture uvPlane:_nv12TextureCache.uvTexture textureSize:textureSize];
  
    [_nv12TextureCache releaseTextures];
    _lastDrawnFrameTimeStampNs = timeStampNs;
    
    return resPixelBuffer;
}

- (BOOL)shouldProcessFrameBuffer {
    return YES;
}

#pragma mark - Private

- (void)setupGL {
    [self ensureGLContext];
    glDisable(GL_DITHER);
}

- (void)teardownGL {
    [self ensureGLContext];
    _nv12TextureCache = nil;
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

- (CustomNV12TextureCache *)nv12TextureCache {
    if (!_nv12TextureCache) {
      _nv12TextureCache = [[CustomNV12TextureCache alloc] initWithContext:_glContext];
    }
    return _nv12TextureCache;
}

@end
