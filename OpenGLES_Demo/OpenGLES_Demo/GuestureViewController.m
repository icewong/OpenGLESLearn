//
//  GuestureViewController.m
//  OpenGLES_Demo
//
//  Created by WangBing on 2018/2/2.
//  Copyright © 2018年 SkyLight. All rights reserved.
//

#import "GuestureViewController.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreMotion/CoreMotion.h>
#define kDevidCount 120

#define kLimitDegreeUpDown 80.0


typedef struct{
    GLfloat position[3];
    GLfloat texturePosition[2];
} Vertex;


@interface GuestureViewController ()

@property (nonatomic,strong)GLKBaseEffect * effect;

@property(nonatomic,assign)GLint degreeX;
@property(nonatomic,assign)GLint degreeY;

@end

@implementation GuestureViewController

{
    Vertex * _cirleVertex;
    GLuint * _vertextIndex;
    
    GLKMatrix4 _modelMatrix;
    
    GLuint _bufferVBO;
    GLuint _bufferIndexVBO;
    
    
    
    
    GLKMatrix4 _rotmatrix;
    GLKVector3 _anchor_position;
    GLKVector3 _current_position;
    
    GLKQuaternion _quatstart;
    GLKQuaternion _quat;
    
    
    CMMotionManager *_motionMgr;
    float t;
    float s;
    GLKQuaternion srcQuaternion;
    GLKQuaternion desQuaternion;
    GLKQuaternion curQuaternion;
    GLKMatrix4 _worldTrasform;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    _worldTrasform.m[0] = 0.0;
    _worldTrasform.m[1] = 0.0;
    _worldTrasform.m[2] =1.0;
    _worldTrasform.m[3] = 0.0;
    _worldTrasform.m[4] = 1.0;
    _worldTrasform.m[5] = 0.0;
    _worldTrasform.m[6] = 0.0;
    _worldTrasform.m[7] = 0.0;
    _worldTrasform.m[8] = 0.0;
    _worldTrasform.m[9] = 1.0;
    _worldTrasform.m[10] = 0.0;
    _worldTrasform.m[11] = 0.0;
    _worldTrasform.m[12] = 0.0;
    _worldTrasform.m[13] = 0.0;
    _worldTrasform.m[14] = 0.0;
    _worldTrasform.m[15] = 1.0;
    // Do any additional setup after loading the view.
    GLKView * glView = (GLKView *)self.view;
    EAGLContext * contex = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!contex) {
        NSLog(@"context创建失败");
    }
    if (![EAGLContext setCurrentContext:contex]) {
        NSLog(@"设置当前context失败");
    }
    
    
    
    _motionMgr = [[CMMotionManager alloc] init];
    _motionMgr.gyroUpdateInterval = 0.1;
    
    
    [_motionMgr startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXMagneticNorthZVertical toQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
        if(motion){
            CMRotationRate rotationRate = motion.rotationRate;
            double rotationX = rotationRate.x;
            double rotationY = rotationRate.y;
            double rotationZ = rotationRate.z;
            
            double value = rotationX * rotationX + rotationY * rotationY + rotationZ * rotationZ;
            
            // 防抖处理，阀值以下的朝向改变将被忽略
            if (value > 0.01) {
                CMAttitude *attitude = motion.attitude;
                t = 0.0f;
                s = 0.0f;

                // 从当前朝向以固定加速度像目标朝向进行四元数插值
                srcQuaternion = _quatstart;
                desQuaternion = GLKQuaternionNormalize(GLKQuaternionMake(attitude.quaternion.x, attitude.quaternion.y, attitude.quaternion.z, -attitude.quaternion.w));
            }
            
        }
    }];
    
    

    
    
    glView.context = contex;
    glView.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.useConstantColor = GL_TRUE;
    self.effect.constantColor = GLKVector4Make(0.8, 0.8, 0.8, 1.0);
    
    glEnable(GL_DEPTH_TEST);
    //[self setupLighting];
    [self setupTexture];
    [self setupBufferVBO];
    
    glClearColor(0.3, 0.3, 0.3, 1.0);
    
    // 设置视角和物体的矩阵变换
    GLfloat aspect = self.view.frame.size.width / self.view.frame.size.height;
    
    self.effect.transform.modelviewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -3);
    
    self.effect.transform.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(60), aspect, 0.1f, 10.0f);
    
    
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch * touch = touches.anyObject;
    CGPoint location = [touch locationInView:self.view];
    
    _anchor_position = GLKVector3Make(location.x, location.y, 0);
    _anchor_position = [self projectontosurface:_anchor_position];
    
    _current_position = _anchor_position;
    _quatstart = _quat;
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
//    UITouch * touch = touches.anyObject;
//    CGPoint currentPoint = [touch locationInView:self.view];
//    CGPoint previousPoint = [touch previousLocationInView:self.view];
//
//    self.degreeX += currentPoint.x - previousPoint.x;
//    self.degreeY += currentPoint.y - previousPoint.y;
//
//    // 限制上下转动的角度
//    if (self.degreeY > kLimitDegreeUpDown) {
//        self.degreeY = kLimitDegreeUpDown;
//    }
//
//    if (self.degreeY < -kLimitDegreeUpDown) {
//        self.degreeY = -kLimitDegreeUpDown;
//    }
    
    
    UITouch * touch = touches.anyObject;
    CGPoint location = [touch locationInView:self.view];
    CGPoint lastloc  = [touch previousLocationInView:self.view];
    CGPoint diff = CGPointMake(lastloc.x - location.x, lastloc.y - location.y);
    float rotx = -1 * GLKMathDegreesToRadians(diff.y / 2.0);
    float roty = -1 * GLKMathDegreesToRadians(diff.x / 2.0);
    
    BOOL isinvertible;
    GLKVector3 xaxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotmatrix, &isinvertible),
                                                 GLKVector3Make(1, 0, 0));
    _rotmatrix = GLKMatrix4Rotate(_rotmatrix, rotx, xaxis.x, xaxis.y, xaxis.z);
    GLKVector3 yaxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotmatrix, &isinvertible),
                                                 GLKVector3Make(0, 1, 0));
    _rotmatrix = GLKMatrix4Rotate(_rotmatrix, roty, yaxis.x, yaxis.y, yaxis.z);
    
    _current_position = GLKVector3Make(location.x, location.y, 0);
    _current_position = [self projectontosurface:_current_position];
    
    if (s <= 1) {
        t += 0.05;
        // 以固定初速度和加速度对原朝向和目标朝向进行插值
        // s = v0 *t + a * t * t / 2;
        curQuaternion = GLKQuaternionNormalize(GLKQuaternionSlerp(srcQuaternion, desQuaternion, s));
    }
}

