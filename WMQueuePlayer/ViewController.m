//
//  ViewController.m
//  WMQueuePlayer
//
//  Created by 郑文明 on 16/9/20.
//  Copyright © 2016年 郑文明. All rights reserved.
//

#import "ViewController.h"
#import "TCQueuePlayerViewController.h"
#import "WMQueuePlayer.h"


@interface ViewController ()
@property(nonatomic,retain)WMQueuePlayer *queuePlayer;

@property(nonatomic,strong)NSMutableArray *urlArray;

@end

@implementation ViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.urlArray = [NSMutableArray arrayWithObjects:@"http://ips.ifeng.com/3gs.ifeng.com/userfiles/video02/2014/08/29/2228059-280-068-2342.mp4",
                         @"http://ips.ifeng.com/3gs.ifeng.com/userfiles/video02/2014/09/01/2233658-280-068-2335.mp4",
                         @"http://ips.ifeng.com/3gs.ifeng.com/userfiles/video02/2014/08/29/2228059-280-068-2342.mp4",
                         @"http://ips.ifeng.com/3gs.ifeng.com/userfiles/video02/2014/08/26/2220447-280-068-2354.mp4", nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _queuePlayer = [[WMQueuePlayer alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 300)];
    _queuePlayer.backgroundColor = [UIColor lightGrayColor];
    _queuePlayer.progress = ^(NSTimeInterval currentTime, NSTimeInterval duration){
        NSLog(@"%.2f",currentTime);
    };
    NSMutableArray *temURLArray = [NSMutableArray array];
    for (NSString *aUrlString in self.urlArray) {
        [temURLArray addObject:[NSURL URLWithString:aUrlString]];
    }
    [_queuePlayer setUrls:temURLArray index:0];
    [_queuePlayer play];
    [self.view addSubview:_queuePlayer];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];

    [_queuePlayer nextItem];
    
    return;
    
    NSMutableArray *itemArray = [NSMutableArray array];
    for (NSString *aString in self.urlArray) {
        [itemArray addObject:[AVPlayerItem playerItemWithURL:[NSURL URLWithString:aString]]];
    }
    
    
    
    
    TCQueuePlayerViewController *tc=[[TCQueuePlayerViewController alloc]initWithItems:itemArray];
    [self presentViewController:tc animated:YES completion:^{
        [tc.player play];
    }];
}

@end
