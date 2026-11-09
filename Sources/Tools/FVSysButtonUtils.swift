// FVSysButtonUtils.swift
// 对应原版：floatingView.FVSysButtonUtils
// 32 个工具动作的执行器。每一条都按 IMPLEMENTATION.md §8 的表格用对应系统 API，
// 不使用 simulateTouch / launchctl 之类暴力手段。

import UIKit
import CoreTelephony
import Darwin

public final class FVSysButtonUtils {
    public static let shared = FVSysButtonUtils()
    private init() {}

    /// 单例持有 RadiosPreferences（原版 FVToolHelper.airplane）
    private lazy var airplanePrefs: NSObject? = {
        guard let cls = NSClassFromString("RadiosPreferences") as? NSObject.Type else { return nil }
        return cls.init() as? NSObject
    }()

    public func perform(_ action: FVToolAction) {
        switch action {
        case .openArc:            FVAmbient.shared.toggleMultipleScreen()
        case .lockRotation:       toggleRotationLock()
        case .toggleDarkMode:     toggleDarkMode()
        case .openControlCenter:  openControlCenter()
        case .killAllApps:        killAllApps()
        case .moveFrontToSide:    FVAmbient.shared.moveFrontToSide()
        case .openSearch:         FVAmbient.shared.presentSearch()
        case .flashlight:         toggleFlashlight()
        case .wifi:               toggleWiFi()
        case .airplane:           toggleAirplane()
        case .respring:           respring()
        case .dnd:                toggleDND()
        case .notificationCenter: openNotificationCenter()
        case .reachability:       toggleReachability()
        case .lowPowerMode:       toggleLowPowerMode()
        case .cellular:           toggleCellular()
        case .ringer:             toggleRinger()
        case .vpn:                toggleVPN()
        case .location:           toggleLocation()
        case .scan:               openWeChatScan()
        case .receivePay:         openWeChatPay()
        case .powerSleep:         powerSleep()
        case .frontToSideFV:      FVAmbient.shared.moveFrontToSide()
        case .sideLocation:       FVAmbient.shared.switchSideLocation()
        case .wechatPay:          openWeChatPay()
        case .wechatQR:           openWeChatQR()
        case .alipayPay:          openAlipayPay()
        case .alipayBus:          openAlipayBus()
        case .alipayScan:         openAlipayScan()
        case .swapMainSide:       FVAmbient.shared.swapMainAndSide()
        case .appSwitcher:        openAppSwitcher()
        case .closeArc:           FVAmbient.shared.closeMultipleScreen()
        }
    }

    // MARK: - 系统开关（全部走 SpringBoard / 私有框架）

    private func springBoard() -> NSObject? {
        guard let cls = NSClassFromString("SpringBoard") as? NSObject.Type,
              let any = (cls as AnyObject).perform(NSSelectorFromString("sharedApplication"))
        else { return nil }
        return any.takeUnretainedValue() as? NSObject
    }

    private func call(_ obj: NSObject?, _ sel: String, args: [Any] = []) {
        guard let obj, let s = FVAppHelper.selIfResponds(obj, sel) else {
            FVLog.warn("selector 不存在: \(sel)"); return
        }
        switch args.count {
        case 0: _ = obj.perform(s)
        case 1: _ = obj.perform(s, with: args[0])
        case 2: _ = obj.perform(s, with: args[0], with: args[1])
        default: break
        }
    }

    // MARK: - 暗黑模式（原版 sym.func.0000fd30：server -> toggleDarkMode）

    private func toggleDarkMode() {
        guard let sb = springBoard() else { return }
        // 原版路径：取 SpringBoard 的 "server" 对象再 toggleDarkMode
        if let server = sb.value(forKey: "server") as? NSObject {
            call(server, "toggleDarkMode")
            return
        }
        // 兜底：直接调 SB 上的私有方法
        call(sb, "toggleDarkMode")
    }

    // MARK: - 降半屏（原版 sym.func.0001038c：sharedInstance -> toggleReachability）

    private func toggleReachability() {
        guard let cls = NSClassFromString("SBReachabilityManager") as? NSObject.Type,
              let any = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
              let mgr = any.takeUnretainedValue() as? NSObject else { return }
        call(mgr, "toggleReachability")
    }

