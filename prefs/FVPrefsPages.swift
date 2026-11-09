// FVPrefsPages.swift
// 26 个设置页的完整实现。每页结构与 DEEP_DIVE_SETTINGS.md 一一对应。
// 所有 get/set 走 FVPrefsStore（含 Darwin 热重载）。

import Preferences
import UIKit

// MARK: - 1) RootListController

public final class FVPrefsRootListController: PSListController {

    public override func specifiers() -> [Any]! {
        var list: [PSSpecifier] = []

        list.append(FVSpec.group(GroupCell(name: "三屏", footerText: "",
                                           key: "multipleScreenVC_group")))
        list.append(FVSpec.link(LinkCell(name: "三屏", className: FVMultipleScreenVC.self,
                                         isController: true, key: "multipleScreenVC",
                                         action: nil,
                                         icon: UIImage(systemName: "calendar.day.timeline.left"))))

        list.append(FVSpec.group(GroupCell(name: "浮窗", footerText: "",
                                           key: "floatingView_group")))
        list.append(FVSpec.link(LinkCell(name: "浮窗", className: FVFloatingViewVC.self,
                                         isController: true, key: "floatingView",
                                         action: nil,
                                         icon: UIImage(systemName: "platter.2.filled.iphone"))))

        list.append(FVSpec.group(GroupCell(name: "其他杂项功能", footerText: "",
                                           key: "otherFunctionalVC_group")))
        list.append(FVSpec.link(LinkCell(name: "其他杂项功能", className: FVOtherFunctionalVC.self,
                                         isController: true, key: "otherFunctionalVC",
                                         action: nil,
                                         icon: UIImage(systemName: "square.grid.2x2"))))

        list.append(FVSpec.group(GroupCell(name: "", footerText: "",
                                           key: "operability_button_group")))
        list.append(FVSpec.button(ButtonCell(name: "导出配置(非备份配置)",
                                             action: #selector(exportPlist), key: "copyPlistValues_btn",
                                             icon: UIImage(systemName: "square.and.arrow.up.on.square"))))
        list.append(FVSpec.button(ButtonCell(name: "从文件中导入配置",
                                             action: #selector(importPlist), key: "exportPlistValues_btn",
                                             icon: UIImage(systemName: "square.and.arrow.down.on.square"))))
        list.append(FVSpec.button(ButtonCell(name: "从备份文件恢复配置",
                                             action: #selector(restoreBackup), key: "importPlistValues_btn",
                                             icon: UIImage(systemName: "rectangle.dashed.and.paperclip"))))
        list.append(FVSpec.button(ButtonCell(name: "重置为默认配置",
                                             action: #selector(resetPlist), key: "resetPlistValues_btn",
                                             icon: UIImage(systemName: "rectangle.dashed.and.paperclip"))))
        return list
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "floating-view"
    }

    @objc private func exportPlist() {
        let url = URL(fileURLWithPath: FVPrefsStore.plistPath)
        let p = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        p.delegate = self
        present(p, animated: true)
    }

    @objc private func importPlist() {
        let p = UIDocumentPickerViewController(forOpeningContentTypes: [.propertyList])
        p.delegate = self
        p.allowsMultipleSelection = false
        present(p, animated: true)
    }

    @objc private func restoreBackup() {
        let backup = FVPrefsStore.plistPath + ".bak"
        guard FileManager.default.fileExists(atPath: backup) else {
            alert("未找到备份文件, 请先备份或者从外部导入!")
            return
        }
        try? FileManager.default.removeItem(atPath: FVPrefsStore.plistPath)
        try? FileManager.default.copyItem(atPath: backup, toPath: FVPrefsStore.plistPath)
        FVPrefsStore.shared.reload()
    }

