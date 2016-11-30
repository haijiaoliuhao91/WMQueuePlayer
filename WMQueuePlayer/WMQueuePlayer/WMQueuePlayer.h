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


@protocol WMQueuePlayerDelegate <NSObject>

@optional
- (void)queuePlayerEndPlayed:(AVPlayerItem *)item;

@end




@interface WMQueuePlayer : UIView
/**
 *  AVQueuePlayer 继承于 AVPlayer，所以可以播放视频、音频列表
 */
@property (nonatomic, strong,) AVQueuePlayer   *queuePlayer;
@property (nonatomic, assign) id<WMQueuePlayerDelegate> delegate;

/**
 *  播放进度回调
 */
@property (nonatomic, copy) void(^progress)(NSTimeInterval currentTime, NSTimeInterval duration);




/**
 *playerLayer,可以修改frame
 */
@property (nonatomic,retain ) AVPlayerLayer  *playerLayer;







/**
 *  是否正在播放
 */
@property (nonatomic, assign, readonly) BOOL    isPlaying;

/**
 *  设置播放列表
 *
 *  @param urls  列表url
 *  @param index 要播放的元素位置
 */
- (void)setUrls:(NSArray <NSURL *>*)urls index:(NSInteger)index;

/**
 *  上一首
 */
- (void)lastItem;

/**
 *  下一首
 */
- (void)nextItem;

/**
 *  播放
 */
- (void)play;

/**
 *  暂停
 */
- (void)pause;


@end
