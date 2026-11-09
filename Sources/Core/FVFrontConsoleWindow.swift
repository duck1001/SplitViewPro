// FVFrontConsoleWindow.swift
// 对应原版：floatingView.FVFrontConsoleWindow（UIWindow，windowLevel = 28.0）
// 操控台 / 搜索面板必须盖住浮窗（27）所以在 28。

import UIKit

public final class FVFrontConsoleWindow: UIWindow {
    public var _vc: FVFrontConsoleVC?

    public override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        windowLevel = UIWindow.Level(rawValue: 28.0)   // 实证：立即数 28.0
        backgroundColor = .clear
        isHidden = true                               // 默认隐藏，呼出时再显
        let vc = FVFrontConsoleVC()
        rootViewController = vc
        _vc = vc
    }

    public required init?(coder: NSCoder) { fatalError() }
}

public final class FVFrontConsoleVC: UIViewController {
    public override func loadView() {
        let v = UIView()
        v.backgroundColor = .clear
        v.frame = UIScreen.main.bounds
        view = v
    }
}
