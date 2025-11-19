//
//  VideoDownloadManager.m
//  Test
//
//  Created by test on 2025/5/15.
//

#import "VideoDownloadManager.h"

@interface VideoDownloadManager () <NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSession *session;

@end

@implementation VideoDownloadManager

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

- (NSURLSessionDataTask *)downloadVideoWithURL:(NSString *)url
                                         range:(NSRange)range
                                    completion:(void(^)(NSData *data, NSRange range, NSError *error))completion {
    NSURL *URL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setValue:[NSString stringWithFormat:@"bytes=%lu-%lu",
                      (unsigned long)range.location,
                      (unsigned long)(range.location + range.length - 1)] forHTTPHeaderField:@"Range"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (completion) {
            completion(data, range, error);
        }
    }];
    
    [task resume];
    return task;
}

@end
