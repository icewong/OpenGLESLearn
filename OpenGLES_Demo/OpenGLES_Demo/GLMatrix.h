//
//  GLMatrix.h
//  OpenGLES_Draw_Sphere
//
//  Created by SkyLight on 2017/11/13.
//  Copyright © 2017年 xujie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLFingerRotation.h"
@interface GLMatrix : NSObject

- (BOOL)singleMatrixWithSize:(CGSize)size matrix:(GLKMatrix4 *)matrix fingerRotation:(GLFingerRotation *)fingerRotation;

@end
