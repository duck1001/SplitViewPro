// FVSideBarContainerView.swift
// 对应原版：floatingView.FVSideBarContainerView
//          （继承 FVDisabledTaskScreenView : UITextField <UIGestureRecognizerDelegate>）
// 字段：contentView: FVSideBarContentView?、fromPointValue: CGPoint、toPointValue: CGPoint、isOpened: Bool

import UIKit

public final class FVSideBarContainerView: FVDisabledTaskScreenView, UIGestureRecognizerDelegate {

    public var contentView: FVSideBarContentView?
    public var fromPointValue: CGPoint = .zero
    public var toPointValue: CGPoint = .zero
    public var isOpened = false

    /// 0 = 贴左边缘，1 = 贴右边缘
    public var positionType: Int = 0

    public var onSelectApp: ((_ bundleIdentifier: String) -> Void)?

    private var pan: UIPanGestureRecognizer?

    // MARK: - 初始化

    public init(positionType: Int) {
        self.positionType = positionType
        super.init(frame: FVScreenUtils.shared.mainBounds)
        setup()
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let screen = FVScreenUtils.shared.mainBounds
        let store = FVPrefsStore.shared
        let width = CGFloat(store.double(FVKey.sideBarWidth))
        let factor = FVScreenUtils.shared.currentInterface == 0
            ? CGFloat(store.double(FVKey.sideBarHeightVer))
            : CGFloat(store.double(FVKey.sideBarHeightHor))
        let height = screen.height * max(0.2, min(1.0, factor))

        // 初始位置：贴在屏幕对应侧的屏幕外（收起状态）
        let x: CGFloat = positionType == 0 ? -(width + 12) : screen.width + 12
        frame = CGRect(x: x, y: screen.midY - height / 2, width: width, height: height)

        backgroundColor = .clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowOpacity = Float(store.double(FVKey.sideBarShadowOpacity))
        layer.shadowRadius  = CGFloat(store.double(FVKey.sideBarShadowRange))

        let cv = FVSideBarContentView(frame: bounds)
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cv.gridCellDelegate = self
        cv.layer.cornerRadius = 14
        cv.layer.masksToBounds = true
        cv.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.92)
        addSubview(cv)
        contentView = cv

        // 数据来源：allApps（设置里「侧边栏自定义应用排序」写入）
        let apps = store.array(FVKey.allApps, as: String.self)
        cv.setData(apps.isEmpty ? defaultApps() : apps)
        cv.layoutSubviews(with: CGSize(width: width - 8,
                                       height: CGFloat(store.double(FVKey.sideBarAppIconSize))))

        // 拖拽手势（从边缘拉出）
        let p = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        p.delegate = self
        addGestureRecognizer(p)
        pan = p
    }

    private func defaultApps() -> [String] {
        ["com.apple.mobilesafari", "com.apple.MobileSMS",
         "com.apple.mobilemail", "com.apple.camera"]
    }

    // MARK: - 展开 / 收起

    public func open(animated: Bool = true) {
        guard !isOpened else { return }
        let screen = FVScreenUtils.shared.mainBounds
        let targetX: CGFloat = positionType == 0 ? 6 : screen.width - bounds.width - 6
        isOpened = true
        let block = { self.frame.origin.x = targetX }
        animated ? UIView.animate(withDuration: 0.26, delay: 0,
                                  usingSpringWithDamping: 0.82,
                                  initialSpringVelocity: 0.5, animations: block)
                 : block()
    }

    public func close(animated: Bool = true) {
        guard isOpened else { return }
        let screen = FVScreenUtils.shared.mainBounds
        let targetX: CGFloat = positionType == 0 ? -(bounds.width + 12) : screen.width + 12
        isOpened = false
        let block = { self.frame.origin.x = targetX }
        animated ? UIView.animate(withDuration: 0.24, animations: block) : block()
    }

    public func toggle() { isOpened ? close() : open() }

    // MARK: - 手势

    @objc private func onPan(_ g: UIPanGestureRecognizer) {
        let t = g.translation(in: superview)
        switch g.state {
        case .began:
            fromPointValue = g.location(in: superview)
        case .changed:
            toPointValue = g.location(in: superview)
            let dirOut: CGFloat = positionType == 0 ? 1 : -1
            let dx = t.x * dirOut
            if dx > 0 && !isOpened {
                frame.origin.x = (positionType == 0 ? -(bounds.width + 12) : FVScreenUtils.shared.mainBounds.width + 12) + dx
            } else if isOpened {
                frame.origin.x = (positionType == 0 ? 6 : FVScreenUtils.shared.mainBounds.width - bounds.width - 6) + t.x
            }
        case .ended, .cancelled:
            let dirOut: CGFloat = positionType == 0 ? 1 : -1
            if t.x * dirOut > bounds.width * 0.25 || g.velocity(in: superview).x * dirOut > 300 {
                isOpened ? close() : open()
            } else {
                isOpened ? open() : close()
            }
        default: break
        }
    }

    // 原版：gestureRecognizer:shouldReceiveTouch: 只在自己可见区域收触摸
    public func gestureRecognizer(_ g: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let p = touch.location(in: self)
        return bounds.contains(p)
    }
}

extension FVSideBarContainerView: FVGridCellDelegate {
    public func gridCellDidSelect(bundleIdentifier: String) {
        FVFeedback.shared.impact(.light)
        onSelectApp?(bundleIdentifier)
    }
}
