//
//  GLFingerRotation.m
//  OpenGLES_Draw_Sphere
//
//  Created by SkyLight on 2017/11/13.
//  Copyright © 2017年 xujie. All rights reserved.
//

#import "GLFingerRotation.h"

@implementation GLFingerRotation


+ (instancetype)fingerRotation
{
    return [[self alloc] init];
}

+ (CGFloat)degress
{
    return 60.0;
}

- (void)clean
{
    self.x = 0;
    self.y = 0;
}
@end
