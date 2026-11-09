// FVAppDispatchItem.swift
// 对应原版：floatingView.FVAppDispatchItem（UIView <UIGestureRecognizerDelegate>）
// 字段（名字/含义一一对应）：
//   bundleIdentifier, fromPoint, toPoint, intersectWithDragLabel,
//   markView, moveBar, topMoveBar, sourceAppBID, scale, isSideCard,
//   sideCardDelegate, initialDistance, innerKeyboardIsDisplay,
//   recordOnlyInnerKeyboardIsShow, swipe_directions, hostingView
//
// 手势分四组（原版 selector 证据）：
//   onDragEvent:      顶部/底部条拖动
//   onResizeEvent:    四角缩放
//   onClickCornerEvent: / onClickMainHostingView:  点击
//   handleSwipe:      四方向滑动

import UIKit

public protocol FVSideCardDelegate: AnyObject {
    func sideCardDidRequestAttach(_ item: FVAppDispatchItem)
    func sideCardDidRequestDetach(_ item: FVAppDispatchItem)
    func sideCardDidChangeLocation(_ item: FVAppDispatchItem, to positionType: Int)
}

public final class FVAppDispatchItem: UIView, UIGestureRecognizerDelegate {

    // MARK: - 字段（与原版一一对应）

    public var bundleIdentifier: String = ""
    public var fromPoint: CGPoint?
    public var toPoint: CGPoint?
    public var intersectWithDragLabel = false
    public var markView: FVAppDispatchSideMarkView?
    public var moveBar: FVAppDispatchSideMarkView?
    public var topMoveBar: FVAppDispatchSideMarkView?
    public var sourceAppBID: String = ""
    public var scale: Double = 1.0
    public var isSideCard = false
    public weak var sideCardDelegate: FVSideCardDelegate?
    public var initialDistance: CGFloat = 0
    public var innerKeyboardIsDisplay = false
    public var recordOnlyInnerKeyboardIsShow = false
    public var swipe_directions: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
    public let hostingView: FVAppDispatchHostingView

    // MARK: - 回调

    public var onClickTop: (() -> Void)?
    public var onClickBottom: (() -> Void)?
    public var onSwipe: ((UISwipeGestureRecognizer.Direction) -> Void)?
    public var onFullScreenRequest: (() -> Void)?
    public var onFrameChanged: ((CGRect) -> Void)?

    private var dragStartCenter: CGPoint = .zero
    private var resizeCorner: Int = -1

    // MARK: - 初始化

    public init(frame: CGRect, bundleIdentifier: String, sourceAppBID: String = "") {
        self.bundleIdentifier = bundleIdentifier
        self.sourceAppBID = sourceAppBID.isEmpty ? bundleIdentifier : sourceAppBID
        self.hostingView = FVAppDispatchHostingView(frame: CGRect(origin: .zero, size: frame.size))
        super.init(frame: frame)
        setup()
    }
    public required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        clipsToBounds = false
        backgroundColor = .clear
        layer.cornerRadius = 22
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowOpacity = Float(FVPrefsStore.shared.double(FVKey.shadowOpacity))
        layer.shadowRadius  = CGFloat(FVPrefsStore.shared.double(FVKey.shadowRange))

        hostingView.frame = bounds
        hostingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingView.layer.cornerRadius = 22
        hostingView.layer.masksToBounds = true
        hostingView.setApp(bundleIdentifier: bundleIdentifier, dynamic: true)
        addSubview(hostingView)

        // 三条视觉提示条
        let mark = FVAppDispatchSideMarkView(kind: .mark)
        let mv   = FVAppDispatchSideMarkView(kind: .moveBar)
        let tmv  = FVAppDispatchSideMarkView(kind: .topMoveBar)
        markView = mark; moveBar = mv; topMoveBar = tmv
        [mark, mv, tmv].forEach { addSubview($0); $0.alpha = 0 }

