// FVBootstrap.swift
// 编排层：把「读配置 → 建窗口 → 装 HID → 建侧边栏/环形菜单」串起来。
// 对应原版：FVTweakInit / CManager / FVAmbient 的角色。

import UIKit

public final class FVAmbient {
    public static let shared = FVAmbient()

    public private(set) var floatingBundleIDs: Set<String> = []
    private var windowScene: UIWindowScene?
    private var fvWindow: FVWindow?
    private var consoleWindow: FVFrontConsoleWindow?
    private var rootWindow: FVRootWindow?
    private var sideBarLeft: FVSideBarContainerView?
    private var sideBarRight: FVSideBarContainerView?
    private var arcLeft: FVArcContainerView?
    private var arcRight: FVArcContainerView?
    private var dispatchView: FVAppDispatchView?
    private var floatBall: FVFloatingActionView?
    private let io = FVIOEvent()

    private init() {}

    // MARK: - 启动

    public func start() {
        FVPrefsStore.shared.setDefaultsIfNeeded()
        FVScreenUtils.shared.refresh()

        DispatchQueue.main.async { [weak self] in
            self?.buildWindows()
            self?.buildOverlays()
            self?.startHID()
            self?.observeRotation()
        }
        FVLog.info("FVBootstrap 启动完成")
    }

