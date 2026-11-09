// FVFloatBallView.swift
// 对应原版：floatingView.FVFloatingActionView（继承 FVDisabledTaskScreenView）
// 字段（原版实证）：
//   imageView: UIImageView、badgeView: FVBadgeView、contentView: UIView?、
//   currentActivityApp: String、verticalCenterX/Y、horizontalCenterX/Y: Double
// 行为：三个手势 —— onClickImgWithSender: / onMoveImg: / longTouchWithSender:

import UIKit

// FVBadgeView 已移至 FVSmallComponents.swift

public final class FVFloatingActionView: FVDisabledTaskScreenView {

    public let imageView = UIImageView()
    public let badgeView = FVBadgeView()
    public var contentView: UIView?
    public var currentActivityApp: String = ""
    public var verticalCenterX: Double = 0.5
    public var verticalCenterY: Double = 0.5
    public var horizontalCenterX: Double = 0.5
    public var horizontalCenterY: Double = 0.5

    public var onTap: (() -> Void)?
    public var onLongPress: (() -> Void)?

    private var panStart: CGPoint = .zero

    public init(diameter: CGFloat = 52) {
        super.init(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        setup(diameter: diameter)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder); setup(diameter: 52) }

    private func setup(diameter: CGFloat) {
        let store = FVPrefsStore.shared
        backgroundColor = .black.withAlphaComponent(0.001)   // 几乎透明但能收触摸
        layer.cornerRadius = diameter / 2
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowOpacity = Float(store.double(FVKey.floatBallShadowOpacity))
        layer.shadowRadius = 6

        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.72),
            imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.72),
        ])

        badgeView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeView)
        NSLayoutConstraint.activate([
            badgeView.topAnchor.constraint(equalTo: topAnchor, constant: -2),
            badgeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 2),
            badgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 16),
            badgeView.heightAnchor.constraint(equalToConstant: 16),
        ])
        badgeView.isHidden = !store.bool(FVKey.floatBallShowBadge)

        // 三手势
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickImgWithSender(_:))))
        let long = UILongPressGestureRecognizer(target: self, action: #selector(longTouchWithSender(_:)))
        long.minimumPressDuration = 0.5
        addGestureRecognizer(long)
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onMoveImg(_:))))
    }

    @objc private func onClickImgWithSender(_ g: UITapGestureRecognizer) {
        FVFeedback.shared.impact(.light)
        onTap?()
    }
    @objc private func longTouchWithSender(_ g: UILongPressGestureRecognizer) {
        guard g.state == .began else { return }
        guard FVPrefsStore.shared.bool(FVKey.floatBallLongPressSide) else { return }
        FVFeedback.shared.impact(.medium)
        onLongPress?()
    }
    @objc private func onMoveImg(_ g: UIPanGestureRecognizer) {
        let screen = FVScreenUtils.shared.mainBounds
        switch g.state {
        case .began:
            panStart = center
        case .changed:
            let t = g.translation(in: superview)
            center = CGPoint(x: panStart.x + t.x, y: panStart.y + t.y)
        case .ended, .cancelled:
            // 吸附到最近的屏幕边缘（原版归一化落盘）
            let half = bounds.width / 2
            let targetX = center.x < screen.midX ? half + 8 : screen.width - half - 8
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.5) {
                self.center.x = targetX
            }
            verticalCenterX = Double(center.x / screen.width)
            horizontalCenterY = Double(center.y / screen.height)
            FVFileManager.write("\(verticalCenterX)", name: "verticalCenterX.txt")
            FVFileManager.write("\(horizontalCenterY)", name: "horizontalCenterY.txt")
        default: break
        }
    }
}
