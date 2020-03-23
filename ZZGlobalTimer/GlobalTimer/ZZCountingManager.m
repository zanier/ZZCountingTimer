//
//  ZZCountingManager.m
//  ZZGlobalTimer
//
//  Created by ZZ on 2020/3/23.
//  Copyright © 2020 zz. All rights reserved.
//

#import "ZZCountingManager.h"
#import "ZZGlobalCountingTimer.h"

@interface ZZCountingManager () {
    dispatch_semaphore_t _lock;
    NSMutableDictionary<NSNumber *, ZZGlobalCountingTimer *> *_dic; // 保存定时器对象
    NSMapTable<id, NSMapTable<NSNumber *, ZZGlobalCountingTimer *> *> *_mapTable;
}

@end

@implementation ZZCountingManager

/// MARK: 单例
+ (instancetype)share {
    static ZZCountingManager *share;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[ZZCountingManager alloc] init];
    });
    return share;
}

/// 初始化
- (instancetype)init {
    if (self = [super init]) {
        _lock = dispatch_semaphore_create(1);
        _dic = [NSMutableDictionary dictionary];
        _mapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory];
    }
    return self;
}
  
/// MARK: 获取订阅实例对象
/// @param interval 订阅的时间间隔
- (ZZGlobalCountingTimer *)countingTimerWithInterval:(NSTimeInterval)interval {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    ZZGlobalCountingTimer *countingTimer = _dic[@(interval)];
    dispatch_semaphore_signal(_lock);
    return countingTimer;
}

- (ZZGlobalCountingTimer *)countingTimerWithObject:(id)object interval:(NSTimeInterval)interval {
    if (!object) return nil;
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSMapTable *mapTable = [_mapTable objectForKey:object];
    ZZGlobalCountingTimer *countingTimer = [mapTable objectForKey:@(interval)];
    dispatch_semaphore_signal(_lock);
    return countingTimer;
}

/// MARK: 添加订阅
/// @param object 订阅者
/// @param date 计时的起始时间
/// @param interval 订阅的时间间隔
/// @param handler 定时触发的回调
- (void)addSubscriber:(id)object fireDate:(NSDate *)date interval:(NSTimeInterval)interval eventHandler:(void(^)(id object, NSDate *start, NSTimeInterval duration))handler {
    // 参数非空判断
    if (!object || !date || interval <= 0 || !handler) return;
    // 获取定时器
    ZZGlobalCountingTimer *countingTimer = [self countingTimerWithInterval:interval];
    if (!countingTimer) {
        // 创建定时器
        countingTimer = [[ZZGlobalCountingTimer alloc] initWithTimeInterval:interval];
    }
    // 定时器添加订阅者
    [countingTimer addSubscriber:object fireDate:date eventHandler:handler];
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSMapTable *mapTable = [_mapTable objectForKey:object];
    if (!mapTable) {
        mapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsWeakMemory];
        [_mapTable setObject:mapTable forKey:object];
    }
    [mapTable setObject:countingTimer forKey:@(interval)];
    dispatch_semaphore_signal(_lock);
    [countingTimer startTimer];
}

/// MARK: 更新订阅的起始时间
/// @param object 订阅者对象
/// @param interval 订阅的时间间隔
/// @param date 更新后的起始时间
- (void)updateFireDateWithSubscriber:(id)object interval:(NSTimeInterval)interval fireDate:(NSDate *)date {
    if (!object || !date) return;
    // 获取定时器
    ZZGlobalCountingTimer *countingTimer = [self countingTimerWithObject:object interval:interval];
    if (!countingTimer) return;
    // 定时器更新
    [countingTimer updateSubscriber:object fireDate:date];
}

///// MARK: 如果未订阅则进行订阅，如果订阅则只更新时间
///// @param key 主键
///// @param date 更新后的起始时间
///// @param handler 如果订阅则设置每秒定时触发的回调
//- (void)updateSubscriber:(id)object fireDate:(NSDate *)date eventHandler:(void(^)(id object, NSDate *start, NSTimeInterval duration))handler {
//    if ([self subscriberWithObject:object]) {
//        [self updateSubscriber:object fireDate:date];
//    } else {
//        [self addSubscriber:object fireDate:date eventHandler:handler];
//    }
//}


/// MARK: 移除订阅者的一次订阅
/// @param object 订阅者
/// @param interval 订阅的时间间隔
- (void)removeSubscriber:(id)object interval:(NSTimeInterval)interval {
    // 获取定时器
    ZZGlobalCountingTimer *countingTimer = [self countingTimerWithObject:object interval:interval];
    [countingTimer removeSubscriber:object];
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSMapTable *mapTable = [_mapTable objectForKey:object];
    if (mapTable.count == 0) {
        // 删除字典
        [_mapTable removeObjectForKey:object];
    }
    dispatch_semaphore_signal(_lock);
}

/// MARK: 移除订阅者的全部订阅
/// @param object 订阅者
- (void)removeSubscriber:(id)object {
    if (!object) return;
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSMapTable *mapTable = [_mapTable objectForKey:object];
    // 迭代获取定时器
    ZZGlobalCountingTimer *timer = mapTable.objectEnumerator.nextObject;
    while (timer) {
        [timer removeSubscriber:object];
        timer = mapTable.objectEnumerator.nextObject;
    }
    // 删除字典
    [mapTable removeAllObjects];
    dispatch_semaphore_signal(_lock);
}

@end
