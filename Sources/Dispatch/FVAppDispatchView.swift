// FVAppDispatchView.swift
// 对应原版：floatingView.FVAppDispatchView（UIView）
// 字段：cardViews: [FVAppDispatchItem]、spacing、widthScale_withHeight、
//       sideCardMinWidth、sideCardMinHeight、angle、floatingViewRect: FVMiniViewRectInfo
//
// 三屏布局的本质：同一个 view 里放「1 个主屏卡 + N 个侧边卡」。

import UIKit

public final class FVAppDispatchView: UIView, FVSideCardDelegate {

    public var cardViews: [FVAppDispatchItem] = []
    public let spacing: CGFloat = 8
    public let widthScale_withHeight: CGFloat = 0.62
    public var sideCardMinWidth: CGFloat = 120
    public var sideCardMinHeight: CGFloat = 160
    public var angle: CGFloat = 0
    public var floatingViewRect = FVMiniViewRectInfo()

    public var onNeedFullScreen: ((_ bundleIdentifier: String) -> Void)?

    private var mainCard: FVAppDispatchItem? {
        cardViews.first { !$0.isSideCard }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        restoreLayout()
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    // MARK: - 打开 / 关闭

    public func present(bundleIdentifier: String, asSide: Bool = false) {
        let screen = FVScreenUtils.shared.mainBounds
        let size: CGSize
        if asSide {
            size = CGSize(width: max(sideCardMinWidth, screen.width * 0.30),
                          height: max(sideCardMinHeight, screen.height * 0.42))
        } else {
            size = CGSize(width: screen.width * widthScale_withHeight,
                          height: screen.height * widthScale_withHeight)
        }
        let origin: CGPoint
        if asSide {
            let count = cardViews.filter { $0.isSideCard }.count
            let x = count % 2 == 0 ? 8 : screen.width - size.width - 8
            origin = CGPoint(x: x, y: screen.midY - size.height / 2 + CGFloat(count) * spacing)
        } else {
            origin = CGPoint(x: screen.midX - size.width / 2, y: screen.midY - size.height / 2)
        }

        let item = FVAppDispatchItem(frame: CGRect(origin: origin, size: size),
                                     bundleIdentifier: bundleIdentifier)
        item.isSideCard = asSide
        item.sideCardDelegate = self
        item.onFullScreenRequest = { [weak self] in
            self?.onNeedFullScreen?(bundleIdentifier)
        }
        addSubview(item)
        cardViews.append(item)

        item.alpha = 0
        item.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        UIView.animate(withDuration: 0.32, delay: 0,
                       usingSpringWithDamping: 0.8, initialSpringVelocity: 0.6) {
            item.alpha = 1
            item.transform = .identity
        }
        refreshFloatingRect()
    }

    public func close(_ item: FVAppDispatchItem) {
        UIView.animate(withDuration: 0.22, animations: {
            item.alpha = 0
            item.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: { _ in
            item.reset()
            item.removeFromSuperview()
            self.cardViews.removeAll { $0 === item }
            self.refreshFloatingRect()
        })
    }

    // MARK: - 布局恢复（归一化）

    public func restoreLayout() {
        floatingViewRect = FVMiniViewRectInfo.load()
    }

    private func refreshFloatingRect() {
        let screen = FVScreenUtils.shared.mainBounds
        let f = FVMiniViewRectInfo.load()
        let w = screen.width * CGFloat(f.floatingViewHScale)
        let h = screen.height * CGFloat(f.floatingViewVScale)
        let cx = screen.width * CGFloat(f.floatingViewVCenterX)
        let cy = screen.height * CGFloat(f.floatingViewVCenterY)
        FVScreenUtils.shared.floatingRect = CGRect(x: cx - w/2, y: cy - h/2, width: w, height: h)
    }

    // MARK: - 交换主次屏

    public func swapMainAndSide() {
        let screen = FVScreenUtils.shared.mainBounds
        guard let main = mainCard else { return }
        let sides = cardViews.filter { $0.isSideCard }
        guard let firstSide = sides.first else { return }

        let oldMainFrame = main.frame
        let oldSideFrame = firstSide.frame
        firstSide.isSideCard = false
        main.isSideCard = true

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            main.frame = CGRect(x: screen.width - oldSideFrame.width - 8,
                                y: oldSideFrame.minY,
                                width: oldSideFrame.width, height: oldSideFrame.height)
            firstSide.frame = oldMainFrame
        }
    }

    // MARK: - 自动布局（原版 dispatchHostingView_mainItem_closed_donotAutoLayout）

    public func autoLayoutSideCards() {
        guard !FVPrefsStore.shared.bool(FVKey.mainClosedNoAutoLayout) else { return }
        let store = FVPrefsStore.shared
        let limit = max(1, store.int(FVKey.sideViewItemCount))
        let sides = Array(cardViews.filter { $0.isSideCard }.prefix(limit))
        let screen = FVScreenUtils.shared.mainBounds
        let left = store.int(FVKey.sideViewDisplayLocation) == 0

        for (i, item) in sides.enumerated() {
            let h = item.frame.height
            let y = screen.midY - h / 2 + CGFloat(i) * spacing
            let x = left ? 8 : screen.width - item.frame.width - 8
            UIView.animate(withDuration: 0.3) {
                item.frame.origin = CGPoint(x: x, y: y)
            }
        }
    }

    // MARK: - FVSideCardDelegate

    public func sideCardDidRequestAttach(_ item: FVAppDispatchItem) {
        item.isSideCard = true
        autoLayoutSideCards()
    }
    public func sideCardDidRequestDetach(_ item: FVAppDispatchItem) {
        item.isSideCard = false
    }
    public func sideCardDidChangeLocation(_ item: FVAppDispatchItem, to positionType: Int) {
        let screen = FVScreenUtils.shared.mainBounds
        let x = positionType == 0 ? 8 : screen.width - item.frame.width - 8
        UIView.animate(withDuration: 0.3) { item.frame.origin.x = x }
    }
}
