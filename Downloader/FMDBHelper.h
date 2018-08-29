//
//  FMDBHelper.h
//  MultiDownload
//
//  Created by txooo on 2018/8/29.
//  Copyright © 2018年 领琾. All rights reserved.
//

#ifdef DEBUG

#define LRString [NSString stringWithFormat:@"%s", __FILE__].lastPathComponent
#define DLog(...){\
NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];\
[dateFormatter setDateStyle:NSDateFormatterMediumStyle];\
[dateFormatter setTimeStyle:NSDateFormatterShortStyle];\
[dateFormatter setDateFormat:@"HH:mm:ss:SSSSSS"];\
NSString *str = [dateFormatter stringFromDate:[NSDate date]];\
printf("%s %s 第%d行: %s\n\n",[str UTF8String] , [LRString UTF8String] ,__LINE__, [[NSString stringWithFormat:__VA_ARGS__] UTF8String]);\
}

//#define DLog( s, ... ) NSLog( @"< %@:(%d) > %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )

#else

#define DLog( s, ... )

#endif

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>

@interface BSDownloadSessionModel : NSObject

@property (nonatomic, strong) NSURLSessionDownloadTask *task;
//0~1
@property (nonatomic, assign) float progress;

@property (nonatomic, copy) NSString *fileName;
/** 下载地址 */
@property (nonatomic, copy) NSURL *url;

@end

@interface FMDBHelper : NSObject
/// 数据库操作队列
@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

+ (instancetype)sharedInstance;

- (void)deallocManager;

-(void)insertExcelWithFileName:(NSString *)fileName result:(void(^)(BOOL result))resultBlock;
- (void)fetchExcelResultBlock:(void(^)(FMResultSet * rsSet))resultBlock ;
-(void)fetchExcelWithFileName:(NSString *)fileName resultBlock:(void(^)(FMResultSet * rsSet))resultBlock;
/**
 *  通过文件名删除
 */
- (void)deleteExcel:(NSString *)fileName result:(void(^)(BOOL result))resultBlock;

/**
 *  通过文件索引删除
 */
- (void)deleteFileAtIndex:(NSInteger)index result:(void (^)(BOOL result))resultBlock;


/** 保存所有下载相关信息 */
@property (nonatomic, strong) NSMutableArray<BSDownloadSessionModel *> *sessionModels;
@end
