//
//  CustomTargetShader.m
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/27.
//

#import "CustomTargetShader.h"
#import "CustomOpenGLDefines.h"
#import "CustomShaderUtil.h"
#import "CustomPixelBufferUtils.h"

static const int kYTextureUnit = 0;
static const int kUTextureUnit = 1;
static const int kVTextureUnit = 2;
static const int kUvTextureUnit = 1;

// Vertex shader doesn't do anything except pass coordinates through.
const char kVertexShaderSource[] =
  SHADER_VERSION
  VERTEX_SHADER_IN " vec2 position;\n"
  VERTEX_SHADER_IN " vec2 texcoord;\n"
  VERTEX_SHADER_OUT " vec2 v_texcoord;\n"
  "void main() {\n"
  "    gl_Position = vec4(position.x, position.y, 0.0, 1.0);\n"
  "    v_texcoord = texcoord;\n"
  "}\n";

// Fragment shader converts YUV values from input textures into a final RGB
// pixel. The conversion formula is from http://www.fourcc.org/fccyvrgb.php.
static const char kI420FragmentShaderSource[] =
  SHADER_VERSION
  "precision highp float;"
  FRAGMENT_SHADER_IN " vec2 v_texcoord;\n"
  "uniform lowp sampler2D s_textureY;\n"
  "uniform lowp sampler2D s_textureU;\n"
  "uniform lowp sampler2D s_textureV;\n"
  FRAGMENT_SHADER_OUT
  "void main() {\n"
  "    float y, u, v, r, g, b;\n"
  "    y = " FRAGMENT_SHADER_TEXTURE "(s_textureY, v_texcoord).r;\n"
  "    u = " FRAGMENT_SHADER_TEXTURE "(s_textureU, v_texcoord).r;\n"
  "    v = " FRAGMENT_SHADER_TEXTURE "(s_textureV, v_texcoord).r;\n"
  "    u = u - 0.5;\n"
  "    v = v - 0.5;\n"
  "    r = y + 1.403 * v;\n"
  "    g = y - 0.344 * u - 0.714 * v;\n"
  "    b = y + 1.770 * u;\n"
  "    " FRAGMENT_SHADER_COLOR " = vec4(r, g, b, 1.0);\n"
  "  }\n";

// 简单的灰度滤镜片段着色器: 原理 -> float color = (r + g + b) / 3.0 -> gl_FragColor = vec4(color,color,color,1.0)
static const char kNV12FragmentShaderSource[] =
  SHADER_VERSION
  "precision mediump float;"
  FRAGMENT_SHADER_IN " vec2 v_texcoord;\n"
  "uniform lowp sampler2D s_textureY;\n"
  "uniform lowp sampler2D s_textureUV;\n"
  FRAGMENT_SHADER_OUT
  "void main() {\n"
  "    mediump float y;\n"
  "    mediump vec2 uv;\n"
  "    y = " FRAGMENT_SHADER_TEXTURE "(s_textureY, v_texcoord).r;\n"
  "    uv = " FRAGMENT_SHADER_TEXTURE "(s_textureUV, v_texcoord).ra -\n"
  "        vec2(0.5, 0.5);\n"
  "    mediump float r,g,b,color;\n"
  "    r = y + 1.403 * uv.y;\n"
  "    g = y - 0.344 * uv.x - 0.714 * uv.y;\n"
  "    b = y + 1.770 * uv.x;\n"
  "    color = (r + g + b) / 3.0;\n"
  "    " FRAGMENT_SHADER_COLOR " = vec4(color,\n"
  "                                     color,\n"
  "                                     color,\n"
  "                                     1.0);\n"
  "  }\n";

