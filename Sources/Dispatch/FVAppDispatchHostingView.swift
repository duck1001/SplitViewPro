// FVAppDispatchHostingView.swift
// 对应原版：floatingView.FVAppDispatchHostingView（UIView）
// 与 FVHostingView 的区别：它是浮窗卡片内部的真正容器，
// 额外带 snapshotView，且在拖拽结束时用 alpha 动画收尾（原版 7 个方法）。

import UIKit

public final class FVAppDispatchHostingView: FVHostingView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 8
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    public func setDragHighlight(_ on: Bool) {
        UIView.animate(withDuration: 0.12) {
            self.alpha = on ? 0.75 : 1.0
        }
    }
}
