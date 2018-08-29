//
//  TableViewCell.h
//  MultiDownload
//
//  Created by txooo on 2018/8/29.
//  Copyright © 2018年 领琾. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FMDBHelper.h"

@interface TableViewCell : UITableViewCell

@property (nonatomic, strong) NSIndexPath *indexpath;

@property (nonatomic, strong) BSDownloadSessionModel *model;

@end
