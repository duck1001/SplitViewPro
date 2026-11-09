// FVSmallComponents.swift
// 小件集合：FVBadgeView / FVLoadingView / FVButton / FVResizeMaskView / FVDragLabelView
//            FVBottomView / FVBottomToolBar / FVBottomSideBar / FVBroadsideView
//            FVFrontConsoleContainer
// 每个都标注了对应的原版字节数与关键证据。

import UIKit

// MARK: - FVBadgeView（640 字节）

public final class FVBadgeView: UIView {
    public let labelText = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear                    // 证据：clearColor
        layer.cornerRadius = 9
        layer.masksToBounds = true
        labelText.font = .systemFont(ofSize: 11, weight: .bold)
        labelText.textColor = .white                // 证据：setTextColor
        labelText.textAlignment = .center
        labelText.translatesAutoresizingMaskIntoConstraints = false
        addSubview(labelText)
        NSLayoutConstraint.activate([
            labelText.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelText.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        isHidden = true
    }

    /// 证据：func.00039864 的 setText
    public func setBadge(_ text: String?, color: UIColor = .systemRed) {
        backgroundColor = color
        labelText.text = text
        isHidden = (text == nil || text!.isEmpty)
    }
}

// MARK: - FVLoadingView（UIActivityIndicatorView）

public final class FVLoadingView: UIActivityIndicatorView {
    public init(style: UIActivityIndicatorView.Style = .medium) {
        super.init(style: style)
        hidesWhenStopped = true                    // 证据：setHidesWhenStopped
        color = .systemBlue
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        hidesWhenStopped = true
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

// MARK: - FVButton（UIButton）

public final class FVButton: UIButton {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

// MARK: - FVResizeMaskView（缩放遮罩）

public final class FVResizeMaskView: UIView {
    public let imageView = UIImageView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        // 证据：setImage / setContentMode
        imageView.image = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.white.withAlphaComponent(0.7)
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(imageView)
        isUserInteractionEnabled = false
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

// MARK: - FVDragLabelView（底部拖拽指示条，340 字节）

public final class FVDragLabelView: UIView {
    /// 原版 ivar：标识属于哪个界面
    public var interfaceNum: Int = 0

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    /// 证据：func.0003c1e8 的 convertRect —— 被拖动判定调用
    public func rectInWindow() -> CGRect {
        convert(bounds, to: nil)
    }
}

// MARK: - FVBottomToolBar（UIStackView，143 行核心）

public final class FVBottomToolBar: UIStackView {
    public var onTap: ((_ index: Int) -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .horizontal
        distribution = .fillEqually
        alignment = .center
        spacing = 6
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    public func setItems(_ symbols: [String]) {
        arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (i, s) in symbols.enumerated() {
            let b = UIButton(type: .system)
            b.setImage(UIImage(systemName: s), for: .normal)
            b.tintColor = .white
            b.tag = i
            b.addTarget(self, action: #selector(onClickBar(_:)), for: .touchUpInside)
            addArrangedSubview(b)
            b.widthAnchor.constraint(equalToConstant: 36).isActive = true   // 证据：setActive
        }
    }

    @objc private func onClickBar(_ b: UIButton) {
        FVFeedback.shared.impact(.light)
        onTap?(b.tag)
    }
}

// MARK: - FVBottomSideBar（UIStackView，含 isTop 字段）

public final class FVBottomSideBar: UIStackView {
    public var isTop = false
    public var onTap: ((_ bundleIdentifier: String) -> Void)?
    private var ids: [String] = []

    public override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .horizontal
        distribution = .fillEqually
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    public func setApps(_ bundleIdentifiers: [String]) {
        ids = bundleIdentifiers
        arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (i, bid) in bundleIdentifiers.enumerated() {
            let b = UIButton(type: .system)
            b.setImage(FVAppHelper.icon(for: bid), for: .normal)
            b.tag = i
            b.addTarget(self, action: #selector(onClickBar(_:)), for: .touchUpInside)
            addArrangedSubview(b)
            b.widthAnchor.constraint(equalToConstant: 40).isActive = true
        }
    }

    @objc private func onClickBar(_ b: UIButton) {
        guard b.tag < ids.count else { return }
        FVFeedback.shared.impact(.light)
        onTap?(ids[b.tag])
    }
}

// MARK: - FVBottomView（6664 字节）

public final class FVBottomView: UIView {
    public var toolBar: FVBottomToolBar?
    public var contentView: FVBottomGridView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        let tb = FVBottomToolBar()
        tb.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tb)
        NSLayoutConstraint.activate([
            tb.leadingAnchor.constraint(equalTo: leadingAnchor),
            tb.trailingAnchor.constraint(equalTo: trailingAnchor),
            tb.bottomAnchor.constraint(equalTo: bottomAnchor),
            tb.heightAnchor.constraint(equalToConstant: 44),
        ])
        toolBar = tb
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

// MARK: - FVBroadsideView（3596 字节，侧边横排）

public final class FVBroadsideView: UIView {
    public var subviewsList: [FVHostingView] = []
    public var onTapItem: ((_ bid: String) -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    /// 证据：func.0003a560（437ln）
    public func add(_ bundleIdentifier: String) {
        let h = FVHostingView(frame: .zero)
        h.setApp(bundleIdentifier: bundleIdentifier)
        addSubview(h)
        subviewsList.append(h)
        relayout(animated: true)
    }

    /// 证据：func.0003aaa8（387ln）
    public func removeAllItems() {
        for v in subviewsList {
            UIView.animate(withDuration: 0.22, animations: {
                v.alpha = 0
                v.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }, completion: { _ in v.removeFromSuperview() })
        }
        subviewsList.removeAll()
    }

    @objc private func onClickItemViewWithSender(_ g: UITapGestureRecognizer) {
        onTapItem?("")
    }

    private func relayout(animated: Bool) {
        let n = max(1, subviewsList.count)
        let w = bounds.width / CGFloat(n)
        let block = {
            for (i, v) in self.subviewsList.enumerated() {
                v.frame = CGRect(x: CGFloat(i) * w, y: 0,
                                 width: w, height: self.bounds.height)
            }
        }
        animated ? UIView.animate(withDuration: 0.26, animations: block) : block()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        relayout(animated: false)
    }
}

// MARK: - FVFrontConsoleContainer（7540 字节）

public final class FVFrontConsoleContainer: UIView {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        // 证据：initWithDynamicProvider → 深浅色自适应
        backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.12, alpha: 0.96)
                : UIColor(white: 0.97, alpha: 0.96)
        }
        layer.cornerRadius = 22
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 24
    }

    public func present(from screen: CGRect) {
        if frame == .zero {
            frame = CGRect(x: 20, y: screen.height,
                           width: screen.width - 40,
                           height: screen.height * 0.6)
        }
        let target = frame
        frame.origin.y = screen.height
        UIView.animate(withDuration: 0.34, delay: 0,
                       usingSpringWithDamping: 0.82,
                       initialSpringVelocity: 0.5) {
            self.frame = target
        }
    }

    public func dismiss(to screen: CGRect) {
        UIView.animate(withDuration: 0.26) {
            self.frame.origin.y = screen.height
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        subviews.first?.frame = bounds.insetBy(dx: 12, dy: 12)
    }
}