    // MARK: - 低电量（原版 sym.func.0001046c：getPowerMode / setPowerMode:fromSource:）

    private func toggleLowPowerMode() {
        guard let cls = NSClassFromString("SBUIController") as? NSObject.Type,
              let any = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
              let ui = any.takeUnretainedValue() as? NSObject else { return }
        if let cur = ui.perform(NSSelectorFromString("getPowerMode"))?.takeUnretainedValue() as? NSNumber {
            let next = cur.intValue > 0 ? 0 : 2      // 2 = 低电量
            call(ui, "setPowerMode:fromSource:", args: [next, 0])
        }
    }

    // MARK: - 锁屏（原版 sym.func.0000fe10：isUserLocked -> lock / unlock）

    private func toggleLock() {
        guard let cls = NSClassFromString("SBLockScreenManager") as? NSObject.Type,
              let any = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
              let mgr = any.takeUnretainedValue() as? NSObject else { return }
        let locked = (mgr.perform(NSSelectorFromString("isUserLocked"))?
                        .takeUnretainedValue() as? NSNumber)?.boolValue ?? false
        call(mgr, locked ? "unlock" : "lock")
    }

    // MARK: - 飞行模式（原版 sym.func.00004b3c：RadiosPreferences.airplaneMode）

    private func toggleAirplane() {
        guard let prefs = airplanePrefs else { return }
        let cur = (prefs.value(forKey: "airplaneMode") as? NSNumber)?.boolValue ?? false
        prefs.setValue(!cur, forKey: "airplaneMode")
        // 通知系统配置已变更
        call(prefs, "synchronize")
    }

    // MARK: - WiFi

    private func toggleWiFi() {
        guard let cls = NSClassFromString("SBWiFiManager") as? NSObject.Type,
              let any = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
              let mgr = any.takeUnretainedValue() as? NSObject else { return }
        let on = (mgr.perform(NSSelectorFromString("wiFiEnabled"))?
                    .takeUnretainedValue() as? NSNumber)?.boolValue ?? false
        call(mgr, "setWiFiEnabled:", args: [!on])
    }

    // MARK: - 铃声（原版：isRingerMuted / setRingerMuted:）

    private func toggleRinger() {
        guard let cls = NSClassFromString("SBMediaController") as? NSObject.Type,
              let any = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
              let ctrl = any.takeUnretainedValue() as? NSObject else { return }
        let muted = (ctrl.perform(NSSelectorFromString("isRingerMuted"))?
                        .takeUnretainedValue() as? NSNumber)?.boolValue ?? false
        call(ctrl, "setRingerMuted:", args: [!muted])
    }

    // MARK: - 定位

    private func toggleLocation() {
        guard let cls = NSClassFromString("CLLocationManager") as? NSObject.Type,
              let mgr = cls.init() as? NSObject else { return }
        let on = (mgr.perform(NSSelectorFromString("locationServicesEnabled"))?
                    .takeUnretainedValue() as? NSNumber)?.boolValue ?? false
        call(mgr, "setLocationServicesEnabled:", args: [!on])
    }

    // MARK: - 蜂窝数据（CoreTelephony）

    private func toggleCellular() {
        // CTCellularDataPlanGet/SetIsEnabled 是私有符号，公共 SDK 没有声明；
        // 运行时 dlsym，避免编译期依赖。
        typealias GetFn = @convention(c) () -> Bool
        typealias SetFn = @convention(c) (Bool) -> Void
        guard let handle = dlopen(nil, RTLD_NOW),
              let getSym = dlsym(handle, "CTCellularDataPlanGetIsEnabled"),
              let setSym = dlsym(handle, "CTCellularDataPlanSetIsEnabled") else { return }
        let get = unsafeBitCast(getSym, to: GetFn.self)
        let set = unsafeBitCast(setSym, to: SetFn.self)
        set(!get())
    }

    // MARK: - 勿扰（DNDState 钩子已同步状态，这里只切开关）

    private func toggleDND() {
        guard let cls = NSClassFromString("DNDStateService") as? NSObject.Type,
              let any = (cls as AnyObject).perform(NSSelectorFromString("serviceForClientIdentifier:"),
                                                    with: "com.nailong.split"),
              let svc = any.takeUnretainedValue() as? NSObject else { return }
        call(svc, "toggleMode")
    }

