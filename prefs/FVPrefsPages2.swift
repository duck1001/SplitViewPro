// FVPrefsPages2.swift
// 设置页 10~26（后半部分）。结构与 DEEP_DIVE_SETTINGS.md 对应。

import Preferences
import UIKit

// MARK: - 10) FloatingViewMainDispatchViewGestureVC

public final class FVFloatingViewMainDispatchViewGestureVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "主屏浮窗手势设置",
                                   footerText: "主屏浮窗取消了灰色背景、以及图钉，因此操作也有很大的变更。\n\n缩放：四个角落拉伸，即可对主屏浮窗进行缩放。\n\n移动：顶部和底部均可拖动，顶部触控高度是状态栏高度，底部触控高度是系统黑条高度。\n\n其他：在横屏状态下，因为浮窗较小，建议使用顶部区域进行移动、缩放。",
                                   key: "dispatchHostingView_sideItem_gesture_tips")),

            FVSpec.group(GroupCell(name: "dispatchHostingView_mainItem_clickBottomEvent_group",
                                   footerText: "底部区域高度为系统屏幕底部黑条的高度大小。",
                                   key: "dispatchHostingView_mainItem_clickBottomEvent_group")),
            FVSpec.tab(TabCell(name: "点击浮窗底部区域",
                               values: FVActionList.values, titles: FVActionList.titles,
                               key: FVKey.mainClickBottom, defaultValue: "0")),

            FVSpec.group(GroupCell(name: "dispatchHostingView_mainItem_clickTopEvent_group",
                                   footerText: "顶部区域高度为系统屏幕状态栏高度。",
                                   key: "dispatchHostingView_mainItem_clickTopEvent_group")),
            FVSpec.tab(TabCell(name: "点击浮窗顶部区域",
                               values: FVActionList.values, titles: FVActionList.titles,
                               key: FVKey.mainClickTop, defaultValue: "0")),

            FVSpec.group(GroupCell(name: "dispatchHostingView_mainItem_moveBottomFullScreenOpen_group",
                                   footerText: "拖拽区域始终位于屏幕底部中心部位，拖拽到这的时候，浮窗会降低一点透明度，松手便会全屏打开。",
                                   key: "dispatchHostingView_mainItem_moveBottomFullScreenOpen_group")),
            FVSpec.toggle(ToggleCell(name: "拖拽到屏幕底部全屏打开?",
                                     key: FVKey.mainMoveBottomFull, defaultValue: true,
                                     icon: UIImage(systemName: "rectangle.and.hand.point.up.left"))),

            FVSpec.group(GroupCell(name: "FloatingViewMainDispatchViewCornerSizeVC_group",
                                   footerText: "如果你觉得顶部或者底部触控区域偏小，可自行调节区域大小。",
                                   key: "FloatingViewMainDispatchViewCornerSizeVC_group")),
            FVSpec.link(LinkCell(name: "角落区域大小设置",
                                 className: FVFloatingViewMainDispatchViewCornerSizeVC.self,
                                 isController: true, key: "FloatingViewMainDispatchViewCornerSizeVC",
                                 action: nil, icon: UIImage(systemName: "square.dashed"))),

            FVSpec.group(GroupCell(name: "dispatchHostingView_mainItem_clickCorner_toSideLocation_group",
                                   footerText: "",
                                   key: "dispatchHostingView_mainItem_clickCorner_toSideLocation_group")),
            FVSpec.tab(TabCell(name: "角落拖拽到侧边目标",
                               values: ["0", "1", "2"],
                               titles: ["不处理", "左侧", "右侧"],
                               key: FVKey.mainCornerToSide, defaultValue: "0")),
            FVSpec.tab(TabCell(name: "角落拖拽到侧边的场景",
                               values: ["0", "1"],
                               titles: ["当前场景", "指定场景"],
                               key: FVKey.mainCornerToSideScene, defaultValue: "0")),
        ]
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "主屏浮窗手势设置(调度)"
    }
}

// MARK: - 11) FloatingViewMainDispatchViewCornerSizeVC

