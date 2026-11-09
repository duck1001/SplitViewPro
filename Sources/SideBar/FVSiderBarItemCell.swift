// FVSiderBarItemCell.swift
// 对应原版：floatingView.FVSiderBarItemCell（UICollectionViewCell）
// 字段：imageView: FVAppIconView、bundleIdentifier: String

import UIKit

public final class FVAppIconView: UIImageView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .scaleAspectFit
        layer.cornerRadius = 12
        layer.masksToBounds = true
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

public final class FVSiderBarItemCell: UICollectionViewCell {
    public let imageView = FVAppIconView()
    public var bundleIdentifier: String = ""

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.86),
            imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.86),
        ])
    }
    public required init?(coder: NSCoder) { fatalError() }

    public func configure(bundleIdentifier bid: String) {
        self.bundleIdentifier = bid
        imageView.image = FVAppHelper.icon(for: bid)
    }
}
