//
//  ARLine.m
//  ARRuler
//
//  Created by 国信 on 2019/2/22.
//  Copyright © 2019年 国信. All rights reserved.
//

#import "ARLine.h"

@implementation ARLine
-(instancetype)initWithScnView:(ARSCNView *)scnView scnVector:(SCNVector3)startVector unit:(CGFloat)unit{
    if (self = [super init]) {
        self.scnView = scnView;
        self.startVector = startVector;
        self.unit = unit;
        SCNSphere *sph = [SCNSphere sphereWithRadius:0.5];
        sph.firstMaterial.diffuse.contents = [UIColor redColor];
        sph.firstMaterial.lightingModelName = SCNLightingModelConstant;
        [sph.firstMaterial setDoubleSided:YES];
        
        self.startNode = [SCNNode nodeWithGeometry:sph];
        self.startNode.scale = SCNVector3Make(kScale, kScale, kScale);
        self.startNode.position = startVector;
        [self.scnView.scene.rootNode addChildNode:self.startNode];
        
        self.endNode = [SCNNode nodeWithGeometry:sph];
        self.endNode.scale = SCNVector3Make(kScale , kScale, kScale);
        
        self.cnText = [SCNText textWithString:@"" extrusionDepth:0.1];
        self.cnText.font = [UIFont systemFontOfSize:2];
        self.cnText.firstMaterial.diffuse.contents = [UIColor redColor];
        self.cnText.firstMaterial.lightingModelName = SCNLightingModelConstant;
        [self.cnText setAlignmentMode:kCAAlignmentCenter];
        [self.cnText.firstMaterial setDoubleSided:YES];
        [self.cnText setTruncationMode:kCATruncationMiddle];
        
        SCNNode *tNode = [SCNNode nodeWithGeometry:self.cnText];
        [tNode setEulerAngles:SCNVector3Make(0, M_PI, 0)];
        tNode.scale = SCNVector3Make(kScale, kScale, kScale);
        
        self.textNode = [[SCNNode alloc]init];
        [self.textNode addChildNode:tNode];//添加到包装节点上
        SCNLookAtConstraint *constranint = [SCNLookAtConstraint lookAtConstraintWithTarget:scnView.pointOfView];
        [constranint setGimbalLockEnabled:YES];
        self.textNode.constraints = @[constranint];
        [scnView.scene.rootNode addChildNode:self.textNode];
        
    }
    return self;
}

-(void)upDateToVector:(SCNVector3)scnVector{
    [self.lineNode removeFromParentNode];
    UInt8 indices[] = {0,1};
    NSData *indexData = [NSData dataWithBytes:indices length:sizeof(indices)];
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData primitiveType:SCNGeometryPrimitiveTypeLine primitiveCount:1 bytesPerIndex:sizeof(UInt8)];//线
    
    SCNVector3 positions[] = {self.startVector,scnVector};
    SCNGeometrySource *source = [SCNGeometrySource geometrySourceWithVertices:positions count:2];//线顶点的集合
    SCNGeometry *geomtry = [SCNGeometry geometryWithSources:@[source] elements:@[element]];//几何体
    
    geomtry.firstMaterial.diffuse.contents = [UIColor greenColor];
    geomtry.firstMaterial.lightingModelName =  SCNLightingModelConstant;
    [geomtry.firstMaterial setDoubleSided:YES];
    
    SCNNode *node = [SCNNode nodeWithGeometry:geomtry];
    
    self.lineNode = node;
    [self.scnView.scene.rootNode addChildNode:self.lineNode];
    
    self.cnText.string = [NSString stringWithFormat:@"%.2f",[self destanceWithVector:scnVector]*self.unit];
    self.textNode.position = SCNVector3Make((self.startVector.x + scnVector.x)/2.0, (self.startVector.y + scnVector.y)/2.0, (self.startVector.z+scnVector.z)/2.0);
    self.endNode.position = scnVector;
    if (self.endNode.parentNode == nil) {
        [self.scnView.scene.rootNode addChildNode:self.endNode];
    }
}

-(double)destanceWithVector:(SCNVector3)scnVector{
    double dest = sqrt((self.startVector.x - scnVector.x)*(self.startVector.x - scnVector.x)+(self.startVector.y -scnVector.y)* (self.startVector.y -scnVector.y)+ (self.startVector.z - scnVector.z)* (self.startVector.z - scnVector.z));
    return dest;
}

+(double)destanceWithVector:(SCNVector3)startVector endVector:(SCNVector3)endVector{
    double dest = sqrt((startVector.x - endVector.x)*(startVector.x - endVector.x)+
                       (startVector.y -endVector.y)*(startVector.y - endVector.y)+
                       (startVector.z - endVector.z)*(startVector.z - endVector.z));
    return dest;
}
-(void)remove{
    [self.startNode removeFromParentNode];
    [self.endNode removeFromParentNode];
    [self.lineNode removeFromParentNode];
    [self.textNode removeFromParentNode];
}

@end
