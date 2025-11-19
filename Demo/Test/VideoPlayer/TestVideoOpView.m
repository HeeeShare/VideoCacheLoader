//
//  TestVideoOpView.m
//  chat
//
//  Created by Test on 2023/12/4.
//

#define indicatorGap 8

#import "TestVideoOpView.h"

@interface TestVideoOpView()
@property (nonatomic,strong) UIView *progressBV;
@property (nonatomic,strong) UIView *lineCV;
@property (nonatomic,strong) UIView *playedLV;
@property (nonatomic,strong) UIView *bufferLV;
@property (nonatomic,strong) UIView *indicatorBV;
@property (nonatomic,strong) UIView *indicatorView;
@property (nonatomic,strong) UILabel *totalTL;
@property (nonatomic,strong) UILabel *playedTL;
@property (nonatomic,assign) CGFloat playRate;
@property (nonatomic,assign) CGFloat panLocation;
@property (nonatomic,assign) CGFloat totalIndiW;
@property (nonatomic,strong) NSTimer *hideTimer;
@property (nonatomic,assign) BOOL firstLyFlag;
@property (nonatomic,strong) UIImageView *shadowIV;
@property (nonatomic,assign) CGFloat lineVH;
@property (nonatomic,assign) BOOL large;

@end

@implementation TestVideoOpView

- (void)tapSelf {
    if (!self.closeHideItems) {
        if (self.playBtn.alpha == 1.0) {
            [self Test_hideTimerAction];
        }else{
            [self Test_showItems];
            [self Test_hideItems];
        }
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self Test_setupUI];
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSelf)];
        [self addGestureRecognizer:tapGes];
    }
    
    return self;
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    [self Test_clearTimer];
    if (_hideTimer) {
        [_hideTimer invalidate];
        _hideTimer = nil;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self Test_setupFrame];
    
    if (self.frame.size.width > 0) {
        self.firstLyFlag = NO;
    }
}

- (void)setDuration:(CGFloat)duration {
    _duration = duration;
    self.totalTL.text = [self Test_getTimeStr:duration];
}

- (void)setCurrentPT:(CGFloat)currentPT {
    _currentPT = currentPT;
    
    if (self.duration > 0 && currentPT >=0 &&  currentPT <= self.duration) {
        self.playRate = (float)currentPT/self.duration;
        if (self.playRate > 1) {
            self.playRate = 1;
        }
        self.playedTL.text = [self Test_getTimeStr:currentPT];
        [self Test_updatePlayRate];
    }
}

- (void)setIndicatorColor:(UIColor *)ic {
    _IndicatorColor = ic;
    self.indicatorView.backgroundColor = ic;
}

- (void)setIndicatorSize:(CGFloat)is {
    _IndicatorSize = is;
    self.indicatorView.frame = CGRectMake(self.indicatorView.frame.origin.x, self.indicatorView.frame.origin.y, is, is);
    self.indicatorView.layer.cornerRadius = is/2;
}

- (void)setPlayedPColor:(UIColor *)PlayedPColor {
    _PlayedPColor = PlayedPColor;
    self.playedLV.backgroundColor = PlayedPColor;
}

- (void)setBufferPColor:(UIColor *)BufferPColor {
    _BufferPColor = BufferPColor;
    self.bufferLV.backgroundColor = BufferPColor;
}

- (void)setVideoBT:(CGFloat)videoBT {
    _videoBT = videoBT;
    if (self.duration <= 0) return;
    
    CGFloat bRate = videoBT/self.duration;
    if (bRate > 1) {
        bRate = 1;
    }
    self.bufferLV.frame = CGRectMake(self.playedLV.frame.origin.x, 0, self.lineCV.bounds.size.width*bRate, self.playedLV.frame.size.height);
}

- (void)showItemView {
    [self Test_clearTimer];
    [self Test_showItems];
}

- (void)hideItemViewDelay:(BOOL)delay {
    if (delay) {
        [self Test_hideItems];
    }else{
        [self Test_hideTimerAction];
    }
}

- (void)seekToRate:(CGFloat)rate {
    self.playRate = rate;
    self.currentPT = self.playRate*self.duration;
    
    if (!_closeUpdatePlayTime && self.delegate && [self.delegate respondsToSelector:@selector(videoOpView:seekToTime:)]) {
        [self.delegate videoOpView:self seekToTime:self.currentPT];
    }
}

