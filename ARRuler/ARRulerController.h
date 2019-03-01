//
//  ARRulerController.h
//  ARRuler
//
//  Created by 国信 on 2019/2/22.
//  Copyright © 2019年 国信. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ARKit/ARKit.h>
#import <SceneKit/SceneKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARRulerController : UIViewController

@property (nonatomic,strong) UIImageView *addView;

@property (nonatomic,strong) UILabel *infoLabel;

@property (nonatomic,strong) ARSCNView *scnView;

@property (nonatomic,strong) UIButton *resetBtn;

@end

NS_ASSUME_NONNULL_END
