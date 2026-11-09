// FVPrefsPages3.swift
// 设置页 19~26（Arc 菜单系列）。结构与 DEEP_DIVE_SETTINGS.md 对应。

import Preferences
import UIKit

// MARK: - 19) ArcMenuVC

public final class FVArcMenuVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "ArcMenuVCPrefs_group",
                                   footerText: "", key: "ArcMenuVCPrefs_group")),

            FVSpec.link(LinkCell(name: "arc-层级与按钮大小设置",
                                 className: FVArcLevelAndItemSizeVC.self, isController: true,
                                 key: "FVArcLevelAndItemSizeVC", action: nil,
                                 icon: UIImage(systemName: "circle.hexagongrid"))),
            FVSpec.link(LinkCell(name: "arc-应用层级设置",
                                 className: FVArcAppLevelVC.self, isController: true,
                                 key: "FVArcAppLevelVC", action: nil,
                                 icon: UIImage(systemName: "app.badge"))),
            FVSpec.link(LinkCell(name: "arc-工具栏层级设置",
                                 className: FVArcToolLevelVC.self, isController: true,
                                 key: "FVArcToolLevelVC", action: nil,
                                 icon: UIImage(systemName: "wrench.and.screwdriver"))),
            FVSpec.link(LinkCell(name: "arc-风格化设置",
                                 className: FVArcStylizedVC.self, isController: true,
                                 key: "FVArcStylizedVC", action: nil,
                                 icon: UIImage(systemName: "paintbrush.pointed"))),
            FVSpec.link(LinkCell(name: "arc-工具栏颜色设置",
                                 className: FVArcIconColor.self, isController: true,
                                 key: "FVArcIconColor", action: nil,
                                 icon: UIImage(systemName: "eyedropper.halffull"))),
            FVSpec.link(LinkCell(name: "arc-灵敏度",
                                 className: FVArcSensitivenessVC.self, isController: true,
                                 key: "FVArcSensitivenessVC", action: nil,
                                 icon: UIImage(systemName: "hand.point.up.braille"))),
            FVSpec.link(LinkCell(name: "arc-二维码、扫一扫设置",
                                 className: FVArcQrcodeVC.self, isController: true,
                                 key: "FVArcQrcodeVC", action: nil,
                                 icon: UIImage(systemName: "qrcode.viewfinder"))),

            FVSpec.group(GroupCell(name: "arcVibrationFeedback_group",
                                   footerText: "", key: "arcVibrationFeedback_group")),
            FVSpec.toggle(ToggleCell(name: "arc 振动反馈",
                                     key: FVKey.arcVibrationFeedback, defaultValue: true,
                                     icon: UIImage(systemName: "iphone.radiowaves.left.and.right"))),

            FVSpec.group(GroupCell(name: "arcMenuVc_onTakeScreenHideSelf_group",
                                   footerText: "", key: "arcMenuVc_onTakeScreenHideSelf_group")),
            FVSpec.toggle(ToggleCell(name: "打开 arc 时截屏隐藏自身",
                                     key: FVKey.arcMenuHideSelfOnShot,
                                     defaultValue: false, icon: nil)),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "arc 菜单" }
}

// MARK: - 20) FVArcLevelAndItemSizeVC

public final class FVArcLevelAndItemSizeVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "arc-层级与按钮大小设置",
                                   footerText: "", key: "FVArcLevelAndItemSizeVC_group")),

            FVSpec.tab(TabCell(name: "应用层级数量",
                               values: ["1", "2", "3", "4"],
                               titles: ["1 层", "2 层", "3 层", "4 层"],
                               key: FVKey.arcAppLevelCount, defaultValue: "3")),
            FVSpec.tab(TabCell(name: "工具栏层级数量",
                               values: ["1", "2", "3"],
                               titles: ["1 层", "2 层", "3 层"],
                               key: FVKey.arcToolLevelCount, defaultValue: "2")),

            FVSpec.group(GroupCell(name: "arcAppShowCount_inner_group",
                                   footerText: "内外圈显示数量。0 = 自动均分。",
                                   key: "arcAppShowCount_inner_group")),
            FVSpec.slider(SliderCell(name: "内圈显示数量", key: FVKey.arcAppShowCountInner,
                                     defaultValue: 22, min: 0, max: 40,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: false,
                                     leftImage: nil, rightImage: nil)),
            FVSpec.slider(SliderCell(name: "外圈显示数量", key: FVKey.arcAppShowCountOuter,
                                     defaultValue: 22, min: 0, max: 40,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: false,
                                     leftImage: nil, rightImage: nil)),

            FVSpec.group(GroupCell(name: "arcAppDisplay_center_distance_group",
                                   footerText: "",
                                   key: "arcAppDisplay_center_distance_group")),
            FVSpec.slider(SliderCell(name: "内外圈中心距离",
                                     key: FVKey.arcAppDisplayCenterDist,
                                     defaultValue: 0, min: -40, max: 40,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: true,
                                     leftImage: nil, rightImage: nil)),

            FVSpec.link(LinkCell(name: "arc菜单App排序",
                                 className: FVSortAppVC.self, isController: true,
                                 key: "arc_sortApp",
                                 action: #selector(gotoSortApp(_:)),
                                 icon: UIImage(systemName: "arrow.up.arrow.down"))),
            FVSpec.link(LinkCell(name: "arc-工具栏排序",
                                 className: FVSortToolsVC.self, isController: true,
                                 key: "arc_sortTools",
                                 action: #selector(gotoSortTools(_:)),
                                 icon: UIImage(systemName: "arrow.up.arrow.down"))),
        ]
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "arc-层级与按钮大小设置"
    }
    @objc private func gotoSortApp(_ s: Any?) {
        navigationController?.pushViewController(FVSortAppVC(), animated: true)
    }
    @objc private func gotoSortTools(_ s: Any?) {
        navigationController?.pushViewController(FVSortToolsVC(), animated: true)
    }
}

