// FVArcLayout.swift
// 对应原版：floatingView.FVArcLayout（UICollectionViewLayout）
// 字段：itemSize: CGSize、attributesList: [UICollectionViewLayoutAttributes]、
//       startAngle / endAngle / radius: CGFloat
//
// 排布算法（从 prepareLayout @ 0x56f48 反编译还原）：
//   mid  = collectionView.bounds 中心
//   step = (endAngle - startAngle) / (n - 1)
//   第 i 项 center = mid + radius * (cos θ, sin θ)      θ = startAngle + i*step

import UIKit

public final class FVArcLayout: UICollectionViewLayout {

    public var itemSize: CGSize = CGSize(width: 44, height: 44)
    public private(set) var attributesList: [UICollectionViewLayoutAttributes] = []
    public var startAngle: CGFloat = 0
    public var endAngle: CGFloat = .pi * 2
    public var radius: CGFloat = 100

    public override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }
        attributesList.removeAll(keepingCapacity: true)

        let mid = CGPoint(x: cv.bounds.midX, y: cv.bounds.midY)
        let n = cv.numberOfItems(inSection: 0)
        guard n > 0 else { return }

        let step: CGFloat = n >= 2 ? (endAngle - startAngle) / CGFloat(n - 1) : 0

        for i in 0..<n {
            let theta = startAngle + CGFloat(i) * step
            let attr = UICollectionViewLayoutAttributes(
                forCellWithIndexPath: IndexPath(item: i, section: 0))
            attr.size = itemSize
            // 原版调用 __sincos_stret；Swift 里直接用 sin/cos 等价（编译器会优化成同一条指令）
            let sf = sin(theta), cf = cos(theta)
            attr.center = CGPoint(x: mid.x + radius * cf, y: mid.y + radius * sf)
            attributesList.append(attr)
        }
    }

    public override var collectionViewContentSize: CGSize {
        collectionView?.bounds.size ?? .zero
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        attributesList
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.item < attributesList.count else { return nil }
        return attributesList[indexPath.item]
    }

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { true }
}
