//
//  VideoResourceLoaderHandler.h
//  Test
//
//  Created by test on 2025/5/15.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@class VideoResourceLoaderHandler;

@protocol VideoResourceLoaderHandlerDelegate <NSObject>
@optional
- (void)VideoResourceLoader:(VideoResourceLoaderHandler *)handler didUpdateCache:(NSArray *)cacheArray;

@end

@interface VideoResourceLoaderHandler : NSObject <AVAssetResourceLoaderDelegate>
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVURLAsset *urlAsset;
@property (nonatomic, weak) id<VideoResourceLoaderHandlerDelegate> delegate;
@property (nonatomic, assign) NSUInteger unitSize;//分片大小，默认1m。
@property (nonatomic,assign,readonly) long long videoLength;

- (instancetype)initWithVideoUrl:(NSURL *)url;
- (void)configResourceLoader;
- (NSUInteger)cacheSize;
- (NSUInteger)allCacheSize;
- (void)deleteCache;
- (void)deleteAllCache;

@end
