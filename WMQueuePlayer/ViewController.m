//
//  ViewController.m
//  WMQueuePlayer
//
//  Created by 郑文明 on 16/9/20.
//  Copyright © 2016年 郑文明. All rights reserved.
//

#import "ViewController.h"

#import "PlayerViewController.h"



@interface ViewController ()

@property(nonatomic,assign)CGFloat progress;

@end

@implementation ViewController

- (IBAction)pushToNextVC:(UIButton *)sender {
    PlayerViewController *playerVC = [[PlayerViewController alloc]init];
    [self.navigationController pushViewController:playerVC animated:YES];
}
- (void)viewDidLoad {

    
    [super viewDidLoad];
   
}

@end
