# ZZCountingTimer

**背景**

在之前接手过的一个项目中，因业务需求需要有很多的计时文本。比如在一个 UITableView 中，每个 Cell 都有一个文本，显示了事件发生了多久。频繁创建定时器不利于管理，因此项目中使用了一个定时器的管理类来进行所有定时器的管理。

管理类是个单例，通过传入一个 ID 来创建一个秒计的定时器，通过传入 block 保存一个回调，两者保存在管理类中，并通过 ID 来配对，定时器定时地执行 block。

**不足**

经过研究过后，发现了很多不便与问题。

第一，项目中，每有一个需要计时的地方，就会创建一个定时器保存在类中，多个定时器一起运行。首先在内存与计算上有一定的优化空间，其次每个定时器独立工作，会有两个 label 刷新不一致的情况。比如同样在计时，在 1s 内，第 0s  label1刷新，第 0.3s label2 刷新，在视觉上会有些奇怪。

第二，计时的时间保存在 timer.userInfo 中，每执行一次便 +1s。同时为了保证在后台也在计时，所以在 applicationDidEnterBackground 时暂停所有计时器且记录暂停时间，在 applicationWillEnterForeground 时开启所有定时器且记录开始时间，两者相减得到切到后台的时间，然后加到每个定时器的计数当中。这样导致逻辑比较麻烦，并且需要在 AppDelagate 中引用，增加耦合度。

除了上述两点，还有一些不规范、不严谨的地方。而且 NSTimer 收 RunLoop 影响并不是精确的，且 NSTimer、Block 使用不当会产生循环引用。所以，为了更加简便且安全的管理计时，抽空重新写了个计时的工具。

## 思路

实现的核心思想就是统一定时器，方便管理的同时又减少计算，将所有的计时操作用 Block 保存起来，每秒依次执行所有的操作。从设计模式上来说就是订阅者模式，定时器是发布者，定时发布事件，而界面是订阅者，接受事件并处理。以此为主，加以 GCDTimer、多线程实现工具的线程安全与高效运行。

整个工具分为四个部分：

* ZZGCDTimer：使用 dispatch_source_t 创建的定时器，这里直接使用了 YYTimer。
* ZZCountingTimerSubscribe：订阅类
* ZZCountingTimer：类似于一个频道，管理同一种订阅的定时器类
* ZZCountingManager：管理多个不同 ZZCountingTimer 的管理类，负责不同频道的管理。

## 实现过程

#### ZZGCDTimer

YYTimer 中使用 dispatch_source_t 创建的定时器，在主线程运行且线程安全，不受 RunLoop 影响时间更加精确，不会对外界对象产生强引用，所以采用其作为内部的定时器。

#### ZZCountingTimerSubscribe

```objective-c
/// 订阅
@interface ZZCountingTimerSubscribe : NSObject

@property (nonatomic, weak) id object;              // 订阅对象
@property (nonatomic, strong) NSDate *startDate;    // 计时的起始时间
@property (nonatomic, assign) BOOL pause;           // 订阅是否暂停
@property (nonatomic, copy) void (^eventHandler)(id object, NSDate *startDate, NSTimeInterval duration); // 定时触发执行的回调

@end
```

该实例对象表示外界的一次订阅，包含订阅所需的信息。

* object：订阅的索引对象，一般设置为订阅者本身。这里使用 weak 保存到内部的 NSMapTable 中，当 object 被释放后，此次订阅将自动移除，不会产生内存泄漏。
* startDate：计时的开始时间
* pause：设置为 YES 则不会定时触发 eventHandler。（功能待完善）
* eventHandler：定时触发的回调。

当检测到 object 释放后，会移除这个订阅对象。如果 eventHandler 强引用了 object 而且没有在适当的时机移除该订阅，则会产生循环引用。可将外界的 UILabel 设为 object 然后在 Block 直接使用。

```objective-c
[[ZZCountingManager share] addSubscriber:self.timingLabel fireDate:[NSDate date] interval:1 eventHandler:^(id  _Nonnull object, NSDate * _Nonnull startDate, NSTimeInterval duration) {
    UILabel *label = (UILabel *)object;
    label.text = [NSString stringWithFormat:@"%.0f", duration];
}];
```

#### ZZCountingTimer

管理同一种订阅的频道类，实现了以下功能：

1. 创建 ZZGCDTimer 产生定时事件。
2. 保存多个订阅 ZZCountingTimerSubscribe。
3. 定时执行每个订阅的 eventHandler。
4. 在有订阅时开始定时器，没订阅时关闭定时器。

通过 NSMapTable 保存订阅，当弱指针对象 object 被释放后，整个订阅也会被释放，避免。

``` objective-c
_mapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory];

[_mapTable setObject:subscriber forKey:object];
```

通过前后两个时间点相减，计算获得经过多少时间，比通过计数的方式更直观准确。

```objective-c
NSDate *now = [NSDate date];
// 执行每个订阅者的回调
[_mapTable.objectEnumerator.allObjects enumerateObjectsUsingBlock:^(ZZCountingTimerSubscribe * _Nonnull subscriber, NSUInteger idx, BOOL * _Nonnull stop) {
    if (subscriber.eventHandler && !subscriber.pause) {
        NSTimeInterval duration = [now timeIntervalSinceDate:subscriber.startDate];
        subscriber.eventHandler(subscriber.object, subscriber.startDate, duration);
    }
}];
```

#### ZZCountingManager

多频道的单例管理对象，提供对外的接口。

```objective-c
NSMutableDictionary<NSNumber *, ZZCountingTimer *> *_timerDic;
NSMapTable<id, NSMapTable<NSNumber *, ZZCountingTimer *> *> *_mapTable;
```

* _timerDic：用来保存所有的频道定时器，主键是定时器的时间间隔，不同的频道拥有不同的时间间隔，类似于频率。
* _mapTable：订阅者和频道的映射，主要用来提供额外的接口支持。

```objective-c
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
```

当外界调用订阅接口时，如果对应 interval 频率下已拥有 ZZCountingTimer，则调用其接口添加一个新的订阅，若不存在则创建新的 ZZCountingTimer 执行添加订阅，并将其保存到 _timerDic。

当移除一个订阅时，通过 interval、object 找到对应的订阅并移除。

当移除订阅或订阅者 object 被释放时，timer 触发检测当前的订阅数。如果订阅数为零则自动停止定时器，并通过代理让 ZZCountingManager 删除自身。

## 使用

```objective-c
// 创建一个定时订阅事件
[[ZZCountingManager share] addSubscriber:self.textLabel fireDate:[NSDate date] interval:1 eventHandler:^(id  _Nonnull object, NSDate * _Nonnull start, NSTimeInterval duration) {
    UILabel *label = (UILabel *)object;
    label.text = [NSString stringWithFormat:@"%.0f", duration];
}];

// 更新订阅的起始时间，可在 cell 复用后使用刷新视图
[[ZZCountingManager share] updateFireDateWithSubscriber:self.textLabel interval:1 fireDate:startDate];
```

## 待完善

在实际业务需求中其实只需要一个每秒定时触发的定时器就足够了，然后通过一个 key 来索引各个订阅。但后续考虑到其他需求便添加了一些其他的功能，比如创建不同频率定时事件、订阅事件随订阅者一起释放等。目前所有操作都是在一个线程中完成的，考虑到未来订阅过多的情况，在后续将通过子线程分摊一些操作，以避免主线程卡顿。