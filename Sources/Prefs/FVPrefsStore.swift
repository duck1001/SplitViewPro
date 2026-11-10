// FVPrefsStore.swift
// 对应原版：floatingView.FVPrefs
// 原版把配置写在 /var/mobile/Library/Preferences/com.be-huge.floating-view-prefs.plist，
// 改完 Post Darwin 通知，SpringBoard 侧监听热重载（无需 respring）。

import Foundation

public final class FVPrefsStore {
    public static let shared = FVPrefsStore()

    public static let domain = "com.nailong.split" as CFString

    /// 与原版同构：配置就是一个普通 plist 文件
    public static var plistPath: String {
        // CFPreferences 最终落到 rootfs 的 /var/mobile/Library/Preferences。
        // RootHide 的 jbroot 是随机路径，不能写死 /var/jb；这里始终用 rootfs 路径。
        return "/var/mobile/Library/Preferences/com.nailong.split.plist"
    }
    public static let changedNotification = "com.nailong.split.prefs-didChange" as CFString

    private var cache: [String: Any] = [:]
    private let lock = NSLock()

    private init() {
        reload()
        observe()
    }

    // MARK: - 读

    public func bool(_ key: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return (cache[key] as? Bool) ?? (cache[key] as? NSNumber)?.boolValue ?? false
    }
    public func double(_ key: String) -> Double {
        lock.lock(); defer { lock.unlock() }
        return (cache[key] as? Double) ?? (cache[key] as? NSNumber)?.doubleValue ?? 0
    }
    public func int(_ key: String) -> Int {
        lock.lock(); defer { lock.unlock() }
        return (cache[key] as? Int) ?? (cache[key] as? NSNumber)?.intValue ?? 0
    }
    public func string(_ key: String) -> String {
        lock.lock(); defer { lock.unlock() }
        return (cache[key] as? String) ?? ""
    }
    public func array<T>(_ key: String, as: T.Type = T.self) -> [T] {
        lock.lock(); defer { lock.unlock() }
        return (cache[key] as? [T]) ?? []
    }

    // MARK: - 写

    public func set(_ value: Any?, for key: String) {
        lock.lock()
        if let v = value { cache[key] = v } else { cache.removeValue(forKey: key) }
        let snapshot = cache
        lock.unlock()

        let cf = snapshot as CFDictionary
        CFPreferencesSetAppValue(key as CFString, value as CFPropertyList?, Self.domain)
        CFPreferencesAppSynchronize(Self.domain)
        _ = cf
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(Self.changedNotification), nil, nil, true)
    }

    public func setDefaultsIfNeeded() {
        let existing = CFPreferencesCopyAppValue("__inited__" as CFString, Self.domain)
        if existing != nil { return }
        for (k, v) in FVPrefsDefaults.values {
            CFPreferencesSetAppValue(k as CFString, v as CFPropertyList?, Self.domain)
        }
        CFPreferencesSetAppValue("__inited__" as CFString, true as CFPropertyList, Self.domain)
        CFPreferencesAppSynchronize(Self.domain)
        reload()
    }

    // MARK: - 重载 / 监听

    public func reload() {
        var merged = FVPrefsDefaults.values
        for key in Array(merged.keys) {
            if let v = CFPreferencesCopyAppValue(key as CFString, Self.domain) {
                merged[key] = v
            }
        }
        lock.lock(); cache = merged; lock.unlock()
    }

    private func observe() {
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            observer,
            { _, obs, _, _, _ in
                guard let obs else { return }
                Unmanaged<FVPrefsStore>.fromOpaque(obs).takeUnretainedValue().reload()
            },
            Self.changedNotification, nil, .deliverImmediately)
    }
}

// MARK: - 默认值表（来自二进制实证：Slider 默认值 0x3fe9999…=0.8 / 0x3ff0000000000000=1.0，
// arcAppDisplayItemSize_level_N = 22.0 等）

