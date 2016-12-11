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
static void *PlayViewStatusObservationContext = &PlayViewStatusObservationContext;

@interface WMQueuePlayer ()<UIGestureRecognizerDelegate>{
    NSMutableArray *dataSource;
    CGFloat currentItemDuration;
  }
//监听播放起状态的监听者
@property (nonatomic ,strong) id playbackTimeObserver;
//显示缓冲进度
@property (nonatomic,strong) UIProgressView *loadingProgress;
//进度滑块
@property (nonatomic, strong) UISlider *progressSlider;
/**
 *  显示播放时间的UILabel
 */
@property (nonatomic,strong) UILabel        *leftTimeLabel;
@property (nonatomic,strong) UILabel        *rightTimeLabel;
@property (nonatomic, strong)NSDateFormatter *dateFormatter;
@property (nonatomic, assign) BOOL isDragingSlider;//是否正在拖曳UISlider，默认为NO
/**
 *  菊花（加载框）
 */
@property (nonatomic,strong) UIActivityIndicatorView *loadingView;
/**
 *  显示加载失败的UILabel
 */

@property (nonatomic,strong) UILabel        *loadFailedLabel;
@end


@implementation WMQueuePlayer
#pragma mark
#pragma mark lazy 加载失败的label
-(UILabel *)loadFailedLabel{
    if (_loadFailedLabel==nil) {
        _loadFailedLabel = [[UILabel alloc]init];
        _loadFailedLabel.backgroundColor = [UIColor clearColor];
        _loadFailedLabel.textColor = [UIColor whiteColor];
        _loadFailedLabel.textAlignment = NSTextAlignmentCenter;
        _loadFailedLabel.text = @"视频加载失败";
        _loadFailedLabel.hidden = YES;
        [self.contentView addSubview:_loadFailedLabel];
        
        [_loadFailedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.contentView);
            make.width.equalTo(self.contentView);
            make.height.equalTo(@30);
            
        }];
    }
    return _loadFailedLabel;
}
-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}
-(void)awakeFromNib{
    [super awakeFromNib];
    [self setupUI];
}
- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}
-(void)setupUI{
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
    
    
    //小菊花
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    //    UIActivityIndicatorViewStyleWhiteLarge 的尺寸是（37，37）
    //    UIActivityIndicatorViewStyleWhite 的尺寸是（22，22）
    [self.contentView addSubview:self.loadingView];
    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.contentView);
    }];
    [self.loadingView startAnimating];
    
    //topView
    self.topView = [[UIImageView alloc]init];
    self.topView.image = WMQueuePlayerImage(@"top_shadow");
    self.topView.userInteractionEnabled = YES;
