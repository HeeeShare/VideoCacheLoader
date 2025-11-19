//
//  VideoCacheHandler.m
//  Test
//
//  Created by test on 2025/5/15.
//

#import "VideoCacheHandler.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

@interface VideoCacheHandler ()
@property (nonatomic,strong) NSString *cachePath;
@property (nonatomic,strong) NSFileManager *fileManager;
@property (nonatomic,strong) NSLock *lock;
@property (nonatomic,strong) NSString *videoUrl;
@property (nonatomic,assign) long long videlLength;

@end

@implementation VideoCacheHandler
- (instancetype)initWithUrl:(NSString *)url {
    self = [super init];
    if (self) {
        _videoUrl = url;
        _cachePath = [self getFilePath:url];
        _fileManager = [NSFileManager defaultManager];
        _lock = [[NSLock alloc] init];
        
        // 创建缓存目录
        [self createCacheDir];
    }
    return self;
}

- (void)createCacheDir {
    if (![_fileManager fileExistsAtPath:_cachePath]) {
        NSError *error = nil;
        [_fileManager createDirectoryAtPath:_cachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&error];
        if (!error) {
            [self saveVideoLength:self.videlLength];
            NSLog(@"cachePath : %@",_cachePath);
        }
    }
}

- (NSString *)getFilePath:(NSString *)url {
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *cacheDirectory = [cachePath stringByAppendingPathComponent:@"VideoChunks"];
    NSString *fileName = [self makeMd5:url];
    NSString *path = [NSString stringWithFormat:@"%@/%@",cacheDirectory,fileName];
    return path;
}

- (NSString *)cacheFilePathForRange:(NSRange)range {
    return [self.cachePath stringByAppendingPathComponent:
            [NSString stringWithFormat:@"cache_%lu_%lu",
             (unsigned long)range.location,
             (unsigned long)range.length]];
}

- (NSData *)getCacheDataForRange:(NSRange)range {
    NSString *filePath = [self cacheFilePathForRange:range];
    NSData *cacheData = [NSData dataWithContentsOfFile:filePath];
    if (!cacheData) {
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_cachePath error:nil];
        for (NSString *fileName in contents) {
            if ([fileName containsString:@"cache_"] && ![fileName isEqualToString:@"cache_0_2"]) {
                NSArray <NSString *>*arr = [fileName componentsSeparatedByString:@"_"];
                NSUInteger min = arr[1].integerValue;
                NSUInteger max = arr[1].integerValue + arr[2].integerValue;
                if (range.location >= min && range.location < max) {
                    cacheData = [NSData dataWithContentsOfFile:[self.cachePath stringByAppendingPathComponent:fileName]];
                    if (cacheData) {
                        if (range.location + range.length > max) {
                            cacheData = [cacheData subdataWithRange:NSMakeRange(range.location - min, max - range.location)];
                        }else{
                            cacheData = [cacheData subdataWithRange:NSMakeRange(range.location - min, range.length)];
                        }
                    }
                }
            }
        }
    }
    
    return cacheData;
}

- (void)cacheData:(NSData *)data forRange:(NSRange)range {
    [self.lock lock];
    // 防止文件夹被意外删除
    [self createCacheDir];
    
    NSString *filePath = [self cacheFilePathForRange:range];
    [data writeToFile:filePath atomically:YES];
    [self.lock unlock];
}

- (NSArray *)getCacheRanges {
    NSMutableArray *contents = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:_cachePath error:nil]];
    [contents removeObject:@"cache_0_2"];
    [contents removeObject:@"VideoLength"];
    NSArray *new_contents = [contents sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        NSArray <NSString *>*arr1 = [obj1 componentsSeparatedByString:@"_"];
        NSArray <NSString *>*arr2 = [obj2 componentsSeparatedByString:@"_"];
        NSUInteger location1 = arr1[1].integerValue;
        NSUInteger location2 = arr2[1].integerValue;
        if (location2 > location1) {
            return NSOrderedAscending;
        }else if(location2 < location1) {
            return NSOrderedDescending;
        }else{
            return NSOrderedSame;
        }
    }];
    
    NSMutableArray *rangeArray = [NSMutableArray array];
    NSUInteger location_a = 0;
    NSUInteger length_a = 0;
    for (NSString *fileName in new_contents) {
        NSArray <NSString *>*arr = [fileName componentsSeparatedByString:@"_"];
        NSUInteger location = arr[1].integerValue;
        NSUInteger length = arr[2].integerValue;
        
        if (fileName == new_contents.firstObject) {
            location_a = location;
            length_a = length;
        }else{
            if (location_a + length_a == location) {
                length_a+=length;
            }else{
                [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(location_a, length_a)]];
                location_a = location;
                length_a = length;
            }
            
            if (fileName == new_contents.lastObject) {
                [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(location_a, length_a)]];
            }
        }
    }
    
    return rangeArray;
}

