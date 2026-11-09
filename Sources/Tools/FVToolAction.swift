// FVToolAction.swift
// 对应原版：工具菜单枚举（在 floatingView.dylib 里是一组图标 + 标题 +
// 序号三元组，打包成 FVToolBtnInfo；设置面板用 FVToolsInfo）。
//
// 顺序来自 cstring 表 0x50740 起的连续排列（即 UI 顺序），
// 复刻时保持顺序一致，可让配置数据在两边互通。

import Foundation

public enum FVToolAction: Int, CaseIterable {
    case openArc = 0            // 打开三屏、浮窗
    case lockRotation = 1       // 锁定屏幕转向
    case toggleDarkMode = 2     // 切换普通、暗黑模式
    case openControlCenter = 3  // 打开控制中心
    case killAllApps = 4        // 清理后台任务栏应用
    case moveFrontToSide = 5    // 将前台应用放置在侧边
    case openSearch = 6         // 打开搜索应用界面
    case flashlight = 7         // 打开、关闭手电筒
    case wifi = 8               // 打开、关闭 WiFi
    case airplane = 9           // 打开、关闭飞行模式
    case respring = 10          // 重启 SpringBoard
    case dnd = 11               // 切换勿扰、正常模式
    case notificationCenter = 12// 打开、关闭通知中心
    case reachability = 13      // 降半屏
    case lowPowerMode = 14      // 切换低电量模式
    case cellular = 15          // 打开、关闭蜂窝数据
    case ringer = 16            // 打开、关闭铃声
    case vpn = 17               // 打开、关闭 VPN
    case location = 18          // 打开、关闭定位
    case scan = 19              // 扫一扫
    case receivePay = 20        // 收付款
    case powerSleep = 21        // 关机并重启
    case frontToSideFV = 22     // 前台应用浮窗化并放侧边
    case sideLocation = 23      // 侧边位置改变
    case wechatPay = 24         // 微信收/付款
    case wechatQR = 25          // 微信我的二维码
    case alipayPay = 26         // 支付宝收/付款
    case alipayBus = 27         // 支付宝乘车码
    case alipayScan = 28        // 支付宝扫一扫
    case swapMainSide = 29      // 交换主次屏位置
    case appSwitcher = 30       // 后台任务栏应用
    case closeArc = 31          // 关闭三屏界面

    public var title: String {
        switch self {
        case .openArc: return "打开三屏、浮窗"
        case .lockRotation: return "锁定屏幕转向"
        case .toggleDarkMode: return "切换普通、暗黑模式"
        case .openControlCenter: return "打开控制中心"
        case .killAllApps: return "清理后台任务栏应用"
        case .moveFrontToSide: return "将前台应用放置在侧边"
        case .openSearch: return "打开搜索应用界面"
        case .flashlight: return "打开、关闭手电筒"
        case .wifi: return "打开、关闭 WiFi"
        case .airplane: return "打开、关闭飞行模式"
        case .respring: return "重启 SpringBoard"
        case .dnd: return "切换勿扰、正常模式"
        case .notificationCenter: return "打开、关闭通知中心"
        case .reachability: return "降半屏"
        case .lowPowerMode: return "切换低电量模式"
        case .cellular: return "打开、关闭蜂窝数据"
        case .ringer: return "打开、关闭铃声"
        case .vpn: return "打开、关闭 VPN"
        case .location: return "打开、关闭定位"
        case .scan: return "扫一扫"
        case .receivePay: return "收付款"
        case .powerSleep: return "关机并重启"
        case .frontToSideFV: return "前台应用浮窗化并放侧边"
        case .sideLocation: return "侧边位置改变"
        case .wechatPay: return "微信收/付款"
        case .wechatQR: return "微信我的二维码"
        case .alipayPay: return "支付宝收/付款"
        case .alipayBus: return "支付宝乘车码"
        case .alipayScan: return "支付宝扫一扫"
        case .swapMainSide: return "交换主次屏位置"
        case .appSwitcher: return "后台任务栏应用"
        case .closeArc: return "关闭三屏界面"
        }
    }

    public var symbolName: String {
        switch self {
        case .openArc: return "rectangle.on.rectangle"
        case .lockRotation: return "lock.rotation"
        case .toggleDarkMode: return "light.max"
        case .openControlCenter: return "switch.2"
        case .killAllApps: return "trash.slash"
        case .moveFrontToSide: return "sidebar.squares.right"
        case .openSearch: return "magnifyingglass"
        case .flashlight: return "flashlight.on.fill"
        case .wifi: return "wifi"
        case .airplane: return "airplane"
        case .respring: return "arrow.turn.up.right"
        case .dnd: return "hand.raised"
        case .notificationCenter: return "bell.badge"
        case .reachability: return "arrow.turn.up.left"
        case .lowPowerMode: return "minus.plus.batteryblock"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .ringer: return "bell.badge"
        case .vpn: return "network"
        case .location: return "location"
        case .scan: return "qrcode.viewfinder"
        case .receivePay: return "qrcode"
        case .powerSleep: return "power.dotted"
        case .frontToSideFV: return "rectangle.portrait.center.inset.filled"
        case .sideLocation: return "arrow.left.and.right"
        case .wechatPay: return "qrcode"
        case .wechatQR: return "qrcode"
        case .alipayPay: return "qrcode"
        case .alipayBus: return "buscode"
        case .alipayScan: return "qrcode.viewfinder"
        case .swapMainSide: return "arrow.left.arrow.right"
        case .appSwitcher: return "rectangle.on.rectangle"
        case .closeArc: return "xmark"
        }
    }

    public init?(iconName: String) {
        guard let v = Self.allCases.first(where: { $0.symbolName == iconName }) else { return nil }
        self = v
    }
}