//    self.topView.backgroundColor = [UIColor lightGrayColor];

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
//    self.bottomView.backgroundColor = [UIColor lightGrayColor];
    [self.contentView addSubview:self.bottomView];
    //autoLayout bottomView
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).with.offset(0);
        make.right.equalTo(self.contentView).with.offset(0);
        make.height.mas_equalTo(50);
        make.bottom.equalTo(self.contentView).with.offset(0);
    }];
    
    
    
    //titleLabel
    self.titleLabel = [[UILabel alloc]init];
    //    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [self.topView addSubview:self.titleLabel];
    //autoLayout titleLabel
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topView).with.offset(45);
        make.right.equalTo(self.topView).with.offset(-45);
        make.center.equalTo(self.topView);
        make.top.equalTo(self.topView).with.offset(0);
        
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
    self.progressSlider.maximumTrackTintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
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
        make.centerY.equalTo(self.bottomView.mas_centerY).offset(-1);
        make.height.mas_equalTo(30);
    }];

    
    //缓冲进度
    self.loadingProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.loadingProgress.progressTintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
    self.loadingProgress.trackTintColor    = [UIColor clearColor];
    [self.bottomView addSubview:self.loadingProgress];
    [self.loadingProgress setProgress:0.0 animated:NO];
    
    
    [self.loadingProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(45);
        make.right.equalTo(self.bottomView).with.offset(-45);
        make.centerY.equalTo(self.bottomView.mas_centerY);
    }];
    
    
    [self.bottomView sendSubviewToBack:self.loadingProgress];
    

    
 
    
    
    
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
    
    
    //_closeBtn
    _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _closeBtn.showsTouchWhenHighlighted = YES;
    //    _closeBtn.backgroundColor = [UIColor redColor];
    [_closeBtn addTarget:self action:@selector(colseTheVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:_closeBtn];
    //autoLayout _closeBtn
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topView).with.offset(5);
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(30);
        make.top.equalTo(self.topView).with.offset(20);
        
    }];
    
    
    
    //左上角的返回按钮的样式
    if (self.closeBtnStyle==CloseBtnStylePop) {
        [_closeBtn setImage:WMQueuePlayerImage(@"play_back.png") forState:UIControlStateNormal];
        [_closeBtn setImage:WMQueuePlayerImage(@"play_back.png") forState:UIControlStateSelected];
        
    }else{
        [_closeBtn setImage:WMQueuePlayerImage(@"close") forState:UIControlStateNormal];
        [_closeBtn setImage:WMQueuePlayerImage(@"close") forState:UIControlStateSelected];
    }
    
    self.rightTimeLabel.text = [self convertTime:0.0];//设置默认值
    dataSource = [NSMutableArray array];
    self.currentIndex = -1;
}
#pragma mark
#pragma mark - 关闭按钮点击func
-(void)colseTheVideo:(UIButton *)sender{
    if (self.delegate&&[self.delegate respondsToSelector:@selector(wmplayer:clickedCloseButton:)]) {
//        [self.delegate wmplayer:self clickedCloseButton:sender];
    }
}
-(void)setQueuePlayer{
    if (self.queuePlayer==nil) {
        self.queuePlayer = [AVQueuePlayer queuePlayerWithItems:dataSource];
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.queuePlayer];
        self.playerLayer.frame = self.bounds;
        self.playerLayer.videoGravity = AVLayerVideoGravityResize;
        [self.contentView.layer insertSublayer:_playerLayer atIndex:0];
    }
}
-(void)addPlayerTimeObserver{
    __weak typeof(self) weakSelf = self;
    self.playbackTimeObserver =  [self.queuePlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [weakSelf syncSlider];
    }];
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
        
        if (self.isDragingSlider==YES) {//拖拽slider中，不更新slider的值
            
        }else if(self.isDragingSlider==NO){
            [self.progressSlider setValue:(maxValue - minValue) * currentTime / duration + minValue];
        }
    }
}


