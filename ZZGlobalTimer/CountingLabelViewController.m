//
//  CountingLabelViewController.m
//  ZZGlobalTimer
//
//  Created by ZZ on 2020/3/22.
//  Copyright © 2020 zz. All rights reserved.
//

#import "CountingLabelViewController.h"
#import "ZZGlobalCountingTimer.h"

@interface CountingLabelViewController ()

@property (nonatomic, strong) UILabel *timingLabel0;
@property (nonatomic, strong) UILabel *timingLabel1;
@property (nonatomic, strong) UILabel *timingLabel2;

@end

@implementation CountingLabelViewController

- (void)dealloc {
    [ZZGlobalCountingTimer unsubscribeWithKey:NSStringFromSelector(@selector(timingLabel0))];
    [ZZGlobalCountingTimer unsubscribeWithKey:NSStringFromSelector(@selector(timingLabel2))];
}

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
    self.timingLabel0.numberOfLines = 0;
    [self.view addSubview:self.timingLabel1];
    self.timingLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(32, 64 + 32 + 32 + 84, 300, 42)];
    self.timingLabel2.text = @"timingLabel2";
    self.timingLabel0.numberOfLines = 0;
    [self.view addSubview:self.timingLabel2];
}

- (void)beginCounting {
    __weak UILabel *weakTimingLabel0 = self.timingLabel0;
    __weak UILabel *weakTimingLabel1 = self.timingLabel1;
    [ZZGlobalCountingTimer subscribeWithKey:NSStringFromSelector(@selector(timingLabel0)) fireDate:[NSDate date] eventHandler:^(NSString * _Nonnull key, NSDate * _Nonnull start, NSTimeInterval duration) {
        NSDate *now = [start dateByAddingTimeInterval:duration];
        weakTimingLabel0.text = [NSString stringWithFormat:@"start: %@, duration: %.2f", start, duration];
        weakTimingLabel1.text = [now description];

    }];
    __weak UILabel *weakTimingLabel2 = self.timingLabel2;
    [ZZGlobalCountingTimer subscribeWithKey:NSStringFromSelector(@selector(timingLabel2)) fireDate:[NSDate date] eventHandler:^(NSString * _Nonnull key, NSDate * _Nonnull start, NSTimeInterval duration) {
        NSDate *now = [start dateByAddingTimeInterval:duration];
        weakTimingLabel2.text = [NSString stringWithFormat:@"start: %@, duration: %.0f, now: %@", start, duration, now];
    }];
}

@end
