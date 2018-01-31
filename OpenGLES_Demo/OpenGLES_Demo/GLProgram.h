//
//  GLProgram.h
//  OpenGLES_Draw_Sphere
//
//  Created by SkyLight on 2017/11/10.
//  Copyright © 2017年 xujie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface GLProgram : NSObject

@property (nonatomic, strong) NSMutableArray *attributes;
@property (nonatomic, strong) NSMutableArray *uniforms;
@property (nonatomic, assign) GLuint vertShader;
@property (nonatomic, assign) GLuint fragShader;
@property (nonatomic, assign) GLuint program;

- (id)initWithVertexShaderString:(NSString *)vShaderString
            fragmentShaderString:(NSString *)fShaderString;
- (id)initWithVertexShaderFilename:(NSString *)vShaderFilename
            fragmentShaderFilename:(NSString *)fShaderFilename;
- (void)addAttribute:(NSString *)attributeName;
- (GLuint)attributeIndex:(NSString *)attributeName;
- (GLuint)uniformIndex:(NSString *)uniformName;
- (BOOL)link;
- (void)use;

@end
