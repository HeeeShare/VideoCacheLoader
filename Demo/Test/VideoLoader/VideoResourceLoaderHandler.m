//
//  VideoResourceLoaderHandler.m
//  Test
//
//  Created by test on 2025/5/15.
//

#import "VideoResourceLoaderHandler.h"
#import "VideoCacheHandler.h"
#import "VideoDownloadManager.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface VideoResourceLoaderHandler ()
@property (nonatomic,strong) VideoCacheHandler *cacheHandler;
@property (nonatomic,strong) VideoDownloadManager *downloadManager;
@property (nonatomic,strong) NSString *videoUrl;
@property (nonatomic,assign) long long videoLength;

@end

@implementation VideoResourceLoaderHandler
- (instancetype)initWithVideoUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        _unitSize = 1000*1000;
        _videoUrl = url.absoluteString;
        _cacheHandler = [[VideoCacheHandler alloc] initWithUrl:_videoUrl];
        _downloadManager = [[VideoDownloadManager alloc] init];
        
        [self configResourceLoader];
    }
    return self;
}

- (void)configResourceLoader {
    if (_urlAsset) {
        [_urlAsset.resourceLoader setDelegate:nil queue:nil];
        _urlAsset = nil;
    }
    
    if (self.playerItem) {
        self.playerItem = nil;
    }
    
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:_videoUrl] resolvingAgainstBaseURL:NO];
    components.scheme = @"streaming";
    
    NSURL *assetUrl = components.URL;
    _urlAsset = [AVURLAsset URLAssetWithURL:assetUrl options:nil];
    [_urlAsset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    self.playerItem = [AVPlayerItem playerItemWithAsset:_urlAsset];
}

- (NSUInteger)allCacheSize {
    return [_cacheHandler allCacheSize];
}

- (NSUInteger)cacheSize {
    return [_cacheHandler cacheSize];
}

- (void)deleteCache {
    [_cacheHandler deleteCache];
}

- (void)deleteAllCache {
    [_cacheHandler deleteAllCache];
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSRange requestedRange = NSMakeRange((NSUInteger)loadingRequest.dataRequest.requestedOffset,
                                         (NSUInteger)loadingRequest.dataRequest.requestedLength);
    if (loadingRequest.contentInformationRequest) {
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(@"video/mp4"), NULL);
        loadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
        loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
        
        _videoLength = [_cacheHandler getVideoLength];
        if (_videoLength == 0) {
            _videoLength = [self getVideoContentLength];
            [_cacheHandler saveVideoLength:_videoLength];
        }
        
        loadingRequest.contentInformationRequest.contentLength = _videoLength;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(VideoResourceLoader:didUpdateCache:)]) {
            [self.delegate VideoResourceLoader:self didUpdateCache:[self.cacheHandler getCacheRanges]];
        }
    } else {
        NSUInteger length = _unitSize;
        if (length > requestedRange.length) {
            length = requestedRange.length;
        }
        requestedRange = NSMakeRange(requestedRange.location, length);
        
        NSLog(@"准备 ： %0.2lfM",requestedRange.location/1000.0/1000.0);
    }
    
    NSData *cachedData = [self.cacheHandler getCacheDataForRange:requestedRange];
    if (cachedData) {
        [loadingRequest.dataRequest respondWithData:cachedData];
        [loadingRequest finishLoading];
        return YES;
    }
    
    // 开始下载
    NSLog(@"开始下载 ： %0.2lfM  %@",requestedRange.location/1000.0/1000.0,loadingRequest);
    
    NSUInteger downloadLocation = (requestedRange.location/_unitSize)*_unitSize;
    NSUInteger downloadLength = requestedRange.length + requestedRange.location - downloadLocation;
    if (downloadLength < _unitSize) {
        downloadLength = _videoLength - downloadLocation;
    }
    
    if (downloadLength > _unitSize) {
        downloadLength = _unitSize;
    }
    NSRange downloadRange = NSMakeRange(downloadLocation, downloadLength);
    if (loadingRequest.contentInformationRequest) {
        downloadRange = requestedRange;
    }
    
    __weak __typeof(self) a_ws = self;
    [self.downloadManager downloadVideoWithURL:self.videoUrl
                                         range:downloadRange
                                    completion:^(NSData *data, NSRange range, NSError *error) {
        if (error) {
            [loadingRequest finishLoadingWithError:error];
        } else {
            [a_ws.cacheHandler cacheData:data forRange:downloadRange];
            if (loadingRequest.dataRequest.requestedOffset == range.location) {
                
            }
            
            NSRange aaaRange = NSMakeRange((NSUInteger)loadingRequest.dataRequest.requestedOffset,
                                           (NSUInteger)loadingRequest.dataRequest.requestedLength);
            NSData *cachedData = [a_ws.cacheHandler getCacheDataForRange:aaaRange];
            [loadingRequest.dataRequest respondWithData:cachedData];
            [loadingRequest finishLoading];
            
            if (a_ws.delegate && [a_ws.delegate respondsToSelector:@selector(VideoResourceLoader:didUpdateCache:)]) {
                [a_ws.delegate VideoResourceLoader:a_ws didUpdateCache:[a_ws.cacheHandler getCacheRanges]];
            }
            
            NSLog(@"下载完成 ： %0.2lfM",requestedRange.location/1000.0/1000.0);
        }
    }];
    
    return YES;
}

// 获取视频文件总长度的方法
- (long long)getVideoContentLength {
    NSURL *url = [NSURL URLWithString:self.videoUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    
    __block long long contentLength = 0;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            contentLength = response.expectedContentLength;
        }
        dispatch_semaphore_signal(semaphore);
    }] resume];
    
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)));
    return contentLength;
}

- (void)dealloc {
    NSLog(@"VideoResourceLoaderHandler dealloc~");
}

@end
