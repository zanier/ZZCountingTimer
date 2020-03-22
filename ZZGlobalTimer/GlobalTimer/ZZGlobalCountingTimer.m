//
//  ZZGlobalCountingTimer.m
//  Demo10251
//
//  Created by zz on 2019/10/30.
//  Copyright © 2019 zailing. All rights reserved.
//

#import "ZZGlobalCountingTimer.h"
#import "ZZGCDTimer.h"

/// 订阅者对象
@interface ZZGlobalCountingTimerSubscriber : NSObject

@property (nonatomic, copy) NSString *key;          // 订阅的主键
@property (nonatomic, strong) NSDate *start;        // 计时的起始时间
@property (nonatomic, copy) void (^eventHandler)(NSString *key, NSDate *start, NSTimeInterval duration); // 每秒定时触发执行的回调

@end

@implementation ZZGlobalCountingTimerSubscriber

@end

@interface ZZGlobalCountingTimer () {
    dispatch_semaphore_t _lock;
    ZZGCDTimer *_timer; // GCD定时器
    NSMutableDictionary<NSString *, ZZGlobalCountingTimerSubscriber *> *_dic; // 保存当前的订阅者
}

@end

@implementation ZZGlobalCountingTimer

/// MARK: 单例
+ (instancetype)share {
    static ZZGlobalCountingTimer *share;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[ZZGlobalCountingTimer alloc] init];
    });
    return share;
}

/// 初始化
- (instancetype)init {
    if (self = [super init]) {
        _lock = dispatch_semaphore_create(1);
        _dic = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)startTimer {
    if (!_timer || !_timer.valid) {
        _timer = [ZZGCDTimer timerWithTimeInterval:1 target:self selector:@selector(timerAction:) repeats:YES];
    }
}

- (void)stopTimer {
    [_timer invalidate];
    _timer = nil;
}

/// MARK: - 定时器每秒定时触发
- (void)timerAction:(ZZGCDTimer *)timer {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSArray<ZZGlobalCountingTimerSubscriber *> *allValues = _dic.allValues;
    dispatch_semaphore_signal(_lock);
    NSDate *now = [NSDate date];
    // 遍历执行每个订阅者
    [allValues enumerateObjectsUsingBlock:^(ZZGlobalCountingTimerSubscriber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.eventHandler) {
            NSTimeInterval duration = [now timeIntervalSinceDate:obj.start];
            obj.eventHandler(obj.key, obj.start, duration);
        }
    }];
}

/// MARK: -

/// MARK: 获取订阅实例对象
/// @param key 主键
- (ZZGlobalCountingTimerSubscriber *)subscribeRWithKey:(NSString *)key {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    ZZGlobalCountingTimerSubscriber *subscriber = _dic[key];
    dispatch_semaphore_signal(_lock);
    return subscriber;
}

/// MARK: 添加订阅
/// @param key 主键
/// @param date 计时的起始时间
/// @param handler 每秒定时触发的回调
- (void)subscribeWithKey:(NSString *)key fireDate:(NSDate *)date eventHandler:(void(^)(NSString *key, NSDate *start, NSTimeInterval duration))handler {
    // 参数非空判断
    if (!key || ![key isKindOfClass:[NSString class]] || key.length == 0 || !date || !handler) return;
    // 立刻执行一次
    if (handler) {
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:date];
        handler(key, date, duration);
    }
    // 将计时事件封装成订阅者对象
    ZZGlobalCountingTimerSubscriber *subscriber = [[ZZGlobalCountingTimerSubscriber alloc] init];
    subscriber.key = key;
    subscriber.start = date;
    subscriber.eventHandler = handler;
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    /*
    // 键值重复判断
    BOOL duplicate = [_dic.allKeys containsObject:key];
    if (duplicate) {
        NSAssert(!duplicate, @"Duplicate key in ZZGlobalCountingTimer. Please use a different key or call `stopTimerWithKey:` with same key first. Otherwise the old one will be override!");
        return;
    }
     */
    // 保存订阅者
    _dic[key] = subscriber;
    dispatch_semaphore_signal(_lock);
    // 检查开启定时器
    [self startTimer];
}

/// MARK: 更新订阅的起始时间
/// @param key 主键
/// @param date 更新后的起始时间
- (void)updateStartDateWithKey:(NSString *)key start:(NSDate *)date {
    // 参数非空判断
    if (!key || ![key isKindOfClass:[NSString class]] || key.length == 0 || !date) return;
    // 获取订阅者
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    ZZGlobalCountingTimerSubscriber *subscriber = _dic[key];
    // 更新起始日期
    subscriber.start = date;
    dispatch_semaphore_signal(_lock);
    if (!subscriber) return;
    // 执行回调
    if (subscriber.eventHandler) {
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:date];
        subscriber.eventHandler(subscriber.key, subscriber.start, duration);
    }
    // 检查开启定时器
    [self startTimer];
}

/// MARK: 如果未订阅则进行订阅，如果订阅则只更新时间
/// @param key 主键
/// @param date 更新后的起始时间
/// @param handler 如果订阅则设置每秒定时触发的回调
- (void)updateOrSubscribeIfNeededWithKey:(NSString *)key start:(NSDate *)date eventHandler:(void(^)(NSString *key, NSDate *start, NSTimeInterval duration))handler {
    if ([self subscribeRWithKey:key]) {
        [self updateStartDateWithKey:key start:date];
    } else {
        [self subscribeWithKey:key fireDate:date eventHandler:handler];
    }
}

/// MARK: 取消订阅
/// @param key 主键
- (void)unsubscribeWithKey:(NSString *)key {
    // 键值非空判断
    if (!key || ![key isKindOfClass:[NSString class]] || key.length == 0) return;
    NSInteger count = 0;
    // 移除订阅者
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [_dic removeObjectForKey:key];
    count = _dic.allValues.count;
    dispatch_semaphore_signal(_lock);
    // 无订阅者则停止定时器
    if (count == 0) [self stopTimer];
}

/// MARK: - public

+ (void)subscribeWithKey:(NSString *)key fireDate:(NSDate *)date eventHandler:(void(^)(NSString *key, NSDate *start, NSTimeInterval duration))handler {
    [[self share] subscribeWithKey:key fireDate:date eventHandler:handler];
}

+ (void)updateStartDateWithKey:(NSString *)key start:(NSDate *)date {
    [[self share] updateStartDateWithKey:key start:date];
}

+ (void)updateOrSubscribeIfNeededWithKey:(NSString *)key start:(NSDate *)date eventHandler:(void(^)(NSString *key, NSDate *start, NSTimeInterval duration))handler {
    [[self share] updateOrSubscribeIfNeededWithKey:key start:date eventHandler:handler];
}

+ (void)unsubscribeWithKey:(NSString *)key {
    [[self share] unsubscribeWithKey:key];
}

@end
