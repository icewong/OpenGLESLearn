//
//  GLViewController.m
//  OpenGLES_Draw_Sphere
//
//  Created by SkyLight on 2017/11/10.
//  Copyright © 2017年 xujie. All rights reserved.
//

#import "GLViewController.h"
#import "GLProgram.h"
#import <CoreMotion/CoreMotion.h>
#import "GLFingerRotation.h"
#import "GLMatrix.h"
#import "GLUtil.h"


#define MAX_OVERTURE 95.0
#define MIN_OVERTURE 25.0
#define DEFAULT_OVERTURE 45.0
#define ES_PI  (3.14159265f)
#define ROLL_CORRECTION ES_PI/2.0
#define FramesPerSecond 30
#define SphereSliceNum 200
#define SphereRadius 1.0
#define SphereScale 300



const GLfloat kColorConversion709[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};

// Uniform index.
enum {
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_Y,
    UNIFORM_UV,
    UNIFORM_COLOR_CONVERSION_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

typedef NS_ENUM(NSUInteger, GLModelTextureRotateType) {
    GLModelTextureRotateType0,
    GLModelTextureRotateType90,
    GLModelTextureRotateType180,
    GLModelTextureRotateType270,
};


@interface GLViewController ()
{
    GLuint mTextureIdOutput;
    GLuint mFrameBufferId;
    GLuint mRenderBufferId;
    GLint mOriginalFrameBufferId;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLProgram *program;
@property (strong, nonatomic) NSMutableArray *currentTouches;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) CMAttitude *referenceAttitude;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (assign, nonatomic) CGFloat overture;
@property (assign, nonatomic) CGFloat fingerRotationX;
@property (assign, nonatomic) CGFloat fingerRotationY;
@property (assign, nonatomic) CGFloat savedGyroRotationX;
@property (assign, nonatomic) CGFloat savedGyroRotationY;
@property (assign, nonatomic) int numIndices;
@property (assign, nonatomic) CVOpenGLESTextureRef lumaTexture;
@property (assign, nonatomic) CVOpenGLESTextureRef chromaTexture;
@property (assign, nonatomic) CVOpenGLESTextureCacheRef videoTextureCache;
@property (assign, nonatomic) GLKMatrix4 modelViewProjectionMatrix;
@property (assign, nonatomic) GLuint vertexIndicesBufferID;
@property (assign, nonatomic) GLuint vertexBufferID;
@property (assign, nonatomic) GLuint vertexTexCoordID;
@property (assign, nonatomic) GLuint vertexTexCoordAttributeIndex;
@property (assign, nonatomic, readwrite) BOOL isUsingMotion;
@property (nonatomic, assign) int index_count;
@property (nonatomic, assign) int vertex_count;
@property (strong, nonatomic) GLFingerRotation *fingerRotation;
@property (strong, nonatomic) GLMatrix *vrMatrix;
- (void)setupGL;
- (void)tearDownGL;
- (void)buildProgram;

@end

@implementation GLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.vrMatrix = [[GLMatrix alloc] init];
    // Do any additional setup after loading the view.
    self.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if(!self.context)
    {
        NSLog(@"Failed to create ES context");
    }
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.contentScaleFactor = [UIScreen mainScreen].scale;
    self.preferredFramesPerSecond = FramesPerSecond;
    self.overture = DEFAULT_OVERTURE;
    
    [self addGesture];
    [self setupGL];
    [self startDeviceMotion];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addGesture {
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:pinchRecognizer];
}


