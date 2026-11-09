// FVSnapshotView.swift
// 对应原版：floatingView.FVSnapshotView
// 字段只有两个：isLoading: Bool、snapshotView: UIImageView
// 作用：scene 首帧到达前显示 App 图标占位，避免白块。

import UIKit

public final class FVSnapshotView: UIView {
    public var isLoading: Bool = false
    public let snapshotView = UIImageView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        clipsToBounds = true
        snapshotView.contentMode = .scaleAspectFill
        snapshotView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(snapshotView)
        NSLayoutConstraint.activate([
            snapshotView.topAnchor.constraint(equalTo: topAnchor),
            snapshotView.leadingAnchor.constraint(equalTo: leadingAnchor),
            snapshotView.trailingAnchor.constraint(equalTo: trailingAnchor),
            snapshotView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    /// 用 bundleIdentifier 生成占位（原版常量：bundleIdentifier / setImage:）
    public func load(bundleIdentifier: String) {
        isLoading = true
        snapshotView.image = FVAppHelper.icon(for: bundleIdentifier)
        isLoading = false
    }

    public func show(_ visible: Bool) {
        snapshotView.isHidden = !visible
        isHidden = !visible
    }
}
