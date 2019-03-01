//
//  ARDisplayVC.m
//  ARRuler
//
//  Created by zhiwei on 2019/2/27.
//  Copyright © 2019 国信. All rights reserved.
//

#import "ARDisplayVC.h"

@interface ARDisplayVC ()
@property(nonatomic,strong)NSMutableArray *images;
@property(nonatomic,strong)UIScrollView *scr;
@property(nonatomic,assign)CGFloat offset;
@end

@implementation ARDisplayVC

-(id)initWithImages:(NSMutableArray *)images{
    self = [super init];
    if(self){
        _images = images;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _offset = 0;
    
    _scr = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    for(UIImage *image in _images){
        [self addImage:image];
    }
    _scr.contentSize = CGSizeMake(self.view.frame.size.width, _offset + 30);
    
    [self.view addSubview:_scr];
    [self addDissmissButton];
    // Do any additional setup after loading the view.
}

- (void)addImage:(UIImage *)image{
    UIImageView *imageView = [[UIImageView alloc]initWithImage:image];
    CGFloat width = image.size.width > self.view.frame.size.width - 30 ? self.view.frame.size.width - 30 : image.size.width;
    CGFloat height = image.size.height * width / image.size.width;
    imageView.frame = CGRectMake((self.view.frame.size.width - width)/2, _offset + 30 , width , height);
    _offset = CGRectGetMaxY(imageView.frame);
    [_scr addSubview:imageView];
}
- (void)addDissmissButton{
    
    UIButton *but = [UIButton new];
    but.frame = CGRectMake(30, 0, 60, 30);
    but.backgroundColor = [UIColor redColor];
    [but addTarget:self action:@selector(dissmiss) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:but];
}
- (void)dissmiss{
    [self dismissViewControllerAnimated:YES completion:nil];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
