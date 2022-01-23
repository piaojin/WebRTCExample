//
//  CustomDefaultShader.m
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/23.
//

#import "CustomDefaultShader.h"

#if TARGET_OS_IPHONE
#import <OpenGLES/ES3/gl.h>
#else
#import <OpenGL/gl3.h>
#endif

#import "CustomOpenGLDefines.h"
#import "CustomShader.h"
#import <WebRTC/RTCLogging.h>

#include "absl/types/optional.h"

static const int kYTextureUnit = 0;
static const int kUTextureUnit = 1;
static const int kVTextureUnit = 2;
static const int kUvTextureUnit = 1;

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

// 最简单的灰度滤镜片段着色器: 原理 -> float color = (r + g + b) / 3.0 -> gl_FragColor = vec4(color,color,color,1.0)
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
//  "    mediump float r,g,b,color;\n"
//  "    r = y + 1.403 * uv.y;\n"
//  "    g = y - 0.344 * uv.x - 0.714 * uv.y;\n"
//  "    b = y + 1.770 * uv.x;\n"
//  "    color = (r + g + b) / 3.0;\n"
//  "    " FRAGMENT_SHADER_COLOR " = vec4(color,\n"
//  "                                     color,\n"
//  "                                     color,\n"
//  "                                     1.0);\n"
//  "  }\n";

// 原始片段着色器
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
  "    " FRAGMENT_SHADER_COLOR " = vec4(y + 1.403 * uv.y,\n"
  "                                     y - 0.344 * uv.x - 0.714 * uv.y,\n"
  "                                     y + 1.770 * uv.x,\n"
  "                                     1.0);\n"
  "  }\n";


@implementation CustomDefaultShader {
  GLuint _VBO;
  GLuint _VAO;
  // Store current rotation and only upload new vertex data when rotation changes.
  absl::optional<RTCVideoRotation> _currentRotation;

  GLuint _i420Program;
  GLuint _nv12Program;
}

- (void)dealloc {
  glDeleteProgram(_i420Program);
  glDeleteProgram(_nv12Program);
  glDeleteBuffers(1, &_VBO);
  glDeleteVertexArrays(1, &_VAO);
}

- (BOOL)createAndSetupI420Program {
  NSAssert(!_i420Program, @"I420 program already created");
  _i420Program = RTCCreateProgramFromFragmentSource(kI420FragmentShaderSource);
  if (!_i420Program) {
    return NO;
  }
  GLint ySampler = glGetUniformLocation(_i420Program, "s_textureY");
  GLint uSampler = glGetUniformLocation(_i420Program, "s_textureU");
  GLint vSampler = glGetUniformLocation(_i420Program, "s_textureV");

  if (ySampler < 0 || uSampler < 0 || vSampler < 0) {
    RTCLog(@"Failed to get uniform variable locations in I420 shader");
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

// 创建着色器程序，顶点着色器, 片段着色器，并且编译链接着色器.
- (BOOL)createAndSetupNV12Program {
  NSAssert(!_nv12Program, @"NV12 program already created");
  _nv12Program = RTCCreateProgramFromFragmentSource(kNV12FragmentShaderSource);
  if (!_nv12Program) {
    return NO;
  }
  GLint ySampler = glGetUniformLocation(_nv12Program, "s_textureY");
  GLint uvSampler = glGetUniformLocation(_nv12Program, "s_textureUV");

  if (ySampler < 0 || uvSampler < 0) {
    RTCLog(@"Failed to get uniform variable locations in NV12 shader");
    glDeleteProgram(_nv12Program);
    _nv12Program = 0;
    return NO;
  }

  glUseProgram(_nv12Program);
  glUniform1i(ySampler, kYTextureUnit);
  glUniform1i(uvSampler, kUvTextureUnit);

  return YES;
}

// 设置VAO,VBO并且上传顶点数据
- (BOOL)prepareVertexBufferWithRotation:(RTCVideoRotation)rotation {
  if (!_VBO && !RTCCreateVertexBuffer(&_VBO, &_VAO)) {
    RTCLog(@"Failed to setup vertex buffer");
    return NO;
  }
#if !TARGET_OS_IPHONE
  glBindVertexArray(_VAO);
#endif
  glBindBuffer(GL_ARRAY_BUFFER, _VBO);
  if (!_currentRotation || rotation != *_currentRotation) {
    _currentRotation = absl::optional<RTCVideoRotation>(rotation);
    // 上传顶点数据,包括顶点坐标和纹理坐标数据
    RTCSetVertexData(*_currentRotation);
  }
  return YES;
}

- (void)applyShadingForFrameWithWidth:(int)width
                               height:(int)height
                             rotation:(RTCVideoRotation)rotation
                               yPlane:(GLuint)yPlane
                               uPlane:(GLuint)uPlane
                               vPlane:(GLuint)vPlane {
  if (![self prepareVertexBufferWithRotation:rotation]) {
    return;
  }

  if (!_i420Program && ![self createAndSetupI420Program]) {
    RTCLog(@"Failed to setup I420 program");
    return;
  }

  glUseProgram(_i420Program);

  glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kYTextureUnit));
  glBindTexture(GL_TEXTURE_2D, yPlane);

  glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kUTextureUnit));
  glBindTexture(GL_TEXTURE_2D, uPlane);

  glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kVTextureUnit));
  glBindTexture(GL_TEXTURE_2D, vPlane);

  glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
}

// 应用着色器
- (void)applyShadingForFrameWithWidth:(int)width
                               height:(int)height
                             rotation:(RTCVideoRotation)rotation
                               yPlane:(GLuint)yPlane
                              uvPlane:(GLuint)uvPlane {
  // 设置VAO,VBO并且上传顶点数据
  if (![self prepareVertexBufferWithRotation:rotation]) {
    return;
  }

  // 创建着色器程序，顶点着色器, 片段着色器，并且编译链接着色器.
  if (!_nv12Program && ![self createAndSetupNV12Program]) {
    RTCLog(@"Failed to setup NV12 shader");
    return;
  }

  // 绘制
  glUseProgram(_nv12Program);

  glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kYTextureUnit));
  glBindTexture(GL_TEXTURE_2D, yPlane);

  glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kUvTextureUnit));
  glBindTexture(GL_TEXTURE_2D, uvPlane);

  glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
}

@end
