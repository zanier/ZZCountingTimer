//
//  CountingTableViewCell.m
//  ZZGlobalTimer
//
//  Created by ZZ on 2020/3/22.
//  Copyright © 2020 zz. All rights reserved.
//

#import "CountingTableViewCell.h"
#import "ZZCountingManager.h"

@implementation CountingTableViewCell

- (void)dealloc {
    NSLog(@"cell <%p> dealloc", self);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        __weak typeof(self) weakSelf = self;
        [[ZZCountingManager share] addSubscriber:self.textLabel fireDate:[NSDate date] interval:1 eventHandler:^(id  _Nonnull object, NSDate * _Nonnull start, NSTimeInterval duration) {
            UILabel *label = (UILabel *)object;
            label.text = [NSString stringWithFormat:@"%.0f", duration];
            weakSelf.detailTextLabel.text = [NSString stringWithFormat:@"start at %@", start];
        }];
    }
    return self;
}

- (void)setStartDate:(NSDate *)startDate {
    [[ZZCountingManager share] updateFireDateWithSubscriber:self.textLabel interval:1 fireDate:startDate];
}

@end
