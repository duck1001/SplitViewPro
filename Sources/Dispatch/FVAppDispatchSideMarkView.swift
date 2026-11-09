// FVAppDispatchSideMarkView.swift
// 对应原版：floatingView.FVAppDispatchSideMarkView（UIImageView）
// 就是浮窗上那三条细窄的视觉提示条（markView / moveBar / topMoveBar）。

import UIKit

public final class FVAppDispatchSideMarkView: UIImageView {
    public enum Kind { case mark, moveBar, topMoveBar }
    public let kind: Kind

    public init(kind: Kind) {
        self.kind = kind
        super.init(frame: .zero)
        contentMode = .scaleToFill
        backgroundColor = UIColor.white.withAlphaComponent(0.0)
        layer.cornerRadius = kind == .mark ? 2 : 1
        isUserInteractionEnabled = false
    }
    public required init?(coder: NSCoder) { fatalError() }

    public func setVisible(_ on: Bool) {
        UIView.animate(withDuration: 0.18) {
            self.alpha = on ? 1 : 0
        }
    }
}
