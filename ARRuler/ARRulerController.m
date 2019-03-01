//
//  ARRulerController.m
//  ARRuler
//
//  Created by 国信 on 2019/2/22.
//  Copyright © 2019年 国信. All rights reserved.
//

#import "ARRulerController.h"
#import "ARLine.h"
#import <Vision/Vision.h>
#import "ARDisplayVC.h"
@interface ARRulerController ()<ARSCNViewDelegate,ARSessionDelegate>

@property (nonatomic,strong) ARSession *arSession;

@property (nonatomic,strong) ARWorldTrackingConfiguration *arSessionConfiguration;

@property (nonatomic,assign) SCNVector3 vectorZero;

@property (nonatomic,assign) SCNVector3 vectorStart;

@property (nonatomic,assign) SCNVector3 vectorStop;

@property (nonatomic,strong) ARLine *currentLine;

@property (nonatomic,strong) NSMutableArray *arLines;

@property (nonatomic,assign) BOOL isMuseing;

@property (nonatomic,strong) NSMutableArray *rectNodesArr;
@property (nonatomic,strong) NSDate *lastUpdate;
@property (nonatomic,strong) NSMutableArray *rectLines;
@property (nonatomic,strong) UIImage *currentImage;
@property (nonatomic,strong) VNRectangleObservation *currentObservation;
@property (nonatomic,assign) CGRect *currentRect;
@property (nonatomic,assign) CGPoint sizePoint;

@end

@implementation ARRulerController

-(ARSCNView *)scnView{
    if (_scnView == nil) {
        _scnView = [[ARSCNView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    }
    return _scnView;
}

-(UILabel *)infoLabel{
    if (_infoLabel == nil) {
        _infoLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, 40)];
        
    }
    return _infoLabel;
}

-(UIImageView *)addView{
    if (_addView == nil) {
        _addView = [[UIImageView alloc]initWithFrame:CGRectMake((self.view.bounds.size.width-30)/2, (self.view.bounds.size.height-30)/2, 30, 30)];
        [_addView setImage:[UIImage imageNamed:@"WhiteImage"]];
    }
    return _addView;
}

-(UIButton *)resetBtn{
    if (_resetBtn == nil) {
        _resetBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, self.view.bounds.size.height-50, 150, 50)];
        [_resetBtn setTitle:@"清除" forState:UIControlStateNormal];
        [_resetBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    }
    return _resetBtn;
}

#pragma mark Getter

-(ARSession *)arSession{
    if (_arSession == nil) {
        _arSession = [[ARSession alloc] init];
        _arSession.delegate = self;
    }
    return _arSession;
}