#pragma mark - GLKViewController Subclass
//As an alternative to implementing a glkViewControllerUpdate: method in a delegate, your subclass can provide an update method instead.
- (void)update {
    
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(self.overture), aspect, 0.1f, 400.0f);
    //projectionMatrix = GLKMatrix4Rotate(projectionMatrix, ES_PI, 1.0f, 0.0f, 0.0f);
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
//    float scale = [UIScreen mainScreen].scale;//SphereScale;
//    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, scale, scale, scale);
//    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.fingerRotationX);
//    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.fingerRotationY);
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -5.0f);
    if(self.isUsingMotion) {
        CMDeviceMotion *deviceMotion = self.motionManager.deviceMotion;
        if (deviceMotion != nil) {
            CMAttitude *attitude = deviceMotion.attitude;
            
            if (self.referenceAttitude != nil) {
                [attitude multiplyByInverseOfAttitude:self.referenceAttitude];
            } else {
                //NSLog(@"was nil : set new attitude", nil);
                self.referenceAttitude = deviceMotion.attitude;
            }
            
            float cRoll = -fabs(attitude.roll); // Up/Down landscape
            float cYaw = attitude.yaw;  // Left/ Right landscape
            float cPitch = attitude.pitch; // Depth landscape
            
            UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
            if (orientation == UIDeviceOrientationLandscapeRight ){
                cPitch = cPitch*-1; // correct depth when in landscape right
            }
            
            modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, cRoll); // Up/Down axis
            modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, cPitch);
            modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, cYaw);
            
            modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, ROLL_CORRECTION);
            
            modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.fingerRotationX);
            modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.fingerRotationY);
            
            self.savedGyroRotationX = cRoll + ROLL_CORRECTION + self.fingerRotationX;
            self.savedGyroRotationY = cPitch + self.fingerRotationY;
        }
    } else {
        //modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.fingerRotationX);
        modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.fingerRotationY);
    }
    
    self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    
    
//    GLKMatrix4 mViewMatrix = GLKMatrix4MakeLookAt(-2.0, 0.0, 0.0, -2.0, 0.0, -1.0, 0.0, 1.0, 0.0);
//    GLKMatrix4 matrix = GLKMatrix4Multiply(mViewMatrix, modelViewMatrix);
//    self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, matrix);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, GL_FALSE, self.modelViewProjectionMatrix.m);
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    //glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self refreshTexture];
    

    glClear(GL_COLOR_BUFFER_BIT);
    
//    GLKMatrix4 matrix;
//    BOOL success = [self.vrMatrix singleMatrixWithSize:rect.size matrix:&matrix fingerRotation:[GLFingerRotation fingerRotation]];
//
//    if (success)
//    {
//        //glViewport(rect.origin.x, rect.origin.y, CGRectGetWidth(rect), CGRectGetHeight(rect));
//
//       glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, GL_FALSE, self.modelViewProjectionMatrix.m);
//         glDrawElements(GL_TRIANGLES, self.numIndices, GL_UNSIGNED_SHORT, 0);
//
//    }
    
    glDrawElements(GL_TRIANGLES, self.numIndices, GL_UNSIGNED_SHORT, 0);
    //从数组数据渲染图元
    //glDrawElements(GL_LINE_LOOP, self.numIndices, GL_UNSIGNED_SHORT, 0);
    
}


- (void)refreshTexture
{
    [self texture:[UIImage imageNamed:@"earth-diffuse.jpg"]];
    
//    glActiveTexture(GL_TEXTURE1);
//    //载入纹理
//    glBindTexture(GL_TEXTURE_2D, _textureID);
//    //为当前程序对象指定Uniform变量的值,参数1代表使用的新值（GL_TEXTURE1）
//    glUniform1i(uniforms[UNIFORM_UV], 1);;
//    //[self createFrameBufferWidth:3840 height:1920];
}

- (void)refreshTexture11 {
    CVReturn err;
    CVPixelBufferRef pixelBuffer =[self pixelBufferFromCGImage:[UIImage imageNamed:@"earth-diffuse.jpg"].CGImage];
    if (pixelBuffer != nil) {
        GLsizei textureWidth = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
        GLsizei textureHeight = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);
        
        if (!self.videoTextureCache) {
            NSLog(@"No video texture cache");
            return;
        }
        
        [self cleanUpTextures];
        
        // Y-plane
        glActiveTexture(GL_TEXTURE0);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           self.videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RGBA,
                                                           textureWidth,
                                                           textureHeight,
                                                           GL_RGBA,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &_lumaTexture);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        
        glBindTexture(CVOpenGLESTextureGetTarget(self.lumaTexture), CVOpenGLESTextureGetName(self.lumaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // UV-plane.
        glActiveTexture(GL_TEXTURE1);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           self.videoTextureCache,
                                                           pixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RG_EXT,
                                                           textureWidth/2,
                                                           textureHeight/2,
                                                           GL_RG_EXT,
                                                           GL_UNSIGNED_BYTE,
                                                           1,
                                                           &_chromaTexture);
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(self.chromaTexture), CVOpenGLESTextureGetName(self.chromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        CFRelease(pixelBuffer);
    }
}