// 原始片段着色器
//static const char kNV12FragmentShaderSource[] =
//  SHADER_VERSION
//  "precision mediump float;"
//  FRAGMENT_SHADER_IN " vec2 v_texcoord;\n"
//  "uniform lowp sampler2D s_textureY;\n"
//  "uniform lowp sampler2D s_textureUV;\n"
//  FRAGMENT_SHADER_OUT
//  "void main() {\n"
//  "    mediump float y;\n"
//  "    mediump vec2 uv;\n"
//  "    y = " FRAGMENT_SHADER_TEXTURE "(s_textureY, v_texcoord).r;\n"
//  "    uv = " FRAGMENT_SHADER_TEXTURE "(s_textureUV, v_texcoord).ra -\n"
//  "        vec2(0.5, 0.5);\n"
//  "    " FRAGMENT_SHADER_COLOR " = vec4(y + 1.403 * uv.y,\n"
//  "                                     y - 0.344 * uv.x - 0.714 * uv.y,\n"
//  "                                     y + 1.770 * uv.x,\n"
//  "                                     1.0);\n"
//  "  }\n";

@interface CustomTargetShader()

@property(nonatomic, assign) GLuint VBO;
@property(nonatomic, assign) GLuint VAO;
@property(nonatomic, assign) GLuint nv12Program;
@property(nonatomic, assign) GLuint i420Program;
@property(nonatomic, strong) EAGLContext *glContext;
/*Store current rotation and only upload new vertex data when rotation changes.*/
@property(nonatomic, assign) CustomVideoRotation currentRotation;
@property(nonatomic) GLuint frameBuffer;

@end

@implementation CustomTargetShader

/// glContext used for creating texture cache and should the same as the one which used for process pixel buffer. And the glContext will set value by CustomPixelBufferProcesser.
- (void)setGLContext:(EAGLContext *)glContext {
    _glContext = glContext;
    _frameBuffer = -1;
}

- (void)dealloc {
    glDeleteProgram(_nv12Program);
    glDeleteProgram(_i420Program);
    glDeleteBuffers(1, &_VBO);
    glDeleteVertexArrays(1, &_VAO);
    glDeleteFramebuffers(1, &_frameBuffer);
}

- (BOOL)createAndSetupI420Program {
  NSAssert(!_i420Program, @"I420 program already created");
    _i420Program = [CustomShaderUtil createProgramWithVertexShaderSource:kVertexShaderSource fragmentShaderSource:kI420FragmentShaderSource];
  if (!_i420Program) {
    return NO;
  }
  GLint ySampler = glGetUniformLocation(_i420Program, "s_textureY");
  GLint uSampler = glGetUniformLocation(_i420Program, "s_textureU");
  GLint vSampler = glGetUniformLocation(_i420Program, "s_textureV");

  if (ySampler < 0 || uSampler < 0 || vSampler < 0) {
    DLog(@"Failed to get uniform variable locations in I420 shader");
    glDeleteProgram(_i420Program);
    _i420Program = 0;
    return NO;
  }

  glUseProgram(_i420Program);
  glUniform1i(ySampler, kYTextureUnit);
  glUniform1i(uSampler, kUTextureUnit);
  glUniform1i(vSampler, kVTextureUnit);

  return YES;
}

/// 创建着色器程序，顶点着色器, 片段着色器，并且编译链接着色器.
- (BOOL)createAndSetupNV12Program {
    NSAssert(!_nv12Program, @"NV12 program already created");
    _nv12Program = [CustomShaderUtil createProgramWithVertexShaderSource:kVertexShaderSource fragmentShaderSource:kNV12FragmentShaderSource];
  
    if (!_nv12Program) {
        return NO;
    }
    
    GLint ySampler = glGetUniformLocation(_nv12Program, "s_textureY");
    GLint uvSampler = glGetUniformLocation(_nv12Program, "s_textureUV");

    if (ySampler < 0 || uvSampler < 0) {
        DLog(@"Failed to get uniform variable locations in NV12 shader");
        glDeleteProgram(_nv12Program);
        _nv12Program = 0;
        return NO;
    }

    glUseProgram(_nv12Program);
    glUniform1i(ySampler, kYTextureUnit);
    glUniform1i(uvSampler, kUvTextureUnit);

    return YES;
}

