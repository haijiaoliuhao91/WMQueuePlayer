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
// 枚举值，包含播放器左上角的关闭按钮的类型
typedef NS_ENUM(NSInteger, CloseBtnStyle){
    CloseBtnStylePop, //pop箭头<-
    CloseBtnStyleClose  //关闭（X）
};
// 播放器的几种状态
typedef NS_ENUM(NSInteger, WMQueuePlayerState) {
    WMQueuePlayerStateFailed,        // 播放失败
    WMQueuePlayerStateBuffering,     // 缓冲中
    WMQueuePlayerStatePlaying,       // 播放中
    WMQueuePlayerStateStopped,        //暂停播放
    WMQueuePlayerStateFinished,        //暂停播放
    WMQueuePlayerStatePause,       // 暂停播放
};
@class WMQueuePlayer;


@protocol WMQueuePlayerDelegate <NSObject>

@optional

/**
 WMQueuePlayer的当前item播放完毕后调用的代理方法

 @param player 播放器对象
 @param item 当前播放的AVPlayerItem对象
 @param currentIndex 播放器播放的item在dataSource中的index
 */
- (void)wmQueuePlayer:(WMQueuePlayer *)player itemDidPlayToEnd:(AVPlayerItem *)item index:(NSInteger )currentIndex;


/**
 WMQueuePlayer的当前item被切换为另一个item时候调用的代理方法

 @param player 播放器对象
 @param item 当前播放的AVPlayerItem对象
 @param currentIndex 播放器播放的item在dataSource中的index
 */
- (void)wmQueuePlayer:(WMQueuePlayer *)player itemDidChanged:(AVPlayerItem *)item index:(NSInteger )currentIndex;

/**
 WMQueuePlayer中的item加载完毕，内部解码成功，可以播放的时候调用的代理方法

 @param player 播放器对象
 @param item 当前播放的AVPlayerItem对象
 @param currentIndex 播放器播放的item在dataSource中的index
 */
- (void)wmQueuePlayer:(WMQueuePlayer *)player itemReadyToPlay:(AVPlayerItem *)item index:(NSInteger )currentIndex;

/**
 WMQueuePlayer中的closeBtn(关闭按钮)被点击后调用的代理方法

 @param player 播放器对象
 @param closeBtn 关闭按钮对象
 @param currentIndex 播放器播放的item在dataSource中的index
 */
- (void)wmQueuePlayer:(WMQueuePlayer *)player didClickedColsedBtn:(UIButton *)closeBtn index:(NSInteger )currentIndex;

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
 ＊  播放器左上角按钮的类型
 */
@property (nonatomic, assign) CloseBtnStyle   closeBtnStyle;

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
 *  左上角关闭按钮
 */
@property (nonatomic,retain ) UIButton       *closeBtn;
/**
 *  是否正在播放
 */
@property (nonatomic, assign, readonly) BOOL    isPlaying;

/**
 *  是否是循环播放
 */
@property (nonatomic, assign) BOOL    isLoopPlay;

/**
 ＊  播放器状态
 */
@property (nonatomic, assign) WMQueuePlayerState   state;
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