- (GLKVector3) projectontosurface:(GLKVector3) touchpoint
{
    
    float radius = self.view.bounds.size.width/3;
    GLKVector3 center = GLKVector3Make(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 0);
    
    GLKVector3 p = GLKVector3Subtract(touchpoint, center);
    // flip the y-axis because pixel coords increase toward the bottom.
    p = GLKVector3Make(p.x, p.y * -1, p.z);
    
    float radius2 = radius * radius;
    float length2 = p.x*p.x + p.y*p.y;
    
    if (length2 <= radius2)
        p.z = sqrt(radius2 - length2);
    else
    {
//                p.x *= radius / sqrt(length2);
//                p.y *= radius / sqrt(length2);
//                p.z = 0;
        p.z = radius2 / (2.0 * sqrt(length2));
        float length = sqrt(length2 + p.z * p.z);
        p = GLKVector3DivideScalar(p, length);
    }
    return GLKVector3Normalize(p);
}
- (void)computeincremental {
    
    GLKVector3 axis = GLKVector3CrossProduct(_anchor_position, _current_position);
    float dot = GLKVector3DotProduct(_anchor_position, _current_position);
    float angle = acosf(dot);
    GLKQuaternion q_rot = GLKQuaternionMakeWithAngleAndVector3Axis(angle * 2, axis);
    q_rot = GLKQuaternionNormalize(q_rot);
    
    // todo: do something with q_rot...
    _quat = GLKQuaternionMultiply(q_rot, _quatstart);
    
}
/**
 设置纹理
 */
- (void)setupTexture{
    
    // 加载纹理图片
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];//GLKTextureLoaderOriginBottomLeft 纹理坐标系是相反的
    NSError * error;
    
    CGImageRef image = [UIImage imageNamed:@"earth-diffuse.jpg"].CGImage;
    GLKTextureInfo * textureInfo = [GLKTextureLoader textureWithCGImage:image options:options error:&error];
    
    // 设置纹理可用
    self.effect.texture2d0.enabled = GL_TRUE;
    // 传递纹理信息
    self.effect.texture2d0.name = textureInfo.name;
    self.effect.texture2d0.target = textureInfo.target;
}


/**
 设置顶点缓存VBO
 */
