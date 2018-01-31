//
//  GLViewController.h
//  OpenGLES_Draw_Sphere
//
//  Created by SkyLight on 2017/11/10.
//  Copyright © 2017年 xujie. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <UIKit/UIKit.h>
@interface GLViewController : GLKViewController<UIGestureRecognizerDelegate>

@property (assign, nonatomic, readonly) BOOL isUsingMotion;

- (void)startDeviceMotion;
- (void)stopDeviceMotion;

@end