#pragma mark - Generate Sphere
int esGenSphere(int numSlices, float radius, float **vertices,
                float **texCoords, uint16_t **indices, int *numVertices_out) {
    
    int numParallels = numSlices / 2;//100
    int numVertices = (numParallels + 1) * (numSlices + 1);//101*201
    int numIndices = numParallels * numSlices * 6;//100 *201*101*6=
    float angleStep = (2.0f * ES_PI) / ((float) numSlices);
    
    if (vertices != NULL) {
        *vertices = malloc(sizeof(float) * 3 * numVertices);
    }
    
    if (texCoords != NULL) {
        *texCoords = malloc(sizeof(float) * 2 * numVertices);
    }
    
    if (indices != NULL) {
        *indices = malloc(sizeof(uint16_t) * numIndices);
    }
    
    //多少个同心圆
    for (int i = 0; i < numParallels + 1; i++) {
        for (int j = 0; j < numSlices + 1; j++) {
            int vertex = (i * (numSlices + 1) + j) * 3;
            
            if (vertices) {
                (*vertices)[vertex + 0] = radius * sinf(angleStep * (float)i) * sinf(angleStep * (float)j);
                (*vertices)[vertex + 1] = radius * cosf(angleStep * (float)i);
                (*vertices)[vertex + 2] = radius * sinf(angleStep * (float)i) * cosf(angleStep * (float)j);
            }
            
            if (texCoords) {
                int texIndex = (i * (numSlices + 1) + j) * 2;
                (*texCoords)[texIndex + 0] = (float)j / (float)numSlices;
                (*texCoords)[texIndex + 1] = 1.0f - ((float)i / (float)numParallels);
            }
        }
    }
    
    // Generate the indices
    if (indices != NULL) {
        uint16_t *indexBuf = (*indices);
        for (int i = 0; i < numParallels ; i++) {
            for (int j = 0; j < numSlices; j++) {
                *indexBuf++ = i * (numSlices + 1) + j;
                *indexBuf++ = (i + 1) * (numSlices + 1) + j;
                *indexBuf++ = (i + 1) * (numSlices + 1) + (j + 1);
                
                *indexBuf++ = i * (numSlices + 1) + j;
                *indexBuf++ = (i + 1) * (numSlices + 1) + (j + 1);
                *indexBuf++ = i * (numSlices + 1) + (j + 1);
            }
        }
    }
    
    if (numVertices_out) {
        *numVertices_out = numVertices;
    }
    
    return numIndices;
}


#pragma mark - Setup OpenGL

- (void)setupGL {
    [EAGLContext setCurrentContext:self.context];
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_GREATER);
    [self buildProgram];
    [self setupBuffers];
    [self setupVideoCache];
    [self.program use];
    glUniform1i(uniforms[UNIFORM_Y], 0);
    glUniform1i(uniforms[UNIFORM_UV], 1);
    glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, kColorConversion709);
}

- (void)setupBuffers {
    
    GLfloat *vVertices = NULL;
    GLfloat *vTextCoord = NULL;
    GLushort *indices = NULL;
    int numVertices = 0;
    self.numIndices = esGenSphere(SphereSliceNum, SphereRadius, &vVertices, &vTextCoord, &indices, &numVertices);
    
    self.index_count = (int)indices;
    self.vertex_count = (int)vVertices;
    //Indices 加载顶点索引数据
    glGenBuffers(1, &_vertexIndicesBufferID);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.vertexIndicesBufferID);// 将命名的缓冲对象绑定到指定的类型上去
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.numIndices*sizeof(GLushort), indices, GL_STATIC_DRAW);
    
    // Vertex 加载顶点坐标数据
    glGenBuffers(1, &_vertexBufferID);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBufferID);
    glBufferData(GL_ARRAY_BUFFER, numVertices*3*sizeof(GLfloat), vVertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);// 绑定到位置上
    //数据开始传入opengl
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*3, NULL);
    
    // Texture Coordinates 加载纹理坐标
        glGenBuffers(1, &_vertexTexCoordID);
        glBindBuffer(GL_ARRAY_BUFFER, self.vertexTexCoordID);
        glBufferData(GL_ARRAY_BUFFER, numVertices*2*sizeof(GLfloat), vTextCoord, GL_DYNAMIC_DRAW);
    
        glEnableVertexAttribArray(self.vertexTexCoordAttributeIndex);
        glVertexAttribPointer(self.vertexTexCoordAttributeIndex, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);
}

- (void)setupVideoCache {
    if (!self.videoTextureCache) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_videoTextureCache);
        if (err != noErr) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
            return;
        }
    }
}

