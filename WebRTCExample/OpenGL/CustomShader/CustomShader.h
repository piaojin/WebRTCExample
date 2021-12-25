//
//  CustomShader.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/22.
//

#import <WebRTC/RTCVideoFrame.h>

NS_ASSUME_NONNULL_BEGIN

RTC_EXTERN const char kRTCVertexShaderSource[];

RTC_EXTERN GLuint RTCCreateShader(GLenum type, const GLchar* source);
RTC_EXTERN GLuint RTCCreateProgram(GLuint vertexShader, GLuint fragmentShader);
RTC_EXTERN GLuint
RTCCreateProgramFromFragmentSource(const char fragmentShaderSource[_Nonnull]);
RTC_EXTERN BOOL RTCCreateVertexBuffer(GLuint* vertexBuffer,
                                      GLuint* vertexArray);
RTC_EXTERN void RTCSetVertexData(RTCVideoRotation rotation);

NS_ASSUME_NONNULL_END
