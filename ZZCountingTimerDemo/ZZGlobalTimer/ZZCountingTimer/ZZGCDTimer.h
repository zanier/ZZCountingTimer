//
//  ZZGCDTimer.h
//  SafeElevatorManager
//
//  Created by zz on 2019/10/25.
//  Copyright © 2019 zz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// YYTimer 封装的线程安全的 GCD timer 代替 NSTimer
/// * 永远在主线程运行
/// * 不受 RunLoop 影响，时间更精确
/// * 对 target 弱引用，不会产生循环引用
@interface ZZGCDTimer : NSObject

+ (ZZGCDTimer *)timerWithTimeInterval:(NSTimeInterval)interval
                                target:(id)target
                              selector:(SEL)selector
                               repeats:(BOOL)repeats;

- (instancetype)initWithFireTime:(NSTimeInterval)start
                        interval:(NSTimeInterval)interval
                          target:(id)target
                        selector:(SEL)selector
                         repeats:(BOOL)repeats NS_DESIGNATED_INITIALIZER;

@property (readonly) BOOL repeats;
@property (readonly) NSTimeInterval timeInterval;
@property (readonly, getter=isValid) BOOL valid;

- (void)invalidate;

- (void)fire;

@end

NS_ASSUME_NONNULL_END
