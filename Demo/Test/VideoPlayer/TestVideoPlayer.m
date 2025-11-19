//
//  TestVideoPlayer.m
//  chat
//
//  Created by Test on 2023/12/4.
//

#import "TestVideoPlayer.h"

@implementation TestVideoPreView
+ (Class)layerClass {
    return [AVPlayerLayer class];
}
- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}
- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end

@interface TestVideoPlayer ()<TestVideoControlViewDelegate,VideoResourceLoaderHandlerDelegate>
@property (nonatomic,strong) TestVideoPreView *videoPreVV;
@property (nonatomic,strong) id VideoObserver;
@property (nonatomic,strong) AVPlayerItem *playerItem;
@property (nonatomic,assign) TestPlayerState playerState;
@property (nonatomic,strong) UIImageView *testLoadingIV;
@property (nonatomic,strong) UIImageView *testPIV;
@property (nonatomic,assign) CGFloat currentTime;
@property (nonatomic,strong) TestVideoOpView *videoOpView;
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,assign) BOOL playing;
@property (nonatomic,assign) BOOL pauseByEvents;
@property (nonatomic,assign) BOOL localVideo;
@property (nonatomic,strong) dispatch_queue_t testDurationQ;
@property (nonatomic,strong) dispatch_queue_t testSizeQ;
@property (nonatomic,assign) CGFloat seekRate;
@property (nonatomic,strong) VideoResourceLoaderHandler *videoLoader;

@end

@implementation TestVideoPlayer
- (void)dealloc {
    [self Test_removeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.playerItem = nil;
    NSLog(@"TestVideoPlayer : dealloc");
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self test_setupUI];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self test_setupUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self test_setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.testLoadingIV.center = CGPointMake(self.width/2, self.height/2);
        self.videoOpView.frame = self.bounds;
    }];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    if (self.thumbImage) {
        CGFloat videoWidth = self.bounds.size.width;
        CGFloat videoHeight = videoWidth*self.thumbImage.size.height/self.thumbImage.size.width;
        if (videoHeight > self.bounds.size.height) {
            videoHeight = self.bounds.size.height;
            videoWidth = videoHeight*self.thumbImage.size.width/self.thumbImage.size.height;
        }
        self.videoPreVV.frame = CGRectMake(0, 0, videoWidth, videoHeight);
        self.videoPreVV.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        self.testPIV.frame = self.videoPreVV.frame;
    }
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    self.videoOpView.duration = self.duration;
    if (self.duration == 0) {
        [self Test_getVideoDuration];
    }
}

- (void)setVideoUrl:(NSString *)videoUrl {
    _videoUrl = videoUrl;
    if (videoUrl) {
        if (!self.thumbImage) {
            [self Test_getVideoSize];
        }
        
        if (![videoUrl containsString:@"http"]) {
            self.localVideo = YES;
        }
        
        [self pause];
        [self Test_removeObserver];
        self.videoPreVV.player = nil;
        self.playerItem = nil;
        self.currentTime = 0;
        self.videoOpView.currentPT = self.currentTime;
        self.videoOpView.videoBT = 0;
        
        if (self.localVideo) {
            self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:self.videoUrl]];
        }else{
            _videoLoader = [[VideoResourceLoaderHandler alloc] initWithVideoUrl:[NSURL URLWithString:self.videoUrl]];
            _videoLoader.delegate = self;
            self.playerItem = _videoLoader.playerItem;
        }
        
        self.videoPreVV.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        [self Test_addObserver];
    }
}

- (void)setPlayerState:(TestPlayerState)playerState {
    _playerState = playerState;
    self.videoOpView.canHideItemViewFlag = playerState==TestPlayerStatePlaying;
}

- (void)setMute:(BOOL)mute {
    _mute = mute;
    [[AVAudioSession sharedInstance] setCategory:mute?AVAudioSessionCategoryAmbient:AVAudioSessionCategoryPlayback error:nil];
}

- (void)setThumbImage:(UIImage *)thumbImage {
    _thumbImage = thumbImage;
    [UIView animateWithDuration:0.25 animations:^{
        self.testPIV.alpha = 1.0;
    }];
    self.testPIV.image = thumbImage;
    
    if (thumbImage) {
        CGFloat videoW = self.width;
        CGFloat videoH = self.width*thumbImage.size.height/thumbImage.size.width;
        if (videoH > self.height) {
            videoH = self.height;
            videoW = videoH*thumbImage.size.width/thumbImage.size.height;
        }
        self.videoPreVV.frame = CGRectMake(0, 0, videoW, videoH);
        self.videoPreVV.center = CGPointMake(self.width/2, self.height/2);
        self.testPIV.frame = self.videoPreVV.frame;
    }
}