- (CVReturn)createBGRATextureCacheWithWidth:(int)width height:(int)height pixelBuffer:(CVPixelBufferRef *)pixelBuffer outTexture:(CVOpenGLESTextureRef *)outTexture textureCache:(CVOpenGLESTextureCacheRef *)textureCache {
    CVReturn ret = CVOpenGLESTextureCacheCreate(
        kCFAllocatorDefault, NULL,
        #if COREVIDEO_USE_EAGLCONTEXT_CLASS_IN_API
         _glContext,
        #else
        (__bridge void *)glContext,
        #endif
        NULL, textureCache);
    
    if (ret != kCVReturnSuccess) {
        return ret;
    }
    
    *pixelBuffer = [CustomPixelBufferUtils createEmptyPixelBuffer:kCVPixelFormatType_32BGRA targetSize:CGSizeMake(width, height)];
    
    ret = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, *textureCache, *pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, static_cast<GLsizei>(width), static_cast<GLsizei>(height), GL_BGRA, GL_UNSIGNED_BYTE, 0, outTexture);

    return ret;
}

- (BOOL)bindFrameBufferWithTexture: (GLuint)textureID width:(int)width height:(int)height {
    if (_frameBuffer == -1) {
        glGenFramebuffers(1, &_frameBuffer);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureID, 0);
    
    GLenum fboStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (fboStatus == GL_FRAMEBUFFER_UNSUPPORTED) {
        DLog(@"ERROR::FRAMEBUFFER:: Framebuffer unsupported");
        return NO;
    } else if (fboStatus != GL_FRAMEBUFFER_COMPLETE) {
        DLog(@"ERROR::FRAMEBUFFER:: Framebuffer is not complete!");
        return NO;
    }
    glViewport(0, 0, width, height);
    return YES;
}

- (void)bindTexture:(GLuint)textureID width:(int)width height:(int)height {
    glActiveTexture(GL_TEXTURE0);
    
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, static_cast<GLsizei>(width), static_cast<GLsizei>(height), 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
}

/// Callback for I420 frames. Each plane is given as a texture.
- (nullable CVPixelBufferRef)applyShadingForTextureWithWidth:(int)width height:(int)height orientation:(UIInterfaceOrientation)orientation yPlane:(GLuint)yPlane uPlane:(GLuint)uPlane vPlane:(GLuint)vPlane CF_RETURNS_RETAINED {
    
    CVPixelBufferRef pixelBuffer = NULL;
    CVOpenGLESTextureRef outTexture = NULL;
    CVOpenGLESTextureCacheRef textureCache = NULL;
    GLuint textureID = -1;
    
    // Create BGRA pixel buffer for FBO
    CVReturn ret = [self createBGRATextureCacheWithWidth:width height:height pixelBuffer:&pixelBuffer outTexture:&outTexture textureCache:&textureCache];
    
    if (ret != kCVReturnSuccess) {
        if (outTexture) {
            CFRelease(outTexture);
        }
        
        if (textureCache) {
            CFRelease(textureCache);
        }
        
        if (pixelBuffer) {
            CVPixelBufferRelease(pixelBuffer);
        }
        DLog(@"CVOpenGLESTextureCacheCreateTextureFromImage faild");
        return nil;
    } else {
        textureID = CVOpenGLESTextureGetName(outTexture);
        [self bindTexture:textureID width:width height:height];
        if (![self bindFrameBufferWithTexture:textureID width:width height:height]) {
            return nil;
        }
    }
    
    if (![self prepareVertexBufferWithRotation:[self convertOrientationFrom:orientation]]) {
        return nil;
    }
      
    if (!_i420Program && ![self createAndSetupI420Program]) {
        DLog(@"Failed to setup I420 program");
        return nil;
    }
      
    glUseProgram(_i420Program);
      
    glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kYTextureUnit));
    glBindTexture(GL_TEXTURE_2D, yPlane);
      
    glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kUTextureUnit));
    glBindTexture(GL_TEXTURE_2D, uPlane);
      
    glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kVTextureUnit));
    glBindTexture(GL_TEXTURE_2D, vPlane);

    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    if (textureID != -1) {
        glDeleteTextures(1, &textureID);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glFlush();
    
    if (outTexture) {
        CFRelease(outTexture);
    }

    if (textureCache) {
        CFRelease(textureCache);
    }
    
    CVPixelBufferRef targetPixelBuffer = [CustomPixelBufferUtils convertBGRAToI420:pixelBuffer];
    
    if (pixelBuffer) {
        CVPixelBufferRelease(pixelBuffer);
    }
    
    return targetPixelBuffer;
}