#pragma mark - private action
- (void)Test_setupUI {
    self.PlayedPColor = [UIColor systemGreenColor];
    self.IndicatorColor = [UIColor whiteColor];
    self.lineVH = 4;
    self.IndicatorSize = 10;
    
    self.firstLyFlag = YES;
    [self addSubview:self.shadowIV];
    [self addSubview:self.progressBV];
    [self.progressBV addSubview:self.totalTL];
    [self.progressBV addSubview:self.playedTL];
    [self.progressBV addSubview:self.lineCV];
    [self.lineCV addSubview:self.bufferLV];
    [self.lineCV addSubview:self.playedLV];
    [self.progressBV addSubview:self.indicatorBV];
    [self.indicatorBV addSubview:self.indicatorView];
    [self addSubview:self.playBtn];
}

- (void)Test_setupFrame {
    [UIView animateWithDuration:self.firstLyFlag?0:0.3 animations:^{
        self.progressBV.frame = CGRectMake(self.progressInsets.left, self.bounds.size.height - 40 - self.progressInsets.bottom, self.bounds.size.width - self.progressInsets.left - self.progressInsets.right, 40);
        self.playBtn.frame = CGRectMake((self.bounds.size.width - 60)/2, (self.bounds.size.height - 60)/2, 60, 60);
        self.playedTL.frame = CGRectMake(8, 0, 50, 40);
        self.totalTL.frame = CGRectMake(self.progressBV.bounds.size.width - 50, 0, 50, 40);
        self.indicatorView.center = CGPointMake(self.indicatorBV.bounds.size.width/2, self.indicatorBV.bounds.size.height/2);
        [self Test_updatePlayRate];
        [self setVideoBT:self.videoBT];
        self.shadowIV.frame = CGRectMake(0, self.progressBV.frame.origin.y - 20, self.bounds.size.width, self.bounds.size.height - (self.progressBV.frame.origin.y - 20));
    }];
}

- (void)Test_updatePlayRate {
    self.totalIndiW = self.totalTL.frame.origin.x - CGRectGetMaxX(self.playedTL.frame) - 2*indicatorGap;
    
    self.lineCV.frame = CGRectMake(CGRectGetMaxX(self.playedTL.frame) + indicatorGap, CGRectGetMidY(self.totalTL.frame) - self.lineVH/2, self.totalIndiW, self.lineVH);
    self.playedLV.frame = CGRectMake(0, 0, self.lineCV.bounds.size.width*self.playRate, self.lineCV.bounds.size.height);
    self.indicatorBV.center = CGPointMake(self.lineCV.frame.origin.x + CGRectGetMaxX(self.playedLV.frame), CGRectGetMidY(self.lineCV.frame));
}

- (void)Test_playBtnClick {
    self.playBtn.selected = !self.playBtn.selected;
    
    if (self.playBtn.selected) {
        if (self.delegate || [self.delegate respondsToSelector:@selector(videoOpViewPlayVideo:)]) {
            [self.delegate videoOpViewPlayVideo:self];
        }
        [self Test_hideItems];
    }else{
        [self Test_clearTimer];
        if (self.delegate || [self.delegate respondsToSelector:@selector(videoOpViewPauseVideo:)]) {
            [self.delegate videoOpViewPauseVideo:self];
        }
    }
}

- (void)Test_clearTimer {
    if (_hideTimer) {
        [_hideTimer invalidate];
        _hideTimer = nil;
    }
}

- (void)Test_handleIndicatorGes:(UIPanGestureRecognizer *)panGes {
    if (self.duration<=0) return;
    
    if (panGes.state == UIGestureRecognizerStateBegan) {
        self.panLocation = self.indicatorBV.center.x;
        self.panFlag = YES;
    }
    
    CGPoint translatedPoint = [panGes translationInView:self.indicatorBV];
    self.panLocation+=translatedPoint.x;
    self.playRate = (self.panLocation - self.lineCV.frame.origin.x)/self.totalIndiW;
    if (self.playRate<=0) {
        self.playRate = 0;
    }else if (self.playRate>=1.0) {
        self.playRate = 1.0;
    }
    self.currentPT = self.playRate*self.duration;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoOpView:seekToTime:)]) {
        [self.delegate videoOpView:self seekToTime:self.currentPT];
    }
    
    [self Test_clearTimer];
    [self Test_showItems];
    if (panGes.state == UIGestureRecognizerStateEnded) {
        self.panFlag = NO;
        [self Test_hideItems];
    }
    
    [panGes setTranslation:CGPointMake(0, 0) inView:self.indicatorBV];
}