- (void)setThumbIVMode:(UIViewContentMode)thumbIVMode {
    _thumbIVMode = thumbIVMode;
    self.testPIV.contentMode = thumbIVMode;
}

- (void)play {
    if (self.playerState!=TestPlayerStatePlaying) [self Test_play];
}

- (void)pause {
    if (self.playerState!=TestPlayerStatePause) [self Test_pause];
}

- (void)seekToTime:(NSTimeInterval)time {
    self.currentTime = time;
    self.videoOpView.currentPT = time;
    [self.videoPreVV.player seekToTime:CMTimeMakeWithSeconds(time,30) toleranceBefore:CMTimeMake(1, 30) toleranceAfter:CMTimeMake(1, 30)];
}

- (void)showOpView {
    [self.videoOpView showItemView];
}

- (void)hideOpView:(BOOL)delay {
    [self.videoOpView hideItemViewDelay:delay];
}

#pragma mark - observer&notify
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        if (self.playerState==TestPlayerStatePlaying && self.playerItem.status==AVPlayerItemStatusReadyToPlay) {
            [self play];
        }else if (self.playerItem.status==AVPlayerItemStatusFailed){
            self.playerState = TestPlayerStateError;
            if (self.delegate && [self.delegate respondsToSelector:@selector(playerError:)]) {
                [self.delegate playerError:self];
            }
        }
        
        NSInteger status = [change[@"new"] integerValue];
        if (status == AVPlayerStatusReadyToPlay) {
            self.testLoadingIV.hidden = YES;
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        CGFloat sec = CMTimeGetSeconds(self.playerItem.duration);
        if (!isnan(sec) && self.duration != sec) {
            self.duration = sec;
            self.videoOpView.duration = self.duration;
            [self.videoPreVV.player seekToTime:CMTimeMakeWithSeconds(self.videoOpView.duration*self.seekRate,30) toleranceBefore:CMTimeMake(1, 30) toleranceAfter:CMTimeMake(1, 30)];
        }
        
        NSArray *test_array = self.videoPreVV.player.currentItem.loadedTimeRanges;
        CMTimeRange test_timeRange = [test_array.firstObject CMTimeRangeValue];
        NSTimeInterval test_totalBuffer = CMTimeGetSeconds(test_timeRange.start) + CMTimeGetSeconds(test_timeRange.duration);
        self.videoOpView.videoBT = test_totalBuffer;
        
        NSTimeInterval test_scale = 0.0;
        if (self.duration > 0.0) {
            test_scale = test_totalBuffer/self.duration;
        }
    }
}

- (void)TestDidEnterBG {
    [self Test_pauseByEventsStart];
}

- (void)TestDidBecomeActive {
    [self Test_playByEventsEnd];
}

#pragma mark - private
- (void)test_setupUI {
    self.backgroundColor = [UIColor blackColor];
    [self addSubview:self.videoPreVV];
    [self addSubview:self.testPIV];
    [self addSubview:self.testLoadingIV];
    [self addSubview:self.videoOpView];
    
    self.thumbIVMode = UIViewContentModeScaleAspectFit;
}

- (void)Test_play {
    if (self.playerState == TestPlayerStateError) {
        [self Test_reloadPlayerToPlay];
    }else{
        [self Test_playAction];
    }
    
    [self.timer invalidate];
    self.timer = nil;
    self.timer = [NSTimer timerWithTimeInterval:0.3 target:self selector:@selector(loadingTimerAction) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)Test_pause {
    [self.videoPreVV.player pause];
    self.videoOpView.playBtn.selected = NO;
    [self.videoOpView showItemView];
    [self.timer invalidate];
    self.timer = nil;
    self.playing = NO;
    self.testLoadingIV.hidden = YES;
    if (self.playerState == TestPlayerStatePlaying) {
        self.playerState = TestPlayerStatePause;
    }
}

- (void)stop {
    [self pause];
    [self seekToTime:0];
    self.videoOpView.videoBT = 0;
    [self Test_handlePlayFinished];
}

- (void)Test_playAction {
    if (self.playerState==TestPlayerStatePlayFinished) {
        [self.videoPreVV.player seekToTime:CMTimeMakeWithSeconds(self.videoOpView.currentPT,30) toleranceBefore:CMTimeMake(1, 30) toleranceAfter:CMTimeMake(1, 30)];
    }
    
    if (self.playerState==TestPlayerStateDefault && self.videoOpView.duration) {
        self.seekRate = self.videoOpView.currentPT/self.videoOpView.duration;
    }
    
    self.videoPreVV.player.volume = !self.mute;
    [self setMute:self.mute];
    [self.videoPreVV.player play];
    self.playerState = TestPlayerStatePlaying;
    self.videoOpView.playBtn.selected = YES;
    [self.videoOpView hideItemViewDelay:YES];
}

- (void)Test_clearTimer {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)Test_reloadPlayerToPlay {
    if (self.playerState==TestPlayerStatePlaying || self.playerState==TestPlayerStateError) {
        [self.videoPreVV.player pause];
        [self Test_removeObserver];
        
        self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:_videoUrl]];
        [self.videoPreVV.player replaceCurrentItemWithPlayerItem:self.playerItem];
        [self.videoPreVV.player seekToTime:CMTimeMakeWithSeconds(self.currentTime, 30) toleranceBefore:CMTimeMake(1, 30) toleranceAfter:CMTimeMake(1, 30)];
        [self Test_addObserver];
        [self.videoPreVV.player play];
        self.playerState = TestPlayerStatePlaying;
    }
}