public enum FVPrefsDefaults {
    public static let values: [String: Any] = [
        // 环形菜单
        FVKey.arcAppLevelCount: 3,
        FVKey.arcToolLevelCount: 2,
        FVKey.arcAppDisplayCount(1): 0, FVKey.arcAppDisplayCount(2): 0,
        FVKey.arcAppDisplayCount(3): 0, FVKey.arcAppDisplayCount(4): 0,
        FVKey.arcToolDisplayCount(1): 0, FVKey.arcToolDisplayCount(2): 0,
        FVKey.arcToolDisplayCount(3): 0,
        FVKey.arcAppDisplayItemSize(1): 22.0, FVKey.arcAppDisplayItemSize(2): 22.0,
        FVKey.arcAppDisplayItemSize(3): 22.0, FVKey.arcAppDisplayItemSize(4): 22.0,
        FVKey.arcToolDisplayItemSize(1): 22.0, FVKey.arcToolDisplayItemSize(2): 22.0,
        FVKey.arcToolDisplayItemSize(3): 22.0,
        FVKey.arcAppRadius(1): 22.0, FVKey.arcAppRadius(2): 66.0,
        FVKey.arcAppRadius(3): 110.0, FVKey.arcAppRadius(4): 154.0,
        FVKey.arcToolRadius(1): 22.0, FVKey.arcToolRadius(2): 66.0,
        FVKey.arcToolRadius(3): 110.0,
        FVKey.arcAppShowCountInner: 22, FVKey.arcAppShowCountOuter: 22,
        FVKey.arcAppDisplayCenterDist: 0.0,
        FVKey.arcContainerSensitivity: 0.5,
        FVKey.arcMenuTriggerWay: 0,
        FVKey.arcVibrationFeedback: true,
        FVKey.arcMenuHideSelfOnShot: false,
        FVKey.arcButtonBgStatus: false,
        FVKey.arcButtonBgValue: "",
        FVKey.arcToolsIsOnColor: "",
        FVKey.arcToolsNotIsOnColor: "",

        // 外观
        FVKey.shadowOpacity: 0.8,
        FVKey.shadowRange: 1.0,
        FVKey.safeDistanceTop: 0.0,
        FVKey.sideSafeDistanceTop: 0.0,
        FVKey.origin1IsCenter: false,
        FVKey.origin34IsZoom: true,
        FVKey.offDumpingAnimation: false,
        FVKey.shotImgStatus: true,
        FVKey.islandAnimated: false,

        // 侧边栏
        FVKey.sideViewItemCount: 2,
        FVKey.sideViewDisplayLocation: 0,
        FVKey.sideBarWidth: 300.0,
        FVKey.sideBarHeightVer: 0.5,
        FVKey.sideBarHeightHor: 0.5,
        FVKey.sideBarAppIconSize: 44.0,
        FVKey.sideBarShadowOpacity: 0.5,
        FVKey.sideBarShadowRange: 1.0,
        FVKey.sideIconMoveFeedback: true,
        FVKey.sideContainerContent: 0,
        FVKey.sideContentHideOnShot: false,

        // 手势绑定（0 = 未绑定）
        FVKey.mainClickTop: 0,
        FVKey.mainClickBottom: 0,
        FVKey.mainCornerToSide: 0,
        FVKey.mainCornerToSideScene: 0,
        FVKey.mainMoveBottomFull: true,
        FVKey.mainMoveBottomFeedback: true,
        FVKey.mainMoveBottomTakeScene: false,
        FVKey.mainClosedNoAutoLayout: false,
        FVKey.sideClickEvent: 0,
        FVKey.sideSwipeUp: 0,
        FVKey.sideSwipeDown: 0,
        FVKey.sideSwipeLeft: 0,
        FVKey.sideSwipeRight: 0,
        FVKey.topCornerTouchWidth: 40.0,
        FVKey.bottomCornerTouchWidth: 40.0,

        // 键盘
        FVKey.kbShowWayPortrait: 0,
        FVKey.kbShowWayLandscape: 0,
        FVKey.kbCloseOnOutsideHide: false,
        FVKey.kbMoveOutsidePosition: false,
        FVKey.kbPartyFeedback: false,

        // 通知
        FVKey.notifOpenFloat: false,
        FVKey.notifOpenGestureWay: 0,

        // 桌面
        FVKey.sbIconGesture: false,
        FVKey.sbIconOpenFloat: true,
        FVKey.shortcutOpenFloat: true,
        FVKey.switcherEndedEvent: false,
        FVKey.switcherExcludedApps: [String](),
        FVKey.universeLinkOpenFloat: false,
        FVKey.universeExcludedApps: [String](),
        FVKey.autoCloseBindLink: false,

        // 其他
        FVKey.touchOutsideStatus: true,
        FVKey.touchOutsideValue: 0,
        FVKey.touchOutsideList: [Int](),
        FVKey.frontConsoleEnable: false,
        FVKey.frontConsoleTriggerWay: 0,
        FVKey.multiScreenRenderPos: 0,
        FVKey.onCloseConsoleCleanMini: false,
        FVKey.cameraPermission: true,
        FVKey.displayQrcodeWay: 0,
        FVKey.qrcodeWay: 0,
        FVKey.scanWay: 0,
        FVKey.floatBallShowBadge: true,
        FVKey.floatBallHideOnShot: false,
        FVKey.floatBallLongPressSide: true,
        FVKey.floatBallShadowOpacity: 0.5,
        FVKey.floatBallStickyOpacity: 0.6,
        FVKey.showBundleIdSubtitle: false,
        FVKey.searchKBAvoidShade: true,
        FVKey.searchLongPressMenu: true,
        FVKey.searchLongPressOpenWay: 0,
        FVKey.searchOpenWay12: 0,
        FVKey.searchOpenWay34: 0,

        // 数据
        FVKey.allApps: [String](),
        FVKey.allTools: [Int](),
        FVKey.pendingTools: [Int](),
        FVKey.selectedTools: [Int](),
        FVKey.dragLabelTableCells: [Int](),
    ]
}
