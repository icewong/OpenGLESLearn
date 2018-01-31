//
//  GLFingerRotation.h
//  OpenGLES_Draw_Sphere
//
//  Created by SkyLight on 2017/11/13.
//  Copyright © 2017年 xujie. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface GLFingerRotation : NSObject

+ (instancetype)fingerRotation;

+ (CGFloat)degress;

@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;

- (void)clean;

@end