- (void)loadingTimerAction {
    if (self.playerState == TestPlayerStatePlaying || self.playerState == TestPlayerStateError) {
        self.testLoadingIV.hidden = NO;
    }
}

- (void)Test_addObserver {
    __weak __typeof(self) Test_ews = self;
    self.VideoObserver = [self.videoPreVV.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        
        if (CMTimeGetSeconds(time) <= Test_ews.seekRate*Test_ews.duration) {
            return;
        }
        
        Test_ews.playing = YES;
        Test_ews.testLoadingIV.hidden = YES;
        [Test_ews.timer invalidate];
        Test_ews.timer = nil;
        Test_ews.timer = [NSTimer timerWithTimeInterval:0.3 target:Test_ews selector:@selector(loadingTimerAction) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:Test_ews.timer forMode:NSRunLoopCommonModes];
        
        Test_ews.seekRate = 0;
        Test_ews.currentTime = CMTimeGetSeconds(time);
        if (Test_ews.currentTime>=0.1) {
            [UIView animateWithDuration:0.3 animations:^{
                Test_ews.testPIV.alpha = 0;
            }];
        }
        
        if (Test_ews.delegate && [Test_ews.delegate respondsToSelector:@selector(player:playingAtTime:)]) {
            [Test_ews.delegate player:Test_ews playingAtTime:Test_ews.currentTime];
        }
        
        //播放完毕
        if (Test_ews.duration > 0 && Test_ews.duration - Test_ews.currentTime <= 0.0335 ) {
            [Test_ews Test_handlePlayFinished];
            if (Test_ews.delegate && [Test_ews.delegate respondsToSelector:@selector(playerFinished:)]) {
                [Test_ews.delegate playerFinished:Test_ews];
            }
        }
        
        if (!Test_ews.closeUpdatePlayTime && Test_ews.playerState == TestPlayerStatePlaying && !Test_ews.videoOpView.panFlag) {
            Test_ews.videoOpView.currentPT = Test_ews.currentTime;
        }
    }];
    
    [self.videoPreVV.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.videoPreVV.player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TestDidEnterBG) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(TestDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)Test_removeObserver {
    if (self.VideoObserver) {
        [self.videoPreVV.player removeTimeObserver:self.VideoObserver];
        self.VideoObserver = nil;
        [self.videoPreVV.player.currentItem cancelPendingSeeks];
        [self.videoPreVV.player.currentItem.asset cancelLoading];
        [self.videoPreVV.player.currentItem removeObserver:self forKeyPath:@"status"];
        [self.videoPreVV.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    }
}

- (void)Test_handlePlayFinished {
    self.playerState = TestPlayerStatePlayFinished;
    self.videoOpView.playBtn.selected = NO;
    [self.videoOpView showItemView];
    self.currentTime = 0;
    self.testPIV.alpha = 1.0;
    
    if (!self.videoOpView.panFlag) {
        self.videoOpView.currentPT = self.currentTime;
    }
}

- (void)Test_getVideoDuration {
    self.testDurationQ = dispatch_queue_create("com.Test.duration", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(self.testDurationQ, ^{
        NSURL*videoUrl = [NSURL URLWithString:self.videoUrl];
        if (self.localVideo) {
            videoUrl = [NSURL fileURLWithPath:self.videoUrl];
        }
        
        AVURLAsset *avUrlAsset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
        CMTime time = [avUrlAsset duration];
        self.duration = CMTimeGetSeconds(time);
        if (isnan(self.duration)) {
            self.duration = 0;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.videoOpView.duration = self.duration;
        });
    });
}

- (void)Test_getVideoSize {
    self.testPIV.alpha = 0;
    self.testSizeQ = dispatch_queue_create("com.Test.size", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(self.testSizeQ, ^{
        NSURL *Test_0 = [NSURL URLWithString:self.videoUrl];
        if (self.localVideo) {
            Test_0 = [NSURL fileURLWithPath:self.videoUrl];
        }
        AVURLAsset *Test_1 = [AVURLAsset URLAssetWithURL:Test_0 options:nil];
        CGSize Test_2 = CGSizeZero;
        NSArray *array = Test_1.tracks;
        for (AVAssetTrack *track in array) {
            if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
                Test_2 = track.naturalSize;
            }
        }
        
        AVAssetImageGenerator *Test_4 = [[AVAssetImageGenerator alloc] initWithAsset:Test_1];
        Test_4.appliesPreferredTrackTransform = YES;
        CMTime Test_5 = CMTimeMakeWithSeconds(0.0, 600);
        NSError *Test_6 = nil;
        CMTime Test_7;
        CGImageRef Test_8 = [Test_4 copyCGImageAtTime:Test_5 actualTime:&Test_7 error:&Test_6];
        UIImage *Test_9 = [[UIImage alloc] initWithCGImage:Test_8];
        CGImageRelease(Test_8);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.thumbImage = Test_9;
        });
    });
}