-(NSMutableArray *)arLines{
    if (_arLines == nil) {
        _arLines = [NSMutableArray array];
    }
    return _arLines;
}
-(ARWorldTrackingConfiguration *)arSessionConfiguration{
    if (_arSessionConfiguration == nil) {
        
        _arSessionConfiguration = [[ARWorldTrackingConfiguration alloc] init];
        
        _arSessionConfiguration.planeDetection = ARPlaneDetectionHorizontal;
        
        _arSessionConfiguration.lightEstimationEnabled = YES;
        
    }
    return _arSessionConfiguration;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self addSubView];
    self.scnView.delegate = self;
    self.scnView.showsStatistics = YES;
    self.scnView.autoenablesDefaultLighting = YES;
    self.scnView.session = self.arSession;
    self.vectorZero = SCNVector3Zero;
    
    [self.resetBtn addTarget:self action:@selector(resetBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    _rectNodesArr = [NSMutableArray new];
    _lastUpdate = [NSDate date];
    _rectLines = [NSMutableArray new];
    
}

-(void)resetBtnClick:(UIButton *)btn{
    for (ARLine *line in self.arLines) {
        [line remove];
    }
    [self.arLines removeAllObjects];
}

-(void)addSubView{
    [self.view addSubview:self.scnView];
    [self.infoLabel setTextAlignment:NSTextAlignmentCenter];
    [self.infoLabel setText:@"系统初始化中..."];
    [self.view addSubview:self.infoLabel];
    [self.view addSubview:self.resetBtn];
    [self.view addSubview:self.addView];
}
- (void)addTakePhotoButton{
    
    UIButton *but = [UIButton new];
    but.frame = CGRectMake(0, 0, 60, 60);
    but.backgroundColor = [UIColor whiteColor];
    but.layer.cornerRadius = 30;
    but.layer.masksToBounds = YES;
    but.clipsToBounds = YES;
    [but addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
    but.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - 50);
    [self.view addSubview:but];
}

-(void)takePhoto{
    [self.arSession pause];
    [self startRequestDetectRectangles:self.currentImage finsh:^(UIImage *image) {
        if(!image){
            return ;
        }
        NSMutableArray *marr = [@[image] mutableCopy];
        ARDisplayVC *vc= [[ARDisplayVC alloc]initWithImages:marr];
        [self presentViewController:vc animated:YES completion:^{
            
        }];
    }];
//   UIImage *image = [self extractPerspectiveRect:self.currentObservation from:self.currentImage.CGImage];
//    NSMutableArray *marr = [@[image] mutableCopy];
//    ARDisplayVC *vc= [[ARDisplayVC alloc]initWithImages:marr];
//    [self presentViewController:vc animated:YES completion:^{
//
//    }];
}



- (UIImage *)extractPerspectiveRect:(VNRectangleObservation *)observation from:(CGImageRef)cgImage{
    // get the pixel buffer into Core Image
    CIImage *ciImage = [CIImage imageWithCGImage:cgImage];
    
    // convert corners from normalized image coordinates to pixel coordinates
    CGPoint topLeft = CGPointMake(observation.topLeft.x * ciImage.extent.size.width, observation.topLeft.y * ciImage.extent.size.height); //observation.topLeft.scaled(to: ciImage.extent.size)
    CGPoint topRight = CGPointMake(observation.topRight.x * ciImage.extent.size.width, observation.topRight.y * ciImage.extent.size.height);//observation.topRight.scaled(to: ciImage.extent.size)
    CGPoint bottomLeft = CGPointMake(observation.bottomLeft.x * ciImage.extent.size.width, observation.bottomLeft.y * ciImage.extent.size.height);//observation.bottomLeft.scaled(to: ciImage.extent.size)
    CGPoint bottomRight = CGPointMake(observation.bottomRight.x * ciImage.extent.size.width, observation.bottomRight.y * ciImage.extent.size.height);//observation.bottomRight.scaled(to: ciImage.extent.size)
    
    // pass those to the filter to extract/rectify the image
    NSLog(@"%@@" ,observation.description);
   
    CIImage *ciimage = [ciImage imageByApplyingFilter:@"CIPerspectiveCorrection"
                                  withInputParameters:@{
                                                        @"inputTopLeft":  [CIVector vectorWithCGPoint:topLeft],
                                                        
                                                        @"inputTopRight":  [CIVector vectorWithCGPoint:topRight],
                                                        
                                                        @"inputBottomLeft":  [CIVector vectorWithCGPoint:bottomLeft],
                                                        
                                                        @"inputBottomRight":  [CIVector vectorWithCGPoint:bottomRight]
                                                        
                                                        }];
    
    CIContext *context = [[CIContext alloc]init];
    
    return [UIImage imageWithCGImage:[context createCGImage:ciimage fromRect:ciimage.extent]];
//    return ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
//                                                                          "inputTopLeft": CIVector(cgPoint: topLeft),
//                                                                          "inputTopRight": CIVector(cgPoint: topRight),
//                                                                          "inputBottomLeft": CIVector(cgPoint: bottomLeft),
//                                                                          "inputBottomRight": CIVector(cgPoint: bottomRight),
//                                                                          ]
//                                  )
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.arSession runWithConfiguration:self.arSessionConfiguration options:ARSessionRunOptionRemoveExistingAnchors];
    [self addTakePhotoButton];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.arSession pause];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    return;
    if (!self.isMuseing) {
        self.isMuseing = YES;
        self.vectorStart = SCNVector3Zero;
        self.vectorStop = SCNVector3Zero;
        self.addView.image = [UIImage imageNamed:@"GreenImage"];
    }else{
        self.addView.image = [UIImage imageNamed:@"WhiteImage"];
        self.isMuseing = NO;
        if (self.currentLine) {
            [self.arLines addObject:self.currentLine];
            self.currentLine = nil ;
        }
    }
}
- (CGRect) boundingBox:(CGRect)boundingBox imageRect:(CGRect)bounds{
    
    CGFloat imageWidth = bounds.size.width;
    CGFloat imageHeight = bounds.size.height;
    
    // Begin with input rect.
    CGRect rect = boundingBox;
    
    // Reposition origin.
    rect.origin.x *= imageWidth;
    rect.origin.x += bounds.origin.x;
    rect.origin.y = (1 - rect.origin.y) * imageHeight + bounds.origin.y;
    
    // Rescale normalized coordinates.
    rect.size.width *= imageWidth;
    rect.size.height *= imageHeight;
    
    // Change the size to make it square.
    CGFloat diff = fabs(rect.size.height - rect.size.width);
    if (rect.size.width > rect.size.height) {
        rect.size.height = rect.size.width;
        rect.origin.y = rect.origin.y + (diff / 2);
    } else {
        rect.size.width = rect.size.height;
        rect.origin.x = rect.origin.x - (diff / 2);
    }
    
    return rect;
}