public final class FVFloatingViewMainDispatchViewCornerSizeVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "角落区域大小设置",
                                   footerText: "为了节约性能，区域大小调节后，需要重新打开浮窗才生效(无需注销)。\n\n调节的大小是左右两个角同时增减，请注意不要调节过大，否则会影响到拖动区域。",
                                   key: "dispatchHostingView_sideView_cornerSize_group")),

            FVSpec.group(GroupCell(name: "dispatchHostingView_sideView_mainItem_TopCornerTouchWidth_group",
                                   footerText: "",
                                   key: "dispatchHostingView_sideView_mainItem_TopCornerTouchWidth_group")),
            FVSpec.slider(SliderCell(name: "顶部角落区域宽度", key: FVKey.topCornerTouchWidth,
                                     defaultValue: 40, min: 10, max: 120,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: true,
                                     leftImage: nil, rightImage: nil)),

            FVSpec.group(GroupCell(name: "dispatchHostingView_sideView_mainItem_BottomCornerTouchWidth_group",
                                   footerText: "",
                                   key: "dispatchHostingView_sideView_mainItem_BottomCornerTouchWidth_group")),
            FVSpec.slider(SliderCell(name: "底部角落区域宽度", key: FVKey.bottomCornerTouchWidth,
                                     defaultValue: 40, min: 10, max: 120,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: true,
                                     leftImage: nil, rightImage: nil)),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "角落区域大小设置" }
}

// MARK: - 12) FloatingViewSideDispatchViewGestureVC

public final class FVFloatingViewSideDispatchViewGestureVC: PSListController {
    public override func specifiers() -> [Any]! {
        var list: [PSSpecifier] = [
            FVSpec.group(GroupCell(name: "侧边小窗手势设置",
                                   footerText: "注意：滑动手势的方向，和左右布局无关！\n\n如果选择侧边改变位置，则是临时的改变，注销后恢复默认设置的位置。",
                                   key: "dispatchHostingView_sideItem_gesture_tips")),
        ]
        let items: [(String, String, String)] = [
            ("点击侧边小窗", "dispatchHostingView_sideItem_clickEvent", FVKey.sideClickEvent),
            ("向下滑动小窗", "dispatchHostingView_sideItem_swipeDownEvent", FVKey.sideSwipeDown),
            ("向上滑动小窗", "dispatchHostingView_sideItem_swipeUpEvent", FVKey.sideSwipeUp),
            ("向左滑动小窗", "dispatchHostingView_sideItem_swipeLeftEvent", FVKey.sideSwipeLeft),
            ("向右滑动小窗", "dispatchHostingView_sideItem_swipeRightEvent", FVKey.sideSwipeRight),
        ]
        for (title, groupKey, prefKey) in items {
            list.append(FVSpec.group(GroupCell(name: "\(groupKey)_group",
                                               footerText: "", key: "\(groupKey)_group")))
            list.append(FVSpec.tab(TabCell(name: title,
                                           values: FVActionList.values,
                                           titles: FVActionList.titles,
                                           key: prefKey, defaultValue: "0")))
        }
        return list
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "侧边小窗手势设置(调度)"
    }
}

// MARK: - 13) FloatingViewDispatchItemsAutoLayoutVC

public final class FVFloatingViewDispatchItemsAutoLayoutVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "调度窗口自动布局设置",
                                   footerText: "如果未打开此开关，则在关闭调度主屏时，会将侧边最后一个小窗移动到主屏区域。\n\n如果打开此开关，则不会自动进行布局，仅当新打开或者将侧边小窗切换到主屏才会自动布局。",
                                   key: "dispatchHostingView_mainItem_closed_donotAutoLayout_group")),
            FVSpec.toggle(ToggleCell(name: "调度主屏浮窗, 不自动布局?",
                                     key: FVKey.mainClosedNoAutoLayout, defaultValue: false,
                                     icon: UIImage(systemName: "square.grid.3x3"))),
            FVSpec.group(GroupCell(name: "", footerText: "如果你不满意调度窗口自动布局逻辑，可以自行关闭它。",
                                   key: "autoLayout_footer_group")),
        ]
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "调度窗口自动布局设置"
    }
}

// MARK: - 14) OtherFunctionalVC

