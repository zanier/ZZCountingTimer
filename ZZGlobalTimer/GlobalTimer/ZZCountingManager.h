//
//  ZZCountingManager.h
//  ZZGlobalTimer
//
//  Created by ZZ on 2020/2/23.
//  Copyright © 2020 zz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZZCountingTimer.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZCountingManager : NSObject

/// 获取单例对象
+ (instancetype)share;

/// 当前正在运行的定时器字典
@property (nonatomic, readonly) NSDictionary<NSNumber *, ZZCountingTimer *> *timerDic;

/// MARK: 查询订阅是否存在
/// @param object 订阅者对象
/// @param interval 订阅的触发时间间隔
- (BOOL)isSubscribingWithObject:(id)object interval:(NSTimeInterval)interval;

/// MARK: 添加订阅
///
/// @param object
/// * 订阅者对象，会对其产生弱引用。若订阅者对象释放，则自动移除订阅
///
/// @param date
/// * 计时的起始时间，以此计算获得计时的时间间隔
///
/// @param interval
/// * 计时的时间间隔
///
/// @param handler
/// * 每秒定时触发的回调，在后台时不会执行，使用时避免循环引用
/// * key: 订阅的主键
/// * start: 计时的起始时间
/// * duration: 当前时间减去起始时间的时间间隔
- (void)addSubscriber:(id)object fireDate:(NSDate *)date interval:(NSTimeInterval)interval eventHandler:(void(^)(id object, NSDate *startDate, NSTimeInterval duration))handler;

/// MARK: 更新订阅的起始时间
/// @param object 订阅者对象
/// @param interval 订阅的时间间隔
/// @param date 更新后的起始时间
- (void)updateFireDateWithSubscriber:(id)object interval:(NSTimeInterval)interval fireDate:(NSDate *)date;

/// MARK: 移除一个订阅者的一次订阅
/// @param object 订阅者
/// @param interval 订阅的时间间隔
- (void)removeSubscriber:(id)object interval:(NSTimeInterval)interval;

/// MARK: 移除一个订阅者的全部订阅
/// @param object 订阅者
- (void)removeSubscriber:(id)object;

/// MARK: 移除一个定时器
/// @param interval 定时器触发的时间间隔
- (void)removeSubscriberWithInterval:(NSTimeInterval)interval;

@end

NS_ASSUME_NONNULL_END