// MARK: - 21) FVArcAppLevelVC（应用环 4 层）

public final class FVArcAppLevelVC: PSListController {
    public override func specifiers() -> [Any]! {
        var list: [PSSpecifier] = [
            FVSpec.group(GroupCell(name: "arc-应用层级设置",
                                   footerText: "每层可独立设置显示数量、按钮大小、半径。数量为 0 表示自动均分整圈。",
                                   key: "FVArcAppLevelVC_group")),
        ]
        let names = ["第一层", "第二层", "第三层", "第四层"]
        let radii = [22.0, 66.0, 110.0, 154.0]
        for level in 1...4 {
            let n = names[level - 1]

            list.append(FVSpec.group(GroupCell(
                name: "arcAppDisplayCount_level_\(level)_group",
                footerText: "", key: "arcAppDisplayCount_level_\(level)_group")))
            list.append(FVSpec.slider(SliderCell(
                name: "\(n)app数量",
                key: FVKey.arcAppDisplayCount(level),
                defaultValue: 0, min: 0, max: 30,
                showValue: true, isSegmented: false,
                segmentCount: nil, isContinuous: false,
                leftImage: nil, rightImage: nil)))

            list.append(FVSpec.group(GroupCell(
                name: "arcAppDisplayItemSize_level_\(level)_group",
                footerText: "", key: "arcAppDisplayItemSize_level_\(level)_group")))
            list.append(FVSpec.slider(SliderCell(
                name: "\(n)（按钮大小）",
                key: FVKey.arcAppDisplayItemSize(level),
                defaultValue: 22, min: 12, max: 60,
                showValue: true, isSegmented: false,
                segmentCount: nil, isContinuous: true,
                leftImage: nil, rightImage: nil)))

            list.append(FVSpec.group(GroupCell(
                name: "arcAppRadius_level_\(level)_group",
                footerText: "", key: "arcAppRadius_level_\(level)_group")))
            list.append(FVSpec.slider(SliderCell(
                name: "\(n)（半径）",
                key: FVKey.arcAppRadius(level),
                defaultValue: radii[level - 1], min: 20, max: 300,
                showValue: true, isSegmented: false,
                segmentCount: nil, isContinuous: true,
                leftImage: nil, rightImage: nil)))
        }
        return list
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "arc-应用层级设置"
    }
}

// MARK: - 22) FVArcToolLevelVC（工具环 3 层）

public final class FVArcToolLevelVC: PSListController {
    public override func specifiers() -> [Any]! {
        var list: [PSSpecifier] = [
            FVSpec.group(GroupCell(name: "arc-工具栏层级设置",
                                   footerText: "工具环与应用环叠加显示，工具通常位于外圈。",
                                   key: "FVArcToolLevelVC_group")),
        ]
        let names = ["第一层", "第二层", "第三层"]
        let radii = [22.0, 66.0, 110.0]
        for level in 1...3 {
            let n = names[level - 1]

            list.append(FVSpec.group(GroupCell(
                name: "arcToolDisplayCount_level_\(level)_group",
                footerText: "", key: "arcToolDisplayCount_level_\(level)_group")))
            list.append(FVSpec.slider(SliderCell(
                name: "\(n)工具数量",
                key: FVKey.arcToolDisplayCount(level),
                defaultValue: 0, min: 0, max: 20,
                showValue: true, isSegmented: false,
                segmentCount: nil, isContinuous: false,
                leftImage: nil, rightImage: nil)))

            list.append(FVSpec.group(GroupCell(
                name: "arcToolDisplayItemSize_level_\(level)_group",
                footerText: "", key: "arcToolDisplayItemSize_level_\(level)_group")))
            list.append(FVSpec.slider(SliderCell(
                name: "\(n)（按钮大小）",
                key: FVKey.arcToolDisplayItemSize(level),
                defaultValue: 22, min: 12, max: 60,
                showValue: true, isSegmented: false,
                segmentCount: nil, isContinuous: true,
                leftImage: nil, rightImage: nil)))

            list.append(FVSpec.group(GroupCell(
                name: "arcToolRadius_level_\(level)_group",
                footerText: "", key: "arcToolRadius_level_\(level)_group")))
            list.append(FVSpec.slider(SliderCell(
                name: "\(n)（半径）",
                key: FVKey.arcToolRadius(level),
                defaultValue: radii[level - 1], min: 20, max: 300,
                showValue: true, isSegmented: false,
                segmentCount: nil, isContinuous: true,
                leftImage: nil, rightImage: nil)))
        }
        return list
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "arc-工具栏层级设置"
    }
}

