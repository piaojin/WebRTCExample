//
//  ShaderUtils.swift
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/21.
//

import Foundation
import OpenGLES

// Vertex shader doesn't do anything except pass coordinates through.
let kRTCVertexShaderSource =
"""
SHADER_VERSION
VERTEX_SHADER_IN " vec2 position;\n"
VERTEX_SHADER_IN " vec2 texcoord;\n"
VERTEX_SHADER_OUT " vec2 v_texcoord;\n"
"void main() {\n"
"    gl_Position = vec4(position.x, position.y, 0.0, 1.0);\n"
"    v_texcoord = texcoord;\n"
"}\n
"""

enum VideoRotation: Int {
    case rotation0 = 0
    case rotation90 = 90
    case rotation180 = 180
    case rotation270 = 270
}

// Compiles a shader of the given |type| with GLSL source |source| and returns
// the shader handle or 0 on error.
@available(*, deprecated)
func createShader(type: GLenum, source: String) -> GLuint {
    var shader: GLuint = glCreateShader(type)
    if (shader == 0) {
        return 0
    }
    
//    string.withCString { (char: UnsafePointer<Int8>) in
//        var c: UnsafePointer<GLchar>? = char
//        glShaderSource(shader, 1, &c, nil)
//    }
    
    source.withCString { (char: UnsafePointer<CChar>) in
        var s: UnsafePointer<GLchar>? = char
        glShaderSource(shader, 1, &s, nil)
    }
    
    glCompileShader(shader)
    var compileStatus: GLint = GL_FALSE
    glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &compileStatus)
    if compileStatus == GL_FALSE {
        var logLength: GLint = 0
        glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        if logLength > 0 {
            var char: [GLchar] = [GLchar](repeating: 0, count: Int(logLength))
            glGetShaderInfoLog(shader, logLength, nil, &char)
            print("Shader compile error: \(char)")
        }
        glDeleteShader(shader)
        shader = 0
    }
    return shader
}

// Links a shader program with the given vertex and fragment shaders and
// returns the program handle or 0 on error.
@available(*, deprecated)
func createProgram(vertexShader: GLuint, fragmentShader: GLuint) -> GLuint {
    if vertexShader == 0 || fragmentShader == 0 {
      return 0
    }
    var program: GLuint = glCreateProgram()
    if program == 0 {
        return 0
    }
    glAttachShader(program, vertexShader)
    glAttachShader(program, fragmentShader)
    glLinkProgram(program)
    var linkStatus: GLint = GL_FALSE
    glGetProgramiv(program, GLenum(GL_LINK_STATUS), &linkStatus)
    if linkStatus == GL_FALSE {
        glDeleteProgram(program)
        program = 0
    }
    return program
}

// Creates and links a shader program with the given fragment shader source and
// a plain vertex shader. Returns the program handle or 0 on error.
@available(*, deprecated)
func createProgramFromFragmentSource(fragmentShaderSource: String) -> GLuint {
    let vertexShader: GLuint = createShader(type: GLenum(GL_VERTEX_SHADER), source: kRTCVertexShaderSource)
    if vertexShader == 0 {
        print("Failed to create vertex shader")
    }
    
    let fragmentShader: GLuint = createShader(type: GLenum(GL_FRAGMENT_SHADER), source: fragmentShaderSource)
    if fragmentShader == 0 {
        print("Failed to create fragment shader")
    }
    
    let program: GLuint = createProgram(vertexShader: vertexShader, fragmentShader: fragmentShader)
    
    // Shaders are created only to generate program.
    if vertexShader != 0 {
      glDeleteShader(vertexShader)
    }
    
    if fragmentShader != 0 {
      glDeleteShader(fragmentShader)
    }
    
    // Set vertex shader variables 'position' and 'texcoord' in program.
    let position: GLint = glGetAttribLocation(program, "position")
    let texcoord: GLint = glGetAttribLocation(program, "texcoord")
    if position < 0 || texcoord < 0 {
      glDeleteProgram(program)
      return 0;
    }
    
    // Read position attribute with size of 2 and stride of 4 beginning at the start of the array. The
    // last argument indicates offset of data within the vertex buffer.
    let pointer0offset = UnsafeRawPointer(bitPattern: 0)
    glVertexAttribPointer(GLuint(position), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(4 * MemoryLayout<GLfloat>.stride), pointer0offset)
    glEnableVertexAttribArray(GLuint(position))
    
    // Read texcoord attribute  with size of 2 and stride of 4 beginning at the first texcoord in the
    // array. The last argument indicates offset of data within the vertex buffer.
    let pointer1offset = UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.stride * 2)
    glVertexAttribPointer(
        GLuint(texcoord), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(4 * MemoryLayout<GLfloat>.stride), pointer1offset)
    glEnableVertexAttribArray(GLuint(texcoord))
    return program
}

@available(*, deprecated)
func createVertexBuffer(vertexBuffer: GLuint, vertexArray: GLuint) -> Bool {
    var vertexBuffer = vertexBuffer
    var vertexArray = vertexArray
#if !TARGET_OS_IPHONE
    glGenVertexArrays(1, &vertexArray)
    if vertexArray == 0 {
        return false
    }
    glBindVertexArray(vertexArray)
#endif
    glGenBuffers(1, &vertexBuffer)
    if (vertexBuffer == 0) {
        glDeleteVertexArrays(1, &vertexArray)
        return false
    }
    
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer);
    glBufferData(GLenum(GL_ARRAY_BUFFER), 4 * 4 * MemoryLayout<GLfloat>.stride, nil, GLenum(GL_DYNAMIC_DRAW));
    return true
}

// Set vertex data to the currently bound vertex buffer.
func setVertexData(videoRotation: VideoRotation) {
    
}
