//
//  CustomShaderUtil.m
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/26.
//

#import "CustomShaderUtil.h"
#import "CustomOpenGLDefines.h"

@implementation CustomShaderUtil

/// Compiles a shader of the given |type| with GLSL source |source| and returns
/// the shader handle or 0 on error.
+ (GLuint) createShader:(GLenum)type source:(const GLchar *)source {
    GLuint shader = glCreateShader(type);
    if (!shader) {
        return 0;
    }
    
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);
    GLint compileStatus = GL_FALSE;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileStatus);
    
    if (compileStatus == GL_FALSE) {
      GLint logLength = 0;
      // The null termination character is included in the returned log length.
      glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
        
      if (logLength > 0) {
        GLchar infolog[logLength];
        // The returned string is null terminated.
        glGetShaderInfoLog(shader, logLength, NULL, infolog);
        DLog(@"Shader compile error: %s", infolog);
      }
        
      glDeleteShader(shader);
      shader = 0;
    }
    
    return shader;
}

/// Links a shader program with the given vertex and fragment shaders and
/// returns the program handle or 0 on error.
+ (GLuint) createProgramWithVertexShader:(GLuint)vertexShader fragmentShader:(GLuint)fragmentShader {
    if (vertexShader == 0 || fragmentShader == 0) {
        return 0;
    }
  
    GLuint program = glCreateProgram();
    if (!program) {
        return 0;
    }
  
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    GLint linkStatus = GL_FALSE;
    glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
  
    if (linkStatus == GL_FALSE) {
        GLint logLength = 0;
        // The null termination character is included in the returned log length.
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
        
        if (logLength > 0) {
            GLchar infolog[logLength];
            // The returned string is null terminated.
            glGetProgramInfoLog(program, logLength, NULL, infolog);
            DLog(@"Program compile and link error: %s", infolog);
        }
        
        glDeleteProgram(program);
        program = 0;
    }
    return program;
}

///e.g: 手机竖屏时的顶点数据,x,y是顶点坐标,u,v是纹理坐标.
///const GLfloat gVertices[] = {
///     X, Y, U, V.
///      -1, -1, 0, 1,
///       1, -1, 1, 1,
///       1,  1, 1, 0,
///      -1,  1, 0, 0,
///};
///
/// VBO
/// pos = position(x,y), tex = texcoord(u,v)
/// | pos1 | tex1 | pos2 | tex2 | pos3 | tex3 | pos4 | tex4 |
/// Creates and links a shader program with the given fragment shader source and
/// a plain vertex shader. Returns the program handle or 0 on error.
+ (GLuint) createProgramWithVertexShaderSource:(const char [])vertexShaderSource fragmentShaderSource:(const char [])fragmentShaderSource {
    GLuint vertexShader = [self createShader:GL_VERTEX_SHADER source:vertexShaderSource];
    GLuint fragmentShader = [self createShader:GL_FRAGMENT_SHADER source:fragmentShaderSource];
    GLuint program = [self createProgramWithVertexShader:vertexShader fragmentShader:fragmentShader];
    // Shaders are created only to generate program.
    if (vertexShader) {
        glDeleteShader(vertexShader);
    }
  
    if (fragmentShader) {
        glDeleteShader(fragmentShader);
    }

    // Set vertex shader variables 'position' and 'texcoord' in program.
    GLint position = glGetAttribLocation(program, "position");
    GLint texcoord = glGetAttribLocation(program, "texcoord");
  
    if (position < 0 || texcoord < 0) {
        glDeleteProgram(program);
        return 0;
    }

    // Read position attribute with size of 2 and stride of 4 beginning at the start of the array. The
    // last argument indicates offset of data within the vertex buffer.
    glVertexAttribPointer(position, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), (void *)0);
    glEnableVertexAttribArray(position);

    // Read texcoord attribute  with size of 2 and stride of 4 beginning at the first texcoord in the
    // array. The last argument indicates offset of data within the vertex buffer.
    glVertexAttribPointer(texcoord, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(GLfloat), (void *)(2 * sizeof(GLfloat)));
    glEnableVertexAttribArray(texcoord);
    return program;
}

