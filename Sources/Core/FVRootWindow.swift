// FVRootWindow.swift
// 对应原版：floatingView.FVRootWindow
// 它**不继承 UIWindow**，而是包一个 UIRootSceneWindow（SpringBoard 私有），
// 目的是让侧边栏挂在 RootScene 上，横竖屏切换时始终贴物理屏幕边缘、内部做反向旋转。

import UIKit

public final class FVRootWindow {
    public var rootWindow: NSObject?          // UIRootSceneWindow
    public var rootView: UIView?
    public var isOpen: Bool = false

    public init?() {
        guard let sb = FVAppHelper.springBoardWindow() else { return nil }
        self.rootWindow = sb
        self.rootView = (sb.value(forKey: "rootView") as? UIView)
    }

    /// 把任意视图送进 RootScene 层级（在 Alert 之下、普通窗口之上）
    @discardableResult
    public func attach(_ view: UIView) -> Bool {
        guard let root = rootView ?? (rootWindow as? UIView) else { return false }
        root.addSubview(view)
        isOpen = true
        return true
    }

    public func detach(_ view: UIView) {
        view.removeFromSuperview()
        isOpen = false
    }
}
