//
//  ZZCountingManager.m
//  ZZGlobalTimer
//
//  Created by ZZ on 2020/2/23.
//  Copyright © 2020 zz. All rights reserved.
//

#import "ZZCountingManager.h"
#import "ZZCountingTimer.h"

@interface ZZCountingManager () <ZZCountingTimerDelegate> {
    dispatch_semaphore_t _lock;
    NSMutableDictionary<NSNumber *, ZZCountingTimer *> *_timerDic; // 保存多个频道的定时器对象
    NSMapTable<id, NSMapTable<NSNumber *, ZZCountingTimer *> *> *_mapTable; // 订阅者和频道的映射
}

@property (nonatomic, strong) NSDictionary<NSNumber *, ZZCountingTimer *> *countingTimerDic;

@end

@implementation ZZCountingManager

@dynamic countingTimerDic;

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
        _timerDic = [NSMutableDictionary dictionary];
        _mapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory];
    }
    return self;
}
  
- (NSMutableDictionary<NSNumber *,ZZCountingTimer *> *)countingTimerDic {
    return [_timerDic copy];
}

/// MARK: 查询订阅是否存在
/// @param object 订阅者对象
/// @param interval 订阅的触发时间间隔
- (BOOL)isSubscribingWithObject:(id)object interval:(NSTimeInterval)interval {
    return (BOOL)[self countingTimerWithObject:object interval:interval];
}

/// MARK: 获取定时器实例对象
/// @param object 订阅者对象
/// @param interval 订阅的时间间隔
- (ZZCountingTimer *)countingTimerWithObject:(id)object interval:(NSTimeInterval)interval {
    if (!object) return nil;
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSMapTable *mapTable = [_mapTable objectForKey:object];
    ZZCountingTimer *countingTimer = [mapTable objectForKey:@(interval)];
    dispatch_semaphore_signal(_lock);
    return countingTimer;
}

/// MARK: 获取定时器实例对象
/// @param interval 订阅的时间间隔
- (ZZCountingTimer *)countingTimerWithInterval:(NSTimeInterval)interval {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    ZZCountingTimer *countingTimer = _timerDic[@(interval)];
    dispatch_semaphore_signal(_lock);
    return countingTimer;
}

/// MARK: 添加订阅
/// @param object 订阅者
/// @param date 计时的起始时间
/// @param interval 订阅的时间间隔
/// @param handler 定时触发的回调
- (void)addSubscriber:(id)object fireDate:(NSDate *)date interval:(NSTimeInterval)interval eventHandler:(void(^)(id object, NSDate *startDate, NSTimeInterval duration))handler {
    // 参数非空判断
    if (!object || !date || interval <= 0 || !handler) return;
    // 获取定时器
    ZZCountingTimer *countingTimer = [self countingTimerWithInterval:interval];
    if (!countingTimer) {
        // 创建定时器
        countingTimer = [[ZZCountingTimer alloc] initWithTimeInterval:interval];
        countingTimer.delegate = self;
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
    _timerDic[@(interval)] = countingTimer;
    dispatch_semaphore_signal(_lock);
    // 开启定时器
    [countingTimer startTimer];
}

/// MARK: 更新订阅的起始时间
/// @param object 订阅者对象
/// @param interval 订阅的时间间隔
/// @param date 更新后的起始时间
- (void)updateFireDateWithSubscriber:(id)object interval:(NSTimeInterval)interval fireDate:(NSDate *)date {
    if (!object || !date) return;
    // 获取定时器
    ZZCountingTimer *countingTimer = [self countingTimerWithObject:object interval:interval];
    if (!countingTimer) return;
    // 定时器更新
    [countingTimer updateSubscriber:object fireDate:date];
}

/// MARK: 移除一个订阅者的一次订阅
/// @param object 订阅者
/// @param interval 订阅的时间间隔
- (void)removeSubscriber:(id)object interval:(NSTimeInterval)interval {
    // 获取定时器
    ZZCountingTimer *countingTimer = [self countingTimerWithObject:object interval:interval];
    [countingTimer removeSubscriber:object];
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSMapTable *mapTable = [_mapTable objectForKey:object];
    if (mapTable.count == 0) {
        // 删除字典
        [_mapTable removeObjectForKey:object];
    }
    if (countingTimer.subscriberCount == 0) {
        _timerDic[@(countingTimer.interval)] = nil;
    }
    dispatch_semaphore_signal(_lock);
}

/// MARK: 移除一个订阅者的全部订阅
/// @param object 订阅者
- (void)removeSubscriber:(id)object {
    if (!object) return;
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSMapTable *mapTable = [_mapTable objectForKey:object];
    // 迭代获取定时器
    ZZCountingTimer *countingTimer = mapTable.objectEnumerator.nextObject;
    while (countingTimer) {
        [countingTimer removeSubscriber:object];
        countingTimer = mapTable.objectEnumerator.nextObject;
    }
    // 删除字典
    [_mapTable removeObjectForKey:object];
    dispatch_semaphore_signal(_lock);
}

/// MARK: 移除一个定时器
/// @param interval 定时器触发的时间间隔
- (void)removeSubscriberWithInterval:(NSTimeInterval)interval {
    // 获取定时器
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    ZZCountingTimer *countingTimer = _timerDic[@(interval)];
//    countingTimer.
    dispatch_semaphore_signal(_lock);
    // 停止定时器
    [countingTimer stopTimer];
    // 定时器停止后，在代理方法中移除定时器
}

/// MARK: - <ZZCountingTimerDelegate>

/// 定时器停止
/// @param countingTimer 定时器
- (void)countingTimerDidStopTimer:(ZZCountingTimer *)countingTimer {
    // 移除并释放定时器实例对象
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [_timerDic removeObjectForKey:@(countingTimer.interval)];
    dispatch_semaphore_signal(_lock);
}


@end