- (UIImage *)imageRotatedByImages:(UIImage *)image degrees:(CGFloat)degrees {

    // Calculate the size of the rotated view's containing box for our drawing space

    CGRect rotatedViewBoxFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    UIView *rotatedViewBox = [[UIView alloc]initWithFrame:rotatedViewBoxFrame];//UIView(frame: rotatedViewBoxFrame)
    //let transform = CGAffineTransform(rotationAngle: degrees * .pi / 180)
    CGAffineTransform transform =  CGAffineTransformMakeRotation(degrees * M_PI / 180);//CGAffineTransformRotate(rotatedViewBox.transform, degrees * M_PI / 180);
    rotatedViewBox.transform = transform;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    if(bitmap == NULL){
        UIGraphicsEndImageContext();
    }
    CGContextTranslateCTM(bitmap, rotatedSize.width / 2, rotatedSize.height / 2);
    //the origin to the middle of the image so we will rotate and scale around the center.
    //bitmap.translate By(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
    // Rotate the image context
    CGContextRotateCTM(bitmap, degrees * M_PI / 180);
    CGContextScaleCTM(bitmap, 1.0, -1.0);
//    bitmap.rotate(by: (degrees * CGFloat.pi / 180))
//    // Now, draw the rotated/scaled image into the context
//    bitmap.scaleBy(x: 1.0, y: -1.0)

    CGRect newFrame = CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height);
