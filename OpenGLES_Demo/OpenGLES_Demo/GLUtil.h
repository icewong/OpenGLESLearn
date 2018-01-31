//
//  GLUtil.h
//  OpenGLES_Demo
//
//  Created by WangBing on 2018/1/31.
//  Copyright © 2018年 SkyLight. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>
@interface GLUtil : NSError
+ (void)texImage2D:(UIImage*)image;
+ (void) glCheck:(NSString*) msg;
@end