    @objc private func resetPlist() {
        alert("此操作不可逆，重置前请记得备份，是否继续?", confirm: true) {
            try? FileManager.default.copyItem(atPath: FVPrefsStore.plistPath,
                                              toPath: FVPrefsStore.plistPath + ".bak")
            for k in FVPrefsDefaults.values.keys {
                CFPreferencesSetAppValue(k as CFString, nil, FVPrefsStore.domain)
            }
            CFPreferencesSetAppValue("__inited__" as CFString, nil, FVPrefsStore.domain)
            FVPrefsStore.shared.setDefaultsIfNeeded()
            FVPrefsStore.shared.reload()
        }
    }

    private func alert(_ msg: String, confirm: Bool = false, _ onOK: (() -> Void)? = nil) {
        let a = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "取消", style: .cancel))
        if confirm {
            a.addAction(UIAlertAction(title: "继续", style: .destructive) { _ in onOK?() })
        } else {
            a.addAction(UIAlertAction(title: "好", style: .default))
        }
        present(a, animated: true)
    }
}

extension FVPrefsRootListController: UIDocumentPickerDelegate {
    public func documentPicker(_ c: UIDocumentPickerViewController,
                               didPickDocumentsAt urls: [URL]) {
        guard let src = urls.first else { return }
        guard src.pathExtension.lowercased() == "plist" else {
            alert("文件格式错误, 只支持plist文件!")
            return
        }
        _ = src.startAccessingSecurityScopedResource()
        defer { src.stopAccessingSecurityScopedResource() }
        try? FileManager.default.removeItem(atPath: FVPrefsStore.plistPath)
        try? FileManager.default.copyItem(atPath: src.path, toPath: FVPrefsStore.plistPath)
        FVPrefsStore.shared.reload()
    }
}

// MARK: - 共用：动作列表（给 TabCell 用）

enum FVActionList {
    static var titles: [String] { FVToolAction.allCases.map { $0.title } }
    static var values: [String] { FVToolAction.allCases.map { "\($0.rawValue)" } }
}

// MARK: - 2) MultipleScreenVC

public final class FVMultipleScreenVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "console_arc_app_group", footerText: "",
                                   key: "console_arc_app_group")),
            FVSpec.link(LinkCell(name: "三屏工具栏排序",
                                 className: FVSortToolsVC.self, isController: true,
                                 key: "SortTools_sideBarContainerVC",
                                 action: #selector(gotoSortTools(_:)),
                                 icon: UIImage(systemName: "slider.horizontal.3"))),

            FVSpec.group(GroupCell(name: "console_toolOrAppSort_group", footerText: "",
                                   key: "console_toolOrAppSort_group")),
            FVSpec.link(LinkCell(name: "三屏以及arc菜单app",
                                 className: FVSortAppVC.self, isController: true,
                                 key: "SortApp_sideBarContainerVC",
                                 action: #selector(gotoSortApp(_:)),
                                 icon: UIImage(systemName: "list.bullet.indent"))),

            FVSpec.toggle(ToggleCell(name: "关闭三屏同时关闭侧边小窗应用？",
                                     key: FVKey.onCloseConsoleCleanMini,
                                     defaultValue: false, icon: nil)),

            FVSpec.group(GroupCell(name: "multiple_screen_renderPosition_group",
                                   footerText: "三屏小窗的排列方式。",
                                   key: "multiple_screen_renderPosition_group")),
            FVSpec.tab(TabCell(name: "三屏小窗显示位置",
                               values: ["0", "1", "2"],
                               titles: ["自动布局", "上下排列", "左右排列"],
                               key: FVKey.multiScreenRenderPos, defaultValue: "0")),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "三屏" }
    @objc private func gotoSortTools(_ s: Any?) {
        navigationController?.pushViewController(FVSortToolsVC(), animated: true)
    }
    @objc private func gotoSortApp(_ s: Any?) {
        navigationController?.pushViewController(FVSortAppVC(), animated: true)
    }
}

// MARK: - 3) FloatingViewVC

