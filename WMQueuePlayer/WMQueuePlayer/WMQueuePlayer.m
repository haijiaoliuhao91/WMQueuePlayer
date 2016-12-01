//
//  WMQueuePlayer.m
//  WMQueuePlayer
//
//  Created by 郑文明 on 16/9/20.
//  Copyright © 2016年 郑文明. All rights reserved.
//

#import "WMQueuePlayer.h"
#import "Masonry.h"

#define WMQueuePlayerSrcName(file) [@"WMQueuePlayer.bundle" stringByAppendingPathComponent:file]
#define WMQueuePlayerFrameworkSrcName(file) [@"Frameworks/WMQueuePlayer.framework/WMQueuePlayer.bundle" stringByAppendingPathComponent:file]

#define WMQueuePlayerImage(file)      [UIImage imageNamed:WMQueuePlayerSrcName(file)] ? :[UIImage imageNamed:WMQueuePlayerFrameworkSrcName(file)]

@interface WMQueuePlayer ()<UIGestureRecognizerDelegate>{
    NSMutableArray      *_nextUrls;
    NSMutableArray      *_playedUrls;
  }
//监听播放起状态的监听者
@property (nonatomic ,strong) id playbackTimeObserver;
@property (nonatomic, strong) UISlider *progressSlider;
/**
 *  显示播放时间的UILabel
 */
@property (nonatomic,strong) UILabel        *leftTimeLabel;
@property (nonatomic,strong) UILabel        *rightTimeLabel;
@property (nonatomic, strong)NSDateFormatter *dateFormatter;

@end