-(void)setCloseBtnStyle:(CloseBtnStyle)closeBtnStyle{
    _closeBtnStyle = closeBtnStyle;
    if (closeBtnStyle==CloseBtnStylePop) {
        [_closeBtn setImage:WMQueuePlayerImage(@"play_back.png") forState:UIControlStateNormal];
        [_closeBtn setImage:WMQueuePlayerImage(@"play_back.png") forState:UIControlStateSelected];
        
    }else{
        [_closeBtn setImage:WMQueuePlayerImage(@"close") forState:UIControlStateNormal];
        [_closeBtn setImage:WMQueuePlayerImage(@"close") forState:UIControlStateSelected];
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
//// 开始拖动
//- (void)beiginSliderScrubbing{
//    self.isDragingSlider = YES;
//
//}
//// 结束拖动
//- (void)endSliderScrubbing{
//    self.isDragingSlider = NO;
//    [self.queuePlayer seekToTime:CMTimeMakeWithSeconds(self.progressSlider.value,self.queuePlayer.currentItem.currentTime.timescale)];
//}
//// 拖动值发生改变
//- (void)sliderScrubbing{
//    
//}
#pragma mark
#pragma mark--开始拖曳sidle
- (void)stratDragSlide:(UISlider *)slider{
    self.isDragingSlider = YES;
}
#pragma mark
#pragma mark - 播放进度,点击事件
- (void)updateProgress:(UISlider *)slider{
    self.isDragingSlider = NO;
    [self.queuePlayer seekToTime:CMTimeMakeWithSeconds(slider.value,self.queuePlayer.currentItem.currentTime.timescale)];
}
#pragma mark - 全屏按钮,点击事件
- (void)fullScreenAction:(UIButton *)sender{
    NSLog(@"fullScreenAction");
//    [self nextItem];

    [self lastItem];
}
- (void)play {
    if (_isPlaying==NO) {
        [self.queuePlayer play];
        self.playOrPauseBtn.selected = NO;
        _isPlaying = YES;
        self.titleLabel.text = [NSString stringWithFormat:@"%li",self.queuePlayer.items.count];
        [self addKVO2CurrentItem];
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
    [self.queuePlayer removeAllItems];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:urls[0]];
    if ([self.queuePlayer canInsertItem:item afterItem:nil]) {
        [self.queuePlayer insertItem:item afterItem:nil];
    }
    [self addItemsDidPlayToEndNotifications];
}

- (void)addUrls:(NSArray<NSURL *> *)urls {
    
    
    NSArray *playItems = _queuePlayer.items;
    if (playItems.count == 0) {
        
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:urls[0]];
        if ([self.queuePlayer canInsertItem:item afterItem:nil]) {
            [self.queuePlayer insertItem:item afterItem:nil];
        }
    }
    [self addItemsDidPlayToEndNotifications];
}
///设置需要播放数据源数组
-(void)setURLArray:(NSArray<NSURL *> *)URLArray{
    
    if (URLArray.count) {
        for (NSURL *url in URLArray) {
            [dataSource addObject:[AVPlayerItem playerItemWithURL:url]];
        }
        [self setQueuePlayer];
        [self addPlayerTimeObserver];
        [self addItemsDidPlayToEndNotifications];
    }
}
//为currentItem添加kvo
-(void)addKVO2CurrentItem{
    AVPlayerItem *currentItem = self.queuePlayer.currentItem;
    if (currentItem) {
        [currentItem addObserver:self
                       forKeyPath:@"status"
                          options:NSKeyValueObservingOptionNew
                          context:PlayViewStatusObservationContext];
        
        [currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
        // 缓冲区空了，需要等待数据
        [currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options: NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
        // 缓冲区有足够数据可以播放了
        [currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options: NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
        
        [currentItem addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
    }

}
//为currentItem移除kvo
-(void)removeKVO2CurrentItem{
    AVPlayerItem *currentItem = self.queuePlayer.currentItem;
    if (currentItem) {
        [currentItem removeObserver:self forKeyPath:@"status"];
        [currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [currentItem removeObserver:self forKeyPath:@"duration"];
        

    }
}
-(void)addItemsDidPlayToEndNotifications{
    NSArray *items = self.queuePlayer.items;
    if (items.count) {
        for (AVPlayerItem *item in items) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:item];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(playerItemDidEndPlay:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:item];
        }
    }
}
#pragma mark
#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    /* AVPlayerItem "status" property value observer. */
    
    if (context == PlayViewStatusObservationContext)
    {
        if ([keyPath isEqualToString:@"status"]) {
            AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            switch (status)
            {
                    /* Indicates that the status of the player is not yet known because
                     it has not tried to load new media resources for playback */
                case AVPlayerStatusUnknown:
                {
                    [self.loadingProgress setProgress:0.0 animated:NO];
                    NSLog(@"%s WMPlayerStateBuffering",__FUNCTION__);
                    
                    self.state = WMQueuePlayerStateBuffering;
                    [self.loadingView startAnimating];
                }
                    break;
                    
                case AVPlayerStatusReadyToPlay:
                {
                    self.state = WMQueuePlayerStatePlaying;
                    
                    /* Once the AVPlayerItem becomes ready to play, i.e.
                     [playerItem status] == AVPlayerItemStatusReadyToPlay,
                     its duration can be fetched from the item. */
                    //                    if (CMTimeGetSeconds(_currentItem.duration)) {
                    //
                    //                        totalTime = CMTimeGetSeconds(_currentItem.duration);
                    //                        if (!isnan(totalTime)) {
                    //                            self.progressSlider.maximumValue = totalTime;
                    //                            NSLog(@"totalTime = %f",totalTime);
                    //
                    //                        }
                    //                    }
                    //监听播放状态
                    
                    
                    //5s dismiss bottomView
//                    if (self.autoDismissTimer==nil) {
//                        self.autoDismissTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(autoDismissBottomView:) userInfo:nil repeats:YES];
//                        [[NSRunLoop currentRunLoop] addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
//                    }
                    
//                    if (self.delegate&&[self.delegate respondsToSelector:@selector(wmplayerReadyToPlay:WMPlayerStatus:)]) {
//                        [self.delegate wmplayerReadyToPlay:self WMPlayerStatus:WMPlayerStatePlaying];
//                    }
                    //here
                    
                    [self.loadingView stopAnimating];
                    // 跳到xx秒播放视频
//                    if (self.seekTime) {
//                        [self seekToTimeToPlay:self.seekTime];
//                    }
                    
                }
                    break;
                    
                case AVPlayerStatusFailed:
                {
                    self.state = WMQueuePlayerStateFailed;
                    NSLog(@"%s WMPlayerStateFailed",__FUNCTION__);
                    
//                    if (self.delegate&&[self.delegate respondsToSelector:@selector(wmplayerFailedPlay:WMPlayerStatus:)]) {
//                        [self.delegate wmplayerFailedPlay:self WMPlayerStatus:WMQueuePlayerStateFailed];
//                    }
                    NSError *error = [self.queuePlayer.currentItem error];
                    if (error) {
                        self.loadFailedLabel.hidden = NO;
                        [self bringSubviewToFront:self.loadFailedLabel];
                        //here
                        [self.loadingView stopAnimating];
                        [self pause];
                        [self.playerLayer removeFromSuperlayer];
                    }
                    NSLog(@"视频加载失败===%@",error.description);
                }
                    break;
            }
            
        }else if ([keyPath isEqualToString:@"duration"]) {
            if ((CGFloat)CMTimeGetSeconds(self.queuePlayer.currentItem.duration) != currentItemDuration) {
                currentItemDuration = (CGFloat)CMTimeGetSeconds(self.queuePlayer.currentItem.duration);
                self.progressSlider.maximumValue = currentItemDuration;
                self.state = WMQueuePlayerStatePlaying;
            }
        }
        else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            
            // 计算缓冲进度
            NSTimeInterval timeInterval = [self availableDuration];
            CMTime duration             = self.queuePlayer.currentItem.duration;
            CGFloat totalDuration       = CMTimeGetSeconds(duration);
            //缓冲颜色
            self.loadingProgress.progressTintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7];
            [self.loadingProgress setProgress:timeInterval / totalDuration animated:NO];
            
            
        } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            [self.loadingView startAnimating];
            // 当缓冲是空的时候
            if (self.queuePlayer.currentItem.playbackBufferEmpty) {
                self.state = WMQueuePlayerStateBuffering;
                NSLog(@"%s WMPlayerStateBuffering",__FUNCTION__);
                
                [self loadedTimeRanges];
            }
            
        } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            //here
            [self.loadingView stopAnimating];
            // 当缓冲好的时候
            if (self.queuePlayer.currentItem.playbackLikelyToKeepUp && self.state == WMQueuePlayerStateBuffering){
                NSLog(@"55555%s WMPlayerStatePlaying",__FUNCTION__);
                
                self.state = WMQueuePlayerStatePlaying;
            }
            
        }
    }
    
}
/**
 *  缓冲回调
 */
