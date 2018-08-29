//
//  TableViewCell.m
//  MultiDownload
//
//  Created by txooo on 2018/8/29.
//  Copyright © 2018年 领琾. All rights reserved.
//

#import "TableViewCell.h"

@interface TableViewCell ()

@property (nonatomic, strong) UIProgressView *progressView;

@end

@implementation TableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self configSubViews];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)configSubViews {
    [self.contentView addSubview:self.progressView];
}

- (void)setModel:(BSDownloadSessionModel *)model {
    _model = model;
    self.textLabel.text = model.fileName ? : @"下载文件";
    DLog(@"下载进度:%f", model.progress);
    [self.progressView setProgress:model.progress];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    DLog(@"%@---%@----%@---%@ --- %tu", keyPath, object, change, context, self.indexpath.row);
    BSDownloadSessionModel *model = (BSDownloadSessionModel *)object;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setProgress:model.progress animated:YES];
    });
}

//移至viewController的dealloc中移除Observer->visibleCells
//- (void)dealloc {
//    @try {
//        [self.model removeObserver:self forKeyPath:@"progress"];
//    } @catch (NSException *exception) {
//        DLog(@"%@", exption.reason);
//    }
//    DLog(@"%s", __func__);
//}

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.tintColor = [UIColor redColor];
        _progressView.frame = CGRectMake(0, 90, CGRectGetWidth(self.bounds), 5);
    }
    return _progressView;
}

@end
