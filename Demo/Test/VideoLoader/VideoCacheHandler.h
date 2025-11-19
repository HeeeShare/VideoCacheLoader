//
//  VideoCacheHandler.h
//  Test
//
//  Created by test on 2025/5/15.
//

#import <Foundation/Foundation.h>

@interface VideoCacheHandler : NSObject

- (instancetype)initWithUrl:(NSString *)url;
- (NSData *)getCacheDataForRange:(NSRange)range;
- (void)cacheData:(NSData *)data forRange:(NSRange)range;
- (NSUInteger)allCacheSize;
- (NSUInteger)cacheSize;
- (void)deleteCache;
- (void)deleteAllCache;
- (long long)getVideoLength;
- (void)saveVideoLength:(long long)videoLength;

@property (nonatomic,strong,readonly) NSString *cachePath;

- (NSArray *)getCacheRanges;

@end
