//
//  GLMatrix.m
//  OpenGLES_Draw_Sphere
//
//  Created by SkyLight on 2017/11/13.
//  Copyright © 2017年 xujie. All rights reserved.
//

#import "GLMatrix.h"
#import "GLSensors.h"

@interface GLMatrix ()

@property (nonatomic, strong) GLSensors * sensors;

@end
@implementation GLMatrix

- (instancetype)init
{
    if (self = [super init]) {
        [self setupSensors];
    }
    return self;
}

#pragma mark - sensors

- (void)setupSensors
{
    self.sensors = [[GLSensors alloc] init];
    [self.sensors start];
    
}

- (BOOL)
singleMatrixWithSize:(CGSize)size matrix:(GLKMatrix4 *)matrix fingerRotation:(GLFingerRotation *)fingerRotation
{
    
    if (!self.sensors.isReady) return NO;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, -fingerRotation.x);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, self.sensors.modelView);
    
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, fingerRotation.y);
    
    float aspect = fabs(size.width / size.height);
    GLKMatrix4 mvpMatrix = GLKMatrix4Identity;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians([GLFingerRotation degress]), aspect, 0.1f, 400.0f);
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(0, 0, 0.0, 0, 0, -1000, 0, 1, 0);
    mvpMatrix = GLKMatrix4Multiply(projectionMatrix, viewMatrix);
    mvpMatrix = GLKMatrix4Multiply(mvpMatrix, modelViewMatrix);
    * matrix = mvpMatrix;
    
    return YES;
}

- (void)dealloc
{
    [self.sensors stop];
}

@end