#pragma mark - OpenGL Program

- (void)buildProgram {
    self.program = [[GLProgram alloc]
                    initWithVertexShaderFilename:@"Shader"
                    fragmentShaderFilename:@"Shader"];
    
    [self.program addAttribute:@"position"];
    [self.program addAttribute:@"texCoord"];
    
    if (![self.program link]) {
        self.program = nil;
        NSAssert(NO, @"Falied to link HalfSpherical shaders");
    }
    
    self.vertexTexCoordAttributeIndex = [self.program attributeIndex:@"texCoord"];
    
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = [self.program uniformIndex:@"modelViewProjectionMatrix"];
    uniforms[UNIFORM_Y] = [self.program uniformIndex:@"SamplerY"];
    uniforms[UNIFORM_UV] = [self.program uniformIndex:@"SamplerUV"];
    uniforms[UNIFORM_COLOR_CONVERSION_MATRIX] = [self.program uniformIndex:@"colorConversionMatrix"];
}



#pragma mark - Texture Cleanup

- (void)cleanUpTextures {
    if (self.lumaTexture) {
        CFRelease(_lumaTexture);
        self.lumaTexture = NULL;
    }
    
    if (self.chromaTexture) {
        CFRelease(_chromaTexture);
        self.chromaTexture = NULL;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}


#pragma mark - Device Motion

- (void)startDeviceMotion {
    self.isUsingMotion = NO;
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.referenceAttitude = nil;
    self.motionManager.deviceMotionUpdateInterval = 1.0 / 30.0;
    self.motionManager.gyroUpdateInterval = 1.0f / 30;
    NSOperationQueue* motionQueue = [[NSOperationQueue alloc] init];
    [self.motionManager setDeviceMotionUpdateInterval:1.0f / 30];
    self.motionManager.showsDeviceMovementDisplay = YES;
    
    [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
    
    self.referenceAttitude = self.motionManager.deviceMotion.attitude; // Maybe nil actually. reset it later when we have data
    
    self.savedGyroRotationX = 0;
    self.savedGyroRotationY = 0;
    
    self.isUsingMotion = YES;
}

- (void)stopDeviceMotion {
    self.fingerRotationX = self.savedGyroRotationX-self.referenceAttitude.roll- ROLL_CORRECTION;
    self.fingerRotationY = self.savedGyroRotationY;
    
    self.isUsingMotion = NO;
    [self.motionManager stopDeviceMotionUpdates];
    self.motionManager = nil;
}





#pragma mark - Touch Event

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if(self.isUsingMotion) return;
    for (UITouch *touch in touches) {
        [_currentTouches addObject:touch];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if(self.isUsingMotion) return;
    UITouch *touch = [touches anyObject];
    float distX = [touch locationInView:touch.view].x - [touch previousLocationInView:touch.view].x;
    float distY = [touch locationInView:touch.view].y - [touch previousLocationInView:touch.view].y;
    distX *= -0.005;
    distY *= -0.005;
    self.fingerRotationX += distY *  self.overture / 100;
    self.fingerRotationY -= distX *  self.overture / 100;
    
    NSLog(@"===self.fingerRotationX===%f",self.fingerRotationX);
    NSLog(@"===self.fingerRotationY===%f",self.fingerRotationY);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //if (self.isUsingMotion) return;
    for (UITouch *touch in touches) {
        [self.currentTouches removeObject:touch];
    }
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        [self.currentTouches removeObject:touch];
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer {
    self.overture /= recognizer.scale;
    
    if (self.overture > MAX_OVERTURE) {
        self.overture = MAX_OVERTURE;
    }
    
    if (self.overture < MIN_OVERTURE) {
        self.overture = MIN_OVERTURE;
    }
}



- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image)); // Not sure why this is even necessary, using CGImageGetWidth/Height in status/context seems to work fine too

    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width, frameSize.height, kCVPixelFormatType_32BGRA, nil, &pixelBuffer);
    if (status != kCVReturnSuccess) {
        return NULL;
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *data = CVPixelBufferGetBaseAddress(pixelBuffer);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(data, frameSize.width, frameSize.height, 8, CVPixelBufferGetBytesPerRow(pixelBuffer), rgbColorSpace, (CGBitmapInfo) kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);

    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    return pixelBuffer;
    
    
    /*
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           frameWidth,
                                           frameHeight),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
     */
}

