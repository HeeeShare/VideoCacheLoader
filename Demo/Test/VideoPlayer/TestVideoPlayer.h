//
//  TestVideoPlayer.h
//  chat
//
//  Created by Test on 2023/12/4.
//

#import <UIKit/UIKit.h>
#import "TestVideoOpView.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "VideoResourceLoaderHandler.h"

@class TestVideoPlayer;

typedef enum : NSUInteger {
    TestPlayerStateDefault,
    TestPlayerStatePlaying,
    TestPlayerStatePause,
    TestPlayerStatePlayFinished,
    TestPlayerStateError,
} TestPlayerState;

@interface TestVideoPreView : UIView
@property (nonatomic,strong) AVPlayer *player;

@end

@protocol TestVideoPlayerDelegate <NSObject>
@optional
- (void)playerPlay:(TestVideoPlayer *)TestPlayer;
- (void)playerPause:(TestVideoPlayer *)TestPlayer;
- (void)playerFinished:(TestVideoPlayer *)TestPlayer;
- (void)playerError:(TestVideoPlayer *)TestPlayer;
- (void)player:(TestVideoPlayer *)TestPlayer playingAtTime:(CGFloat)time;
- (void)playerWillShowOpView:(TestVideoPlayer *)TestPlayer;
- (void)playerWillHideOpView:(TestVideoPlayer *)TestPlayer;
- (void)playerClickOpView:(TestVideoPlayer *)TestPlayer;
- (void)VideoResourceLoad:(long long )videoLength didUpdateCache:(NSArray *)cacheArray;

@end

@interface TestVideoPlayer : UIView
@property (nonatomic,copy) NSString *videoUrl;
@property (nonatomic,assign) CGFloat duration;
@property (nonatomic,assign) BOOL mute;
@property (nonatomic,strong,readonly) UIImageView *testPIV;
@property (nonatomic,strong) UIImage *thumbImage;
@property (nonatomic,assign) UIViewContentMode thumbIVMode;
@property (nonatomic,assign) BOOL closeUpdatePlayTime;
@property (nonatomic,strong,readonly) TestVideoPreView *videoPreVV;
@property (nonatomic,strong,readonly) TestVideoOpView *videoOpView;
@property (nonatomic,assign,readonly) TestPlayerState playerState;
@property (nonatomic,weak) id<TestVideoPlayerDelegate> delegate;
@property (nonatomic,strong,readonly) VideoResourceLoaderHandler *videoLoader;

- (void)play;
- (void)pause;
- (void)stop;
- (void)seekToTime:(NSTimeInterval)time;
- (void)showOpView;
- (void)hideOpView:(BOOL)delay;

@end
