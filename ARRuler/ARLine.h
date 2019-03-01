//
//  ARLine.h
//  ARRuler
//
//  Created by 国信 on 2019/2/22.
//  Copyright © 2019年 国信. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ARKit/ARKit.h>
#import <SceneKit/SceneKit.h>

#define kScale 0.003

NS_ASSUME_NONNULL_BEGIN

@interface ARLine : NSObject

@property (nonatomic,strong) ARSCNView *scnView;

@property (nonatomic,assign) SCNVector3 startVector;

@property (nonatomic,strong) SCNNode *startNode;

@property (nonatomic,strong) SCNNode *endNode;

@property (nonatomic,strong) SCNNode *textNode;

@property (nonatomic,strong) SCNText *cnText;

@property (nonatomic,strong) SCNNode *lineNode;

@property (nonatomic,assign) CGFloat unit;

-(instancetype)initWithScnView:(ARSCNView *)scnView scnVector:(SCNVector3)startVector unit:(CGFloat)unit;

-(void)remove;

-(void)upDateToVector:(SCNVector3 )scnVector;

-(double)destanceWithVector:(SCNVector3 )scnVector;
+(double)destanceWithVector:(SCNVector3)startVector endVector:(SCNVector3)endVector;

@end

NS_ASSUME_NONNULL_END