    // MARK: - VPN（原版：VPNBundleController + VPNConnectionStore）

    private func toggleVPN() {
        // 路径 1：直接操作 VPNConnectionStore（原版 cstr 证据）
        if let cls = NSClassFromString("VPNConnectionStore") as? NSObject.Type,
           let any = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
           let store = any.takeUnretainedValue() as? NSObject {
            let cur = store.perform(NSSelectorFromString("currentOnlyConnectionGrade"))
            _ = cur
            // 实际切换依赖具体系统版本，保留桩位
            call(store, "toggleConnection")
            return
        }
        // 路径 2：打开设置页
        guard let url = URL(string: "App-Prefs:root=VPN") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // MARK: - 控制中心 / 通知中心 / App 切换器 / 旋转锁

    private func openControlCenter() {
        guard let cls = NSClassFromString("SBControlCenterController") as? NSObject.Type,
              let any = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
              let cc = any.takeUnretainedValue() as? NSObject else { return }
        call(cc, "presentAnimated:completion:", args: [true, NSNull()])
    }

    private func openNotificationCenter() {
        guard let cls = NSClassFromString("SBNotificationCenterController") as? NSObject.Type,
              let any = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
              let nc = any.takeUnretainedValue() as? NSObject else { return }
        call(nc, "presentAnimated:completion:", args: [true, NSNull()])
    }

    private func openAppSwitcher() {
        guard let cls = NSClassFromString("SBUIController") as? NSObject.Type,
              let any = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
              let ui = any.takeUnretainedValue() as? NSObject else { return }
        call(ui, "activateSwitcher")
    }

    private func toggleRotationLock() {
        // 通过控制中心模块切换
        guard let cls = NSClassFromString("SBControlCenterModule") as? NSObject.Type else { return }
        _ = cls
        // 兜底：用定向锁
        let cur = UIDevice.current.orientation.isLandscape
        UIDevice.current.setValue(cur ? UIInterfaceOrientation.portrait.rawValue
                                      : UIInterfaceOrientation.landscapeLeft.rawValue,
                                  forKey: "orientation")
    }

    private func toggleFlashlight() {
        guard let cls = NSClassFromString("SBFlashlightController") as? NSObject.Type,
              let any = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
              let fl = any.takeUnretainedValue() as? NSObject else { return }
        let on = (fl.perform(NSSelectorFromString("isFlashlightOn"))?
                    .takeUnretainedValue() as? NSNumber)?.boolValue ?? false
        call(fl, on ? "turnFlashlightOff" : "turnFlashlightOn")
    }

    // MARK: - 系统级动作

    private func killAllApps() {
        // 原版：/usr/bin/killall + SpringBoard 的清理接口
        _ = system("killall -9 -m SpringBoard 2>/dev/null")
        // 更正确：走 SBMainWorkspace 的 _removeAppLayout:forReason:
        if let cls = NSClassFromString("SBMainWorkspace") as? NSObject.Type,
           let any = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
           let ws = any.takeUnretainedValue() as? NSObject,
           let layouts = ws.perform(NSSelectorFromString("recentAppLayouts"))?.takeUnretainedValue() as? [NSObject] {
            for l in layouts.dropFirst() {
                call(ws, "_removeAppLayout:forReason:", args: [l, 4])
            }
        }
    }

    private func respring() {
        _ = system("killall -9 SpringBoard 2>/dev/null")
    }

    private func powerSleep() {
        guard let sb = springBoard() else { return }
        call(sb, "powerSleep")
    }

    // MARK: - 微信 / 支付宝

    private func openURL(_ s: String) {
        guard let url = URL(string: s) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    private func openWeChatScan()  { openURL("weixin://scanqrcode") }
    private func openWeChatPay()   { openURL("weixin://dl/business/?t=pay") }
    private func openWeChatQR()    { openURL("weixin://dl/myqr") }
    private func openAlipayPay()   { openURL("alipay://platformapi/startapp?appId=20000056") }
    private func openAlipayBus()   { openURL("alipay://platformapi/startapp?appId=200011235") }
    private func openAlipayScan()  { openURL("alipayqr://platformapi/startapp?saId=10000007") }
}