    private func buildWindows() {
        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene }).first
        else { FVLog.warn("拿不到 UIWindowScene"); return }
        windowScene = scene

        fvWindow = FVWindow(windowScene: scene)
        consoleWindow = FVFrontConsoleWindow(windowScene: scene)
        rootWindow = FVRootWindow()
    }

    private func buildOverlays() {
        let store = FVPrefsStore.shared

        // 环形菜单（左右各一个实例，原版 FVScreenUtils.leftArc / rightArc）
        let left = FVArcContainerView(positionType: 0)
        let right = FVArcContainerView(positionType: 1)
        left.onExecuteApp  = { [weak self] bid in self?.openInFloatingView(bundleIdentifier: bid) }
        right.onExecuteApp = { [weak self] bid in self?.openInFloatingView(bundleIdentifier: bid) }
        left.onExecuteTool  = { FVSysButtonUtils.shared.perform($0) }
        right.onExecuteTool = { FVSysButtonUtils.shared.perform($0) }
        fvWindow?.addSubview(left)
        fvWindow?.addSubview(right)
        arcLeft = left; arcRight = right
        FVScreenUtils.shared.leftArc = left
        FVScreenUtils.shared.rightArc = right

        // 侧边栏（两个方向，按偏好只启用一个）
        let l = FVSideBarContainerView(positionType: 0)
        let r = FVSideBarContainerView(positionType: 1)
        l.onSelectApp = { [weak self] bid in self?.openInFloatingView(bundleIdentifier: bid) }
        r.onSelectApp = { [weak self] bid in self?.openInFloatingView(bundleIdentifier: bid) }
        if store.int(FVKey.sideViewDisplayLocation) == 0 {
            l.isHidden = false; r.isHidden = true
        } else {
            l.isHidden = true; r.isHidden = false
        }
        fvWindow?.addSubview(l)
        fvWindow?.addSubview(r)
        sideBarLeft = l; sideBarRight = r

        // 浮窗调度容器
        let dv = FVAppDispatchView(frame: UIScreen.main.bounds)
        dv.onNeedFullScreen = { [weak self] bid in self?.requestFullScreen(bid) }
        fvWindow?.addSubview(dv)
        dispatchView = dv

        // 悬浮球：没有 IOHID 时的主入口（点击开/关三屏，长按开搜索）
        let ball = FVFloatingActionView(diameter: 52)
        let screen = FVScreenUtils.shared.mainBounds
        ball.center = CGPoint(x: screen.width - 34, y: screen.midY)
        ball.onTap = { [weak self] in self?.toggleMultipleScreen() }
        ball.onLongPress = { [weak self] in self?.presentSearch() }
        fvWindow?.addSubview(ball)
        floatBall = ball
    }

    private func startHID() {
        io.onTouchPhase = { [weak self] _, _, _ in }
        io.start()
        FVGestureUtils.shared.onArcTrigger = { [weak self] point, positionType in
            self?.showArc(at: point, positionType: positionType)
        }
        FVGestureUtils.shared.onConsoleTrigger = { [weak self] _ in
            self?.toggleMultipleScreen()
        }
    }

    private func observeRotation() {
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            let device = UIDevice.current.orientation
            let interface: UIInterfaceOrientation
            switch device {
            case .landscapeLeft:  interface = .landscapeLeft
            case .landscapeRight: interface = .landscapeRight
            case .portraitUpsideDown: interface = .portraitUpsideDown
            default:              interface = .portrait
            }
            FVScreenUtils.shared.updateInterface(orientation: interface)
            self?.relayoutForRotation()
        }
    }

    // MARK: - 浮窗

    public func openInFloatingView(bundleIdentifier: String, asSide: Bool = false) {
        floatingBundleIDs.insert(bundleIdentifier)
        UserDefaults(suiteName: "fv.last")?.set(bundleIdentifier, forKey: "lastFloating")
        dispatchView?.present(bundleIdentifier: bundleIdentifier, asSide: asSide)
        windowScene?.keyWindow?.makeKey()
        fvWindow?.makeKeyAndVisible()
    }

    public func closeMainFloating() {
        guard let main = dispatchView?.cardViews.first(where: { !$0.isSideCard }) else { return }
        dispatchView?.close(main)
    }

    public func toggleMainFloating() {
        guard let main = dispatchView?.cardViews.first(where: { !$0.isSideCard }) else { return }
        main.isHidden.toggle()
    }

    public func reopenLastFloating() {
        let last = UserDefaults(suiteName: "fv.last")?.string(forKey: "lastFloating") ?? ""
        guard !last.isEmpty else { return }
        openInFloatingView(bundleIdentifier: last)
    }

    public func closeFloatingView(for bundleIdentifier: String) {
        floatingBundleIDs.remove(bundleIdentifier)
    }

    public func requestFullScreen(_ bundleIdentifier: String) {
        // 原版：把 App 推回全屏（走 SBApplication launch 路径）
        guard let cls = NSClassFromString("SBUIController") as? NSObject.Type,
              let any = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
              let ui = any.takeUnretainedValue() as? NSObject else { return }
        let sel = NSSelectorFromString("launchApplicationWithIdentifier:suspended:")
        if ui.responds(to: sel) {
            _ = ui.perform(sel, with: bundleIdentifier, with: false)
        }
    }

    // MARK: - 环形菜单 / 三屏

    private func showArc(at point: CGPoint, positionType: Int) {
        let arc = positionType == 0 ? arcLeft : arcRight
        arc?.show(at: point)
    }

    public func updateArcTouch(_ p: CGPoint) { arcLeft?.updateTouch(at: p); arcRight?.updateTouch(at: p) }
    public func commitArcTouch() { arcLeft?.commitTouch(); arcRight?.commitTouch() }

    public func toggleMultipleScreen() {
        let store = FVPrefsStore.shared
        if store.bool(FVKey.frontConsoleEnable) {
            consoleWindow?.isHidden.toggle()
        } else {
            sideBarLeft?.open()
        }
    }

    public func closeMultipleScreen() {
        sideBarLeft?.close(); sideBarRight?.close()
        arcLeft?.hide(); arcRight?.hide()
    }

    public func moveFrontToSide() {
        guard let bid = FVProcessUtils.frontmostBundleID else { return }
        dispatchView?.present(bundleIdentifier: bid, asSide: true)
        dispatchView?.autoLayoutSideCards()
    }

    public func presentSearch() {
        consoleWindow?.isHidden = false
        consoleWindow?.makeKeyAndVisible()
    }

    public func swapMainAndSide() { dispatchView?.swapMainAndSide() }
    public func switchSideLocation() {
        sideBarLeft?.toggle(); sideBarRight?.toggle()
    }

    // MARK: - 其他 hook 回填

    public func setAllHidden(_ hidden: Bool) {
        fvWindow?.isHidden = hidden
        consoleWindow?.isHidden = hidden
    }
    public func setDNDActive(_ on: Bool) { /* 更新 arc 工具图标态 */ }
    public func onAppLayoutAdded(_ layout: AnyObject) {}
    public func onAppLayoutRemoved(_ layout: AnyObject) {}
    public func onSceneInvalidated(_ scene: AnyObject) {}
    public func registerBanner(_ vc: AnyObject) {}
    public func registerShortLook(_ vc: AnyObject) {}
    public func registerFloatingMenu(for bid: String) {}
    public func floatFrontApplication() {
        guard let bid = FVProcessUtils.frontmostBundleID else { return }
        openInFloatingView(bundleIdentifier: bid)
    }
    public func onKeyboardFrameChanged() {}
    public func onKeyboardLayerFrameChanged(_ f: CGRect) {}
    public func shouldConsumeUndoGesture(_ g: AnyObject) -> Bool { false }
    public func attachSideBarIfNeeded(in rootWindow: AnyObject) {}
    private func relayoutForRotation() {}
}

// MARK: - 启动入口（对应原版 FVTweakInit）

public final class FVBootstrap {
    public static let shared = FVBootstrap()
    private init() {}
    private var started = false

    public func start() {
        guard !started else { return }
        started = true
        FVAmbient.shared.start()
    }
}
