// FVHIDEvent.m
// 说明：
//   iOS 公共 SDK 不提供 IOHIDEventSystemClient 头文件，但 SpringBoard 进程里
//   IOKit 符号是常驻的。这里用 dlsym(RTLD_DEFAULT) 逐个解析，缺符号就降级为 no-op。
//   字段号 0x10000/0x10001 是 digitizer 的 X/Y；不同 iOS 15/16 小版本需要用
//   FVLog 打印实际值校准（见分析报告 §5.2）。

#import "FVHIDEvent.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

typedef void *FVIOHIDClientRef;
typedef void *FVIOHIDEventRef;

typedef FVIOHIDClientRef (*FVCreateFn)(CFAllocatorRef);
typedef void (*FVRegisterBlockFn)(FVIOHIDClientRef, void (^)(FVIOHIDEventRef));
typedef void (*FVRegisterCallbackFn)(FVIOHIDClientRef, void *, void *, void *);
typedef void (*FVScheduleFn)(FVIOHIDClientRef, CFRunLoopRef, CFStringRef);
typedef void (*FVUnscheduleFn)(FVIOHIDClientRef, CFRunLoopRef, CFStringRef);
typedef CFArrayRef (*FVGetChildrenFn)(FVIOHIDEventRef);
typedef int32_t (*FVGetIntFn)(FVIOHIDEventRef, uint32_t);
typedef double (*FVGetFloatFn)(FVIOHIDEventRef, uint32_t);
typedef void (*FVCancelTouchesFn)(void);

static FVCreateFn FVCreate;
static FVRegisterBlockFn FVRegisterBlock;
static FVScheduleFn FVSchedule;
static FVUnscheduleFn FVUnschedule;
static FVGetChildrenFn FVGetChildren;
static FVGetIntFn FVGetInt;
static FVGetFloatFn FVGetFloat;
static FVCancelTouchesFn FVCancelTouches;

@interface FVHIDEvent ()
@property (nonatomic, copy, nullable) FVHIDEventHandler handler;
@property (nonatomic, assign) FVIOHIDClientRef client;
@property (nonatomic, assign) BOOL running;
@end

@implementation FVHIDEvent

+ (void)loadSymbolsIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FVCreate = (FVCreateFn)dlsym(RTLD_DEFAULT, "IOHIDEventSystemClientCreate");
        FVRegisterBlock = (FVRegisterBlockFn)dlsym(RTLD_DEFAULT, "IOHIDEventSystemClientRegisterEventBlock");
        FVSchedule = (FVScheduleFn)dlsym(RTLD_DEFAULT, "IOHIDEventSystemClientScheduleWithRunLoop");
        FVUnschedule = (FVUnscheduleFn)dlsym(RTLD_DEFAULT, "IOHIDEventSystemClientUnscheduleWithRunLoop");
        FVGetChildren = (FVGetChildrenFn)dlsym(RTLD_DEFAULT, "IOHIDEventGetChildren");
        FVGetInt = (FVGetIntFn)dlsym(RTLD_DEFAULT, "IOHIDEventGetIntegerValue");
        FVGetFloat = (FVGetFloatFn)dlsym(RTLD_DEFAULT, "IOHIDEventGetFloatValue");
        FVCancelTouches = (FVCancelTouchesFn)dlsym(RTLD_DEFAULT, "BKSHIDServicesCancelTouchesOnAllDisplays");
    });
}

- (BOOL)startWithHandler:(FVHIDEventHandler)handler {
    if (self.running) return YES;
    [[self class] loadSymbolsIfNeeded];
    if (!FVCreate || !FVRegisterBlock || !FVSchedule || !FVGetChildren || !FVGetFloat) {
        NSLog(@"[SplitViewPro] IOHID symbols unavailable, edge gestures disabled");
        return NO;
    }
    self.handler = handler;
    self.client = FVCreate(kCFAllocatorDefault);
    if (!self.client) return NO;

    __weak typeof(self) weakSelf = self;
    FVRegisterBlock(self.client, ^(FVIOHIDEventRef event) {
        [weakSelf handleEvent:event];
    });
    FVSchedule(self.client, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    self.running = YES;
    return YES;
}

- (void)handleEvent:(FVIOHIDEventRef)event {
    if (!event || !self.handler) return;
    CFArrayRef children = FVGetChildren ? FVGetChildren(event) : NULL;
    if (!children || CFArrayGetCount(children) == 0) return;

    for (CFIndex i = 0; i < CFArrayGetCount(children); i++) {
        FVIOHIDEventRef child = (FVIOHIDEventRef)CFArrayGetValueAtIndex(children, i);
        if (!child) continue;

        double x = FVGetFloat(child, 0x10000);
        double y = FVGetFloat(child, 0x10001);
        if (x == 0 && y == 0) continue;

        // touch 字段 0x10008：1 = down，0 = up（iOS 15/16 实测校准点）
        NSInteger touch = FVGetInt ? FVGetInt(child, 0x10008) : 1;
        FVHIDPhase phase = touch ? FVHIDPhaseMoved : FVHIDPhaseEnded;
        static int32_t lastIndex = -1;
        if (lastIndex != (int32_t)i) {
            phase = FVHIDPhaseBegan;
            lastIndex = (int32_t)i;
        }
        if (!touch) lastIndex = -1;

        self.handler(phase, CGPointMake(x, y), (int32_t)i);
    }
}

- (void)stop {
    if (!self.running) return;
    if (FVUnschedule && self.client) {
        FVUnschedule(self.client, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    }
    self.client = NULL;
    self.running = NO;
    self.handler = nil;
}

- (void)cancelSystemTouches {
    if (FVCancelTouches) FVCancelTouches();
}

- (void)dealloc {
    [self stop];
}

@end
