// SplitViewProPrefsRootListController.m
// 可编译的设置面板（ObjC + Preferences 私有头）。
// 与主 dylib 共用同一个 CFPreferences 域：com.nailong.split。
// 改动后 Post Darwin 通知，SpringBoard 侧 FVPrefsStore 热重载。

#import "SplitViewProPrefsRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <notify.h>
#import <spawn.h>

static NSString *const kDomain = @"com.nailong.split";
static NSString *const kChangedNotification = @"com.nailong.split.prefs-didChange";

static id SVProPrefGet(NSString *key) {
    CFPropertyListRef value = CFPreferencesCopyAppValue((__bridge CFStringRef)key,
                                                        (__bridge CFStringRef)kDomain);
    return (__bridge_transfer id)value;
}

static void SVProPrefSet(NSString *key, id value) {
    CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value,
                             (__bridge CFStringRef)kDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)kDomain);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         (__bridge CFStringRef)kChangedNotification,
                                         NULL, NULL, true);
}

@implementation SplitViewProPrefsRootListController

- (NSMutableArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [NSMutableArray array];

        // ---------- 分屏 / 浮窗 ----------
        [self addGroup:@"分屏与浮窗" footer:@"分屏核心由 SpringBoard 侧 FBScene 重挂载实现。"];
        [self addToggle:@"启用分屏浮窗" key:@"frontConsoleEnable" defaultValue:@YES];
        [self addToggle:@"主屏图标长按打开浮窗" key:@"SBIcon_openFloatingGesture" defaultValue:@YES];
        [self addToggle:@"通知横幅打开浮窗" key:@"notificationViewPrsentFloatV" defaultValue:@NO];
        [self addToggle:@"悬浮球显示角标" key:@"floatingActionImg_showAppBadge" defaultValue:@YES];

        // ---------- 外观 ----------
        [self addGroup:@"外观" footer:nil];
        [self addSlider:@"浮窗阴影透明度" key:@"floatingViewHostingviewShadow_Opacity"
                 min:@0 max:@1.0 default:@0.8];
        [self addSlider:@"侧边栏图标大小" key:@"sideBarContainer_appIconSize_value"
                 min:@20 max:@80 default:@44];

        // ---------- 三屏 ----------
        [self addGroup:@"三屏" footer:@"竖屏显示三屏，横屏显示浮窗。"];
        [self addSegment:@"渲染位置" key:@"multipleScreenRenderPosition"
                 values:@[@0, @1] titles:@[@"竖屏三屏", @"横屏浮窗"] default:@0];

        // ---------- 维护 ----------
        [self addGroup:@"维护" footer:nil];
        [self addButton:@"重置浮窗位置" action:@selector(resetPositions)];
        [self addButton:@"恢复默认设置" action:@selector(resetDefaults)];
    }
    return _specifiers;
}

#pragma mark - Builders

- (void)addGroup:(NSString *)name footer:(NSString *)footer {
    PSSpecifier *group = [PSSpecifier groupSpecifierWithName:name];
    if (footer.length) {
        [group setProperty:footer forKey:@"footerText"];
    }
    [_specifiers addObject:group];
}

- (void)addToggle:(NSString *)name key:(NSString *)key defaultValue:(NSNumber *)defaultValue {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:name
                                                       target:self
                                                          set:@selector(setToggle:specifier:)
                                                          get:@selector(readValue:)
                                                       detail:nil
                                                         cell:PSSwitchCell
                                                         edit:nil];
    [spec setProperty:key forKey:@"key"];
    [spec setProperty:defaultValue forKey:@"default"];
    [_specifiers addObject:spec];
}

- (void)addSlider:(NSString *)name key:(NSString *)key
              min:(NSNumber *)min max:(NSNumber *)max default:(NSNumber *)defaultValue {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:name
                                                       target:self
                                                          set:@selector(setNumber:specifier:)
                                                          get:@selector(readValue:)
                                                       detail:nil
                                                         cell:PSSliderCell
                                                         edit:nil];
    [spec setProperty:key forKey:@"key"];
    [spec setProperty:defaultValue forKey:@"default"];
    [spec setProperty:min forKey:@"min"];
    [spec setProperty:max forKey:@"max"];
    [spec setProperty:@YES forKey:@"showValue"];
    [_specifiers addObject:spec];
}

- (void)addSegment:(NSString *)name key:(NSString *)key
            values:(NSArray *)values titles:(NSArray *)titles default:(NSNumber *)defaultValue {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:name
                                                       target:self
                                                          set:@selector(setNumber:specifier:)
                                                          get:@selector(readValue:)
                                                       detail:nil
                                                         cell:PSSegmentCell
                                                         edit:nil];
    [spec setProperty:key forKey:@"key"];
    [spec setProperty:defaultValue forKey:@"default"];
    [spec setProperty:values forKey:@"validValues"];
    [spec setProperty:titles forKey:@"validTitles"];
    [_specifiers addObject:spec];
}

- (void)addButton:(NSString *)name action:(SEL)action {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:name
                                                       target:self
                                                          set:nil
                                                          get:nil
                                                       detail:nil
                                                         cell:PSButtonCell
                                                         edit:nil];
    [spec setProperty:NSStringFromSelector(action) forKey:@"action"];
    [spec setProperty:name forKey:@"label"];
    [spec setButtonAction:action];
    [_specifiers addObject:spec];
}

#pragma mark - Getter / Setter

- (id)readValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    id value = SVProPrefGet(key);
    if (value == nil) {
        value = [specifier propertyForKey:@"default"];
    }
    return value ?: @NO;
}

- (void)setToggle:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    BOOL on = [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : NO;
    SVProPrefSet(key, @(on));
}

- (void)setNumber:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    double number = [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : 0;
    SVProPrefSet(key, @(number));
}

#pragma mark - Actions

- (void)resetPositions {
    NSString *dir = @"/var/mobile/Library/SplitViewPro/FloatingViewInfo";
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:dir]) {
        [fm removeItemAtPath:dir error:nil];
    }
    SVProPrefSet(@"floatingViewVCenterX", @0.5);
    SVProPrefSet(@"floatingViewVCenterY", @0.5);
    SVProPrefSet(@"floatingViewHCenterX", @0.5);
    SVProPrefSet(@"floatingViewHCenterY", @0.5);
    SVProPrefSet(@"floatingViewVScale", @0.6);
    SVProPrefSet(@"floatingViewHScale", @0.6);
}

- (void)resetDefaults {
    // 删除域，让 SpringBoard 下次启动时按 FVPrefsDefaults 重建。
    CFPreferencesSetMultiple(NULL, NULL, (__bridge CFStringRef)kDomain,
                             kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFPreferencesAppSynchronize((__bridge CFStringRef)kDomain);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         (__bridge CFStringRef)kChangedNotification,
                                         NULL, NULL, true);
}

@end
