//
//  WMQueuePlayer.m
//  WMQueuePlayer
//
//  Created by 郑文明 on 16/9/20.
//  Copyright © 2016年 郑文明. All rights reserved.
//

#import "WMQueuePlayer.h"

@interface WMQueuePlayer ()<UIGestureRecognizerDelegate>{
    NSMutableArray      *_nextUrls;
    NSMutableArray      *_playedUrls;
  }

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
    _playedUrls = [NSMutableArray arrayWithCapacity:0];
    _nextUrls = [NSMutableArray arrayWithCapacity:0];
    _queuePlayer = [AVQueuePlayer queuePlayerWithItems:@[]];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_queuePlayer];
    self.playerLayer.frame = self.bounds;
    self.playerLayer.videoGravity = AVLayerVideoGravityResize;
    [self.layer insertSublayer:_playerLayer atIndex:0];
    __weak typeof(self) weakSelf = self;
    [_queuePlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [weakSelf resetProgress:time];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidEndPlay:) name:AVPlayerItemDidPlayToEndTimeNotification object:_queuePlayer.currentItem];
    
}
- (void)resetProgress:(CMTime)time {
    
    AVPlayerItem *item = _queuePlayer.currentItem;
    
    NSTimeInterval current = CMTimeGetSeconds(item.currentTime);
    NSTimeInterval duation = CMTimeGetSeconds(item.duration);
    if (_progress) {
        _progress(current, duation);
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
        _isPlaying = true;
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
        
        _isPlaying = true;
        [_queuePlayer play];
    }
}



- (void)play {

    
    [self.queuePlayer play];
    _isPlaying = true;
}

- (void)pause {
    [self.queuePlayer pause];
    _isPlaying = true;
}

- (void)playerItemDidEndPlay:(NSNotification *)tifi {
    _isPlaying = false;
    if ([_delegate respondsToSelector:@selector(queuePlayerEndPlayed:)]) {
        
        AVPlayerItem *item = tifi.object;
        
        [_delegate queuePlayerEndPlayed:item];
    }
}

- (AVQueuePlayer *)queuePlayer {
    return _queuePlayer;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
