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

// 最简单的灰度滤镜片段着色器: 原理 -> float color = (r + g + b) / 3.0 -> gl_FragColor = vec4(color,color,color,1.0)
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

@end

@implementation CustomTargetShader {
  // Store current rotation and only upload new vertex data when rotation changes.
  CustomVideoRotation _currentRotation;
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
    NSLog(@"Failed to get uniform variable locations in NV12 shader");
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
    NSLog(@"Failed to setup vertex buffer");
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
- (void)applyShadingForTextureWithRotation:(CustomVideoRotation)rotation
                               yPlane:(GLuint)yPlane
                              uvPlane:(GLuint)uvPlane {
  // 设置VAO,VBO并且上传顶点数据
  if (![self prepareVertexBufferWithRotation:rotation]) {
    return;
  }

  // 创建着色器程序，顶点着色器, 片段着色器，并且编译链接着色器.
  if (!_program && ![self createAndSetupProgram]) {
    NSLog(@"Failed to setup shader");
    return;
  }

  // 绘制
  glUseProgram(_program);

  glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kYTextureUnit));
  glBindTexture(GL_TEXTURE_2D, yPlane);

  glActiveTexture(static_cast<GLenum>(GL_TEXTURE0 + kUvTextureUnit));
  glBindTexture(GL_TEXTURE_2D, uvPlane);

  glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
}

@end