public final class FVFloatingViewVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "floatingView_shadow_settings_group",
                                   footerText: "", key: "floatingView_shadow_settings_group")),
            FVSpec.link(LinkCell(name: "浮窗阴影设置",
                                 className: FVFloatingViewShadowPrefsVC.self, isController: true,
                                 key: "floatingViewShadowPrefsVC", action: nil,
                                 icon: UIImage(systemName: "circle.lefthalf.filled"))),

            FVSpec.group(GroupCell(name: "floatingView_notification_settings_group",
                                   footerText: "", key: "floatingView_notification_settings_group")),
            FVSpec.link(LinkCell(name: "通知横幅设置",
                                 className: FVFloatingViewNotificationVC.self, isController: true,
                                 key: "notificationViewPrsentFloatV", action: nil,
                                 icon: UIImage(systemName: "bell.badge"))),

            FVSpec.group(GroupCell(name: "interfaceOrigin_1_isCenter_group",
                                   footerText: "开启此开关，屏幕转向发生改变或拖拽全屏打开应用后，都不记录位置，固定为屏幕中心。",
                                   key: "interfaceOrigin_1_isCenter_group")),
            FVSpec.toggle(ToggleCell(name: "竖屏浮窗打开固定屏中心?",
                                     key: FVKey.origin1IsCenter, defaultValue: false,
                                     icon: UIImage(systemName: "rectangle.center.inset.filled"))),

            FVSpec.group(GroupCell(name: "clickFlotBg_1_staticTextCell_group",
                                   footerText: "浮窗圆角大小，自行调节，美观与否取决自己眼光。",
                                   key: "clickFlotBg_1_staticTextCell_group")),
            FVSpec.staticText(StaticTextCell(name: "", key: "clickFlotBg_1_staticTextCell")),
            FVSpec.slider(SliderCell(name: "浮窗圆角大小", key: "clickFlotBg_1",
                                     defaultValue: 22, min: 0, max: 60,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: true,
                                     leftImage: nil, rightImage: nil)),

            FVSpec.group(GroupCell(name: "floatingView_safe_distance_top_1_staticTextCell_group",
                                   footerText: "", key: "floatingView_safe_distance_top_1_staticTextCell_group")),
            FVSpec.staticText(StaticTextCell(name: "与刘海方向安全距离",
                                             key: "floatingView_safe_distance_top_1_staticTextCell")),
            FVSpec.slider(SliderCell(name: "", key: FVKey.safeDistanceTop,
                                     defaultValue: 0, min: 0, max: 60,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: true,
                                     leftImage: nil, rightImage: nil)),

            FVSpec.group(GroupCell(name: "floatingViewKeyboardPrefsVC_linkcell_group",
                                   footerText: "", key: "floatingViewKeyboardPrefsVC_linkcell_group")),
            FVSpec.link(LinkCell(name: "浮窗键盘设置",
                                 className: FVFloatingViewKeyboardPrefsVC.self, isController: true,
                                 key: "floatingViewKeyboardPrefsVC", action: nil,
                                 icon: UIImage(systemName: "keyboard"))),

            FVSpec.group(GroupCell(name: "FloatingViewSideViewVC_linkcell_group",
                                   footerText: "", key: "FloatingViewSideViewVC_linkcell_group")),
            FVSpec.link(LinkCell(name: "侧边小窗设置",
                                 className: FVFloatingViewSideViewVC.self, isController: true,
                                 key: "FloatingViewSideViewVC", action: nil,
                                 icon: UIImage(systemName: "sidebar.squares.right"))),

            FVSpec.group(GroupCell(name: "touch_floatingview_touchFVOutsideEventStatus_group",
                                   footerText: "", key: "touch_floatingview_touchFVOutsideEventStatus_group")),
            FVSpec.toggle(ToggleCell(name: "点击浮窗外部事件?",
                                     key: FVKey.touchOutsideStatus,
                                     defaultValue: true, icon: nil)),
            FVSpec.tab(TabCell(name: "点击浮窗外部的动作",
                               values: ["0", "1", "2"],
                               titles: ["无操作", "关闭浮窗", "回到桌面"],
                               key: FVKey.touchOutsideValue, defaultValue: "0")),

            FVSpec.group(GroupCell(name: "floatingview_shotImg_status_group",
                                   footerText: "", key: "floatingview_shotImg_status_group")),
            FVSpec.toggle(ToggleCell(name: "任务栏浮窗应用快照?",
                                     key: FVKey.shotImgStatus, defaultValue: true,
                                     icon: UIImage(systemName: "platter.2.filled.iphone"))),

            FVSpec.group(GroupCell(name: "offFloatingViewDumpingAnimatedStatus_group",
                                   footerText: "关闭后，浮窗的弹性动画将会关闭。",
                                   key: "offFloatingViewDumpingAnimatedStatus_group")),
            FVSpec.toggle(ToggleCell(name: "关闭浮窗弹性动画?",
                                     key: FVKey.offDumpingAnimation,
                                     defaultValue: false, icon: nil)),

            FVSpec.group(GroupCell(name: "universeLinkOpenAppForFV_group",
                                   footerText: "", key: "universeLinkOpenAppForFV_group")),
            FVSpec.toggle(ToggleCell(name: "通用链接采用浮窗打开?",
                                     key: FVKey.universeLinkOpenFloat,
                                     defaultValue: false,
                                     icon: UIImage(systemName: "circle"))),
            FVSpec.toggle(ToggleCell(name: "绑定链接自动关闭浮窗",
                                     key: FVKey.autoCloseBindLink,
                                     defaultValue: false, icon: nil)),
            FVSpec.link(LinkCell(name: "排除应用", className: nil, isController: false,
                                 key: FVKey.universeExcludedApps, action: nil, icon: nil)),

            FVSpec.group(GroupCell(name: "switherGestureEndedEvent_group",
                                   footerText: "如果你想某些应用在结束底部横条手势时，将前台全屏打开的对应应用通过浮窗或挂在侧边，可以打开此功能。",
                                   key: "switherGestureEndedEvent_group")),
            FVSpec.toggle(ToggleCell(name: "底部横条手势结束后, 前台应用是否浮窗打开?",
                                     key: FVKey.switcherEndedEvent, defaultValue: false,
                                     icon: UIImage(systemName: "rectangle.and.hand.point.up.left"))),
            FVSpec.link(LinkCell(name: "排除应用", className: nil, isController: false,
                                 key: FVKey.switcherExcludedApps, action: nil, icon: nil)),

            FVSpec.group(GroupCell(name: "islandPositionAnimatedStatus_group",
                                   footerText: "", key: "islandPositionAnimatedStatus_group")),
            FVSpec.toggle(ToggleCell(name: "灵动岛位移动画",
                                     key: FVKey.islandAnimated,
                                     defaultValue: false, icon: nil)),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "浮窗" }
}

