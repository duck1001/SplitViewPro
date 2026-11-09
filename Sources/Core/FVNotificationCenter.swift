// FVNotificationCenter.swift
// 对应原版：floatingView.FVNotificationCenter（NSObject，3 个方法）
//
// 逆向证据（sym.func.00025870 = init）：
//   x21 = [x24 + 0x360]   → NSNotificationCenter.defaultCenter
//   x19 = str.handleNotification:
//   x1  = str.addObserver:selector:name:object:   × 6 次
//
// 6 个通知名（cstring 表实证）：
//   fv_openFloatingView / fv_openFloatingView_toSide / fv_openFloatingView_lastRun
//   fv_closeMainFloatingApp / fv_toggleMainFloatingAppDisplay
//   （第 6 个推测为 fv_openFloatingView 的另一种变体）
//
// 这是所有「打开浮窗」入口的汇聚点：桌面图标菜单、底部横条、通知横幅、
// 通用链接最终都 post 到这里，由 handleNotification: 统一分派。

import Foundation

public final class FVNotificationCenter: NSObject {
    public static let shared = FVNotificationCenter()

    public enum Event: String, CaseIterable {
        case openFloatingView          = "fv_openFloatingView"
        case openFloatingViewToSide    = "fv_openFloatingView_toSide"
        case openFloatingViewLastRun   = "fv_openFloatingView_lastRun"
        case closeMainFloatingApp      = "fv_closeMainFloatingApp"
        case toggleMainFloatingAppDisplay = "fv_toggleMainFloatingAppDisplay"
    }

    public enum UserInfoKey {
        public static let bundleIdentifier = "bundleIdentifier"
        public static let positionType     = "positionType"
    }

    private override init() {
        super.init()
        for e in Event.allCases {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleNotification(_:)),
                name: Notification.Name(e.rawValue),
                object: nil)
        }
        FVLog.info("FVNotificationCenter 已注册 \(Event.allCases.count) 个观察者")
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    /// 原版：handleNotification:（63 行，按 notification.name 分派）
    @objc private func handleNotification(_ n: Notification) {
        guard let e = Event(rawValue: n.name.rawValue) else {
            FVLog.warn("未知通知: \(n.name.rawValue)")
            return
        }
        let bid = n.userInfo?[UserInfoKey.bundleIdentifier] as? String

        switch e {
        case .openFloatingView:
            guard let bid else { return }
            FVAmbient.shared.openInFloatingView(bundleIdentifier: bid)

        case .openFloatingViewToSide:
            guard let bid else { return }
            FVAmbient.shared.openInFloatingView(bundleIdentifier: bid, asSide: true)

        case .openFloatingViewLastRun:
            FVAmbient.shared.reopenLastFloating()

        case .closeMainFloatingApp:
            FVAmbient.shared.closeMainFloating()

        case .toggleMainFloatingAppDisplay:
            FVAmbient.shared.toggleMainFloating()
        }
    }

    // MARK: - 发送端（原版各处调用）

    public static func post(_ e: Event, _ userInfo: [String: Any]? = nil) {
        NotificationCenter.default.post(
            name: Notification.Name(e.rawValue), object: nil, userInfo: userInfo)
    }

    public static func open(_ bundleIdentifier: String, toSide: Bool = false) {
        post(toSide ? .openFloatingViewToSide : .openFloatingView,
             [UserInfoKey.bundleIdentifier: bundleIdentifier])
    }
}
