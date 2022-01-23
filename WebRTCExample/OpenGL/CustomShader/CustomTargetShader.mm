//
//  CustomTargetShader.m
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/27.
//

#import "CustomTargetShader.h"
#import "CustomOpenGLDefines.h"
#import "CustomShader.h"
#import "CustomShaderUtil.h"
#import "CustomPixelBufferUtils.h"

static const int kYTextureUnit = 0;
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

// 简单的灰度滤镜片段着色器: 原理 -> float color = (r + g + b) / 3.0 -> gl_FragColor = vec4(color,color,color,1.0)
static const char kFragmentShaderSource[] =
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
//static const char kFragmentShaderSource[] =
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
@property(nonatomic, assign) GLuint program;
@property(nonatomic, strong) EAGLContext *glContext;
/*Store current rotation and only upload new vertex data when rotation changes.*/
@property(nonatomic, assign) CustomVideoRotation currentRotation;

@end

@implementation CustomTargetShader

/// glContext used for creating texture cache and should the same as the one which used for process pixel buffer. And the glContext will set value by CustomPixelBufferProcesser.
- (void)setGlContext:(EAGLContext *)glContext {
    _glContext = glContext;
}

- (void)dealloc {
    glDeleteProgram(_program);
    glDeleteBuffers(1, &_VBO);
    glDeleteVertexArrays(1, &_VAO);
}

/// 创建着色器程序，顶点着色器, 片段着色器，并且编译链接着色器.
- (BOOL)createAndSetupProgram {
    NSAssert(!_program, @"NV12 program already created");
    _program = [CustomShaderUtil createProgramWithVertexShaderSource:kVertexShaderSource fragmentShaderSource:kFragmentShaderSource];
  
    if (!_program) {
        return NO;
    }
    
    GLint ySampler = glGetUniformLocation(_program, "s_textureY");
    GLint uvSampler = glGetUniformLocation(_program, "s_textureUV");

    if (ySampler < 0 || uvSampler < 0) {
        DLog(@"Failed to get uniform variable locations in NV12 shader");
        glDeleteProgram(_program);
        _program = 0;
        return NO;
    }

    glUseProgram(_program);
    glUniform1i(ySampler, kYTextureUnit);
    glUniform1i(uvSampler, kUvTextureUnit);

    return YES;
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

/// 应用着色器. Each plane is given as a texture.
- (nullable CVPixelBufferRef)applyShadingForTextureWithRotation:(UIInterfaceOrientation)orientation
                               yPlane:(GLuint)yPlane
                              uvPlane:(GLuint)uvPlane textureSize:(CGSize)textureSize CF_RETURNS_RETAINED {
    // Create BGRA pixel buffer for FBO
    CVPixelBufferRef pixelBuffer = [CustomPixelBufferUtils createEmptyPixelBuffer:kCVPixelFormatType_32BGRA targetSize:textureSize];
    
    CVOpenGLESTextureRef outTexture = NULL;
    CVOpenGLESTextureCacheRef textureCache = NULL;
    GLuint frameBuffer;
    
    // TODO: textureCache && glContext 缓存起来
    CVReturn ret = CVOpenGLESTextureCacheCreate(
        kCFAllocatorDefault, NULL,
        #if COREVIDEO_USE_EAGLCONTEXT_CLASS_IN_API
         _glContext,
        #else
        (__bridge void *)glContext,
        #endif
        NULL, &textureCache);
    
    if (ret != kCVReturnSuccess) {
        DLog(@"CVOpenGLESTextureCacheCreate faild");
        return nil;
    }
    
    ret = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, static_cast<GLsizei>(textureSize.width), static_cast<GLsizei>(textureSize.height), GL_BGRA, GL_UNSIGNED_BYTE, 0, &outTexture);
    
    if (ret != kCVReturnSuccess) {
        if (outTexture) {
            CFRelease(outTexture);
        }
        
        if (textureCache) {
            CFRelease(textureCache);
        }
        DLog(@"CVOpenGLESTextureCacheCreateTextureFromImage faild");
        return nil;
    } else {
        // Set up texture and FBO
        GLuint targetTextureID = CVOpenGLESTextureGetName(outTexture);
        glActiveTexture(GL_TEXTURE0);
        
        glBindTexture(GL_TEXTURE_2D, targetTextureID);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, static_cast<GLsizei>(textureSize.width), static_cast<GLsizei>(textureSize.height), 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        
        // FBO
        glGenFramebuffers(1, &frameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, targetTextureID, 0);
        
        GLenum fboStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (fboStatus == GL_FRAMEBUFFER_UNSUPPORTED) {
            DLog(@"ERROR::FRAMEBUFFER:: Framebuffer unsupported");
        } else if (fboStatus != GL_FRAMEBUFFER_COMPLETE) {
            DLog(@"ERROR::FRAMEBUFFER:: Framebuffer is not complete!");
        }
        glViewport(0, 0, textureSize.width, textureSize.height);
    }
  
    // 设置VAO,VBO并且上传顶点数据, FBO中的buffer方向不对, 通过纹理坐标来修正.
    if (![self prepareVertexBufferWithRotation:[self convertOrientationFrom:orientation]]) {
        return nil;
    }

    // 创建着色器程序，顶点着色器, 片段着色器，并且编译链接着色器.
    if (!_program && ![self createAndSetupProgram]) {
        DLog(@"Failed to setup shader");
        return nil;
    }
  
    // Render
    glUseProgram(_program);
    glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kYTextureUnit));
    glBindTexture(GL_TEXTURE_2D, yPlane);
    glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kUvTextureUnit));
    glBindTexture(GL_TEXTURE_2D, uvPlane);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glDeleteFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glFlush();
    
    if (outTexture) {
        CFRelease(outTexture);
    }

    if (textureCache) {
        CFRelease(textureCache);
    }
    
    OSType pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    CVPixelBufferRef targetPixelBuffer = nil;
    if (pixelFormatType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        targetPixelBuffer = [CustomPixelBufferUtils convertBGRAToI420:pixelBuffer];
    } else {
        targetPixelBuffer = [CustomPixelBufferUtils convertBGRAToNV12:pixelBuffer];
    }
    
    if (pixelBuffer) {
        CVPixelBufferRelease(pixelBuffer);
    }
    
    return targetPixelBuffer;
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