// MARK: - 4) FloatingViewShadowPrefsVC

public final class FVFloatingViewShadowPrefsVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "浮窗阴影设置",
                                   footerText: "数字越小，阴影就越淡。",
                                   key: "floatingViewHostingviewShadow_Opacity_group")),
            FVSpec.slider(SliderCell(name: "浮窗阴影透明度", key: FVKey.shadowOpacity,
                                     defaultValue: 0.8, min: 0, max: 1,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: false,
                                     leftImage: UIImage(systemName: "sun.min"),
                                     rightImage: UIImage(systemName: "sun.max"))),

            FVSpec.group(GroupCell(name: "",
                                   footerText: "数字越小，范围就越小。",
                                   key: "floatingViewHostingviewShadowRange_group")),
            FVSpec.slider(SliderCell(name: "浮窗阴影范围大小", key: FVKey.shadowRange,
                                     defaultValue: 1.0, min: 0, max: 12,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: false,
                                     leftImage: UIImage(systemName: "circle.dotted"),
                                     rightImage: UIImage(systemName: "circle.dashed"))),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "浮窗阴影设置" }
}

// MARK: - 5) FloatingViewNotificationVC

public final class FVFloatingViewNotificationVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "通知横幅设置",
                                   footerText: "如果有新通知横幅，可以自定义下拉或者点击打开浮窗。",
                                   key: "floatingView_notification_settings_group")),
            FVSpec.toggle(ToggleCell(name: "通知横幅打开浮窗?",
                                     key: FVKey.notifOpenFloat, defaultValue: false,
                                     icon: UIImage(systemName: "bell.badge"))),
            FVSpec.tab(TabCell(name: "横幅打开浮窗方式",
                               values: ["0", "1"],
                               titles: ["下拉横幅", "点击横幅"],
                               key: FVKey.notifOpenGestureWay, defaultValue: "0")),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "通知横幅设置" }
}

