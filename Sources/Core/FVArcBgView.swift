// FVArcBgView.swift —— 弧形背景（原版 1784 字节）
// 证据：func.00062238（366ln）有 setColors / setStartPoint / setEndPoint / addSublayer

import UIKit

public final class FVArcBgView: FVDisabledTaskScreenView {
    public var contentView: UIView?
    public var gradientLayer: CAGradientLayer?
    public let appIcon = UIImageView()

    public init(positionType: Int) {
        super.init(frame: FVScreenUtils.shared.mainBounds)
        setup(positionType: positionType)
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(positionType: 0)
    }

    private func setup(positionType: Int) {
        backgroundColor = .clear

        let cv = UIView(frame: bounds)
        cv.backgroundColor = .clear
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(cv)
        contentView = cv

        let g = CAGradientLayer()
        g.frame = bounds
        g.colors = [
            UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 0.92).cgColor,
            UIColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 0.75).cgColor,
        ]
        // 左右方向镜像
        if positionType == 0 {
            g.startPoint = CGPoint(x: 0, y: 0.5)
            g.endPoint   = CGPoint(x: 1, y: 0.5)
        } else {
            g.startPoint = CGPoint(x: 1, y: 0.5)
            g.endPoint   = CGPoint(x: 0, y: 0.5)
        }
        cv.layer.addSublayer(g)
        gradientLayer = g

        appIcon.contentMode = .scaleAspectFit
        appIcon.translatesAutoresizingMaskIntoConstraints = false
        cv.addSubview(appIcon)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds
    }

    public func fadeIn() {
        alpha = 0
        UIView.animate(withDuration: 0.25) { self.alpha = 1 }
    }
}
