// FVRootView.swift —— 渐变根视图（原版 1132 字节）
// 证据：func.0003509c（279ln）setColors / setStartPoint / setEndPoint / addSublayer

import UIKit

public final class FVRootView: UIView {
    public let gradientLayer = CAGradientLayer()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.frame = bounds
        gradientLayer.colors = [
            UIColor(white: 0.10, alpha: 1).cgColor,
            UIColor(white: 0.02, alpha: 1).cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)     // 垂直
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientLayer)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
