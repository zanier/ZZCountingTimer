//
//  CountingTableViewCell.m
//  ZZGlobalTimer
//
//  Created by ZZ on 2020/3/22.
//  Copyright © 2020 zz. All rights reserved.
//

#import "CountingTableViewCell.h"
#import "ZZGlobalCountingTimer.h"

@implementation CountingTableViewCell

- (void)dealloc {
//    [ZZGlobalCountingTimer unsubscribeWithKey:[self key]];
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setStartDate:(NSDate *)startDate {
    __weak typeof(self) weakSelf = self;
//    [ZZGlobalCountingTimer updateOrSubscribeIfNeededWithKey:[self key] start:startDate eventHandler:^(NSString * _Nonnull key, NSDate * _Nonnull start, NSTimeInterval duration) {
//        weakSelf.textLabel.text = [NSString stringWithFormat:@"%.0f s", duration];
//        weakSelf.detailTextLabel.text = [NSString stringWithFormat:@"start at %@", start];
//    }];
}

- (NSString *)key {
    return [NSString stringWithFormat:@"%li", [self hash]];
}

@end