// MARK: - 23) FVArcStylizedVC

public final class FVArcStylizedVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "arc-风格化设置", footerText: "",
                                   key: "FVArcStylizedVC_group")),

            FVSpec.link(LinkCell(name: "arc-工具栏颜色设置",
                                 className: FVArcIconColor.self, isController: true,
                                 key: "FVArcIconColor", action: nil,
                                 icon: UIImage(systemName: "paintbrush.pointed"))),
            FVSpec.link(LinkCell(name: "arc-二维码、扫一扫设置",
                                 className: FVArcQrcodeVC.self, isController: true,
                                 key: "FVArcQrcodeVC", action: nil,
                                 icon: UIImage(systemName: "qrcode.viewfinder"))),

            FVSpec.group(GroupCell(name: "arc_button_bgColor_status_group",
                                   footerText: "开启后可为 arc 按钮设置独立底色。",
                                   key: "arc_button_bgColor_status_group")),
            FVSpec.toggle(ToggleCell(name: "开启arc按钮背景颜色?",
                                     key: FVKey.arcButtonBgStatus,
                                     defaultValue: false,
                                     icon: UIImage(systemName: "circle.fill"))),

            FVSpec.group(GroupCell(name: "arcBtn_bgColor_value_group",
                                   footerText: "", key: "arcBtn_bgColor_value_group")),
            FVSpec.link(LinkCell(name: "按钮背景颜色",
                                 className: nil, isController: false,
                                 key: FVKey.arcButtonBgValue, action: nil,
                                 icon: UIImage(systemName: "eyedropper"))),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "arc-风格化设置" }
}

// MARK: - 24) FVArcIconColor

public final class FVArcIconColor: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "arc-工具栏颜色设置",
                                   footerText: "关闭态与开启态可分别设色，用于反映系统开关的当前状态。",
                                   key: "arcToolIconColor_group")),

            FVSpec.group(GroupCell(name: "arcTools_notIsOn_color_group",
                                   footerText: "", key: "arcTools_notIsOn_color_group")),
            FVSpec.link(LinkCell(name: "功能未开启颜色",
                                 className: ColorPickerTableCell.self, isController: false,
                                 key: FVKey.arcToolsNotIsOnColor, action: nil,
                                 icon: UIImage(systemName: "circle"))),

            FVSpec.group(GroupCell(name: "arcTools_IsOn_color_group",
                                   footerText: "", key: "arcTools_IsOn_color_group")),
            FVSpec.link(LinkCell(name: "功能开启颜色",
                                 className: ColorPickerTableCell.self, isController: false,
                                 key: FVKey.arcToolsIsOnColor, action: nil,
                                 icon: UIImage(systemName: "circle.fill"))),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "arc-工具栏颜色设置" }
}

// MARK: - 25) FVArcSensitivenessVC

public final class FVArcSensitivenessVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "arc-灵敏度",
                                   footerText: "数值越大，手指移动越容易被识别为「切换选中项」。",
                                   key: "arcContainerSensitiveness_onTouchMove_group")),
            FVSpec.slider(SliderCell(name: "触摸移动灵敏度",
                                     key: FVKey.arcContainerSensitivity,
                                     defaultValue: 0.5, min: 0, max: 1,
                                     showValue: true, isSegmented: false,
                                     segmentCount: nil, isContinuous: true,
                                     leftImage: UIImage(systemName: "tortoise"),
                                     rightImage: UIImage(systemName: "hare"))),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "arc-灵敏度" }
}

// MARK: - 26) FVArcQrcodeVC

public final class FVArcQrcodeVC: PSListController {
    public override func specifiers() -> [Any]! {
        [
            FVSpec.group(GroupCell(name: "arc-二维码、扫一扫设置",
                                   footerText: "", key: "FVArcQrcodeVC_group")),
            FVSpec.tab(TabCell(name: "可自行选择二维码逻辑",
                               values: ["0", "1", "2"],
                               titles: ["微信", "支付宝", "自适应"],
                               key: FVKey.displayQrcodeWay, defaultValue: "0")),
            FVSpec.tab(TabCell(name: "可自行选择扫一扫逻辑",
                               values: ["0", "1", "2"],
                               titles: ["微信", "支付宝", "自适应"],
                               key: FVKey.scanWay, defaultValue: "0")),
        ]
    }
    public override func viewDidLoad() { super.viewDidLoad(); title = "arc-二维码、扫一扫设置" }
}