- (void)Test_showItems {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoOpViewWillShow:)]) {
        [self.delegate videoOpViewWillShow:self];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        for (UIView *subView in self.subviews) {
            subView.alpha = 1.0;
        }
    }];
}

- (void)Test_hideItems {
    if (self.canHideItemViewFlag) {
        [self Test_clearTimer];
        _hideTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(Test_hideTimerAction) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:_hideTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)Test_hideTimerAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoOpViewWillHide:)]) {
        [self.delegate videoOpViewWillHide:self];
    }
    
    if (!_large) {
        [UIView animateWithDuration:0.3 animations:^{
            if (self.progressBV.alpha != 0) {
                self.progressBV.alpha = 0;
                self.shadowIV.alpha = self.progressBV.alpha;
            }
            
            self.playBtn.alpha = 0;
        }];
    }
}

- (NSString *)Test_getTimeStr:(CGFloat)text_time {
    int text_min,text_sec;
    text_min = (int)ceil(text_time)/60;
    text_sec = (int)floor(text_time)%60;
    if (text_time - text_min*60 - text_sec >= 0.5) {
        text_sec+=1;
    }
    
    return [NSString stringWithFormat:@"%02d:%02d",text_min,text_sec];
}

#pragma mark - lazy
- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [[UIButton alloc] init];
        _playBtn.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        _playBtn.layer.masksToBounds = YES;
        [_playBtn setImage:[UIImage imageNamed:@"test_pause"] forState:UIControlStateSelected];
        [_playBtn setImage:[UIImage imageNamed:@"test_play"] forState:UIControlStateNormal];
        [_playBtn setImageEdgeInsets:UIEdgeInsetsMake(16, 16, 16, 16)];
        _playBtn.layer.cornerRadius = 30;
        _playBtn.selected = NO;
        _playBtn.adjustsImageWhenHighlighted = NO;
        [_playBtn addTarget:self action:@selector(Test_playBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _playBtn;
}

- (UIView *)progressBV {
    if (!_progressBV) {
        _progressBV = [[UIView alloc] init];
    }
    
    return _progressBV;
}

- (UIView *)lineCV {
    if (!_lineCV) {
        _lineCV = [[UIView alloc] init];
        _lineCV.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        _lineCV.layer.cornerRadius = self.lineVH/2;
        _lineCV.layer.masksToBounds = YES;
    }
    
    return _lineCV;
}

- (UIView *)playedLV {
    if (!_playedLV) {
        _playedLV = [[UIView alloc] init];
    }
    
    return _playedLV;
}

- (UIView *)bufferLV {
    if (!_bufferLV) {
        _bufferLV = [[UIView alloc] init];
        _bufferLV.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    }
    
    return _bufferLV;
}

- (UIView *)indicatorBV {
    if (!_indicatorBV) {
        _indicatorBV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        [_indicatorBV addGestureRecognizer:self.indiPanGes];
    }
    
    return _indicatorBV;
}

- (UIPanGestureRecognizer *)indiPanGes {
    if (!_indiPanGes) {
        _indiPanGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(Test_handleIndicatorGes:)];
        [_indicatorBV addGestureRecognizer:_indiPanGes];
    }
    
    return _indiPanGes;
}

- (UIView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [UIView new];
    }
    
    return _indicatorView;
}

- (UILabel *)totalTL {
    if (!_totalTL) {
        _totalTL = [[UILabel alloc] init];
        _totalTL.textAlignment = NSTextAlignmentCenter;
        _totalTL.text = @"00:00";
        _totalTL.textColor = [UIColor whiteColor];
        _totalTL.font = [UIFont fontWithName:@"Avenir Next" size:14];
    }
    
    return _totalTL;
}

- (UILabel *)playedTL {
    if (!_playedTL) {
        _playedTL = [[UILabel alloc] init];
        _playedTL.textAlignment = NSTextAlignmentCenter;
        _playedTL.text = @"00:00";
        _playedTL.textColor = [UIColor whiteColor];
        _playedTL.font = [UIFont fontWithName:@"Avenir Next" size:14];
    }
    
    return _playedTL;
}

- (UIImageView *)shadowIV {
    if (!_shadowIV) {
        _shadowIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"text_shadow"]];
    }
    
    return _shadowIV;
}

@end
