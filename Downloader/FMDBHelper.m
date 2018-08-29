//
//  FMDBHelper.m
//  MultiDownload
//
//  Created by txooo on 2018/8/29.
//  Copyright © 2018年 领琾. All rights reserved.
//

#import "FMDBHelper.h"

#define     SQL_TABLE_NAME                  @"exceltable"

#define     SQL_CREATE_EXCEL_TABLE          @"create table if not exists exceltable (id integer primary key autoincrement,fileName varchar(256))"

#define     SQL_ADD_EXCEL                   @"insert into exceltable (fileName) values (?)"
#define     SQL_SELECT_EXCEL                @"select * from exceltable"
#define     SQL_SELECT_EXCELWITHURL         @"select * from exceltable where fileName = ?"
#define     SQL_DELETE_EXCELWITHURL         @"delete from exceltable where fileName = ?"

#define PATH_OF_DOCUMENT    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]

@implementation BSDownloadSessionModel

- (instancetype)init {
    if (self = [super init]) {
        //默认1, 只保存下载完成的文件
        _progress = 1;
    }
    return self;
}

- (void)setFileName:(NSString *)fileName {
    _fileName = fileName;
    _url = [NSURL fileURLWithPath:[PATH_OF_DOCUMENT stringByAppendingPathComponent:fileName]];
}

@end

@interface FMDBHelper ()<NSURLSessionDelegate>

@end

@implementation FMDBHelper

static FMDBHelper *downloadManager;
static dispatch_once_t token;

static NSString *userId = @"123";

- (void)dealloc {
    DLog(@"%s", __func__);
}

+ (instancetype)sharedInstance {
    dispatch_once(&token, ^{
        downloadManager = [[FMDBHelper alloc] initWithUserID:userId];
    });
    return downloadManager;
}

- (void)deallocManager {
    token = 0;
    downloadManager = nil;
}

- (id)initWithUserID:(NSString *)userID
{
    if (self = [super init]) {
        NSString *commonQueuePath = [self pathDBCommon];
        self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:commonQueuePath];
        BOOL ok = [self createTable];
        if (!ok) {
            DLog(@"DB: 聊天记录表创建失败");
        }else {
            __weak typeof(self) weakSelf = self;
            [self fetchExcelResultBlock:^(FMResultSet *rsSet) {
                while ([rsSet next]) {;
                    BSDownloadSessionModel *model = [[BSDownloadSessionModel alloc] init];
                    model.fileName = [rsSet stringForColumn:@"fileName"];
                    [[weakSelf mutableArrayValueForKey:@"sessionModels"] addObject:model];
                }
            }];
        }
    }
    return self;
}

-(NSString *)pathDBCommon
{
    NSString *path = [NSString stringWithFormat:@"%@/User/%@/Setting/DB/", NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0], userId];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            DLog(@"File Create Failed: %@", path);
        }
    }
    return [path stringByAppendingString:@"common.sqlite3"];
}

- (BOOL)createTable
{
    NSString *sqlString = [NSString stringWithFormat:SQL_CREATE_EXCEL_TABLE];
    return [self createTableWithSQL:sqlString];
}

- (BOOL)createTableWithSQL:(NSString *)sqlString
{
    __block BOOL ok = YES;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        if(![db tableExists:SQL_TABLE_NAME]){
            ok = [db executeUpdate:sqlString];
        }
    }];
    return ok;
}

-(void)insertExcelWithFileName:(NSString *)fileName result:(void (^)(BOOL))resultBlock {
    BOOL ib = [self excuteSQL:SQL_ADD_EXCEL, fileName];
    resultBlock(ib);
}

- (void)fetchExcelResultBlock:(void(^)(FMResultSet * rsSet))resultBlock {
    [self excuteQuerySQL:SQL_SELECT_EXCEL resultBlock:resultBlock];
}

-(void)fetchExcelWithFileName:(NSString *)fileName resultBlock:(void (^)(FMResultSet *))resultBlock {
    if (self.dbQueue) {
        [_dbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet * retSet = [db executeQuery:SQL_SELECT_EXCELWITHURL,fileName];
            if (resultBlock) {
                resultBlock(retSet);
            }
        }];
    }
}

- (void)deleteExcel:(NSString *)fileName result:(void (^)(BOOL))resultBlock {
    BOOL b = [self excuteSQL:SQL_DELETE_EXCELWITHURL, fileName];
    resultBlock(b);
}

- (NSMutableArray<BSDownloadSessionModel *> *)sessionModels {
    if (!_sessionModels) {
        _sessionModels = [NSMutableArray array];
    }
    return _sessionModels;
}

#pragma mark - 删除
/**
 *  删除该资源
 */
- (void)deleteFileAtIndex:(NSInteger)index result:(void (^)(BOOL))resultBlock
{
    __weak typeof(self) weakSelf = self;
    BSDownloadSessionModel *model = self.sessionModels[index];
    [self deleteExcel:model.fileName result:^(BOOL result) {
        if (result) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *localPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:model.fileName];
            if ([fileManager fileExistsAtPath:localPath]) {
                // 删除沙盒中的资源
                BOOL result = [fileManager removeItemAtPath:localPath error:nil];
                if (result) {
                    // 删除任务
                    [[weakSelf mutableArrayValueForKey:@"sessionModels"] removeObject:model];
                    resultBlock(YES);
                }else {
                    //删除失败时添加到数据库保证数据无误
                    [weakSelf insertExcelWithFileName:model.fileName result:^(BOOL result) {
                        DLog(@"%i", result);
                    }];
                    resultBlock(NO);
                }
            }else {
                // 删除任务
                [[weakSelf mutableArrayValueForKey:@"sessionModels"] removeObject:model];
                resultBlock(YES);
            }
        }else {
            resultBlock(NO);
        }
    }];
}

- (BOOL)excuteSQL:(NSString *)sqlString withArrParameter:(NSArray *)arrParameter
{
    __block BOOL ok = NO;
    if (self.dbQueue) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            ok = [db executeUpdate:sqlString withArgumentsInArray:arrParameter];
        }];
    }
    return ok;
}

- (BOOL)excuteSQL:(NSString *)sqlString withDicParameter:(NSDictionary *)dicParameter
{
    __block BOOL ok = NO;
    if (self.dbQueue) {
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            ok = [db executeUpdate:sqlString withParameterDictionary:dicParameter];
        }];
    }
    return ok;
}

- (BOOL)excuteSQL:(NSString *)sqlString,...
{
    __block BOOL ok = NO;
    if (self.dbQueue) {
        va_list args;
        va_list *p_args;
        p_args = &args;
        va_start(args, sqlString);
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            ok = [db executeUpdate:sqlString withVAList:*p_args];
        }];
        va_end(args);
    }
    return ok;
}

- (void)excuteQuerySQL:(NSString*)sqlStr resultBlock:(void(^)(FMResultSet * rsSet))resultBlock
{
    if (self.dbQueue) {
        [_dbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet * retSet = [db executeQuery:sqlStr];
            if (resultBlock) {
                resultBlock(retSet);
            }
        }];
    }
}

@end