/// Create VAB and VBO and bind them.
+ (BOOL) createVertexBuffer: (GLuint *)VBO VAO:(GLuint *)VAO {
#if !TARGET_OS_IPHONE
    glGenVertexArrays(1, VAO);
    if (*VAO == 0) {
        return NO;
    }
    glBindVertexArray(*VAO);
#endif
    // VBO
    glGenBuffers(1, VBO);
  
    if (*VBO == 0) {
        glDeleteVertexArrays(1, VAO);
        return NO;
    }
    glBindBuffer(GL_ARRAY_BUFFER, *VBO);
    glBufferData(GL_ARRAY_BUFFER, 4 * 4 * sizeof(GLfloat), NULL, GL_DYNAMIC_DRAW);
    return YES;
}

/// 上传顶点数据,包括顶点坐标和纹理坐标数据，纹理坐标包含纹理的方向,纹理方向也可以通过libyuv来后期旋转不过旋转后的buffer会花屏(还不知道原因)
/// Set vertex data to the currently bound vertex buffer.
+ (void) setVertexDataWithRotation:(CustomVideoRotation)rotation {
  // When modelview and projection matrices are identity (default) the world is
  // contained in the square around origin with unit size 2. Drawing to these
  // coordinates is equivalent to drawing to the entire screen. The texture is
  // stretched over that square using texture coordinates (u, v) that range
  // from (0, 0) to (1, 1) inclusive. Texture coordinates are flipped vertically
  // here because the incoming frame has origin in upper left hand corner but
  // OpenGL expects origin in bottom left corner.

  // Rotate the UV coordinates.
    NSInteger rotation_offset;
  switch (rotation) {
    case CustomVideoRotation_0:
      rotation_offset = 2;
      break;
    case CustomVideoRotation_90:
      rotation_offset = 0;
      break;
    case CustomVideoRotation_180:
      rotation_offset = 2;
      break;
    case CustomVideoRotation_270:
      rotation_offset = 1;
      break;
  }
    
    NSMutableArray<NSArray<NSNumber *> *> *uvCoords = [NSMutableArray arrayWithObjects:
                                                         @[@(0), @(1)],
                                                         @[@(1), @(1)],
                                                         @[@(1), @(0)],
                                                         @[@(0), @(0)], nil];
    
    NSMutableArray<NSArray<NSNumber *> *> *tempuvCoords = [NSMutableArray arrayWithObjects:
                                                           [NSNull null],
                                                           [NSNull null],
                                                           [NSNull null],
                                                           [NSNull null], nil];

    for (NSInteger i = 0; i < uvCoords.count; i++) {
        NSInteger tempIndex = i - rotation_offset % uvCoords.count;
        if (tempIndex < 0) {
            tempIndex = tempIndex + uvCoords.count;
        }
        tempuvCoords[tempIndex] = uvCoords[i];
    }
    
  const GLfloat gVertices[] = {
      // X, Y, U, V.
      -1, -1, static_cast<GLfloat>([tempuvCoords[0][0] intValue]), static_cast<GLfloat>([tempuvCoords[0][1] intValue]),
       1, -1, static_cast<GLfloat>([tempuvCoords[1][0] intValue]), static_cast<GLfloat>([tempuvCoords[1][1] intValue]),
       1,  1, static_cast<GLfloat>([tempuvCoords[2][0] intValue]), static_cast<GLfloat>([tempuvCoords[2][1] intValue]),
      -1,  1, static_cast<GLfloat>([tempuvCoords[3][0] intValue]), static_cast<GLfloat>([tempuvCoords[3][1] intValue]),
  };
    
    /*
     e.g: 手机竖屏时
     const GLfloat gVertices[] = {
          X, Y, U, V.
           -1, -1, 0, 1,
            1, -1, 1, 1,
            1,  1, 1, 0,
           -1,  1, 0, 0,
     };
     */
  glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(gVertices), gVertices);
}

@end