//    CGRect(
//                          x: -size.width / 2,
//                          y: -size.height / 2,
//                          width: size.width,
//                          height: size.height
//                          )
    CGContextDrawImage(bitmap, newFrame, image.CGImage);
    //bitmap.draw(cgImage, in: newFrame)
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
-(void)startRequestDetectRectangles{
    VNDetectRectanglesRequest *request = [[VNDetectRectanglesRequest alloc]initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        NSArray *observations = request.results;
        
        // 监测到所有的对象的点位，对每一个检测到的对象创建一个boxView
        if(observations.count > 0){
//            NSLog(@"%@",observations.description);
            for(SCNNode *node in self.rectNodesArr){
                [node removeFromParentNode];
            }
            [self.rectNodesArr removeAllObjects];
        }
        //for (VNRectangleObservation *observation  in observations) {
//            NSLog(@"%f,%f,%f,%f",observation.topLeft,observation.topRight,observation.bottomLeft,observation.bottomRight);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                VNRectangleObservation *observation   =  observations.firstObject;
                CGFloat width = self.view.frame.size.width;
                //CVPixelBufferGetWidth(self.arSession.currentFrame.capturedImage);
                CGFloat height = self.view.frame.size.height;//CVPixelBufferGetHeight(self.arSession.currentFrame.capturedImage);
                CGFloat w = observation.boundingBox.size.width * width;
                
                CGFloat h = observation.boundingBox.size.height * height;
                
                CGFloat x = observation.boundingBox.origin.x * width;
                
                CGFloat y = height - (observation.boundingBox.origin.y * height) - h;
                
                
                CGRect rect = [self boundingBox:observation.boundingBox imageRect:self.view.bounds];
                x = rect.origin.x;
                y = rect.origin.y;
                w = rect.size.width;
                h = rect.size.height;
//                NSLog(@"%@",NSStringFromCGRect(observation.boundingBox));
//                NSLog(@"%@",NSStringFromCGRect(self.view.bounds));
//                NSLog(@"%@",NSStringFromCGRect(rect));
//                NSLog(@"(%f,%f)",width,height);
//                NSLog(@"(%f,%f,%f,%f)",x,y,w,h);
//                NSLog(@"%@",NSStringFromCGRect(self.scnView.frame));
                
//                x = observation.topLeft.x * width;
//                y = (1 - observation.topRight.y) * height;
//                w = fabs(observation.topLeft.x - observation.topRight.x) * width;
//                h = fabs(observation.topLeft.y - observation.bottomLeft.y) * height;
//                CGPoint pointA = CGPointMake(x, y);
//                CGPoint pointB = CGPointMake(x, y+h);
//                CGPoint pointC = CGPointMake(x+w, y);
//                CGPoint pointD = CGPointMake(x+w, y+h);
                CGPoint opointA = observation.topLeft;
                CGPoint opointB = observation.topRight;
                CGPoint opointC = observation.bottomLeft;
                CGPoint opointD = observation.bottomRight;
                
                CGPoint pointA = CGPointMake(opointA.x * width, (1-opointA.y) * height);
                CGPoint pointB = CGPointMake(opointB.x * width, (1-opointB.y) * height);
                CGPoint pointC = CGPointMake(opointC.x * width, (1-opointC.y) * height);
                CGPoint pointD = CGPointMake(opointD.x * width, (1-opointD.y) * height);
                
                
                
                
                NSArray *arr = @[[NSValue valueWithCGPoint:pointA],[NSValue valueWithCGPoint:pointB],[NSValue valueWithCGPoint:pointC],[NSValue valueWithCGPoint:pointD]];
                UIImage *image  = [self imageFromPixelBuffer:self.arSession.currentFrame.capturedImage];
                
                [self drawRectangle:image observation:observation];
            });
            
//        }
    }];
    request.maximumObservations = 6;
    request.minimumAspectRatio = 0.1;
    request.minimumSize = 0.2;
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc]initWithCVPixelBuffer:self.arSession.currentFrame.capturedImage orientation:kCGImagePropertyOrientationRight options:@{}];
    //VNImageRequestHandler *handler = [[VNImageRequestHandler alloc]initWithCGImage:[self imageFromPixelBuffer:self.arSession.currentFrame.capturedImage].CGImage options:@{}];

    [handler performRequests:@[request] error:nil];
}


-(void)startRequestDetectRectangles:(UIImage *)image finsh:(void(^)(UIImage *image))finsh{
    VNDetectRectanglesRequest *request = [[VNDetectRectanglesRequest alloc]initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        NSArray *observations = request.results;
        CGImageRef cgImage = image.CGImage;
        dispatch_async(dispatch_get_main_queue(), ^{
            for(VNRectangleObservation *observation in observations){
                //VNRectangleObservation *observation   =  observations.firstObject;
                CIImage *ciImage = [CIImage imageWithCGImage:cgImage];
                
                // convert corners from normalized image coordinates to pixel coordinates
                CGPoint topLeft = CGPointMake(observation.topLeft.x * ciImage.extent.size.width, observation.topLeft.y * ciImage.extent.size.height); //observation.topLeft.scaled(to: ciImage.extent.size)
                CGPoint topRight = CGPointMake(observation.topRight.x * ciImage.extent.size.width, observation.topRight.y * ciImage.extent.size.height);//observation.topRight.scaled(to: ciImage.extent.size)
                CGPoint bottomLeft = CGPointMake(observation.bottomLeft.x * ciImage.extent.size.width, observation.bottomLeft.y * ciImage.extent.size.height);//observation.bottomLeft.scaled(to: ciImage.extent.size)
                CGPoint bottomRight = CGPointMake(observation.bottomRight.x * ciImage.extent.size.width, observation.bottomRight.y * ciImage.extent.size.height);//observation.bottomRight.scaled(to: ciImage.extent.size)
                
                // pass those to the filter to extract/rectify the image
                NSLog(@"%@@" ,observation.description);
                
                CIImage *ciimage = [ciImage imageByApplyingFilter:@"CIPerspectiveCorrection"
                                              withInputParameters:@{
                                                                    @"inputTopLeft":  [CIVector vectorWithCGPoint:topLeft],
                                                                    
                                                                    @"inputTopRight":  [CIVector vectorWithCGPoint:topRight],
                                                                    
                                                                    @"inputBottomLeft":  [CIVector vectorWithCGPoint:bottomLeft],
                                                                    
                                                                    @"inputBottomRight":  [CIVector vectorWithCGPoint:bottomRight]
                                                                    
                                                                    }];
                if(!ciimage){
                    continue;
                }
                
                CIContext *context = [[CIContext alloc]init];
                
                UIImage *image = [UIImage imageWithCGImage:[context createCGImage:ciimage fromRect:ciimage.extent]];
                NSLog(@"%@",image);
                if(image){
                    finsh(image);
                    break;
                }
            
            }
            
        });
        
        //        }
    }];
    request.maximumObservations = 6;
    request.minimumAspectRatio = 0.1;
    request.minimumSize = 0.2;
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc]initWithCGImage:image.CGImage options:@{}];
    
    [handler performRequests:@[request] error:nil];
}
-(void)renderer:(id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //  NSLog(@"time:%f",time);
        [self worldPosition];
        NSDate *nowDate = [NSDate date];
        
        if([nowDate timeIntervalSinceDate:_lastUpdate] < 1){
            return ;
        }
        _lastUpdate = [_lastUpdate dateByAddingTimeInterval:1];
        [self startRequestDetectRectangles];
        
    });
    
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    
   // if([anchor isKindOfClass:[ARPlaneAnchor class]]){
        