public final class FVOtherFunctionalVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "cameraPermission_group",
                                   footerText: "", key: "cameraPermission_group")),
            FVSpec.toggle(ToggleCell(name: "开启相机权限?",
                                     key: FVKey.cameraPermission, defaultValue: true,
                                     icon: UIImage(systemName: "camera"))),

            FVSpec.group(GroupCell(name: "searchAppVC_group",
                                   footerText: "", key: "searchAppVC_group")),
            FVSpec.link(LinkCell(name: "搜索界面设置",
                                 className: FVSearchAppPrefsVC.self, isController: true,
                                 key: "SearchAppPrefsVC", action: nil,
                                 icon: UIImage(systemName: "magnifyingglass"))),

            FVSpec.group(GroupCell(name: "floatingActionImg_group",
                                   footerText: "", key: "floatingActionImg_group")),
            FVSpec.link(LinkCell(name: "悬浮图标设置",
                                 className: FVSVFlotingActionViewPrefs.self, isController: true,
                                 key: "SVFlotingActionViewPrefs", action: nil,
                                 icon: UIImage(systemName: "circle.circle"))),

            FVSpec.group(GroupCell(name: "SBIconPrefsVC_group",
                                   footerText: "", key: "SBIconPrefsVC_group")),
            FVSpec.toggle(ToggleCell(name: "桌面图标浮窗手势",
                                     key: FVKey.sbIconGesture, defaultValue: false, icon: nil)),
            FVSpec.toggle(ToggleCell(name: "主屏图标长按菜单注入「通过浮窗打开应用」",
                                     key: FVKey.sbIconOpenFloat, defaultValue: true,
                                     icon: UIImage(systemName: "rectangle.on.rectangle"))),
            FVSpec.toggle(ToggleCell(name: "快捷按钮打开浮窗?",
                                     key: FVKey.shortcutOpenFloat, defaultValue: true, icon: nil)),

            FVSpec.group(GroupCell(name: "shotHide_group",
                                   footerText: "", key: "shotHide_group")),
            FVSpec.toggle(ToggleCell(name: "录屏时隐藏浮窗",
                                     key: "floatingview_shotImg_recordHide", defaultValue: false,
                                     icon: UIImage(systemName: "rectangle.dashed.badge.record"))),

            FVSpec.group(GroupCell(name: "qrcode_group",
                                   footerText: "", key: "qrcode_group")),
            FVSpec.link(LinkCell(name: "二维码设置",
                                 className: FVArcQrcodeVC.self, isController: true,
                                 key: "FVArcQrcodeVC", action: nil,
                                 icon: UIImage(systemName: "qrcode"))),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "其他杂项功能" }
}

// MARK: - 15) SVFlotingActionViewPrefs

