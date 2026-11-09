// FVScreenUtils.swift
// 对应原版：floatingView.FVScreenUtils
// 字段：mainBounds: CGRect、currentInterface: Int、leftArc/rightArc: FVArcContainerView?
// 单例，全局唯一真相源（屏幕几何 + 当前接口 + 两个环形菜单实例）。

import UIKit

public final class FVScreenUtils {
    public static let shared = FVScreenUtils()

    public private(set) var mainBounds: CGRect = UIScreen.main.bounds
    public var currentInterface: Int = 0          // 0=竖屏 1=横屏 左 2=横屏 右
    public var leftArc: FVArcContainerView?
    public var rightArc: FVArcContainerView?

    private init() { refresh() }

    // MARK: - 几何

    public func refresh() {
        mainBounds = UIScreen.main.bounds
        if #available(iOS 13.0, *) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                mainBounds = scene.coordinateSpace.bounds
            }
        }
    }

    public var statusBarHeight: CGFloat {
        if #available(iOS 13.0, *),
           let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let status = scene.statusBarManager {
            return status.statusBarFrame.height
        }
        return UIApplication.shared.statusBarFrame.height
    }

    /// 系统底部黑条（Home Indicator）高度，用于「拖到底部全屏打开」热区
    public var bottomIndicatorHeight: CGFloat {
        let bottomInset = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 34
        return max(bottomInset, 34)
    }

    // MARK: - 浮窗矩形（决定「点击浮窗外部」判定）

    public var floatingRect: CGRect = .zero

    public func contains(_ p: CGPoint) -> Bool {
        floatingRect != .zero && floatingRect.contains(p)
    }

    // MARK: - 屏幕旋转

    public func updateInterface(orientation: UIInterfaceOrientation) {
        switch orientation {
        case .landscapeLeft:  currentInterface = 1
        case .landscapeRight: currentInterface = 2
        default:              currentInterface = 0
        }
        refresh()
    }
}
