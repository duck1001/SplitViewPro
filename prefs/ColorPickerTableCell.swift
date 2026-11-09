// ColorPickerTableCell.swift
// 对应原版：floatingViewPrefs.ColorPickerTableCell（PSTableCell <UIColorPickerViewControllerDelegate>）
// 字段：cellSpecifier: PSSpecifier?、colorView: UIView?

import Preferences
import UIKit

public final class ColorPickerTableCell: PSTableCell, UIColorPickerViewControllerDelegate {
    public var cellSpecifier: PSSpecifier?
    public var colorView: UIView?

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, specifier: PSSpecifier?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier, specifier: specifier)
        self.cellSpecifier = specifier
        setup()
    }
    public required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        let v = UIView()
        v.layer.cornerRadius = 8
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.separator.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(v)
        NSLayoutConstraint.activate([
            v.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            v.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            v.widthAnchor.constraint(equalToConstant: 44),
            v.heightAnchor.constraint(equalToConstant: 28),
        ])
        colorView = v
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pick)))
    }

    public override func refreshCellContents(withSpecifier specifier: PSSpecifier?) {
        super.refreshCellContents(withSpecifier: specifier)
        cellSpecifier = specifier
        let key = specifier?.property(forKey: "key") as? String ?? ""
        colorView?.backgroundColor = UIColor(fvHex: FVPrefsStore.shared.string(key)) ?? .systemBlue
    }

    @objc private func pick() {
        let p = UIColorPickerViewController()
        p.delegate = self
        p.selectedColor = colorView?.backgroundColor ?? .systemBlue
        (window?.rootViewController ?? self).present(p, animated: true)
    }

    public func colorPickerViewControllerDidFinish(_ vc: UIColorPickerViewController) {
        guard let key = cellSpecifier?.property(forKey: "key") as? String else { return }
        colorView?.backgroundColor = vc.selectedColor
        FVPrefsStore.shared.set(vc.selectedColor.fvHex, for: key)
        vc.dismiss(animated: true)
    }
}

public final class SeatLabelTableCell: PSTableCell {
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, specifier: PSSpecifier?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier, specifier: specifier)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    public override func refreshCellContents(withSpecifier specifier: PSSpecifier?) {
        super.refreshCellContents(withSpecifier: specifier)
        textLabel?.text = specifier?.name
        detailTextLabel?.text = specifier?.property(forKey: "subtitle") as? String
    }
}