        installGestures()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        hostingView.frame = bounds
        // 顶部/底部条：高度分别等于状态栏 / 黑条
        let sbH = FVScreenUtils.shared.statusBarHeight
        let bh  = FVScreenUtils.shared.bottomIndicatorHeight
        topMoveBar?.frame = CGRect(x: 0, y: 0, width: bounds.width, height: max(sbH, 24))
        moveBar?.frame    = CGRect(x: 0, y: bounds.height - max(bh, 24),
                                   width: bounds.width, height: max(bh, 24))
        markView?.frame   = CGRect(x: bounds.width / 2 - 18, y: bounds.height - 4,
                                   width: 36, height: 3)
        onFrameChanged?(frame)
    }

    // MARK: - 手势安装（4 组）

    private func installGestures() {
        // 1) 顶部拖动
        let topPan = UIPanGestureRecognizer(target: self, action: #selector(onDragEvent(_:)))
        topPan.delegate = self
        topMoveBar?.addGestureRecognizer(topPan)
        topMoveBar?.isUserInteractionEnabled = true

        // 2) 底部拖动
        let botPan = UIPanGestureRecognizer(target: self, action: #selector(onDragEvent(_:)))
        botPan.delegate = self
        moveBar?.addGestureRecognizer(botPan)
        moveBar?.isUserInteractionEnabled = true

        // 3) 四角缩放
        let corners = ["lt", "rt", "lb", "rb"]
        for (i, _) in corners.enumerated() {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(onResizeEvent(_:)))
            pan.delegate = self
            pan.name = "corner\(i)"     // 原版也用 name 区分
            addGestureRecognizer(pan)
        }

        // 4) 点击（顶部 / 底部 / 主体）
        let tapTop = UITapGestureRecognizer(target: self, action: #selector(onClickCornerEvent(_:)))
        tapTop.name = "top"
        topMoveBar?.addGestureRecognizer(tapTop)

        let tapBottom = UITapGestureRecognizer(target: self, action: #selector(onClickCornerEvent(_:)))
        tapBottom.name = "bottom"
        moveBar?.addGestureRecognizer(tapBottom)

        let tapMain = UITapGestureRecognizer(target: self, action: #selector(onClickMainHostingView(_:)))
        hostingView.addGestureRecognizer(tapMain)

        // 5) 四方向滑动
        for dir in swipe_directions {
            let sw = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            sw.direction = dir
            hostingView.addGestureRecognizer(sw)
        }
    }

    // MARK: - 拖动（原版 onDragEvent:）

    @objc private func onDragEvent(_ g: UIPanGestureRecognizer) {
        let t = g.translation(in: superview)
        switch g.state {
        case .began:
            dragStartCenter = center
            markView?.setVisible(true)
            if FVPrefsStore.shared.bool(FVKey.mainMoveBottomFeedback) {
                FVFeedback.shared.impact(.light)
            }
        case .changed:
            center = CGPoint(x: dragStartCenter.x + t.x, y: dragStartCenter.y + t.y)
            // 是否与底部热区相交 → 原版：convertRect:toView: + intersectWithDragLabel
            let screen = FVScreenUtils.shared.mainBounds
            let bh = FVScreenUtils.shared.bottomIndicatorHeight
            let bottomZone = CGRect(x: screen.midX - screen.width * 0.15,
                                    y: screen.height - bh - 60,
                                    width: screen.width * 0.3,
                                    height: bh + 60)
            intersectWithDragLabel = frame.intersects(bottomZone)
            hostingView.setDragHighlight(intersectWithDragLabel)
        case .ended, .cancelled:
            markView?.setVisible(false)
            hostingView.setDragHighlight(false)
            if intersectWithDragLabel &&
                FVPrefsStore.shared.bool(FVKey.mainMoveBottomFull) {
                onFullScreenRequest?()
                return
            }
            // 弹簧回弹（原版：animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:）
            UIView.animate(withDuration: 0.45, delay: 0,
                           usingSpringWithDamping: 0.75,
                           initialSpringVelocity: 0.5,
                           options: [.allowUserInteraction]) {
                self.transform = .identity
            }
            commitFrame()
        default: break
        }
    }

    // MARK: - 四角缩放（原版 onResizeEvent:）

    @objc private func onResizeEvent(_ g: UIPanGestureRecognizer) {
        guard let idxStr = g.name, let idx = Int(idxStr.replacingOccurrences(of: "corner", with: ""))
        else { return }
        let t = g.translation(in: superview)
        switch g.state {
        case .began:
            resizeCorner = idx
            initialDistance = max(1, hypot(bounds.width, bounds.height) / 2)
        case .changed:
            // 按时角算方向符号
            let sx: CGFloat = (idx == 1 || idx == 3) ? 1 : -1     // rt / rb 朝右
            let sy: CGFloat = (idx >= 2) ? 1 : -1                // lb / rb 朝下
            let delta = (sx * t.x + sy * t.y) / 2 / initialDistance
            scale = max(0.35, min(1.6, scale + Double(delta) * 0.02))
            transform = CGAffineTransform(scaleX: scale, y: scale)
        case .ended, .cancelled:
            resizeCorner = -1
            UIView.animate(withDuration: 0.3, delay: 0,
                           usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4) {
                self.transform = .identity
            }
            commitFrame()
        default: break
        }
    }

    // MARK: - 点击

    @objc private func onClickCornerEvent(_ g: UITapGestureRecognizer) {
        if g.name == "top" { onClickTop?() } else { onClickBottom?() }
    }

    @objc private func onClickMainHostingView(_ g: UITapGestureRecognizer) {
        // 原版：把点击透传给 App 内部（不拦截）
        // 这里只在需要时触发「点击浮窗外部事件」的反向逻辑
    }

    // MARK: - 滑动（原版 handleSwipe: → 读 direction 分派）

    @objc private func handleSwipe(_ g: UISwipeGestureRecognizer) {
        onSwipe?(g.direction)
    }

    // MARK: - 手势并发

    public func gestureRecognizer(_ g: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    // MARK: - 位置持久化（原版写 6 个 txt，归一化）

    private func commitFrame() {
        let screen = FVScreenUtils.shared.mainBounds
        guard screen.width > 0, screen.height > 0 else { return }
        var info = FVMiniViewRectInfo.load()
        info.floatingViewVCenterX = Double(center.x / screen.width)
        info.floatingViewVCenterY = Double(center.y / screen.height)
        info.floatingViewHScale   = Double(bounds.width / screen.width)
        info.floatingViewVScale   = Double(bounds.height / screen.height)
        info.save()
        FVScreenUtils.shared.floatingRect = frame
    }
}
