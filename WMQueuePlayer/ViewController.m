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
                         @"http://wscdn.alhls.xiaoka.tv/20161115/57c/da6/OM7VL1SYM2L37pF3/index.m3u8",
                         @"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4", nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _queuePlayer = [[WMQueuePlayer alloc]initWithFrame:CGRectMake(0, 65, self.view.bounds.size.width, 0.75*(self.view.bounds.size.width))];
    _queuePlayer.backgroundColor = [UIColor lightGrayColor];
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

//    if (_queuePlayer.isPlaying) {
//        [_queuePlayer pause];
//    }else{
//        [_queuePlayer play];
//    }
    
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