- (void)loadedTimeRanges
{
    self.state = WMQueuePlayerStateBuffering;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.queuePlayer play];
        //here
        [self.loadingView stopAnimating];
    });
}
/**
 *  设置播放的状态
 *  @param state WMQueuePlayerState
 */
- (void)setState:(WMQueuePlayerState)state
{
    _state = state;
    // 控制菊花显示、隐藏
    if (state == WMQueuePlayerStateBuffering) {
        [self.loadingView startAnimating];
    }else if(state == WMQueuePlayerStatePlaying){
        //here
        [self.loadingView stopAnimating];//
    }else if(state == WMQueuePlayerStatePause){
        //here
        [self.loadingView stopAnimating];//
    }
    else{
        //here
        [self.loadingView stopAnimating];//
    }
}

#pragma mark
#pragma mark playItemAtIndex
///从第index处开始播放，index从0开始
- (void)playItemAtIndex:(NSInteger)index
{
    self.currentIndex = index;
    if (self.queuePlayer.items.count) {
        [self.queuePlayer removeAllItems];
    }else{
        return;
    }
    for (NSInteger i = index; i <dataSource.count; i ++) {
        AVPlayerItem* obj = [dataSource objectAtIndex:i];
        if ([self.queuePlayer  canInsertItem:obj afterItem:nil]) {
            [obj seekToTime:kCMTimeZero];
            [self.queuePlayer  insertItem:obj afterItem:nil];
           
        }
    }
    if (_isPlaying==NO) {
        [self play];
    }
    if ([self.delegate respondsToSelector:@selector(wmQueuePlayer:itemDidChanged:)]) {
        [self.delegate wmQueuePlayer:self itemDidChanged:self.queuePlayer.currentItem];
    }
    
}
#pragma mark
#pragma mark lastItem 上一首⏮
- (void)lastItem {
    _isPlaying = NO;
    if (self.currentIndex==0) {//如果现在播放的为第0个
        if (self.isLoopPlay) {//如果允许循环播放，那么播放最后一个
            [self removeKVO2CurrentItem];//先移除旧的
            [self playItemAtIndex:dataSource.count-1];
        }else{
            return;
        }
    }else{
        [self removeKVO2CurrentItem];//先移除旧的

        [self playItemAtIndex:--self.currentIndex];
    }
}
#pragma mark
#pragma mark nextItem 下一首⏭
- (void)nextItem {
    _isPlaying = NO;

    if (self.queuePlayer.items.count>1) {//大于1个视频，2个以上，说明之前添加过kvo
        [self removeKVO2CurrentItem];//先移除旧的
        [self.queuePlayer advanceToNextItem];
        [self addKVO2CurrentItem];//添加新的
        _isPlaying = YES;
        self.currentIndex++;
        if ([self.delegate respondsToSelector:@selector(wmQueuePlayer:itemDidChanged:)]) {
            [self.delegate wmQueuePlayer:self itemDidChanged:self.queuePlayer.currentItem];
        }
    }else{
        if (self.isLoopPlay) {//如果设置了循环播放，那么播放第0个
            [self removeKVO2CurrentItem];//先移除旧的
            [self playItemAtIndex:0];
        }
    }
    
}
#pragma mark 
#pragma mark playerItemDidEndPlay
- (void)playerItemDidEndPlay:(NSNotification *)notice {
    _isPlaying = NO;
    NSLog(@"播放完毕");

    if ([self.delegate respondsToSelector:@selector(wmQueuePlayer:itemDidPlayToEnd:)]) {
        AVPlayerItem *item = (AVPlayerItem *)notice.object;
        [self.delegate wmQueuePlayer:self itemDidPlayToEnd:item];
    }
    
    if (self.queuePlayer.items.count>1) {//如果>1,说明不是最后一个，还可以下一首
        [self nextItem];
    }else{//这里处理最后一首的情况
        if (self.isLoopPlay) {//先判断是不是设置了循环播放，如果设置了循环播放，那么从第0个开始
            [self playItemAtIndex:0];
        }
    }
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
/**
 *  计算缓冲进度
 *
 *  @return 缓冲进度
 */
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [self.queuePlayer.currentItem loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}
- (void)dealloc {
    NSLog(@"WMQueuePlayer dealloc");
    [self removeKVO2CurrentItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