- (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef {
    CVImageBufferRef imageBuffer =  pixelBufferRef;
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    
    CGImageRef cgImage = CGImageCreate(width, height, 8, 32, bytesPerRow, rgbColorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);
    
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(rgbColorSpace);
    
    //    NSData* imageData = UIImageJPEGRepresentation(image, 1.0);
    //    image = [UIImage imageWithData:imageData];
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return image;
}


- (void)bindPositionLocation:(GLint)position_location
        textureCoordLocation:(GLint)textureCoordLocation
           textureRotateType:(GLModelTextureRotateType)textureRotateType
{
//    // index
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.vertexIndicesBufferID);
//    glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.numIndices * sizeof(GLushort), self.index_count, GL_STATIC_DRAW);
//
//    // vertex
//    glBindBuffer(GL_ARRAY_BUFFER, _vertexBufferID);
//    glBufferData(GL_ARRAY_BUFFER, self.vertex_count * 3 * sizeof(GLfloat), vertex_buffer_data, GL_STATIC_DRAW);
//    glEnableVertexAttribArray(position_location);
//    glVertexAttribPointer(position_location, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
//
//    // texture coord
//    glBindBuffer(GL_ARRAY_BUFFER, self.texture_id);
//    glBufferData(GL_ARRAY_BUFFER, self.vertex_count * 2 * sizeof(GLfloat), texture_buffer_data, GL_DYNAMIC_DRAW);
//    glEnableVertexAttribArray(textureCoordLocation);
//    glVertexAttribPointer(textureCoordLocation, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);
}



- (void)dealloc {
    [self stopDeviceMotion];
    [self tearDownVideoCache];
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
}
- (void)tearDownGL {
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexIndicesBufferID);
    glDeleteBuffers(1, &_vertexBufferID);
    glDeleteBuffers(1, &_vertexTexCoordID);
    
    self.program = nil;
}

- (void)tearDownVideoCache {
    [self cleanUpTextures];
    
    CFRelease(_videoTextureCache);
    self.videoTextureCache = nil;
}


-(void)createFrameBufferWidth:(int)w height:(int)h
{
    if (mTextureIdOutput != 0) {
        glDeleteTextures(1, &mTextureIdOutput);
    }
    
    if (mRenderBufferId != 0) {
        glDeleteRenderbuffers(1, &mRenderBufferId);
    }
    
    if (mFrameBufferId != 0) {
        glDeleteFramebuffers(1, &mFrameBufferId);
    }
    
    
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &mOriginalFrameBufferId);
    
    //
    
    glGenFramebuffers(1, &mFrameBufferId);
    glBindFramebuffer(GL_FRAMEBUFFER, mFrameBufferId);
    [GLUtil glCheck:@"Multi Fish Eye frame buffer"];
    
    // renderer buffer
    glGenRenderbuffers(1, &mRenderBufferId);
    glBindRenderbuffer(GL_RENDERBUFFER, mRenderBufferId);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, w, h);
    [GLUtil glCheck:@"Multi Fish Eye renderer buffer"];
    
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &mTextureIdOutput);
    glBindTexture(GL_TEXTURE_2D, mTextureIdOutput);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    [GLUtil glCheck:@"Multi Fish Eye texture"];
    
    // attach
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, mTextureIdOutput, 0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, mRenderBufferId);
    [GLUtil glCheck:@"Multi Fish Eye attach"];
    
    // check
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Framebuffer is not complete: %d", status);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, mOriginalFrameBufferId);
    [GLUtil glCheck:@"Multi Fish Eye restore"];
}

-(void) texture:(UIImage*)image{
    
    if (image == nil) {
        return;
    }
     [GLUtil texImage2D:image];
    //dispatch_sync(dispatch_get_main_queue(), ^{
        // Bind to the texture in OpenGL
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, self.vertexTexCoordID);
        
        
//        // Set filtering
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
//
//        // for not mipmap
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//
//        // Load the bitmap into the bound texture.
//        [GLUtil texImage2D:image];
//        //glUniform1i(uniforms[UNIFORM_Y], 1);
//        //glUniform1i(self.program.mTextureUniformHandle[0], 1);
//
//        GLuint width = (GLuint)CGImageGetWidth(image.CGImage);
//        GLuint height = (GLuint)CGImageGetHeight(image.CGImage);
//        //[self.sizeContext updateTextureWidth:width height:height];
//    //});
}
@end
