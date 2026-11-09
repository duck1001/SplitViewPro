// FVArcItem.swift
// 对应原版：floatingView.FVArcItem（UICollectionViewCell）
// 字段：itemClassify: FVArcItemType?、levelNum: Int、pointValue: Int、
//       imageView: FVSysIconView、bgColorView: UIView

import UIKit

public enum FVArcItemType {
    case app(FVAppBtnInfo)
    case tool(FVToolBtnInfo)
}

public struct FVAppBtnInfo {
    public let icon: UIImage?
    public let appName: String
    public let appBundleId: String
    public let size: Double
}

public struct FVToolBtnInfo {
    public let icon: UIImage?
    public let iconName: String
    public let isImg: Bool
    public let size: Double
}

public struct FVMiniViewRectInfo {
    public var floatingViewVCenterX: Double = 0
    public var floatingViewVCenterY: Double = 0
    public var floatingViewHCenterX: Double = 0
    public var floatingViewHCenterY: Double = 0
    public var floatingViewVScale: Double = 1
    public var floatingViewHScale: Double = 1

    /// 原版存在 /var/mobile/Library/FloatingViewInfo/*.txt，6 个归一化值
    public static func load() -> FVMiniViewRectInfo {
        var r = FVMiniViewRectInfo()
        let dir = "/var/mobile/Library/FloatingViewInfo"
        func read(_ name: String) -> Double {
            (try? String(contentsOfFile: "\(dir)/\(name).txt", encoding: .utf8))
                .flatMap { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) } ?? 0
        }
        r.floatingViewVCenterX = read("floatingViewVCenterX")
        r.floatingViewVCenterY = read("floatingViewVCenterY")
        r.floatingViewHCenterX = read("floatingViewHCenterX")
        r.floatingViewHCenterY = read("floatingViewHCenterY")
        r.floatingViewVScale   = read("floatingViewVScale").clamped(or: 1)
        r.floatingViewHScale   = read("floatingViewHScale").clamped(or: 1)
        return r
    }

    public func save() {
        let dir = "/var/mobile/Library/FloatingViewInfo"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        func write(_ name: String, _ v: Double) {
            try? "\(v)".write(toFile: "\(dir)/\(name).txt", atomically: true, encoding: .utf8)
        }
        write("floatingViewVCenterX", floatingViewVCenterX)
        write("floatingViewVCenterY", floatingViewVCenterY)
        write("floatingViewHCenterX", floatingViewHCenterX)
        write("floatingViewHCenterY", floatingViewHCenterY)
        write("floatingViewVScale",   floatingViewVScale)
        write("floatingViewHScale",   floatingViewHScale)
    }
}

extension Double {
    func clamped(or fallback: Double) -> Double {
        (self > 0 && self <= 1.5) ? self : fallback
    }
}

public final class FVSysIconView: UIImageView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .scaleAspectFit
        backgroundColor = .clear
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

public final class FVArcItem: UICollectionViewCell {
    public var itemClassify: FVArcItemType?
    public var levelNum: Int = 1
    public var pointValue: Int = 0
    public let imageView = FVSysIconView()
    public let bgColorView = UIView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.addSubview(bgColorView)
        contentView.addSubview(imageView)
        bgColorView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bgColorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bgColorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bgColorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bgColorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.7),
            imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.7),
        ])
        bgColorView.layer.masksToBounds = true
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        bgColorView.layer.cornerRadius = bounds.width / 2
    }

    public func configure(with type: FVArcItemType) {
        itemClassify = type
        switch type {
        case .app(let info):
            imageView.image = info.icon
        case .tool(let info):
            imageView.image = info.icon ?? UIImage(systemName: info.iconName)
        }
    }

    public func setHighlighted(_ on: Bool) {
        let store = FVPrefsStore.shared
        if on {
            let hex = store.string(FVKey.arcButtonBgValue)
            bgColorView.backgroundColor = UIColor(fvHex: hex) ?? UIColor.systemBlue.withAlphaComponent(0.35)
        } else {
            bgColorView.backgroundColor = .clear
        }
    }
}

extension UIColor {
    convenience init?(fvHex: String) {
        var h = fvHex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let v = UInt32(h, radix: 16) else { return nil }
        self.init(red: CGFloat((v >> 16) & 0xFF) / 255,
                  green: CGFloat((v >> 8) & 0xFF) / 255,
                  blue: CGFloat(v & 0xFF) / 255,
                  alpha: 1)
    }
    var fvHex: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }
}
