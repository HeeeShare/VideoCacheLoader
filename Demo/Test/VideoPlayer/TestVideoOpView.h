//
//  TestVideoOpView.h
//  chat
//
//  Created by Test on 2023/12/4.
//

#import <UIKit/UIKit.h>
@class TestVideoOpView;

@protocol TestVideoControlViewDelegate <NSObject>
- (void)videoOpViewPlayVideo:(TestVideoOpView *)TestOpBar;
- (void)videoOpViewPauseVideo:(TestVideoOpView *)TestOpBar;
- (void)videoOpView:(TestVideoOpView *)TestOpBar seekToTime:(CGFloat)time;
- (void)videoOpViewWillShow:(TestVideoOpView *)TestOpBar;
- (void)videoOpViewWillHide:(TestVideoOpView *)TestOpBar;
- (void)videoOpViewClick:(TestVideoOpView *)TestOpBar;

@end

@interface TestVideoOpView : UIView
@property (nonatomic,assign,readonly) CGFloat playRate;
@property (nonatomic,strong,readonly) UIView *lineCV;
@property (nonatomic,strong,readonly) UIView *progressBV;
@property (nonatomic,strong,readonly) UIImageView *shadowIV;
@property (nonatomic,strong) UIButton *playBtn;
@property (nonatomic,strong) UIColor *PlayedPColor;
@property (nonatomic,strong) UIColor *BufferPColor;
@property (nonatomic,strong) UIColor *IndicatorColor;
@property (nonatomic,assign) CGFloat IndicatorSize;
@property (nonatomic,strong) UIPanGestureRecognizer *indiPanGes;
@property (nonatomic,assign) CGFloat duration;
@property (nonatomic,assign) CGFloat currentPT;
@property (nonatomic,assign) CGFloat videoBT;
@property (nonatomic,assign) UIEdgeInsets progressInsets;
@property (nonatomic,assign) BOOL panFlag;
@property (nonatomic,assign) BOOL canHideItemViewFlag;
@property (nonatomic,assign) BOOL closeHideItems;
@property (nonatomic,assign) BOOL closeUpdatePlayTime;
@property (nonatomic,weak) id <TestVideoControlViewDelegate> delegate;
- (void)showItemView;
- (void)hideItemViewDelay:(BOOL)delay;
- (void)seekToRate:(CGFloat)rate;

@end
