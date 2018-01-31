//
//  GLSensors.h
//  OpenGLES_Draw_Sphere
//
//  Created by SkyLight on 2017/11/13.
//  Copyright © 2017年 xujie. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface GLSensors : NSObject

@property (nonatomic, assign, readonly, getter=isReady) BOOL ready;

- (void)start;
- (void)stop;

- (GLKMatrix4)modelView;

@end
