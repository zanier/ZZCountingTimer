//
//  ZZGlobalCountingTimer.h
//  Demo10251
//
//  Created by zz on 2019/10/30.
//  Copyright © 2019 zailing. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 全局计时工具
/// * 创建单例维护一个 GCDTimer
/// * 保存所有的订阅者
/// * 每秒定时触发每个订阅者的回调
/// * 当前时间 - 起始时间 = 时间间隔
@interface ZZGlobalCountingTimer : NSObject

/// MARK: 添加订阅
///
/// @param key
/// * 主键，为避免主键重复，可以使用相关对象的地址或哈希值：
/// * [NSString stringWithFormat:@"%li", obj.hash]
///
/// @param date
/// * 计时的起始时间（不是订阅时的时间），以此计算获得计时的时间间隔
///
/// @param handler
/// * 每秒定时触发的回调，在后台时不会执行，使用时避免循环引用
/// * key: 订阅的主键
/// * start: 计时的起始时间
/// * duration: 当前时间减去起始时间的时间间隔
+ (void)subscribeWithKey:(NSString *)key fireDate:(NSDate *)date eventHandler:(void(^)(NSString *key, NSDate *start, NSTimeInterval duration))handler;

/// MARK: 更新订阅的起始时间
/// * 更新订阅的起始时间，并触发一次回调用于及时更新状态
/// * 用于像单元格复用等场景，cell复用时，通过该方法实现订阅的复用
///
/// @param key 主键
/// @param date 更新后的起始时间
+ (void)updateStartDateWithKey:(NSString *)key start:(NSDate *)date;

/// MARK: 如果未订阅则进行订阅，如果订阅则只更新时间
/// @param key 主键
/// @param date 更新后的起始时间
/// @param handler 如果订阅则设置每秒定时触发的回调
+ (void)updateOrSubscribeIfNeededWithKey:(NSString *)key start:(NSDate *)date eventHandler:(void(^)(NSString *key, NSDate *start, NSTimeInterval duration))handler;

/// MARK: 取消订阅
/// * 在使用结束后务必移除订阅，否则订阅一直存在，可能会导致内存泄漏
///
/// @param key 主键
+ (void)unsubscribeWithKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
