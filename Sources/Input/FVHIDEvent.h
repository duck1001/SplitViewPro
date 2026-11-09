// FVHIDEvent.h
// IOHID 采集的 ObjC 桥。Swift 侧不直接 import IOKit.hid（iOS 公共 SDK 没有该模块），
// 由这个桥在运行时 dlsym 私有符号，避免编译期私有头依赖。

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FVHIDPhase) {
    FVHIDPhaseBegan = 0,
    FVHIDPhaseMoved = 1,
    FVHIDPhaseEnded = 2,
    FVHIDPhaseCancelled = 3,
};

typedef void (^FVHIDEventHandler)(FVHIDPhase phase, CGPoint point, int32_t index);

@interface FVHIDEvent : NSObject

/// 启动 IOHIDEventSystemClient。若私有符号不存在则安全失败（返回 NO）。
- (BOOL)startWithHandler:(FVHIDEventHandler)handler;
- (void)stop;

/// 抢断系统触摸，避免 Home 指示条/边缘手势被误触发。
- (void)cancelSystemTouches;

@end

NS_ASSUME_NONNULL_END
