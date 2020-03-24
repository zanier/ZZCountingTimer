//
//  CountingTableViewController.m
//  ZZGlobalTimer
//
//  Created by ZZ on 2020/3/22.
//  Copyright © 2020 zz. All rights reserved.
//

#import "CountingTableViewController.h"
#import "CountingTableViewCell.h"
#import "ZZCountingManager.h"

@interface CountingTableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *startDates;

@end

@implementation CountingTableViewController

- (void)dealloc {
    NSLog(@"CountingTableViewController <%p> dealloc", self);
    NSLog(@"timerDic: %@", [ZZCountingManager share].timerDic);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSMutableArray *mutableArray = [NSMutableArray array];
    for (int i = 0; i < 20; i++) {
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:i * -60 * 30];
        [mutableArray addObject:date];
    }
    self.startDates = [mutableArray copy];
    [self.view addSubview:self.tableView];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.rowHeight = 88;
        _tableView.tableFooterView = [[UIView alloc] init];
    }
    return _tableView;
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.startDates.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cell";
    CountingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[CountingTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    [cell setStartDate:self.startDates[indexPath.row]];
    return cell;
}

@end
