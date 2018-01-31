//
//  GLUtil.m
//  OpenGLES_Demo
//
//  Created by WangBing on 2018/1/31.
//  Copyright © 2018年 SkyLight. All rights reserved.
//

#import "GLUtil.h"

@implementation GLUtil




+ (void)texImage2D:(UIImage*)image{
    assert(image!=nil);
    
    GLuint width = (GLuint)CGImageGetWidth(image.CGImage);
    GLuint height = (GLuint)CGImageGetHeight(image.CGImage);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc( height * width * 4 );
    CGContextRef context = CGBitmapContextCreate( imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
    CGColorSpaceRelease( colorSpace );
    CGContextClearRect( context, CGRectMake( 0, 0, width, height ) );
    CGContextDrawImage( context, CGRectMake( 0, 0, width, height ), image.CGImage );
    
    //glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    [GLUtil glCheck:@"texImage2D"];
    CGContextRelease(context);
    free(imageData);
}

+ (void) glCheck:(NSString*) msg{
    int error;
    while( (error = glGetError()) != GL_NO_ERROR ){
        NSString* desc;
        
        switch(error) {
            case GL_INVALID_OPERATION:      desc = @"INVALID_OPERATION";      break;
            case GL_INVALID_ENUM:           desc = @"INVALID_ENUM";           break;
            case GL_INVALID_VALUE:          desc = @"INVALID_VALUE";          break;
            case GL_OUT_OF_MEMORY:          desc = @"OUT_OF_MEMORY";          break;
            case GL_INVALID_FRAMEBUFFER_OPERATION:  desc = @"INVALID_FRAMEBUFFER_OPERATION";  break;
        }
        NSLog(@"************ glError:%@ *** %@",msg,desc);
    }
}


//+ (GLuint)createTextureWithImage:(UIImage *)image{
//    
//    //转换为CGImage，获取图片基本参数
//    CGImageRef cgImageRef = [image CGImage];
//    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
//    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
//    CGRect rect = CGRectMake(0, 0, width, height);
//    
//    //绘制图片
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    void *imageData = malloc(width * height * 4);
//    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmap　　　　ByteOrder32Big);
//    CGContextTranslateCTM(context, 0, height);
//    CGContextScaleCTM(context, 1.0f, -1.0f);
//    CGColorSpaceRelease(colorSpace);
//    CGContextClearRect(context, rect);
//    CGContextDrawImage(context, rect, cgImageRef);
//    //纹理一些设置，可有可无
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    
//    //生成纹理
//    glEnable(GL_TEXTURE_2D);
//    GLuint textureID;
//    glGenTextures(1, &textureID);
//    glBindTexture(GL_TEXTURE_2D, textureID);
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
//    
//    //绑定纹理位置
//    glBindTexture(GL_TEXTURE_2D, 0);
//    //释放内存
//    CGContextRelease(context);
//    free(imageData);
//    return textureID;
//}
@end
