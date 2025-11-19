//
//  VideoDownloadManager.h
//  Test
//
//  Created by test on 2025/5/15.
//

#import <Foundation/Foundation.h>

@interface VideoDownloadManager : NSObject

- (NSURLSessionDataTask *)downloadVideoWithURL:(NSString *)url
                                         range:(NSRange)range
                                    completion:(void(^)(NSData *data, NSRange range, NSError *error))completion;

@end