public final class FVSVFlotingActionViewPrefs: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "resetIcon_group",
                                   footerText: "", key: "resetIcon_group")),
            FVSpec.button(ButtonCell(name: "重置图标位置",
                                     action: #selector(resetIconPosition),
                                     key: "resetSBIconLocation",
                                     icon: UIImage(systemName: "arrow.counterclockwise"))),

            FVSpec.group(GroupCell(name: "隐藏浮窗图标条件",
                                   footerText: "", key: "showFloatIconCases_group")),
            FVSpec.tab(TabCell(name: "隐藏浮窗图标条件",
                               values: ["0", "1", "2", "3"],
                               titles: ["从不隐藏", "全屏应用时", "锁屏时", "两者都"],
                               key: "showFloatIconCases", defaultValue: "0")),

            FVSpec.group(GroupCell(name: "floatingActionImgContainerShadow_Opacity_group",
                                   footerText: "数字越小，越透明。",
                                   key: "floatingActionImgContainerShadow_Opacity_group")),
            FVSpec.slider(SliderCell(name: "悬浮图标阴影透明度",
                                     key: FVKey.floatBallShadowOpacity,
                                     defaultValue: 0.5, min: 0, max: 1,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: false,
                                     leftImage: nil, rightImage: nil)),

            FVSpec.group(GroupCell(name: "floatingActionImgContainerWasSticky_Opacity_group",
                                   footerText: "",
                                   key: "floatingActionImgContainerWasSticky_Opacity_group")),
            FVSpec.slider(SliderCell(name: "悬浮图标悬停时透明度",
                                     key: FVKey.floatBallStickyOpacity,
                                     defaultValue: 0.6, min: 0, max: 1,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: false,
                                     leftImage: nil, rightImage: nil)),

            FVSpec.group(GroupCell(name: "floatingActionImg_showAppBadge_group",
                                   footerText: "", key: "floatingActionImg_showAppBadge_group")),
            FVSpec.toggle(ToggleCell(name: "显示应用角标?",
                                     key: FVKey.floatBallShowBadge, defaultValue: true, icon: nil)),

            FVSpec.group(GroupCell(name: "floatingActionImg_onTakeScreenHideSelf_group",
                                   footerText: "", key: "floatingActionImg_onTakeScreenHideSelf_group")),
            FVSpec.toggle(ToggleCell(name: "截屏时隐藏自身",
                                     key: FVKey.floatBallHideOnShot, defaultValue: false, icon: nil)),

            FVSpec.group(GroupCell(name: "floatingActionImg_longTouch_showSideToolContainer_group",
                                   footerText: "",
                                   key: "floatingActionImg_longTouch_showSideToolContainer_group")),
            FVSpec.toggle(ToggleCell(name: "长按显示侧边工具栏",
                                     key: FVKey.floatBallLongPressSide, defaultValue: true,
                                     icon: UIImage(systemName: "hand.point.up.braille"))),
        ]
    }

    public override func viewDidLoad() { super.viewDidLoad(); title = "悬浮图标设置" }

    @objc private func resetIconPosition() {
        FVFileManager.write("0.5", name: "verticalCenterX.txt")
        FVFileManager.write("0.5", name: "verticalCenterY.txt")
        FVFileManager.write("0.5", name: "horizontalCenterX.txt")
        FVFileManager.write("0.5", name: "horizontalCenterY.txt")
        NotificationCenter.default.post(name: Notification.Name("fv_toggleMainFloatingAppDisplay"), object: nil)
    }
}

// MARK: - 16) SearchAppPrefsVC

public final class FVSearchAppPrefsVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "frontConsoleEnable_group",
                                   footerText: "", key: "frontConsoleEnable_group")),
            FVSpec.toggle(ToggleCell(name: "操控台总开关",
                                     key: FVKey.frontConsoleEnable, defaultValue: false,
                                     icon: UIImage(systemName: "slider.horizontal.3"))),

            FVSpec.group(GroupCell(name: "frontConsoleTriggerWay_group",
                                   footerText: "", key: "frontConsoleTriggerWay_group")),
            FVSpec.tab(TabCell(name: "操控台触发方式",
                               values: ["0", "1", "2"],
                               titles: ["底部上滑", "角落拉出", "两者都"],
                               key: FVKey.frontConsoleTriggerWay, defaultValue: "0")),

            FVSpec.group(GroupCell(name: "searchAppVC_longPress_sheetShortcutMenu_group",
                                   footerText: "",
                                   key: "searchAppVC_longPress_sheetShortcutMenu_group")),
            FVSpec.toggle(ToggleCell(name: "长按弹出快捷菜单",
                                     key: FVKey.searchLongPressMenu, defaultValue: true, icon: nil)),
            FVSpec.tab(TabCell(name: "快捷菜单打开应用方式",
                               values: ["0", "1", "2"],
                               titles: ["全屏", "浮窗", "侧边"],
                               key: FVKey.searchLongPressOpenWay, defaultValue: "0")),

            FVSpec.group(GroupCell(name: "searchAppView_openAppWay_group",
                                   footerText: "", key: "searchAppView_openAppWay_group")),
            FVSpec.tab(TabCell(name: "搜索面板打开应用方式1/2",
                               values: ["0", "1", "2"],
                               titles: ["全屏", "浮窗", "侧边"],
                               key: FVKey.searchOpenWay12, defaultValue: "0")),
            FVSpec.tab(TabCell(name: "搜索面板打开应用方式3/4",
                               values: ["0", "1", "2"],
                               titles: ["全屏", "浮窗", "侧边"],
                               key: FVKey.searchOpenWay34, defaultValue: "0")),

            FVSpec.group(GroupCell(name: "searchAppVC_keyboardWillShow_avoid_shade_group",
                                   footerText: "",
                                   key: "searchAppVC_keyboardWillShow_avoid_shade_group")),
            FVSpec.toggle(ToggleCell(name: "键盘弹起时避免遮挡",
                                     key: FVKey.searchKBAvoidShade, defaultValue: true, icon: nil)),

            FVSpec.group(GroupCell(name: "showIdentifiersAsSubtitle_group",
                                   footerText: "", key: "showIdentifiersAsSubtitle_group")),
            FVSpec.toggle(ToggleCell(name: "列表显示 bundle id 副标题",
                                     key: FVKey.showBundleIdSubtitle, defaultValue: false, icon: nil)),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "搜索界面设置" }
}

