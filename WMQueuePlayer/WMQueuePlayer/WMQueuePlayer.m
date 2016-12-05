//
//  WMQueuePlayer.m
//  WMQueuePlayer
//
//  Created by 郑文明 on 16/9/20.
//  Copyright © 2016年 郑文明. All rights reserved.
//

#import "WMQueuePlayer.h"
#import "Masonry.h"
#import "WMProgressView.h"


#define WMQueuePlayerSrcName(file) [@"WMQueuePlayer.bundle" stringByAppendingPathComponent:file]
#define WMQueuePlayerFrameworkSrcName(file) [@"Frameworks/WMQueuePlayer.framework/WMQueuePlayer.bundle" stringByAppendingPathComponent:file]

#define WMQueuePlayerImage(file)      [UIImage imageNamed:WMQueuePlayerSrcName(file)] ? :[UIImage imageNamed:WMQueuePlayerFrameworkSrcName(file)]

@interface WMQueuePlayer ()<UIGestureRecognizerDelegate,WMProgressViewDelegate>{
    NSMutableArray *dataSource;
  }
//监听播放起状态的监听者
@property (nonatomic ,strong) id playbackTimeObserver;
@property (nonatomic, strong) WMProgressView *progressSlider;
/**
 *  显示播放时间的UILabel
 */
@property (nonatomic,strong) UILabel        *leftTimeLabel;
@property (nonatomic,strong) UILabel        *rightTimeLabel;
@property (nonatomic, strong)NSDateFormatter *dateFormatter;
@property (nonatomic, assign) BOOL isDragingSlider;//是否正在拖曳UISlider，默认为NO

@end


@implementation WMQueuePlayer

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
    
//    self.progressSlider = [[UISlider alloc]init];
//    self.progressSlider.minimumValue = 0.0;
//    [self.progressSlider setThumbImage:WMQueuePlayerImage(@"dot")  forState:UIControlStateNormal];
//    self.progressSlider.minimumTrackTintColor = [UIColor greenColor];
//    self.progressSlider.maximumTrackTintColor = [UIColor whiteColor];
//    self.progressSlider.backgroundColor = [UIColor clearColor];
//    self.progressSlider.value = 0.0;//指定初始值
//    //进度条的拖拽事件
//    [self.progressSlider addTarget:self action:@selector(stratDragSlide:)  forControlEvents:UIControlEventValueChanged];
//    //进度条的点击事件
//    [self.progressSlider addTarget:self action:@selector(updateProgress:) forControlEvents:UIControlEventTouchUpInside];
//    [self.bottomView addSubview:self.progressSlider];
//
//    //autoLayout slider
//    [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.equalTo(self.bottomView).with.offset(45);
//        make.right.equalTo(self.bottomView).with.offset(-45);
//        make.center.equalTo(self.bottomView);
//    }];

    
    
    
    
    self.progressSlider = [[WMProgressView alloc]initWithFrame:CGRectMake(0, 0, 320,50)];
    self.progressSlider.minimumValue = 0.0;
    self.progressSlider.playProgressBackgoundColor = [UIColor whiteColor];
    self.progressSlider.trackBackgoundColor = [UIColor greenColor];
    
//    self.progressSlider.minimumTrackTintColor = [UIColor greenColor];
//    self.progressSlider.maximumTrackTintColor = [UIColor whiteColor];
    self.progressSlider.backgroundColor = [UIColor orangeColor];
    self.progressSlider.value = 0.0;//指定初始值
    [self.bottomView addSubview:self.progressSlider];
    
    //autoLayout slider
//    [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.equalTo(self.bottomView).with.offset(45);
//        make.right.equalTo(self.bottomView).with.offset(-45);
//        make.center.equalTo(self.bottomView);
//    }];
    
    
    
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
    dataSource = [NSMutableArray array];
    self.currentIndex = -1;
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


- (CMTime)playerItemDuration
{
//    AVPlayerItem *currentItem = _queuePlayer.currentItem;
//
//    NSTimeInterval current = CMTimeGetSeconds(currentItem.currentTime);
//    NSTimeInterval duation = CMTimeGetSeconds(currentItem.duration);
    return [self.queuePlayer.currentItem duration];
}
// 开始拖动
- (void)beiginSliderScrubbing{
    self.isDragingSlider = YES;

}
// 结束拖动
- (void)endSliderScrubbing{
    self.isDragingSlider = NO;
    [self.queuePlayer seekToTime:CMTimeMakeWithSeconds(self.progressSlider.value,self.queuePlayer.currentItem.currentTime.timescale)];
}
// 拖动值发生改变
- (void)sliderScrubbing{
    
}
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
- (void)fullScreenAction:(UIButton *)sender{
    NSLog(@"fullScreenAction");
    [self lastItem];
}
- (void)play {
    if (_isPlaying==NO) {
        [self.queuePlayer play];
        self.playOrPauseBtn.selected = NO;
        _isPlaying = YES;
        self.titleLabel.text = [NSString stringWithFormat:@"%li",self.queuePlayer.items.count];
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
#pragma mark lastItem
///上一首⏮
- (void)lastItem {
    if (self.currentIndex==0) {//如果现在播放的为第0个
        if (self.isLoopPlay) {//如果允许循环播放，那么播放最后一个
            [self playItemAtIndex:dataSource.count-1];
        }else{
            return;
        }
    }else{
        [self playItemAtIndex:--self.currentIndex];
    }
}
#pragma mark
#pragma mark nextItem
///下一首⏭
- (void)nextItem {
    
    if (self.queuePlayer.items.count>1) {
        [self.queuePlayer advanceToNextItem];
        _isPlaying = YES;
        self.currentIndex++;
        if ([self.delegate respondsToSelector:@selector(wmQueuePlayer:itemDidChanged:)]) {
            [self.delegate wmQueuePlayer:self itemDidChanged:self.queuePlayer.currentItem];
        }
    }else{
        if (self.isLoopPlay) {//如果设置了循环播放，那么播放第0个
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
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
