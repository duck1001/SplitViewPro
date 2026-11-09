// FVObjCBridge.h
// Swift 侧不方便直接对 AnyObject 调 perform；这里统一用 ObjC 包一层。
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

id _Nullable FVPerform0(id _Nullable target, NSString *selectorName);
id _Nullable FVPerform1(id _Nullable target, NSString *selectorName, id _Nullable arg1);
id _Nullable FVPerform2(id _Nullable target, NSString *selectorName,
                        id _Nullable arg1, id _Nullable arg2);
id _Nullable FVPerform3(id _Nullable target, NSString *selectorName,
                        id _Nullable arg1, id _Nullable arg2, id _Nullable arg3);

NS_ASSUME_NONNULL_END
