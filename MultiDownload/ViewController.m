//
//  ViewController.m
//  MultiDownload
//
//  Created by txooo on 2018/8/29.
//  Copyright © 2018年 领琾. All rights reserved.
//

#import "ViewController.h"
#import "LJDownloader.h"
#import "FMDBHelper.h"
#import "DownloadViewController.h"

#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [downloadButton setBackgroundColor:[UIColor lightGrayColor]];
    [downloadButton setTitle:@"下载" forState:UIControlStateNormal];
    [downloadButton addTarget:self action:@selector(downloadAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:downloadButton];
    downloadButton.frame = CGRectMake(SCREENWIDTH / 2 - 50, 200, 100, 50);
    
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [infoButton setBackgroundColor:[UIColor lightGrayColor]];
    [infoButton setTitle:@"查看" forState:UIControlStateNormal];
    [infoButton addTarget:self action:@selector(lookInfoAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:infoButton];
    
    infoButton.frame = CGRectMake(SCREENWIDTH / 2 - 50, 300, 100, 50);
}

- (void)downloadAction {
    NSString *urlString = @"http://wind4app-bdys.oss-cn-hangzhou.aliyuncs.com/CMD_MarkDown.zip";
    BSDownloadSessionModel *model = [[BSDownloadSessionModel alloc] init];
    model.fileName = @"下载文件名称";
    model.task = [LJDownloader downloadURL:urlString fileName:^(NSString *fileName) {
        @synchronized(model) {
            model.fileName = fileName;
        }
    } progress:^(NSProgress *progress) {
        @synchronized(model) {
            model.progress = (float)progress.completedUnitCount/progress.totalUnitCount;
            DLog(@"进度:%f", model.progress);
        }
    } success:^(NSURL *result, NSError *error) {
        @synchronized(model) {
            if (result) {
                //置空task
                model.task = nil;
                model.progress = 1;
                [[FMDBHelper sharedInstance] insertExcelWithFileName:model.fileName result:^(BOOL result) {
                    if (!result) {
                        DLog(@"报表下载失败!");
                    }else {
                        DLog(@"报表下载成功!");
                    }
                }];
            }else {
                DLog(@"报表下载失败!");
                DLog(@"%tu----%@", error.code, error.description);
                //如果是断点续传,此处需判断是否是主动取消
                [[[FMDBHelper sharedInstance] mutableArrayValueForKey:@"sessionModels"] removeObject:model];
            }
        }
    }];
    [[[FMDBHelper sharedInstance] mutableArrayValueForKey:@"sessionModels"] addObject:model];
}

- (void)lookInfoAction {
    DownloadViewController *viewController = [[DownloadViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
