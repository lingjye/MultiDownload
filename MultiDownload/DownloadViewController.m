//
//  DownloadViewController.m
//  MultiDownload
//
//  Created by txooo on 2018/8/29.
//  Copyright © 2018年 领琾. All rights reserved.
//

#import "DownloadViewController.h"
#import "TableViewCell.h"
#import "LJDownloader.h"
#import "FMDBHelper.h"

@interface DownloadViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation DownloadViewController

- (void)dealloc {
    for (TableViewCell *cell in self.tableView.visibleCells) {
        [cell.model removeObserver:cell forKeyPath:@"progress"];
    }
    [[FMDBHelper sharedInstance] removeObserver:self forKeyPath:@"sessionModels"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.tableView];
    
    [[FMDBHelper sharedInstance] addObserver:self forKeyPath:@"sessionModels" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    DLog(@"数据源发生变化刷新列表");
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [FMDBHelper sharedInstance].sessionModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([TableViewCell class])];
    cell.indexpath = indexPath;
    cell.model = [FMDBHelper sharedInstance].sessionModels[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(TableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell.model addObserver:cell forKeyPath:@"progress" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(TableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell.model removeObserver:cell forKeyPath:@"progress"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    BSDownloadSessionModel *model = [FMDBHelper sharedInstance].sessionModels[indexPath.row];
    if (model.task) {
        if (model.task.state == NSURLSessionTaskStateRunning) {
            [model.task cancel];
        }else {
            [model.task resume];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:[TableViewCell class] forCellReuseIdentifier:NSStringFromClass([TableViewCell class])];
    }
    return _tableView;
}

@end
