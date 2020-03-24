//
//  ZZCountingTimer.h
//  Demo10251
//
//  Created by zz on 2019/10/30.
//  Copyright © 2019 zz. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZZCountingTimer, ZZCountingTimerSubscriber;

NS_ASSUME_NONNULL_BEGIN

@protocol ZZCountingTimerDelegate <NSObject>

@optional
- (void)countingTimer:(ZZCountingTimer *)countingTimer didAddSubscriber:(ZZCountingTimerSubscriber *)subscriber;
- (void)countingTimerDidStartTimer:(ZZCountingTimer *)countingTimer;
- (void)countingTimerDidStopTimer:(ZZCountingTimer *)countingTimer;

@end

/// 订阅者对象
@interface ZZCountingTimerSubscriber : NSObject

@property (nonatomic, weak) id object;              // 订阅者对象
@property (nonatomic, copy) NSString *key;          // 订阅的主键
@property (nonatomic, strong) NSDate *start;        // 计时的起始时间
@property (nonatomic, assign) BOOL pause;           // 订阅是否暂停
@property (nonatomic, copy) void (^eventHandler)(NSString *key, NSDate *start, NSTimeInterval duration); // 定时触发执行的回调

@end

/// 全局计时工具
/// * 创建单例维护一个 GCDTimer
/// * 保存所有的订阅者
/// * 每秒定时触发每个订阅者的回调
/// * 当前时间 - 起始时间 = 时间间隔
@interface ZZCountingTimer : NSObject

/// 初始化方法
/// @param interval 定时器触发的时间间隔，不可更改
- (instancetype)initWithTimeInterval:(NSTimeInterval)interval;

@property (nonatomic, weak) id<ZZCountingTimerDelegate> delegate;

@property (nonatomic, readonly) NSTimeInterval interval;        // 定时器的触发时间间隔，在 `ZZCountingManager` 中将作为 key 保存到字典当中。

@property (nonatomic, readonly) NSInteger subscriberCount;      // 当前持有的订阅数

@property (nonatomic, readonly, getter=isValid) BOOL valid;     // 定时器是否正在运行

/// 开始定时器
- (void)startTimer;

/// 停止定时器
- (void)stopTimer;

/// MARK: 添加订阅
///
/// @param object
/// * 订阅者对象，会对其产生弱引用。若订阅者对象释放，则自动移除订阅
///
/// @param date
/// * 计时的起始时间（不是订阅时的时间），以此计算获得计时的时间间隔
///
/// @param handler
/// * 每秒定时触发的回调，在后台时不会执行，使用时避免循环引用
/// * key: 订阅的主键
/// * start: 计时的起始时间
/// * duration: 当前时间减去起始时间的时间间隔
- (void)addSubscriber:(id)object fireDate:(NSDate *)date eventHandler:(void(^)(id object, NSDate *start, NSTimeInterval duration))handler;

/// MARK: 更新订阅的起始时间
/// @param object 订阅者对象
/// @param date 更新后的起始时间
- (void)updateSubscriber:(id)object fireDate:(NSDate *)date;

/// MARK: 如果未订阅则进行订阅，如果订阅则只更新时间
/// @param object 订阅者对象
/// @param date 更新后的起始时间
/// @param handler 如果订阅则设置每秒定时触发的回调
- (void)updateSubscriber:(id)object fireDate:(NSDate *)date eventHandler:(void(^)(id object, NSDate *start, NSTimeInterval duration))handler;

/// MARK: 移除订阅对象
/// @param object 订阅者对象
- (void)removeSubscriber:(id)object;

@end

NS_ASSUME_NONNULL_END
