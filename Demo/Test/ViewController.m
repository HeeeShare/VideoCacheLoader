//
//  ViewController.m
//  Test
//
//  Created by test on 2025/5/13.
//

#import "ViewController.h"
#import "TestVideoPlayer.h"

@interface ViewController ()<TestVideoPlayerDelegate>
@property (nonatomic,strong) NSString *video_url;
@property (nonatomic,strong) NSString *cover_url;
@property (nonatomic,strong) UILabel *cacheSizeLabel;
@property (nonatomic,strong) TestVideoPlayer *videoPlayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _cover_url = @"视频封面地址";
    _video_url = @"视频地址";
    
    CGFloat w = kScreenWidth;
    CGFloat h = kScreenWidth*1.2;
    
    _videoPlayer = [[TestVideoPlayer alloc] initWithFrame:CGRectMake(0, 60, w, h)];
    _videoPlayer.centerX = kScreenWidth/2;
    _videoPlayer.backgroundColor = [UIColor blackColor];
    _videoPlayer.delegate = self;
    _videoPlayer.videoUrl = _video_url;
    [self.view addSubview:_videoPlayer];
    
    __weak __typeof(self) ws = self;
    [[YYWebImageManager sharedManager] requestImageWithURL:[NSURL URLWithString:_cover_url] options:1 progress:nil transform:nil completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image) {
                ws.videoPlayer.thumbImage = image;
            }
        });
    }];
    
    CGFloat xxtop = 60 + h;
    
    UIButton *b0 = [[UIButton alloc] initWithFrame:CGRectMake(16, xxtop + 40, 86, 30)];
    b0.backgroundColor = [UIColor colorWithWhite:0 alpha:0.05];
    [b0 addTarget:self action:@selector(clear_cache0) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:b0];
    [b0 setTitle:@"清空当前视频" forState:UIControlStateNormal];
    [b0 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    b0.titleLabel.font = [UIFont systemFontOfSize:12];
    
    UIButton *b1 = [[UIButton alloc] initWithFrame:CGRectMake(16, xxtop + 40, 86, 30)];
    b1.backgroundColor = [UIColor colorWithWhite:0 alpha:0.05];
    [b1 addTarget:self action:@selector(clear_cache1) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:b1];
    [b1 setTitle:@"清空所有视频" forState:UIControlStateNormal];
    [b1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    b1.titleLabel.font = [UIFont systemFontOfSize:12];
    
    UIButton *b2 = [[UIButton alloc] initWithFrame:CGRectMake(16, xxtop + 40, 86, 30)];
    b2.backgroundColor = [UIColor colorWithWhite:0 alpha:0.05];
    [b2 addTarget:self action:@selector(cacheSzie:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:b2];
    [b2 setTitle:@"当前视频缓存" forState:UIControlStateNormal];
    [b2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    b2.titleLabel.font = [UIFont systemFontOfSize:12];
    
    UIButton *b3 = [[UIButton alloc] initWithFrame:CGRectMake(16, xxtop + 40, 86, 30)];
    b3.backgroundColor = [UIColor colorWithWhite:0 alpha:0.05];
    [b3 addTarget:self action:@selector(allCacheSzie:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:b3];
    [b3 setTitle:@"所有缓存" forState:UIControlStateNormal];
    [b3 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    b3.titleLabel.font = [UIFont systemFontOfSize:12];
    
    b1.right = kScreenWidth/2 - 4;
    b0.right = b1.left - 8;
    b2.left = kScreenWidth/2 + 4;
    b3.left = b2.right + 8;
    
    _cacheSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(b2.left, b2.bottom, b2.width, b2.height)];
    _cacheSizeLabel.textAlignment = NSTextAlignmentCenter;
    _cacheSizeLabel.textColor = [UIColor blackColor];
    _cacheSizeLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [self.view addSubview:_cacheSizeLabel];
}

- (void)clear_cache0 {
    [_videoPlayer.videoLoader deleteCache];
}

- (void)clear_cache1 {
    [_videoPlayer.videoLoader deleteAllCache];
}

- (void)cacheSzie:(UIButton *)sender {
    NSUInteger size = [_videoPlayer.videoLoader cacheSize];
    [sender setTitle:[NSString stringWithFormat:@"%0.1fM",size/1000.0/1000.0] forState:UIControlStateNormal];
}

- (void)allCacheSzie:(UIButton *)sender {
    NSUInteger size = [_videoPlayer.videoLoader allCacheSize];
    [sender setTitle:[NSString stringWithFormat:@"%0.1fM",size/1000.0/1000.0] forState:UIControlStateNormal];
}

//delegate
- (void)VideoResourceLoad:(long long)videoLength didUpdateCache:(NSArray *)cacheArray {
    NSUInteger length = 0;
    for (NSValue *value in cacheArray) {
        NSRange range = [value rangeValue];
        length+=range.length;
    }
    if (videoLength) {
        _cacheSizeLabel.text = [NSString stringWithFormat:@"%0.1f%%",100*(CGFloat)length/videoLength];
    }
}

@end
