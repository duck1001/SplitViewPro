// FVWindow.swift
// 对应原版：floatingView.FVWindow（UIWindow，windowLevel = 27.0）
// 原版 FVWindow 只有一个 ivar：_vc: FVViewController?

import UIKit

public final class FVWindow: UIWindow {
    public var _vc: FVViewController?

    public override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        windowLevel = UIWindow.Level(rawValue: 27.0)   // 实证：立即数 27.0
        backgroundColor = .clear
        isHidden = false
        let vc = FVViewController()
        rootViewController = vc
        _vc = vc
    }

    public required init?(coder: NSCoder) { fatalError() }
}

public final class FVViewController: UIViewController {
    public override func loadView() {
        let v = UIView()
        v.backgroundColor = .clear
        v.frame = UIScreen.main.bounds
        view = v
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true
        view.layer.masksToBounds = true
    }
}
