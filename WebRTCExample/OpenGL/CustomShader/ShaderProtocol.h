//
//  ShaderProtocol.h
//  WebRTCExample
//
//  Created by rcadmin on 2021/12/27.
//

#ifndef ShaderProtocol_h
#define ShaderProtocol_h

#import <Foundation/Foundation.h>
#import "CustomTypes.h"

@protocol ShaderProtocol <NSObject>

@property(nonatomic, readonly) GLuint VBO;
@property(nonatomic, readonly) GLuint VAO;
@property(nonatomic, readonly) GLuint program;

- (void)applyShadingForTextureWithRotation:(CustomVideoRotation)rotation yPlane:(GLuint)yPlane uvPlane:(GLuint)uvPlane;

@end

#endif /* ShaderProtocol_h */
