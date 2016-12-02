//
//  WMQueuePlayer.h
//  WMQueuePlayer
//
//  Created by 郑文明 on 16/9/20.
//  Copyright © 2016年 郑文明. All rights reserved.
//


#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class WMQueuePlayer;
@protocol WMQueuePlayerDelegate <NSObject>

@optional

- (void)wmQueuePlayer:(WMQueuePlayer *)player itemDidPlayToEnd:(AVPlayerItem *)item;
- (void)wmQueuePlayer:(WMQueuePlayer *)player itemDidChanged:(AVPlayerItem *)item;

@end




@interface WMQueuePlayer : UIView
/**
 *  AVQueuePlayer 继承于 AVPlayer，所以可以播放视频、音频列表
 */
@property (nonatomic, strong) AVQueuePlayer   *queuePlayer;
@property (nonatomic, assign) id<WMQueuePlayerDelegate> delegate;


/**
 *playerLayer,可以修改frame
 */
@property (nonatomic,retain ) AVPlayerLayer  *playerLayer;



/**
 *  底部操作工具栏
 */
@property (nonatomic,strong ) UIImageView         *bottomView;
/**
 *  顶部操作工具栏
 */
@property (nonatomic,strong ) UIImageView         *topView;

/**
 *  显示播放视频的title
 */
@property (nonatomic,strong) UILabel        *titleLabel;

/**
 *  WMQueuePlayer内部一个UIView，所有的控件统一管理在此view中
 */
@property (nonatomic,strong) UIView        *contentView;
/**
 *  控制全屏的按钮
 */
@property (nonatomic,retain ) UIButton       *fullScreenBtn;
/**
 *  播放暂停按钮
 */
@property (nonatomic,retain ) UIButton       *playOrPauseBtn;
/**
 *  是否正在播放
 */
@property (nonatomic, assign, readonly) BOOL    isPlaying;

/**
 *  是否是循环播放
 */
@property (nonatomic, assign) BOOL    isLoopPlay;


/**
 *  当前播放器播放的视频资源index，如果没有播放，返回-1
 */
@property (nonatomic, assign) NSInteger    currentIndex;

/**
 *  设置播放视频的URLArray数组，可以是本地的路径也可以是http的网络路径
 */
@property (nonatomic,copy) NSArray<NSURL *> *URLArray;


/**
 *  播放上一个
 */
- (void)lastItem;

/**
 *  播放下一个
 */
- (void)nextItem;

/**
 *  播放
 */
- (void)play;
/**
 *  从第index处播放
 */
- (void)playItemAtIndex:(NSInteger)index;
/**
 *  暂停
 */
- (void)pause;


@end