- (void)setupBufferVBO {
    
    // 获取球的顶点和索引
    _cirleVertex = [self getBallDevidNum:kDevidCount];
    _vertextIndex = [self getBallVertexIndex:kDevidCount];
    
    // 设置VBO
    glGenBuffers(1, &_bufferVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _bufferVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * (kDevidCount + 1) * (kDevidCount / 2 + 1), _cirleVertex, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_bufferIndexVBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _bufferIndexVBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLuint) * kDevidCount * (kDevidCount + 1), _vertextIndex, GL_STATIC_DRAW);
    
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)NULL);
    // 设置法线
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)NULL);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    
    
    // 设置纹理坐标
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLfloat *)NULL + 3);
    // 释放顶点数据
    free(_cirleVertex);
    free(_vertextIndex);
    
    
    _rotmatrix = GLKMatrix4Identity;
    _quat = GLKQuaternionMake(0, 0, 0, 1);
    _quatstart = GLKQuaternionMake(0, 0, 0, 1);
}

/**
 设置光照
 */
- (void)setupLighting{
    
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.position = GLKVector4Make(1.0, 0.8, 0.8, 0.0);
    
    self.effect.light0.ambientColor = GLKVector4Make(0.5, 0.5, 0.5, 1.0);
    self.effect.light0.diffuseColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
}


/**
 绘制一个圆环的顶点数组
 
 @param num 要多少个顶点
 @return 返回顶点数组
 */
- (Vertex *)getCirleDevidNum:(GLint) num{
    
    float delta = 2 * M_PI / num;
    float myScale = 0.5; // 半径
    float tempY;
    float tempX;
    
    Vertex * cirleVertex = malloc(sizeof(Vertex) * num);
    memset(cirleVertex, 0x00, sizeof(Vertex) * num);
    
    for (int i = 0; i < num; i++) {
        
        tempY = myScale * sin(delta * i);
        tempX = myScale * cos(delta * i);
        
        cirleVertex[i] = (Vertex){tempX, tempY, 0.0f};
    }
    return cirleVertex;
}



/**
 绘制一个球的顶点
 
 @param num 传入要生成的顶点的一层的个数（最后生成的顶点个数为 num * num）
 @return 返回生成后的顶点
 */
- (Vertex *)getBallDevidNum:(GLint) num{
    
    if (num % 2 == 1) {
        return 0;
    }
    
    GLfloat delta = 2 * M_PI / num; // 分割的份数
    GLfloat ballRaduis = 0.8; // 球的半径
    GLfloat pointZ;
    GLfloat pointX;
    GLfloat pointY;
    GLfloat textureY;
    GLfloat textureX;
    GLfloat textureYdelta = 1.0 / (num / 2);
    GLfloat textureXdelta = 1.0 / num;
    GLint layerNum = num / 2.0 + 1; // 层数
    GLint perLayerNum = num + 1; // 要让点再加到起点所以num + 1
    
    Vertex * cirleVertex = malloc(sizeof(Vertex) * perLayerNum * layerNum);
    memset(cirleVertex, 0x00, sizeof(Vertex) * perLayerNum * layerNum);
    
    // 层数
    for (int i = 0; i < layerNum; i++) {
        // 每层的高度(即pointY)，为负数让其从下向上创建
        pointY = -ballRaduis * cos(delta * i);
        
        // 每层的半径
        GLfloat layerRaduis = ballRaduis * sin(delta * i);
        // 每层圆的点,
        for (int j = 0; j < perLayerNum; j++) {
            // 计算
            pointX = layerRaduis * cos(delta * j);
            pointZ = layerRaduis * sin(delta * j);
            textureX = textureXdelta * j;
            textureY = textureYdelta * i;
            
            cirleVertex[i * perLayerNum + j] = (Vertex){pointX, pointY, pointZ, textureX, textureY};
        }
    }
    
    return cirleVertex;
}



- (GLuint *)getBallVertexIndex:(GLint)num{
    
    // 每层要多原点两次
    GLint sizeNum = sizeof(GLuint) * (num + 1) * (num + 1);
    
    GLuint * ballVertexIndex = malloc(sizeNum);
    memset(ballVertexIndex, 0x00, sizeNum);
    GLint layerNum = num / 2 + 1;
    GLint perLayerNum = num + 1; // 要让点再加到起点所以num + 1
    
    for (int i = 0; i < layerNum; i++) {
        
        
        if (i + 1 < layerNum) {
            
            for (int j = 0; j < perLayerNum; j++) {
                
                // i * perLayerNum * 2每层的下标是原来的2倍
                ballVertexIndex[(i * perLayerNum * 2) + (j * 2)] = i * perLayerNum + j;
                // 后一层数据
                ballVertexIndex[(i * perLayerNum * 2) + (j * 2 + 1)] = (i + 1) * perLayerNum + j;
            }
        } else {
            
            for (int j = 0; j < perLayerNum; j++) {
                // 后最一层数据单独处理
                ballVertexIndex[i * perLayerNum * 2 + j] = i * perLayerNum + j;
            }
        }
    }
    
    return ballVertexIndex;
}



