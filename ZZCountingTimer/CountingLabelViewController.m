//
//  CountingLabelViewController.m
//  ZZGlobalTimer
//
//  Created by ZZ on 2020/3/22.
//  Copyright © 2020 zz. All rights reserved.
//

#import "CountingLabelViewController.h"
#import "ZZCountingManager.h"

@interface CountingLabelViewController ()

@property (nonatomic, strong) UILabel *timingLabel0;
@property (nonatomic, strong) UILabel *timingLabel1;
@property (nonatomic, strong) UILabel *timingLabel2;
@property (nonatomic, strong) UILabel *timingLabel3;

@end

@implementation CountingLabelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupSubViews];
    [self beginCounting];
}

- (void)setupSubViews {
    self.view.backgroundColor = [UIColor whiteColor];
    self.timingLabel0 = [[UILabel alloc] initWithFrame:CGRectMake(32, 64 + 32, 300, 42)];
    self.timingLabel0.text = @"timingLabel0";
    self.timingLabel0.numberOfLines = 0;
    [self.view addSubview:self.timingLabel0];
    self.timingLabel1 = [[UILabel alloc] initWithFrame:CGRectMake(32, 64 + 32 + 16 + 42, 300, 42)];
    self.timingLabel1.text = @"timingLabel1";
    self.timingLabel1.numberOfLines = 0;
    [self.view addSubview:self.timingLabel1];
    self.timingLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(32, 64 + 32 + 32 + 84, 300, 42)];
    self.timingLabel2.text = @"timingLabel2";
    self.timingLabel2.numberOfLines = 0;
    [self.view addSubview:self.timingLabel2];
    self.timingLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(32, 64 + 32 + 32 + 126, 300, 42)];
    self.timingLabel3.text = @"timingLabel2";
    self.timingLabel3.numberOfLines = 0;
    [self.view addSubview:self.timingLabel3];
}

- (void)beginCounting {
    [[ZZCountingManager share] addSubscriber:self.timingLabel0 fireDate:[NSDate date] interval:1 eventHandler:^(id  _Nonnull object, NSDate * _Nonnull startDate, NSTimeInterval duration) {
        UILabel *label = (UILabel *)object;
        label.text = [NSString stringWithFormat:@"%.0f", duration];
    }];
    [[ZZCountingManager share] addSubscriber:self.timingLabel1 fireDate:[NSDate date] interval:2 eventHandler:^(id  _Nonnull object, NSDate * _Nonnull startDate, NSTimeInterval duration) {
        UILabel *label = (UILabel *)object;
        label.text = [NSString stringWithFormat:@"%.0f", duration];
    }];
    [[ZZCountingManager share] addSubscriber:self.timingLabel2 fireDate:[NSDate date] interval:4 eventHandler:^(id  _Nonnull object, NSDate * _Nonnull startDate, NSTimeInterval duration) {
        UILabel *label = (UILabel *)object;
        label.text = [NSString stringWithFormat:@"%.0f", duration];
    }];
    [[ZZCountingManager share] addSubscriber:self.timingLabel2 fireDate:[NSDate date] interval:5 eventHandler:^(id  _Nonnull object, NSDate * _Nonnull start, NSTimeInterval duration) {
        UILabel *label = (UILabel *)object;
        label.text = [NSString stringWithFormat:@"%.0f", duration];
    }];
    [[ZZCountingManager share] addSubscriber:self.timingLabel3 fireDate:[NSDate date] interval:5 eventHandler:^(id  _Nonnull object, NSDate * _Nonnull start, NSTimeInterval duration) {
        UILabel *label = (UILabel *)object;
        label.text = [NSString stringWithFormat:@"%.0f", duration];
    }];
}

@end