/// 应用着色器. Each plane is given as a texture.
- (nullable CVPixelBufferRef)applyShadingForTextureWithWidth:(int)width height:(int)height orientation:(UIInterfaceOrientation)orientation
                               yPlane:(GLuint)yPlane
                              uvPlane:(GLuint)uvPlane CF_RETURNS_RETAINED {
    CVPixelBufferRef pixelBuffer = NULL;
    CVOpenGLESTextureRef outTexture = NULL;
    CVOpenGLESTextureCacheRef textureCache = NULL;
    GLuint textureID = -1;
    
    // Create BGRA pixel buffer for FBO
    CVReturn ret = [self createBGRATextureCacheWithWidth:width height:height pixelBuffer:&pixelBuffer outTexture:&outTexture textureCache:&textureCache];
    
    if (ret != kCVReturnSuccess) {
        if (outTexture) {
            CFRelease(outTexture);
        }
        
        if (textureCache) {
            CFRelease(textureCache);
        }
        
        if (pixelBuffer) {
            CVPixelBufferRelease(pixelBuffer);
        }
        DLog(@"CVOpenGLESTextureCacheCreateTextureFromImage faild");
        return nil;
    } else {
        textureID = CVOpenGLESTextureGetName(outTexture);
        [self bindTexture:textureID width:width height:height];
        if (![self bindFrameBufferWithTexture:textureID width:width height:height]) {
            return nil;
        }
    }
  
    // 设置VAO,VBO并且上传顶点数据, FBO中的buffer方向不对, 通过纹理坐标来修正.
    if (![self prepareVertexBufferWithRotation:[self convertOrientationFrom:orientation]]) {
        return nil;
    }

    // 创建着色器程序，顶点着色器, 片段着色器，并且编译链接着色器.
    if (!_nv12Program && ![self createAndSetupNV12Program]) {
        DLog(@"Failed to setup shader");
        return nil;
    }
  
    // Render
    glUseProgram(_nv12Program);
    glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kYTextureUnit));
    glBindTexture(GL_TEXTURE_2D, yPlane);
    glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kUvTextureUnit));
    glBindTexture(GL_TEXTURE_2D, uvPlane);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    if (textureID != -1) {
        glDeleteTextures(1, &textureID);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glFlush();
    
    if (outTexture) {
        CFRelease(outTexture);
    }

    if (textureCache) {
        CFRelease(textureCache);
    }
    
    CVPixelBufferRef targetPixelBuffer = [CustomPixelBufferUtils convertBGRAToNV12:pixelBuffer];
    
    if (pixelBuffer) {
        CVPixelBufferRelease(pixelBuffer);
    }
    
    return targetPixelBuffer;
}

/// 设置VAO,VBO并且上传顶点数据
- (BOOL)prepareVertexBufferWithRotation:(CustomVideoRotation)rotation {
    if (!_VBO && ![CustomShaderUtil createVertexBuffer:&_VBO VAO:&_VAO]) {
        DLog(@"Failed to setup vertex buffer");
        return NO;
    }
    
    #if !TARGET_OS_IPHONE
    glBindVertexArray(_VAO);
    #endif
  
    glBindBuffer(GL_ARRAY_BUFFER, _VBO);
  
    if (!_currentRotation || rotation != _currentRotation) {
        _currentRotation = rotation;
        // 上传顶点数据,包括顶点坐标和纹理坐标数据
        [CustomShaderUtil setVertexDataWithRotation:_currentRotation];
    }
    return YES;
}

- (CustomVideoRotation)convertOrientationFrom:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationUnknown:
            return CustomVideoRotation_90;
        case UIInterfaceOrientationPortraitUpsideDown:
            return CustomVideoRotation_270;
        case UIInterfaceOrientationLandscapeLeft:
            return CustomVideoRotation_0;
        case UIInterfaceOrientationLandscapeRight:
            return CustomVideoRotation_180;
    }
    return CustomVideoRotation_90;
}

@end
