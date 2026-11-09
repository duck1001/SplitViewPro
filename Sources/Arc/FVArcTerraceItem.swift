// FVArcTerraceItem.swift
// 对应原版：floatingView.FVArcTerraceItem（UIView <UICollectionViewDataSource>）
// 字段：collectionView、arcList: [FVArcItemType?]、levelNum、layout: FVArcLayout?、
//       selectedIndexPath: IndexPath?、touchImg: UIImage?、positionType: Int

import UIKit

public final class FVArcTerraceItem: UIView, UICollectionViewDataSource {

    public var collectionView: UICollectionView?
    public var arcList: [FVArcItemType?] = []
    public var levelNum: Int = 1
    public var layout: FVArcLayout?
    public var selectedIndexPath: IndexPath?
    public var touchImg: UIImage?
    public var positionType: Int = 0    // 0=左 1=右

    public var onSelect: ((_ index: Int) -> Void)?
    public var onHighlight: ((_ index: Int) -> Void)?

    private let cellID = "FVArcItem"

    public init(levelNum: Int, positionType: Int) {
        self.levelNum = levelNum
        self.positionType = positionType
        super.init(frame: .zero)
        setup()
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        isUserInteractionEnabled = false   // 触摸由 FVArcContainerView 统一处理

        let store = FVPrefsStore.shared
        let lay = FVArcLayout()
        lay.itemSize = CGSize(width: store.double(FVKey.arcAppDisplayItemSize(levelNum)),
                              height: store.double(FVKey.arcAppDisplayItemSize(levelNum)))
        lay.radius = CGFloat(store.double(FVKey.arcAppRadius(levelNum)))

        // 角度范围：左半圆 / 右半圆（原版用 positionType 区分）
        if positionType == 0 {          // 左侧：从 90° 到 270°
            lay.startAngle = .pi / 2
            lay.endAngle = .pi * 3 / 2
        } else {                        // 右侧：从 -90° 到 90°
            lay.startAngle = -.pi / 2
            lay.endAngle = .pi / 2
        }
        self.layout = lay

        let cv = UICollectionView(frame: .zero, collectionViewLayout: lay)
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.register(FVArcItem.self, forCellWithReuseIdentifier: cellID)
        cv.isScrollEnabled = false
        cv.isUserInteractionEnabled = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cv)
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: topAnchor),
            cv.leadingAnchor.constraint(equalTo: leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: trailingAnchor),
            cv.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        self.collectionView = cv
    }

    // MARK: - 数据

    public func setItems(_ items: [FVArcItemType?]) {
        arcList = items
        collectionView?.reloadData()
        collectionView?.collectionViewLayout.invalidateLayout()
    }

    /// 手指位置 -> 命中的 item（原版：indexPathForItemAtPoint: / pointValue 判定）
    public func itemIndex(at point: CGPoint) -> Int? {
        guard let cv = collectionView else { return nil }
        let p = convert(point, to: cv)
        // 遍历所有 attribute，找距离最近的且落在 itemSize 半径内
        var best: (Int, CGFloat)?
        for (i, attr) in (layout?.attributesList ?? []).enumerated() {
            let d = hypot(p.x - attr.center.x, p.y - attr.center.y)
            if d <= attr.size.width * 0.75 {
                if best == nil || d < best!.1 { best = (i, d) }
            }
        }
        return best?.0
    }

    public func setHighlighted(index: Int?) {
        selectedIndexPath = index.map { IndexPath(item: $0, section: 0) }
        for case let cell as FVArcItem in (collectionView?.visibleCells ?? []) {
            if let ip = collectionView?.indexPath(for: cell) {
                cell.setHighlighted(ip.item == index)
            }
        }
    }

    // MARK: - UICollectionViewDataSource

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        arcList.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath)
        guard let arcCell = cell as? FVArcItem else { return cell }
        arcCell.levelNum = levelNum
        arcCell.pointValue = indexPath.item
        if indexPath.item < arcList.count, let type = arcList[indexPath.item] {
            arcCell.configure(with: type)
        }
        return arcCell
    }
}