- (void)Test_pauseByEventsStart {
    if (self.playerState==TestPlayerStatePlaying) {
        [self Test_pause];
        self.pauseByEvents = YES;
    }
}

- (void)Test_playByEventsEnd {
    if (self.pauseByEvents) {
        self.pauseByEvents = NO;
        [self Test_play];
        [self.videoOpView hideItemViewDelay:YES];
    }
}

#pragma mark - VideoResourceLoaderHandlerDelegate
- (void)VideoResourceLoader:(VideoResourceLoaderHandler *)handler didUpdateCache:(NSArray *)cacheArray {
    if (_delegate && [_delegate respondsToSelector:@selector(VideoResourceLoad:didUpdateCache:)]) {
        [_delegate VideoResourceLoad:handler.videoLength didUpdateCache:cacheArray];
    }
}

#pragma mark - TestVideoControlViewDelegate
- (void)videoOpViewClick:(TestVideoOpView *)TestOpBar {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerClickOpView:)]) {
        [self.delegate playerClickOpView:self];
    }
}

- (void)videoOpViewPlayVideo:(TestVideoOpView *)TestOpBar {
    [self Test_play];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerPlay:)]) {
        [self.delegate playerPlay:self];
    }
}

- (void)videoOpViewPauseVideo:(TestVideoOpView *)TestOpBar {
    [self Test_pause];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerPause:)]) {
        [self.delegate playerPause:self];
    }
}

- (void)videoOpView:(TestVideoOpView *)TestOpBar seekToTime:(CGFloat)time {
    self.currentTime = time;
    [self.videoPreVV.player seekToTime:CMTimeMakeWithSeconds(time, 30) toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero];
}

- (void)videoOpViewWillShow:(TestVideoOpView *)TestOpBar {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerWillShowOpView:)]) {
        [self.delegate playerWillShowOpView:self];
    }
}

- (void)videoOpViewWillHide:(TestVideoOpView *)TestOpBar {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerWillHideOpView:)]) {
        [self.delegate playerWillHideOpView:self];
    }
}

#pragma mark - lazy
- (TestVideoPreView *)videoPreVV {
    if (!_videoPreVV) {
        _videoPreVV = [TestVideoPreView new];
    }
    
    return _videoPreVV;
}

- (TestVideoOpView *)videoOpView {
    if (!_videoOpView) {
        _videoOpView = [[TestVideoOpView alloc] init];
        _videoOpView.delegate = self;
    }
    
    return _videoOpView;
}

- (UIImageView *)testPIV {
    if (!_testPIV) {
        _testPIV = [[UIImageView alloc] init];
        _testPIV.clipsToBounds = YES;
    }
    
    return _testPIV;
}

- (UIImageView *)testLoadingIV {
    if (!_testLoadingIV) {
        _testLoadingIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        _testLoadingIV.image = [UIImage imageNamed:@"test_loading"];
        _testLoadingIV.hidden = YES;
        _testLoadingIV.alpha = 0.5;
        
        _testLoadingIV.layer.shadowColor = [UIColor blackColor].CGColor;
        _testLoadingIV.layer.shadowOffset = CGSizeZero;
        _testLoadingIV.layer.shadowRadius = 1;
        _testLoadingIV.layer.shadowOpacity = 0.5;
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        animation.fromValue = [NSNumber numberWithFloat:0.f];
        animation.toValue = [NSNumber numberWithFloat:2*M_PI];
        animation.duration = 1.6;
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        animation.repeatCount = MAXFLOAT;
        animation.cumulative = YES;
        [_testLoadingIV.layer addAnimation:animation forKey:@"rotationAnimate"];
    }
    
    return _testLoadingIV;
}

@end