- (void)update{
     [self computeincremental];
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -3.0f);
//    GLKMatrix4 rotation = GLKMatrix4MakeWithQuaternion(_quat);
    GLKMatrix4 rotation = GLKMatrix4MakeWithQuaternion(desQuaternion);
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, rotation);
    self.effect.transform.modelviewMatrix = modelViewMatrix;
//    _modelMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -3);
//
//    _modelMatrix = GLKMatrix4RotateX(_modelMatrix, GLKMathDegreesToRadians(self.degreeY % 360));
//
//    _modelMatrix = GLKMatrix4RotateY(_modelMatrix, GLKMathDegreesToRadians(self.degreeX % 360));
//
//    self.effect.transform.modelviewMatrix = _modelMatrix;
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.effect prepareToDraw];
    // 绘制一个圆环
    //glDrawArrays(GL_LINE_LOOP, 0, kDevidCount * (kDevidCount / 2));
    // 绘制一个圆
    //glDrawArrays(GL_TRIANGLE_FAN, 0, kDevidCount * (kDevidCount / 2));
    
    // 绘制一个球（用层表示）
    //glDrawArrays(GL_LINE_LOOP, 0, (kDevidCount + 1) * (kDevidCount / 2 + 1));
    
    // 绘制一个球
    glDrawElements(GL_TRIANGLE_STRIP, kDevidCount * (kDevidCount + 1), GL_UNSIGNED_INT, 0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
//根据摄像机的位置和朝向获得摄像机世界矩阵的逆矩阵
- (void)getViewMatrix:(GLfloat *)matrix
{
    GLfloat x = _orientation.x;
    GLfloat y = _orientation.y;
    GLfloat z = _orientation.z;
    GLfloat w = _orientation.w;
    GLfloat *rot = malloc(sizeof(GLfloat) * 16);
    rot[0] = 1-2*y*y-2*z*z;
    rot[1] = 2*x*y-2*w*z;
    rot[2] = 2*x*z+2*w*y;
    rot[3] = 0.0;
    rot[4] = 2*x*y+2*w*z;
    rot[5] = 1-2*x*2-2*z*z;
    rot[6] = 2*y*z-2*w*x;
    rot[7] = 0.0;
    rot[8] = 2*x*z-2*w*y;
    rot[9] = 2*y*z+2*w*z;
    rot[10] = 1-2*x*x-2*y*y;
    rot[11] = 0.0;
    rot[12] = 0;
    rot[13] = 0;
    rot[14] = 0;
    rot[15] = 1.0;
    
    GLfloat transX = -rot[0]*_position.x - rot[4]*_position.y - rot[8]*_position.z;
    GLfloat transY = -rot[1]*_position.x - rot[5]*_position.y - rot[9]*_position.z;
    GLfloat transZ = -rot[2]*_position.x - rot[6]*_position.y - rot[10]*_position.z;
    
    rot[12] = transX;
    rot[13] = transY;
    rot[14] = transZ;
    
    memcpy(matrix, rot, sizeof(GLfloat)*16);
    free(rot);
}
- (void)xxxxxTest
{
    GLfloat x = curQuaternion.x;
    GLfloat y = curQuaternion.y;
    GLfloat z = curQuaternion.z;
    GLfloat w = curQuaternion.w;
    _worldTrasform.m[0] = 1-2*y*y-2*z*z;
    _worldTrasform.m[1] = 2*x*y-2*w*z;
    _worldTrasform.m[2] = 2*x*z+2*w*y;
    _worldTrasform.m[3] = 0.0;
    _worldTrasform.m[4] = 2*x*y+2*w*z;
    _worldTrasform.m[5] = 1-2*x*2-2*z*z;
    _worldTrasform.m[6] = 2*y*z-2*w*x;
    _worldTrasform.m[7] = 0.0;
    _worldTrasform.m[8] = 2*x*z-2*w*y;
    _worldTrasform.m[9] = 2*y*z+2*w*z;
    _worldTrasform.m[10] = 1-2*x*x-2*y*y;
    _worldTrasform.m[11] = 0.0;
    _worldTrasform.m[12] = _position.x;
    _worldTrasform.m[13] = _position.y;
    _worldTrasform.m[14] = _position.z;
    _worldTrasform.m[15] = 1.0;
}
 */
@end
