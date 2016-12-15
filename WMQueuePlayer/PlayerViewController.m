//
//  PlayerViewController.m
//  WMQueuePlayer
//
//  Created by zhengwenming on 2016/12/4.
//  Copyright © 2016年 郑文明. All rights reserved.
//

#import "PlayerViewController.h"
#import "TCQueuePlayerViewController.h"
#import "WMQueuePlayer.h"
@interface PlayerViewController ()<WMQueuePlayerDelegate>
@property(nonatomic,strong)NSMutableArray *urlArray;
@property(nonatomic,retain)WMQueuePlayer *queuePlayer;

@end

@implementation PlayerViewController
- (instancetype)init
{
    self = [super init];
    if (self) {
        //        http://baobab.wdjcdn.com/1456653443902B.mp4
        self.urlArray = [NSMutableArray arrayWithObjects:
                         @"http://flv2.bn.netease.com/videolib3/1612/15/SVhGb9739/SD/movie_index.m3u8",
                         @"http://baobab.wdjcdn.com/1456317490140jiyiyuetai_x264.mp4",
                         @"http://ips.ifeng.com/3gs.ifeng.com/userfiles/video02/2014/09/01/2233658-280-068-2335.mp4",
                         @"http://flv2.bn.netease.com/tvmrepo/2016/12/L/I/EC7BA65LI/SD/movie_index.m3u8",
                         @"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4", nil];
    }
    return self;
}

///播放器切换视频的代理
-(void)wmQueuePlayer:(WMQueuePlayer *)player itemDidChanged:(AVPlayerItem *)item index:(NSInteger)currentIndex{
}
///视频播放完成的代理
-(void)wmQueuePlayer:(WMQueuePlayer *)player itemDidPlayToEnd:(AVPlayerItem *)item index:(NSInteger)currentIndex{
    
}

-(void)wmQueuePlayer:(WMQueuePlayer *)player itemReadyToPlay:(AVPlayerItem *)item index:(NSInteger)currentIndex{
    player.titleLabel.text = [NSString stringWithFormat:@"我是第%li个视频",currentIndex];
}
- (void)wmQueuePlayer:(WMQueuePlayer *)player didClickedColsedBtn:(UIButton *)closeBtn index:(NSInteger )currentIndex{
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _queuePlayer = [[WMQueuePlayer alloc]initWithFrame:CGRectMake(0, 65, [UIScreen mainScreen].bounds.size.width ,200)];
    _queuePlayer.backgroundColor = [UIColor lightGrayColor];
    NSMutableArray *temURLArray = [NSMutableArray array];
    for (NSString *aUrlString in self.urlArray) {
        [temURLArray addObject:[NSURL URLWithString:aUrlString]];
    }
    [_queuePlayer setURLArray:temURLArray];
    _queuePlayer.isLoopPlay = YES;//设置循环播放
    _queuePlayer.delegate = self;
    [self.view addSubview:_queuePlayer];
//    [_queuePlayer playItemAtIndex:2];
    [_queuePlayer play];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    
    //    if (_queuePlayer.isPlaying) {
    //        [_queuePlayer pause];
    //    }else{
    //        [_queuePlayer play];
    //    }
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
- (void)dealloc
{
    NSLog(@"PlayerViewController deallco");
}
@end