//        VNDetectRectanglesRequest *request = [[VNDetectRectanglesRequest alloc]initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
//            NSArray *observations = request.results;
//
//            // 监测到所有的对象的点位，对每一个检测到的对象创建一个boxView
//            if(observations.count > 0){
//                NSLog(@"%@",observations.description);
//                for(SCNNode *node in self.rectNodesArr){
//                    [node removeFromParentNode];
//                }
//                [self.rectNodesArr removeAllObjects];
//            }
//            for (VNRectangleObservation *observation  in observations) {
//                 dispatch_async(dispatch_get_main_queue(), ^{
//                CGFloat width = self.view.frame.size.width;
//                //CVPixelBufferGetWidth(self.arSession.currentFrame.capturedImage);
//                CGFloat height = self.view.frame.size.height;//CVPixelBufferGetHeight(self.arSession.currentFrame.capturedImage);
//                CGFloat w = observation.boundingBox.size.width * width;
//
//                CGFloat h = observation.boundingBox.size.height * height;
//
//                CGFloat x = observation.boundingBox.origin.x * width;
//
//                CGFloat y = height - (observation.boundingBox.origin.y * height) - h;
//                NSLog(@"(%f,%f)",width,height);
//                NSLog(@"(%f,%f,%f,%f)",x,y,w,h);
//                NSLog(@"%@",NSStringFromCGRect(self.scnView.frame));
//                CGPoint pointA = CGPointMake(x, y);
//                CGPoint pointB = CGPointMake(x, y+h);
//                CGPoint pointC = CGPointMake(x+w, y);
//                CGPoint pointD = CGPointMake(x+w, y+h);
//
//
//                NSArray *arr = @[[NSValue valueWithCGPoint:pointA],[NSValue valueWithCGPoint:pointB],[NSValue valueWithCGPoint:pointC],[NSValue valueWithCGPoint:pointD]];
//
//                for (NSValue *value in arr) {
//                    CGPoint point = value.CGPointValue;
//                    NSArray *results = [self.scnView hitTest:point types:ARHitTestResultTypeFeaturePoint];
//                    ARHitTestResult *result = [results firstObject];
//                    if(result){
//
//                        SCNBox *box = [SCNBox boxWithWidth:0.005 height:0.005 length:0.005 chamferRadius:0.0025];
//                        box.firstMaterial.diffuse.contents = [UIColor greenColor];
//                        //SCNPlane *box = [SCNPlane planeWithWidth:0.01 height:0.01];
//                        SCNNode *boxnode = [SCNNode nodeWithGeometry:box];
//                        boxnode.position = SCNVector3Make(result.worldTransform.columns[3].x, result.worldTransform.columns[3].y, result.worldTransform.columns[3].z);
//                        [self.scnView.scene.rootNode addChildNode:boxnode];//
//                        [self->_rectNodesArr addObject:boxnode];
//                    }
//
//                }
//                 });
//
//
////
////                CGRect facePointRect = CGRectMake(x, y, w, h);①
////
////                UIView *boxView = [[UIView alloc]initWithFrame:facePointRect];
////
////                boxView.backgroundColor = [UIColor clearColor];
////
////                boxView.layer.borderColor = [UIColor redColor].CGColor;
////
////                boxView.layer.borderWidth = 2;
////
////                [weakSelf.detectCompleteView addSubview:boxView];
//
//            }
//        }];
//    request.maximumObservations = 6;
//    request.minimumAspectRatio = 0.1;
//    request.minimumSize = 0.2;
//        VNImageRequestHandler *handler = [[VNImageRequestHandler alloc]initWithCVPixelBuffer:self.arSession.currentFrame.capturedImage options:@{}];
//        [handler performRequests:@[request] error:nil];
   // }
}
- (void) drawRectangle:(UIImage *)image observation:(VNRectangleObservation *)observation {
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    CGPoint opointA = observation.topLeft;
    CGPoint opointB = observation.topRight;
    CGPoint opointC = observation.bottomLeft;
    CGPoint opointD = observation.bottomRight;
    
    CGPoint pointA = CGPointMake(opointA.x * width, (1-opointA.y) * height);
    CGPoint pointB = CGPointMake(opointB.x * width, (1-opointB.y) * height);
    CGPoint pointC = CGPointMake(opointC.x * width, (1-opointC.y) * height);
    CGPoint pointD = CGPointMake(opointD.x * width, (1-opointD.y) * height);
    NSArray *points = @[[NSValue valueWithCGPoint:pointA],[NSValue valueWithCGPoint:pointB],[NSValue valueWithCGPoint:pointC],[NSValue valueWithCGPoint:pointD]];
    if(![self isValidPoint:points]){
        return;
    }
    self.currentObservation = observation;
    self.currentImage = image;
    for (NSValue *value in points) {
        CGPoint point = value.CGPointValue;
        NSArray *results = [self.scnView hitTest:point types:ARHitTestResultTypeFeaturePoint];
        ARHitTestResult *result = [results firstObject];
        if(result){
            
            SCNBox *box = [SCNBox boxWithWidth:0.005 height:0.005 length:0.005 chamferRadius:0.0025];
            //SCNPlane *box = [SCNPlane planeWithWidth:rect.size.width height:rect.size.height];
            box.firstMaterial.diffuse.contents = [UIColor greenColor];
            //SCNPlane *box = [SCNPlane planeWithWidth:0.01 height:0.01];
            SCNNode *boxnode = [SCNNode nodeWithGeometry:box];
            boxnode.position = SCNVector3Make(result.worldTransform.columns[3].x, result.worldTransform.columns[3].y, result.worldTransform.columns[3].z);
            [self.scnView.scene.rootNode addChildNode:boxnode];//
            [self->_rectNodesArr addObject:boxnode];
        }
        
    }
    for(ARLine *line in _rectLines){
        [line remove];
    }
//    NSValue *valueA = points[0];
//    NSValue *valueB = points[1];
//    NSValue *valueC = points[2];
//    NSValue *valueD = points[3];
//    CGPoint pointA = valueA.CGPointValue;
//    CGPoint pointB = valueB.CGPointValue;
//    CGPoint pointC = valueC.CGPointValue;
//    CGPoint pointD = valueD.CGPointValue;
    [self drawLine:pointA endPoint:pointB];
    [self drawLine:pointA endPoint:pointC];
    [self drawLine:pointC endPoint:pointD];
    [self drawLine:pointB endPoint:pointD];
    
}


