//
//  ZZCountingTimer.m
//  Demo10251
//
//  Created by zz on 2019/10/30.
//  Copyright © 2019 zz. All rights reserved.
//

#import "ZZCountingTimer.h"
#import "ZZGCDTimer.h"
#import "ZZCountingManager.h"

@implementation ZZCountingTimerSubscriber

@end

@interface ZZCountingTimer () {
    dispatch_semaphore_t _lock;
    ZZGCDTimer *_timer; // GCD定时器
    NSMapTable<id, ZZCountingTimerSubscriber *> *_mapTable;
}

@property (nonatomic, assign) NSTimeInterval interval;

@end

@implementation ZZCountingTimer

/// 初始化
- (instancetype)initWithTimeInterval:(NSTimeInterval)interval {
    if (self = [super init]) {
        _interval = interval;
        _lock = dispatch_semaphore_create(1);
        _mapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory];
    }
    return self;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"ZZCountingTimer init error" reason:@"ZZCountingTimer must be initialized with a interval. Use 'initWithTimeInterval:' instead." userInfo:nil];
    return [self initWithTimeInterval:1];
}

- (NSInteger)subscriberCount {
    return [_mapTable count];
}

- (BOOL)isValid {
    return _timer.isValid;
}

- (void)startTimer {
    if (!_timer || !_timer.valid) {
        if (_interval >= 0) {
            _timer = [ZZGCDTimer timerWithTimeInterval:_interval target:self selector:@selector(timerAction:) repeats:YES];
            //NSLog(@"开启定时器 %@", self);
            if ([_delegate respondsToSelector:@selector(countingTimerDidStartTimer:)]) {
                [_delegate countingTimerDidStartTimer:self];
            }
        }
    }
}

- (void)stopTimer {
    [_timer invalidate];
    _timer = nil;
    //NSLog(@"停止定时器 %@", self);
    if ([_delegate respondsToSelector:@selector(countingTimerDidStopTimer:)]) {
        [_delegate countingTimerDidStopTimer:self];
    }
}

/// MARK: - 定时器每秒定时触发
- (void)timerAction:(ZZGCDTimer *)timer {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSArray<ZZCountingTimerSubscriber *> *allValues = _mapTable.objectEnumerator.allObjects;
    dispatch_semaphore_signal(_lock);
    if (allValues.count <= 0) {
        // 无订阅者则停止定时器
        //NSLog(@"无订阅者则停止定时器 %@ \n%@", self, _mapTable);
        [self stopTimer];
        return;
    }
    NSDate *now = [NSDate date];
    // 遍历执行每个订阅者
    [allValues enumerateObjectsUsingBlock:^(ZZCountingTimerSubscriber * _Nonnull subscriber, NSUInteger idx, BOOL * _Nonnull stop) {
        if (subscriber.eventHandler && !subscriber.pause) {
            NSTimeInterval duration = [now timeIntervalSinceDate:subscriber.start];
            subscriber.eventHandler(subscriber.object, subscriber.start, duration);
            //NSLog(@"定时操作 self: %p cls: %@ cls: %p", self, NSStringFromClass([subscriber.object class]), subscriber.object);
        }
    }];
}

/// MARK: 获取订阅实例对象
/// @param object 订阅者对象
- (ZZCountingTimerSubscriber *)subscriberWithObject:(id)object {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    ZZCountingTimerSubscriber *subscriber = [_mapTable objectForKey:object];
    dispatch_semaphore_signal(_lock);
    return subscriber;
}

/// MARK: 添加订阅
/// @param object 订阅者对象
/// @param date 计时的起始时间
/// @param handler 定时触发的回调
- (void)addSubscriber:(id)object fireDate:(NSDate *)date eventHandler:(void(^)(id object, NSDate *start, NSTimeInterval duration))handler {
    // 参数非空判断
    if (!object || !date || !handler) return;
    // 立刻执行一次
    if (handler) {
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:date];
        handler(object, date, duration);
    }
    // 将计时事件封装成订阅者对象
    ZZCountingTimerSubscriber *subscriber = [[ZZCountingTimerSubscriber alloc] init];
    subscriber.object = object;
    subscriber.start = date;
    subscriber.eventHandler = handler;
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    // 保存订阅者
    [_mapTable setObject:subscriber forKey:object];
    dispatch_semaphore_signal(_lock);
    //NSLog(@"添加订阅者: %@ self: %@ mapTable: \n%@", object, self, _mapTable);
    if ([_delegate respondsToSelector:@selector(countingTimer:didAddSubscriber:)]) {
        [_delegate countingTimer:self didAddSubscriber:subscriber];
    }
    // 检查开启定时器
    [self startTimer];
}

/// MARK: 更新订阅的起始时间
/// @param object 订阅者对象
/// @param date 更新后的起始时间
- (void)updateSubscriber:(id)object fireDate:(NSDate *)date {
    // 参数非空判断
    if (!object || !date) return;
    // 获取订阅者
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    ZZCountingTimerSubscriber *subscriber = [_mapTable objectForKey:object];
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
/// @param object 订阅者对象
/// @param date 更新后的起始时间
/// @param handler 如果订阅则设置每秒定时触发的回调
- (void)updateSubscriber:(id)object fireDate:(NSDate *)date eventHandler:(void(^)(id object, NSDate *start, NSTimeInterval duration))handler {
    if ([self subscriberWithObject:object]) {
        [self updateSubscriber:object fireDate:date];
    } else {
        [self addSubscriber:object fireDate:date eventHandler:handler];
    }
}

/// MARK: 移除订阅对象
/// @param object 订阅者对象
- (void)removeSubscriber:(id)object {
    // 键值非空判断
    if (!object) return;
    NSInteger count = 0;
    // 移除订阅者
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [_mapTable removeObjectForKey:object];
    count = _mapTable.count;
    dispatch_semaphore_signal(_lock);
    // 无订阅者则停止定时器
    if (count == 0) [self stopTimer];
}

@end