// MARK: - 17) TouchSizeVC

public final class FVTouchSizeVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "手势区域设置", footerText: "",
                                   key: "ArcMenuVCPrefs_touch_group")),
            FVSpec.group(GroupCell(name: "arc 手势区域大小", footerText: "可能会影响操作",
                                   key: "ArcMenuVCPrefs_touch_staticTextCell_group")),
            FVSpec.slider(SliderCell(name: "arc 手势区域大小",
                                     key: "ArcMenuVCPrefs_touch",
                                     defaultValue: 44, min: 20, max: 100,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: true,
                                     leftImage: nil, rightImage: nil)),

            FVSpec.group(GroupCell(name: "arcMenuTriggerWay_touch_group", footerText: "",
                                   key: "arcMenuTriggerWay_touch_group")),
            FVSpec.tab(TabCell(name: "屏幕底部触发arc方式",
                               values: ["0", "1", "2"],
                               titles: ["不触发", "上滑", "长按"],
                               key: FVKey.arcMenuTriggerWay, defaultValue: "0")),

            FVSpec.group(GroupCell(name: "frontConsoleTriggerWay_touch_group", footerText: "",
                                   key: "frontConsoleTriggerWay_touch_group")),
            FVSpec.tab(TabCell(name: "唤出操控台方式",
                               values: ["0", "1", "2"],
                               titles: ["不触发", "上滑", "长按"],
                               key: FVKey.frontConsoleTriggerWay, defaultValue: "0")),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "手势区域设置" }
}

// MARK: - 18) SBIconPrefsVC

public final class FVSBIconPrefsVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "桌面图标设置", footerText: "",
                                   key: "SBIconPrefsVC_group")),
            FVSpec.toggle(ToggleCell(name: "桌面图标浮窗手势",
                                     key: FVKey.sbIconGesture, defaultValue: false, icon: nil)),
            FVSpec.toggle(ToggleCell(name: "长按菜单「通过浮窗打开应用」",
                                     key: FVKey.sbIconOpenFloat, defaultValue: true,
                                     icon: UIImage(systemName: "rectangle.on.rectangle"))),

            FVSpec.group(GroupCell(name: "shortcutItem_openFloatingView_status_group",
                                   footerText: "",
                                   key: "shortcutItem_openFloatingView_status_group")),
            FVSpec.toggle(ToggleCell(name: "快捷按钮打开浮窗?",
                                     key: FVKey.shortcutOpenFloat, defaultValue: true, icon: nil)),

            FVSpec.group(GroupCell(name: "", footerText: "", key: "resetSBIconLocation_group")),
            FVSpec.button(ButtonCell(name: "重置图标位置",
                                     action: #selector(resetIconPosition),
                                     key: "resetSBIconLocation",
                                     icon: UIImage(systemName: "arrow.counterclockwise"))),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "桌面图标设置" }

    @objc private func resetIconPosition() {
        guard let cls = NSClassFromString("SBIconController") as? NSObject.Type,
              let any = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
              let ctrl = any.takeUnretainedValue() as? NSObject else { return }
        let sel = NSSelectorFromString("resetSBIconLocation")
        if ctrl.responds(to: sel) { _ = ctrl.perform(sel) }
    }
}