@implementation WMQueuePlayer

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self prepare];
    }
    return self;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        [self prepare];
    }
    return self;
}
-(void)prepare{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:true error:nil];
    [self setAutoresizesSubviews:NO];

    
    //wmplayer内部的一个view，用来管理子视图
    self.contentView = [[UIView alloc]init];
    self.contentView.backgroundColor = [UIColor blackColor];
    [self addSubview:self.contentView];
    //autoLayout contentView

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    
    //topView
    self.topView = [[UIImageView alloc]init];
    self.topView.image = WMQueuePlayerImage(@"top_shadow");
    self.topView.userInteractionEnabled = YES;
    [self.contentView addSubview:self.topView];
    //autoLayout topView
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).with.offset(0);
        make.right.equalTo(self.contentView).with.offset(0);
        make.height.mas_equalTo(70);
        make.top.equalTo(self.contentView).with.offset(0);
    }];

    
    
    
    //bottomView
    self.bottomView = [[UIImageView alloc]init];
    self.bottomView.image = WMQueuePlayerImage(@"bottom_shadow");
    self.bottomView.userInteractionEnabled = YES;
    self.bottomView.backgroundColor = [UIColor lightGrayColor];
    [self.contentView addSubview:self.bottomView];
    //autoLayout bottomView
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).with.offset(0);
        make.right.equalTo(self.contentView).with.offset(0);
        make.height.mas_equalTo(50);
        make.bottom.equalTo(self.contentView).with.offset(0);
    }];
    
    
    
    self.playOrPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playOrPauseBtn.showsTouchWhenHighlighted = YES;
    [self.playOrPauseBtn addTarget:self action:@selector(PlayOrPause:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.playOrPauseBtn setImage:WMQueuePlayerImage(@"pause") forState:UIControlStateNormal];
    [self.playOrPauseBtn setImage:WMQueuePlayerImage(@"play") forState:UIControlStateSelected];
    
    [self.bottomView addSubview:self.playOrPauseBtn];
    //autoLayout _playOrPauseBtn
    [self.playOrPauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(0);
        make.height.mas_equalTo(50);
        make.bottom.equalTo(self.bottomView).with.offset(0);
        make.width.mas_equalTo(50);
        
    }];
    self.playOrPauseBtn.selected = YES;//默认状态，即默认是不自动播放
    
    
    //_fullScreenBtn
    self.fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fullScreenBtn.showsTouchWhenHighlighted = YES;
    [self.fullScreenBtn addTarget:self action:@selector(fullScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.fullScreenBtn setImage:WMQueuePlayerImage(@"fullscreen") forState:UIControlStateNormal];
    [self.fullScreenBtn setImage:WMQueuePlayerImage(@"nonfullscreen") forState:UIControlStateSelected];
    [self.bottomView addSubview:self.fullScreenBtn];
    //autoLayout fullScreenBtn
    [self.fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomView).with.offset(0);
        make.height.mas_equalTo(50);
        make.bottom.equalTo(self.bottomView).with.offset(0);
        make.width.mas_equalTo(50);
        
    }];
    
    
    //slider
    self.progressSlider = [[UISlider alloc]init];
    self.progressSlider.minimumValue = 0.0;
    [self.progressSlider setThumbImage:WMQueuePlayerImage(@"dot")  forState:UIControlStateNormal];
    self.progressSlider.minimumTrackTintColor = [UIColor greenColor];
    self.progressSlider.maximumTrackTintColor = [UIColor whiteColor];
    self.progressSlider.backgroundColor = [UIColor clearColor];
    self.progressSlider.value = 0.0;//指定初始值
    //进度条的拖拽事件
    [self.progressSlider addTarget:self action:@selector(stratDragSlide:)  forControlEvents:UIControlEventValueChanged];
    //进度条的点击事件
    [self.progressSlider addTarget:self action:@selector(updateProgress:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.progressSlider];

    //autoLayout slider
    [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(45);
        make.right.equalTo(self.bottomView).with.offset(-45);
        make.center.equalTo(self.bottomView);
    }];
    
    
    
    //leftTimeLabel显示左边的时间进度
    self.leftTimeLabel = [[UILabel alloc]init];
    self.leftTimeLabel.textAlignment = NSTextAlignmentLeft;
    self.leftTimeLabel.textColor = [UIColor whiteColor];
    self.leftTimeLabel.backgroundColor = [UIColor clearColor];
    self.leftTimeLabel.font = [UIFont systemFontOfSize:11];
    [self.bottomView addSubview:self.leftTimeLabel];
    //autoLayout timeLabel
    [self.leftTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(45);
        make.right.equalTo(self.bottomView).with.offset(-45);
        make.height.mas_equalTo(20);
        make.bottom.equalTo(self.bottomView).with.offset(0);
    }];
    self.leftTimeLabel.text = [self convertTime:0.0];//设置默认值
    
    //rightTimeLabel显示右边的总时间
    self.rightTimeLabel = [[UILabel alloc]init];
    self.rightTimeLabel.textAlignment = NSTextAlignmentRight;
    self.rightTimeLabel.textColor = [UIColor whiteColor];
    self.rightTimeLabel.backgroundColor = [UIColor clearColor];
    self.rightTimeLabel.font = [UIFont systemFontOfSize:11];
    [self.bottomView addSubview:self.rightTimeLabel];
    //autoLayout timeLabel
    [self.rightTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(45);
        make.right.equalTo(self.bottomView).with.offset(-45);
        make.height.mas_equalTo(20);
        make.bottom.equalTo(self.bottomView).with.offset(0);
    }];
    self.rightTimeLabel.text = [self convertTime:0.0];//设置默认值


    
    
    _playedUrls = [NSMutableArray arrayWithCapacity:0];
    _nextUrls = [NSMutableArray arrayWithCapacity:0];
    _queuePlayer = [AVQueuePlayer queuePlayerWithItems:@[]];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_queuePlayer];
    self.playerLayer.frame = self.bounds;
    self.playerLayer.videoGravity = AVLayerVideoGravityResize;
    [self.contentView.layer insertSublayer:_playerLayer atIndex:0];
    __weak typeof(self) weakSelf = self;
 self.playbackTimeObserver =  [_queuePlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [weakSelf syncSlider];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidEndPlay:) name:AVPlayerItemDidPlayToEndTimeNotification object:_queuePlayer.currentItem];

}

- (void)removePlayerTimeObserver
{
    [self.queuePlayer removeTimeObserver:self.playbackTimeObserver];
    [self setPlaybackTimeObserver:nil];
}
- (void)syncSlider
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    double interval = .1f;
    double duration = CMTimeGetSeconds(playerDuration);

    if (isfinite(duration)) {
        CGFloat width = CGRectGetWidth(self.progressSlider.bounds);
        interval = 0.5f * duration / width;
        float minValue = [self.progressSlider minimumValue];
        float maxValue = [self.progressSlider maximumValue];
        double currentTime = CMTimeGetSeconds([self.queuePlayer currentTime]);
        [self.progressSlider setMaximumValue:duration];

        
        long long nowTime = self.queuePlayer.currentItem.currentTime.value/self.queuePlayer.currentItem.currentTime.timescale;
        self.leftTimeLabel.text = [self convertTime:nowTime];
        self.rightTimeLabel.text = [self convertTime:duration];
        [self.progressSlider setValue:(maxValue - minValue) * currentTime / duration + minValue];
    }
}


- (CMTime)playerItemDuration
{
//    AVPlayerItem *currentItem = _queuePlayer.currentItem;
//
//    NSTimeInterval current = CMTimeGetSeconds(currentItem.currentTime);
//    NSTimeInterval duation = CMTimeGetSeconds(currentItem.duration);
    return [self.queuePlayer.currentItem duration];
}

