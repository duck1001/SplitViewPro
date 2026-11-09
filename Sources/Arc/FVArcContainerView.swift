// FVArcContainerView.swift
// 对应原版：floatingView.FVArcContainerView（继承 FVDisabledTaskScreenView : UITextField）
// 字段：mainBounds: CGRect、terracelList: [FVArcTerraceItem]、
//       maxTranslationWithHand: CGFloat、totalViews: Int、isDisplay: Bool、
//       positionType: Int、contentView: UIView?

import UIKit

public final class FVArcContainerView: FVDisabledTaskScreenView {

    public var mainBounds: CGRect = .zero
    public var terracelList: [FVArcTerraceItem] = []
    public var maxTranslationWithHand: CGFloat = 0
    public var totalViews: Int = 0
    public var isDisplay: Bool = false
    public var positionType: Int = 0
    public var contentView: UIView?

    public var onExecuteApp: ((_ bundleIdentifier: String) -> Void)?
    public var onExecuteTool: ((_ action: FVToolAction) -> Void)?

    private var currentHighlight: (level: Int, index: Int)?
    private let feedback = FVFeedback.shared

    // MARK: - 初始化

    public init(positionType: Int) {
        self.positionType = positionType
        self.mainBounds = UIScreen.main.bounds
        super.init(frame: mainBounds)
        setup()
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        frame = FVScreenUtils.shared.mainBounds
        backgroundColor = .clear
        alpha = 0
        isHidden = true

        let cv = UIView(frame: bounds)
        cv.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(cv)
        contentView = cv

        maxTranslationWithHand = bounds.width
        buildTerraces()
    }

    // MARK: - 构建各层

    private func buildTerraces() {
        let store = FVPrefsStore.shared
        let appLevels = max(1, min(4, store.int(FVKey.arcAppLevelCount)))
        let toolLevels = max(1, min(3, store.int(FVKey.arcToolLevelCount)))

        var all: [FVArcTerraceItem] = []
        for lv in 1...appLevels {
            let t = FVArcTerraceItem(levelNum: lv, positionType: positionType)
            t.setItems(FVArcDataSource.shared.appItems(level: lv))
            contentView?.addSubview(t)
            t.frame = bounds
            all.append(t)
        }
        for lv in 1...toolLevels {
            let t = FVArcTerraceItem(levelNum: lv, positionType: positionType)
            t.setItems(FVArcDataSource.shared.toolItems(level: lv))
            contentView?.addSubview(t)
            t.frame = bounds
            all.append(t)
        }
        terracelList = all
        totalViews = all.reduce(0) { $0 + $1.arcList.count }

        // 半径按层递增（原版 arcAppRadius_level_N）
        for t in all {
            t.layout?.radius = CGFloat(store.double(FVKey.arcAppRadius(t.levelNum)))
        }
    }

    // MARK: - 显示 / 隐藏

    public func show(at center: CGPoint) {
        // 把 collectionView 的中心挪到手指位置（原版 prepareLayout 用 bounds 中心）
        for t in terracelList {
            t.frame = CGRect(x: center.x - bounds.width / 2,
                             y: center.y - bounds.height / 2,
                             width: bounds.width, height: bounds.height)
            t.collectionView?.collectionViewLayout.invalidateLayout()
            t.collectionView?.reloadData()
        }
        isDisplay = true
        isHidden = false
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
            self.alpha = 1
            for t in self.terracelList {
                t.transform = .identity
            }
        }
    }

    public func hide() {
        isDisplay = false
        currentHighlight = nil
        UIView.animate(withDuration: 0.16, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.isHidden = true
        })
    }

    // MARK: - 触摸移动（由 FVIOEvent / FVGestureUtils 驱动）

    public func updateTouch(at p: CGPoint) {
        var hit: (level: Int, index: Int)?
        for (li, t) in terracelList.enumerated() {
            if let idx = t.itemIndex(at: p) {
                hit = (li, idx)
                break       // 内层优先
            }
        }
        if let h = hit {
            if currentHighlight?.index != h.index || currentHighlight?.level != h.level {
                currentHighlight = h
                for (li, t) in terracelList.enumerated() {
                    t.setHighlighted(index: li == h.level ? h.index : nil)
                }
                if FVPrefsStore.shared.bool(FVKey.arcVibrationFeedback) {
                    feedback.impact(.light)
                }
            }
        } else if currentHighlight != nil {
            currentHighlight = nil
            terracelList.forEach { $0.setHighlighted(index: nil) }
        }
    }

    /// 松手时执行
    public func commitTouch() {
        defer { hide() }
        guard let h = currentHighlight, h.level < terracelList.count else { return }
        let terrace = terracelList[h.level]
        guard h.index < terrace.arcList.count, let item = terrace.arcList[h.index] else { return }

        switch item {
        case .app(let info):
            feedback.impact(.medium)
            onExecuteApp?(info.appBundleId)
        case .tool(let info):
            feedback.impact(.medium)
            if let action = FVToolAction(iconName: info.iconName) {
                onExecuteTool?(action)
            }
        }
    }
}