// MARK: - 6) FloatingViewKeyboardPrefsVC

public final class FVFloatingViewKeyboardPrefsVC: PSListController {
    private let ways = ["0", "1", "2", "3"]
    private let wayTitles = ["自动", "缩放浮窗", "移动浮窗", "不处理"]

    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "wayKeyboardShowIntoFloatingView_1_2_group",
                                   footerText: "", key: "wayKeyboardShowIntoFloatingView_1_2_group")),
            FVSpec.tab(TabCell(name: "浮窗键盘弹出方式（竖屏）",
                               values: ways, titles: wayTitles,
                               key: FVKey.kbShowWayPortrait, defaultValue: "0")),

            FVSpec.group(GroupCell(name: "wayKeyboardShowIntoFloatingView_3_4_group",
                                   footerText: "", key: "wayKeyboardShowIntoFloatingView_3_4_group")),
            FVSpec.tab(TabCell(name: "浮窗键盘弹出方式（横屏）",
                               values: ways, titles: wayTitles,
                               key: FVKey.kbShowWayLandscape, defaultValue: "0")),

            FVSpec.group(GroupCell(name: "isCloseFlotingView_onOutsideKeyboardWillHide_group",
                                   footerText: "注意：是点击空白处收起键盘时，是否同时关闭浮窗。",
                                   key: "isCloseFlotingView_onOutsideKeyboardWillHide_group")),
            FVSpec.toggle(ToggleCell(name: "外置键盘收起时, 同时关闭浮窗?",
                                     key: FVKey.kbCloseOnOutsideHide, defaultValue: false,
                                     icon: UIImage(systemName: "arrow.down.right.and.arrow.up.left"))),

            FVSpec.group(GroupCell(name: "isMoveOutsideKeyboardPosition_group",
                                   footerText: "注意：仅横屏且是外置键盘生效。",
                                   key: "isMoveOutsideKeyboardPosition_group")),
            FVSpec.toggle(ToggleCell(name: "横屏时, 移动外置键盘?",
                                     key: FVKey.kbMoveOutsidePosition, defaultValue: false,
                                     icon: UIImage(systemName: "arrow.left.and.right"))),

            FVSpec.group(GroupCell(name: "partyKeyboardFeedbackStatus_group",
                                   footerText: "该功能未判断是否自带键盘还是三方键盘，如果你喜欢用三方键盘，则打开此开关，否则可能存在叠加震动。同时，触控非键盘区域也可能存在震动，需要自行忍受(后续是否优化还未确定)。",
                                   key: "partyKeyboardFeedbackStatus_group")),
            FVSpec.toggle(ToggleCell(name: "非系统键盘震动?",
                                     key: FVKey.kbPartyFeedback, defaultValue: false,
                                     icon: UIImage(systemName: "iphone.radiowaves.left.and.right"))),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "浮窗键盘设置" }
}

// MARK: - 7) FloatingViewSideViewVC

public final class FVFloatingViewSideViewVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "调度窗口设置", footerText: "",
                                   key: "dispatchHostingView_sideView_group")),

            FVSpec.group(GroupCell(name: "dispatchHostingView_sideViewItemCount_group",
                                   footerText: "理论手机不发烫的情况下，可以多打开几个小窗。如果手机发烫，可能存在掉帧情况，可根据自己习惯设置小窗数量。",
                                   key: "dispatchHostingView_sideViewItemCount_group")),
            FVSpec.slider(SliderCell(name: "侧边小窗数量", key: FVKey.sideViewItemCount,
                                     defaultValue: 2, min: 1, max: 4,
                                     showValue: true, isSegmented: true,
                                     segmentCount: 4, isContinuous: false,
                                     leftImage: nil, rightImage: nil)),

            FVSpec.group(GroupCell(name: "dispatchHostingView_sideViewDisplayLocation_group",
                                   footerText: "注意：左侧即屏幕左侧，右侧则是屏幕右侧。横屏同理，不支持整体拖动。",
                                   key: "dispatchHostingView_sideViewDisplayLocation_group")),
            FVSpec.tab(TabCell(name: "侧边小窗显示位置",
                               values: ["0", "1"],
                               titles: ["屏幕左侧", "屏幕右侧"],
                               key: FVKey.sideViewDisplayLocation, defaultValue: "0")),

            FVSpec.group(GroupCell(name: "FloatingViewMainDispatchViewGestureVC_group",
                                   footerText: "自定义主屏浮窗手势，让全屏打开应用、关闭应用更符合自己操作的习惯。",
                                   key: "FloatingViewMainDispatchViewGestureVC_group")),
            FVSpec.link(LinkCell(name: "主屏浮窗手势设置",
                                 className: FVFloatingViewMainDispatchViewGestureVC.self,
                                 isController: true, key: "FloatingViewMainDispatchViewGestureVC",
                                 action: nil, icon: UIImage(systemName: "hand.point.up.left"))),

            FVSpec.group(GroupCell(name: "FloatingViewSideDispatchViewGestureVC_group",
                                   footerText: "自定义侧边小窗手势，让全屏打开应用、关闭应用、与主屏交换应用更符合自己操作的习惯。",
                                   key: "FloatingViewSideDispatchViewGestureVC_group")),
            FVSpec.link(LinkCell(name: "侧边小窗手势设置",
                                 className: FVFloatingViewSideDispatchViewGestureVC.self,
                                 isController: true, key: "FloatingViewSideDispatchViewGestureVC",
                                 action: nil, icon: UIImage(systemName: "hand.draw"))),

            FVSpec.group(GroupCell(name: "FloatingViewDispatchItemsAutoLayoutVC_group",
                                   footerText: "如果你不满意调度窗口自动布局逻辑，可以自行关闭它。",
                                   key: "FloatingViewDispatchItemsAutoLayoutVC_group")),
            FVSpec.link(LinkCell(name: "调度窗口自动布局设置",
                                 className: FVFloatingViewDispatchItemsAutoLayoutVC.self,
                                 isController: true, key: "FloatingViewDispatchItemsAutoLayoutVC",
                                 action: nil, icon: UIImage(systemName: "square.grid.3x3"))),

            FVSpec.group(GroupCell(name: "floatingView_sideView_safe_distance_top_staticTextCell_group",
                                   footerText: "",
                                   key: "floatingView_sideView_safe_distance_top_staticTextCell_group")),
            FVSpec.slider(SliderCell(name: "小窗与刘海方向安全距离",
                                     key: FVKey.sideSafeDistanceTop,
                                     defaultValue: 0, min: 0, max: 60,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: true,
                                     leftImage: nil, rightImage: nil)),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "调度窗口设置" }
}

// MARK: - 8) SideContainerBarPrefs

