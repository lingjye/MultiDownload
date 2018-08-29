//
//  LJDownloader.h
//  MultiDownload
//
//  Created by txooo on 2018/8/29.
//  Copyright © 2018年 领琾. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

typedef void (^HttpToolsBlock) (id result, NSError* error);

@interface LJDownloader : NSObject

@property(nonatomic,strong) AFHTTPSessionManager *manager;
/**
 *当前的请求operation队列
 */
@property (nonatomic, strong) NSOperationQueue* operationQueue;

+ (instancetype)sharedInstance;

+ (NSURLSessionDownloadTask *)downloadURL:(NSString *)urlStr fileName:(void (^)(NSString *))fileNameBlock progress:(void (^)(NSProgress *))progressBlock success:(HttpToolsBlock)block;
@end
