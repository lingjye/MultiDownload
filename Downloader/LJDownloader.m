//
//  LJDownloader.m
//  MultiDownload
//
//  Created by txooo on 2018/8/29.
//  Copyright © 2018年 领琾. All rights reserved.
//

#import "LJDownloader.h"

@implementation LJDownloader

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LJDownloader *downloadManager;
    dispatch_once(&onceToken, ^{
        downloadManager = [[LJDownloader alloc] init];
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        manager.requestSerializer.timeoutInterval = 20.0f;
        downloadManager.manager = manager;
        downloadManager.operationQueue = downloadManager.manager.operationQueue;
    });
    return downloadManager;
}

+ (NSURLSessionDownloadTask *)downloadURL:(NSString *)urlStr fileName:(void (^)(NSString *))fileNameBlock progress:(void (^)(NSProgress *))progressBlock success:(HttpToolsBlock)block {
    AFHTTPSessionManager *manager = [LJDownloader sharedInstance].manager;
    // 要下载文件的url
    NSURL *url = [NSURL URLWithString:urlStr];
    // 创建请求对象
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // 异步
    NSURLSessionDownloadTask *extractedExpr = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        progressBlock(downloadProgress);
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *fileName = [[LJDownloader sharedInstance] decodeURLPercentEscapeString:response.suggestedFilename];
        // 取得沙盒目录
        NSString *localPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        // 递归检查的文件目录
        NSString *filePath = [[LJDownloader sharedInstance] legalFileNameWithName:fileName home:localPath fileManager:fileManager];
        //生成目录
        fileNameBlock(filePath);
        // 告诉服务器下载的文本保存的位置在那里
        NSURL *documentsDirectoryURL = [fileManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:filePath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"response = %@,filePath = %@",response,filePath);
        block(filePath,error);
    }];
    NSURLSessionDownloadTask *task = extractedExpr;
    [task resume];
    return task;
}

- (NSString *)decodeURLPercentEscapeString:(NSString *)string {
    NSMutableString *outputStr = [NSMutableString stringWithString:string];
    [outputStr replaceOccurrencesOfString:@"+"
                               withString:@""
                                  options:NSLiteralSearch
                                    range:NSMakeRange(0,[outputStr length])];
    return [outputStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}
/**
 *  获取合法文件名, 本地文件名称重复会自动加上'_序号'
 *
 *  @param name 文件名
 *  @param home 目录
 *  @param fileMnager fileManager
 *
 *  @return 如果有就设置，然后返回yes；如果没有就返回no
 */
- (NSString *)legalFileNameWithName:(NSString*)name
                                   home:(NSString*)home
                            fileManager:(NSFileManager*)fileMnager {
    NSString *file = [home stringByAppendingPathComponent:name];
    if ([fileMnager fileExistsAtPath:file]) {
        NSArray *classArray = [name componentsSeparatedByString:@"."];
        NSString *fileClass = @"";
        NSString *fileName = name;
        if (classArray.count > 1) {
            fileClass = [@"." stringByAppendingString:[classArray lastObject]];
            fileName = [name substringToIndex:name.length - fileClass.length - 1];
        }
        NSArray *array = [fileName componentsSeparatedByString:@"_"];
        if (array.count > 1 && [[array lastObject] intValue]>0) {
            fileName = @"";
            name = [fileName stringByAppendingString:[NSString stringWithFormat:@"%@_%d%@",[array firstObject],[[array lastObject] intValue]+1,fileClass]];
        }else {
            name = [fileName stringByAppendingString:[NSString stringWithFormat:@"_1%@",fileClass]];
        }
        //此处用的递归
        return [[LJDownloader sharedInstance] legalFileNameWithName:name home:home fileManager:fileMnager];
    }else{
        return name;
    }
}

@end
