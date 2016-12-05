//
//  ViewController.m
//  WMQueuePlayer
//
//  Created by 郑文明 on 16/9/20.
//  Copyright © 2016年 郑文明. All rights reserved.
//

#import "ViewController.h"

#import "PlayerViewController.h"
#import "WMProgressView.h"


@interface ViewController ()
@property(nonatomic,strong)WMProgressView *progressView;
@property(nonatomic,assign)CGFloat progress;

@end

@implementation ViewController

- (IBAction)pushToNextVC:(UIButton *)sender {
    PlayerViewController *playerVC = [[PlayerViewController alloc]init];
    [self.navigationController pushViewController:playerVC animated:YES];
}
- (void)viewDidLoad {
    CGPoint point = self.view.center;

    [super viewDidLoad];
    self.progressView = [[WMProgressView alloc]initWithFrame:CGRectMake(0, point.y+100, self.view.bounds.size.width, 60)];
    self.progressView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.progressView];
    
//    __typeof(self) weakSelf = self;
//    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
//        weakSelf.progressView.value = self.progress++;
//    }];
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(progressSetFunc) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop]addTimer:timer forMode:NSDefaultRunLoopMode];
   
}
-(void)progressSetFunc{
    self.progressView.value = self.progress++/10.0;

}
@end