#pragma mark
#pragma mark--开始拖曳sidle
- (void)stratDragSlide:(UISlider *)slider{

}
#pragma mark
#pragma mark - 播放进度
- (void)updateProgress:(UISlider *)slider{
//    [self.queuePlayer seekToTime:CMTimeMakeWithSeconds(slider.value, _currentItem.currentTime.timescale)];
}
- (void)fullScreenAction:(UIButton *)sender{
    NSLog(@"fullScreenAction");
}
- (void)play {
    if (_isPlaying==NO) {
        [self.queuePlayer play];
        self.playOrPauseBtn.selected = NO;
        _isPlaying = YES;
    }
}
- (void)pause {
    if (_isPlaying==YES) {
        [self.queuePlayer pause];
        self.playOrPauseBtn.selected = YES;

        _isPlaying = NO;
    }
}
- (void)PlayOrPause:(UIButton *)sender{
    sender.selected = !sender.selected;
    if (_isPlaying==NO) {
        [self play];
    }else{
        [self pause];
    }
}


- (void)resetUrls:(NSArray<NSURL *> *)urls {
    [_queuePlayer removeAllItems];
    [_playedUrls removeAllObjects];
    [_nextUrls removeAllObjects];
    [_nextUrls addObjectsFromArray:urls];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:urls[0]];
    if ([_queuePlayer canInsertItem:item afterItem:nil]) {
        [_queuePlayer insertItem:item afterItem:nil];
    }
}

- (void)addUrls:(NSArray<NSURL *> *)urls {
    
    [_nextUrls addObjectsFromArray:urls];
    
    NSArray *playItems = _queuePlayer.items;
    if (playItems.count == 0) {
        
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:urls[0]];
        if ([_queuePlayer canInsertItem:item afterItem:nil]) {
            [_queuePlayer insertItem:item afterItem:nil];
        }
    }
}

- (void)setUrls:(NSArray<NSURL *> *)urls index:(NSInteger)index {
    [_playedUrls removeAllObjects];
    [_nextUrls removeAllObjects];
    
    if (urls.count == 0 || urls == nil) {
        [_queuePlayer removeAllItems];
        return;
    }
    
    if (index > urls.count) {   //加层保险
        index = urls.count;
    }
    
    [_playedUrls addObjectsFromArray:[urls subarrayWithRange:NSMakeRange(0, index)]];
    [_nextUrls addObjectsFromArray:[urls subarrayWithRange:NSMakeRange(index, urls.count - index)]];
    [_queuePlayer removeAllItems];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:_nextUrls[0]];
    if ([_queuePlayer canInsertItem:item afterItem:nil]) {
        [_queuePlayer insertItem:item afterItem:nil];
    }
}

- (void)lastItem {

    if (_playedUrls.count > 0) {
        
        NSURL *url = _playedUrls[0];
        [_nextUrls insertObject:url atIndex:0];
        [_playedUrls removeObjectAtIndex:0];
        [_queuePlayer advanceToNextItem];
        [_queuePlayer removeAllItems];
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
        if ([_queuePlayer canInsertItem:item afterItem:nil]) {
            [_queuePlayer insertItem:item afterItem:nil];
        }
        [_queuePlayer play];
        _isPlaying = YES;
    }
}


- (void)nextItem {
    
    if (_nextUrls.count > 1) {
        [self.queuePlayer advanceToNextItem];
        [_playedUrls insertObject:_nextUrls[0] atIndex:0];
        [_nextUrls removeObjectAtIndex:0];
        
        NSArray *items = _queuePlayer.items;
        
        if (items.count < _nextUrls.count) {
            NSURL *url = _nextUrls[items.count];
            AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
            if ([_queuePlayer canInsertItem:item afterItem:nil]) {
                [_queuePlayer insertItem:item afterItem:nil];
            }
        }
        
        _isPlaying = YES;
        [_queuePlayer play];
    }
}

- (void)playerItemDidEndPlay:(NSNotification *)tifi {
    _isPlaying = NO;
    if ([_delegate respondsToSelector:@selector(queuePlayerEndPlayed:)]) {
        
        AVPlayerItem *item = tifi.object;
        
        [_delegate queuePlayerEndPlayed:item];
    }
}

- (AVQueuePlayer *)queuePlayer {
    return _queuePlayer;
}
- (NSString *)convertTime:(float)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    return [[self dateFormatter] stringFromDate:d];
}
- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    }
    return _dateFormatter;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