- (BOOL) isValidPoint:(NSArray *)points{
    NSValue *valueA = points[0];
    NSValue *valueB = points[1];
    NSValue *valueC = points[2];
    CGPoint pointA = valueA.CGPointValue;
    CGPoint pointB = valueB.CGPointValue;
    CGPoint pointC = valueC.CGPointValue;
    
    NSArray *aResults = [self.scnView hitTest:pointA types:ARHitTestResultTypeFeaturePoint];
    NSArray *bResults = [self.scnView hitTest:pointB types:ARHitTestResultTypeFeaturePoint];
    NSArray *cResults = [self.scnView hitTest:pointC types:ARHitTestResultTypeFeaturePoint];
    ARHitTestResult *aResult = aResults.firstObject;
    ARHitTestResult *bResult = bResults.firstObject;
    ARHitTestResult *cResult = cResults.firstObject;
    SCNVector3 aVector = SCNVector3Make(aResult.worldTransform.columns[3].x,aResult.worldTransform.columns[3].y, aResult.worldTransform.columns[3].z);
    SCNVector3 bVector = SCNVector3Make(bResult.worldTransform.columns[3].x,bResult.worldTransform.columns[3].y, bResult.worldTransform.columns[3].z);
    SCNVector3 cVector = SCNVector3Make(cResult.worldTransform.columns[3].x,cResult.worldTransform.columns[3].y, cResult.worldTransform.columns[3].z);
    
    CGFloat ab = [ARLine destanceWithVector:aVector endVector:bVector] * 100;
    CGFloat ac = [ARLine destanceWithVector:aVector endVector:cVector] * 100;
    NSLog(@"%f,%f",ab,ac);
    if(ab > 4 && ac > 4){
        
        return YES;
    }
    return NO;

}
- (void) drawLine:(CGPoint)startPoint endPoint:(CGPoint)endPoint{
    NSArray *startResults = [self.scnView hitTest:startPoint types:ARHitTestResultTypeFeaturePoint];
    NSArray *endResults = [self.scnView hitTest:endPoint types:ARHitTestResultTypeFeaturePoint];
    ARHitTestResult *startResult = startResults.firstObject;
    ARHitTestResult *endResult = endResults.firstObject;
    SCNVector3 startVector = SCNVector3Make(startResult.worldTransform.columns[3].x,startResult.worldTransform.columns[3].y, startResult.worldTransform.columns[3].z);
    SCNVector3 endVector = SCNVector3Make(endResult.worldTransform.columns[3].x,endResult.worldTransform.columns[3].y, endResult.worldTransform.columns[3].z);
    ARLine *line = [[ARLine alloc] initWithScnView:self.scnView scnVector:startVector unit:100.0];
    [line upDateToVector:endVector];
    [_rectLines addObject:line];
    
}
-(void)worldPosition{
    
    SCNVector3 worldP = SCNVector3Zero;
    NSArray *results = [self.scnView hitTest:self.view.center types:ARHitTestResultTypeFeaturePoint];
    
    
    //NSLog(@"results = %@",results);
    
    if (results.count<=0) {
        worldP =  SCNVector3Zero;
    }
    ARHitTestResult *result = results.firstObject;
    
    worldP = SCNVector3Make(result.worldTransform.columns[3].x,result.worldTransform.columns[3].y, result.worldTransform.columns[3].z);
    
   
    
    if (_arLines.count<=0) {
        self.infoLabel.text = @"点击屏幕开始测距";
    }
    
    //NSLog(@"_arLines = %@",_arLines);
    
    if (self.isMuseing) {
        
        if (self.vectorStart.x == self.vectorZero.x && self.vectorStart.y == self.vectorZero.y && self.vectorStart.z == self.vectorZero.z) {
            self.vectorStart = worldP;
            self.currentLine = [[ARLine alloc] initWithScnView:self.scnView scnVector:self.vectorStart unit:100.0];
            
        }
        self.vectorStop = worldP;
        [self.currentLine upDateToVector:self.vectorStop];
        self.infoLabel.text = [NSString stringWithFormat:@"%.1f",[self.currentLine destanceWithVector:self.vectorStop]];
        
    }
    
}

- (UIImage*)imageFromPixelBuffer:(CVPixelBufferRef)p {
    CIImage* ciImage = [CIImage imageWithCVPixelBuffer:p];
    CIContext* context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(YES)}];
    CGRect rect = CGRectMake(0, 0, CVPixelBufferGetWidth(p), CVPixelBufferGetHeight(p));
    CGImageRef videoImage = [context createCGImage:ciImage fromRect:rect];
    UIImage* image = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    return image;}

@end