- (NSUInteger)allCacheSize {
    NSUInteger size = 0;
    
    [self.lock lock];
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *cacheDirectory = [cachePath stringByAppendingPathComponent:@"VideoChunks"];
    size = [self getFolderSizeAtPath:cacheDirectory];
    [self.lock unlock];
    
    return size;
}

- (long long)getVideoLength {
    NSString *filePath = [NSString stringWithFormat:@"%@/VideoLength",_cachePath];
    NSError *error;
    NSString *fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    return fileContent.longLongValue;
}

- (void)saveVideoLength:(long long)videlLength {
    if (videlLength > 0) {
        _videlLength = videlLength;
        
        if ([_fileManager fileExistsAtPath:_cachePath]){
            NSString *filePath = [NSString stringWithFormat:@"%@/VideoLength",_cachePath];
            [_fileManager removeItemAtPath:filePath error:nil];
            
            NSError *error;
            BOOL success = [[NSString stringWithFormat:@"%lld",videlLength] writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
            
            if (success) {
                NSLog(@"视频长度保存成功：%lld", videlLength);
            } else {
                NSLog(@"文件创建失败：%@", error.localizedDescription);
            }
        }else{
            [self createCacheDir];
        }
    }
}

- (NSUInteger)cacheSize {
    NSUInteger size = 0;
    
    [self.lock lock];
    size = [self getFolderSizeAtPath:_cachePath];
    [self.lock unlock];
    
    return size;
}

// 获取文件夹大小（包含所有子文件）
- (unsigned long long)getFolderSizeAtPath:(NSString *)folderPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    // 检查路径是否存在
    if (![fileManager fileExistsAtPath:folderPath]) {
        return 0;
    }
    
    // 获取文件夹内容
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:folderPath error:&error];
    if (error) {
        NSLog(@"读取文件夹内容失败: %@", error.localizedDescription);
        return 0;
    }
    
    unsigned long long totalSize = 0;
    for (NSString *fileName in contents) {
        if ([fileName isEqualToString:@"cache_0_2"] || [fileName isEqualToString:@"VideoLength"]) {
            continue;
        }
        
        NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
        
        BOOL isDirectory = NO;
        [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
        
        if (isDirectory) {
            // 递归计算子文件夹大小
            totalSize += [self getFolderSizeAtPath:filePath];
        } else {
            // 计算文件大小
            totalSize += [self getFileSizeAtPath:filePath];
        }
    }
    
    return totalSize;
}

// 获取单个文件大小
- (unsigned long long)getFileSizeAtPath:(NSString *)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:&error];
    
    if (error) {
        NSLog(@"获取文件大小失败: %@", error.localizedDescription);
        return 0;
    }
    
    return [fileAttributes[NSFileSize] unsignedLongLongValue];
}

- (void)deleteCache {
    [self.lock lock];
    [_fileManager removeItemAtPath:[self getFilePath:_videoUrl] error:nil];
    [self.lock unlock];
}

- (void)deleteAllCache {
    [self.lock lock];
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *cacheDirectory = [cachePath stringByAppendingPathComponent:@"VideoChunks"];
    [_fileManager removeItemAtPath:cacheDirectory error:nil];
    [self.lock unlock];
}

- (NSString *)makeMd5:(NSString *)str {
    if ([str isKindOfClass:[NSString class]] || str.length) {
        const char *md_0 = str.UTF8String;
        unsigned char md_1[CC_MD5_DIGEST_LENGTH];
        CC_MD5(md_0, (CC_LONG)strlen(md_0), md_1);
        
        NSMutableString *md_2 = [NSMutableString string];
        for (int p = 0; p < CC_MD5_DIGEST_LENGTH; ++p) {
            [md_2 appendFormat:@"%02x", md_1[p]];
        }
        return md_2;
    }
    
    return @"";
}

- (void)dealloc {
    NSLog(@"VideoCacheHandler dealloc~");
}

@end
