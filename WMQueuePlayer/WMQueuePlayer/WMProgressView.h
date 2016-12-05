//
//  WMProgressView.h
//  WMQueuePlayer
//
//  Created by zhengwenming on 2016/12/4.
//  Copyright © 2016年 郑文明. All rights reserved.
//

#import <UIKit/UIKit.h>



@protocol WMProgressViewDelegate <NSObject>
// 开始拖动
- (void)beiginSliderScrubbing;
// 结束拖动
- (void)endSliderScrubbing;
// 拖动值发生改变
- (void)sliderScrubbing;
@end

@interface WMProgressView : UIView

@property (nonatomic, weak) id<WMProgressViewDelegate> delegate;

@property (nonatomic, assign) CGFloat minimumValue;
@property (nonatomic, assign) CGFloat maximumValue;

@property (nonatomic, assign) CGFloat value;
@property (nonatomic, assign) CGFloat trackValue;
/**
 *  背景颜色：
 playProgressBackgoundColor：播放背景颜色
 trackBackgoundColor ： 缓存条背景颜色
 progressBackgoundColor ： 整个bar背景颜色
 */
@property (nonatomic, strong) UIColor *playProgressBackgoundColor;
@property (nonatomic, strong) UIColor *trackBackgoundColor;
@property (nonatomic, strong) UIColor *progressBackgoundColor;

@end

@interface WMSliderBtn : UIButton

@end

