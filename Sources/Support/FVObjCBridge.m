#import "FVObjCBridge.h"
#import <objc/message.h>

id FVPerform0(id target, NSString *selectorName) {
    if (!target || selectorName.length == 0) return nil;
    SEL selector = NSSelectorFromString(selectorName);
    if (![target respondsToSelector:selector]) return nil;
    typedef id (*Fn)(id, SEL);
    return ((Fn)objc_msgSend)(target, selector);
}

id FVPerform1(id target, NSString *selectorName, id arg1) {
    if (!target || selectorName.length == 0) return nil;
    SEL selector = NSSelectorFromString(selectorName);
    if (![target respondsToSelector:selector]) return nil;
    typedef id (*Fn)(id, SEL, id);
    return ((Fn)objc_msgSend)(target, selector, arg1);
}

id FVPerform2(id target, NSString *selectorName, id arg1, id arg2) {
    if (!target || selectorName.length == 0) return nil;
    SEL selector = NSSelectorFromString(selectorName);
    if (![target respondsToSelector:selector]) return nil;
    typedef id (*Fn)(id, SEL, id, id);
    return ((Fn)objc_msgSend)(target, selector, arg1, arg2);
}

id FVPerform3(id target, NSString *selectorName, id arg1, id arg2, id arg3) {
    if (!target || selectorName.length == 0) return nil;
    SEL selector = NSSelectorFromString(selectorName);
    if (![target respondsToSelector:selector]) return nil;
    typedef id (*Fn)(id, SEL, id, id, id);
    return ((Fn)objc_msgSend)(target, selector, arg1, arg2, arg3);
}