public final class FVSideContainerBarPrefs: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "sideContainerDisplayContent_group",
                                   footerText: "", key: "sideContainerDisplayContent_group")),
            FVSpec.link(LinkCell(name: "侧边栏自定义应用排序",
                                 className: FVSortAppVC.self, isController: true,
                                 key: "SortApp_sideBarContainerVC", action: nil,
                                 icon: UIImage(systemName: "list.bullet.indent"))),

            FVSpec.group(GroupCell(name: "sideContainerDisplayContent_group2",
                                   footerText: "", key: "sideContainerDisplayContent_group2")),
            FVSpec.tab(TabCell(name: "侧边栏显示内容",
                               values: ["0", "1"],
                               titles: ["活跃应用", "自定义应用"],
                               key: FVKey.sideContainerContent, defaultValue: "0")),
            FVSpec.toggle(ToggleCell(name: "截屏时隐藏侧边栏",
                                     key: FVKey.sideContentHideOnShot,
                                     defaultValue: false, icon: nil)),

            FVSpec.group(GroupCell(name: "handOnMoveSideBarApplicationIcon_feedback_group",
                                   footerText: "", key: "handOnMoveSideBarApplicationIcon_feedback_group")),
            FVSpec.toggle(ToggleCell(name: "拖动侧边图标触感反馈",
                                     key: FVKey.sideIconMoveFeedback,
                                     defaultValue: true, icon: nil)),

            FVSpec.group(GroupCell(name: "sideBar_shadow_settings_group",
                                   footerText: "", key: "sideBar_shadow_settings_group")),
            FVSpec.link(LinkCell(name: "侧边栏阴影设置",
                                 className: FVSideContainerBarShadowVC.self, isController: true,
                                 key: "SideContainerBarShadowVC", action: nil,
                                 icon: UIImage(systemName: "circle.lefthalf.filled"))),

            FVSpec.group(GroupCell(name: "sideBarContainerHeight_ver_value_group",
                                   footerText: "", key: "sideBarContainerHeight_ver_value_group")),
            FVSpec.slider(SliderCell(name: "侧边栏高度（竖屏）", key: FVKey.sideBarHeightVer,
                                     defaultValue: 0.5, min: 0.2, max: 1.0,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: true,
                                     leftImage: nil, rightImage: nil)),

            FVSpec.group(GroupCell(name: "sideBarContainerHeight_hor_value_group",
                                   footerText: "", key: "sideBarContainerHeight_hor_value_group")),
            FVSpec.slider(SliderCell(name: "侧边栏高度（横屏）", key: FVKey.sideBarHeightHor,
                                     defaultValue: 0.5, min: 0.2, max: 1.0,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: true,
                                     leftImage: nil, rightImage: nil)),

            FVSpec.group(GroupCell(name: "sideBarContainerWidth_value_group",
                                   footerText: "", key: "sideBarContainerWidth_value_group")),
            FVSpec.slider(SliderCell(name: "侧边栏宽度", key: FVKey.sideBarWidth,
                                     defaultValue: 12, min: 4, max: 40,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: true,
                                     leftImage: nil, rightImage: nil)),

            FVSpec.group(GroupCell(name: "sideBarContainer_appIconSize_value_group",
                                   footerText: "", key: "sideBarContainer_appIconSize_value_group")),
            FVSpec.slider(SliderCell(name: "应用图标大小", key: FVKey.sideBarAppIconSize,
                                     defaultValue: 44, min: 24, max: 72,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: true,
                                     leftImage: nil, rightImage: nil)),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "侧边栏设置" }
}

// MARK: - 9) SideContainerBarShadowVC

public final class FVSideContainerBarShadowVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "侧边栏阴影设置",
                                   footerText: "数字越小，阴影就越淡。",
                                   key: "sideBarContainerShadow_Opacity_group")),
            FVSpec.slider(SliderCell(name: "侧边栏阴影透明度",
                                     key: FVKey.sideBarShadowOpacity,
                                     defaultValue: 0.5, min: 0, max: 1,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: false,
                                     leftImage: nil, rightImage: nil)),

            FVSpec.group(GroupCell(name: "sideBarContainerShadowRange_group",
                                   footerText: "数字越小，范围就越小。",
                                   key: "sideBarContainerShadowRange_group")),
            FVSpec.slider(SliderCell(name: "侧边栏阴影范围大小",
                                     key: FVKey.sideBarShadowRange,
                                     defaultValue: 1.0, min: 0, max: 12,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: false,
                                     leftImage: nil, rightImage: nil)),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "侧边栏阴影设置" }
}
