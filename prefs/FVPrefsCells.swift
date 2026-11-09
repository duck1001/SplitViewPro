// FVPrefsCells.swift
// 对应原版：floatingViewPrefs 的 10 个 Swift 结构体 + specifier 工厂。
// 这些结构体的字段名/顺序来自 __swift5_fieldmd，与原版一一对应。

import Preferences
import UIKit

// MARK: - 10 个 cell 描述结构体（字段名与原版一致）

public struct GroupCell      { public let name: String; public let footerText: String; public let key: String }
public struct StaticTextCell { public let name: String; public let key: String }
public struct ToggleCell     { public let name: String; public let key: String
                               public let defaultValue: Bool; public let icon: UIImage? }
public struct SliderCell     { public let name: String; public let key: String
                               public let defaultValue: Double; public let min: Double; public let max: Double
                               public let showValue: Bool; public let isSegmented: Bool
                               public let segmentCount: Int?; public let isContinuous: Bool
                               public let leftImage: UIImage?; public let rightImage: UIImage? }
public struct TabCell        { public let name: String; public let values: [String]
                               public let titles: [String]; public let key: String
                               public let defaultValue: String }
public struct LinkCell       { public let name: String; public let className: AnyClass?
                               public let isController: Bool; public let key: String
                               public let action: Selector?; public let icon: UIImage? }
public struct ButtonCell     { public let name: String; public let action: Selector
                               public let key: String; public let icon: UIImage? }
public struct AppsCell       { public let name: String; public let key: String
                               public let useDefaultValue: Bool; public let defaultValue: [String]
                               public let useSearchBar: Bool
                               public let includeIdentifiersInSearch: Bool
                               public let showIdentifiersAsSubtitle: Bool }
public struct ColorPickerCell{ public let name: String; public let defaultColor: String
                               public let key: String; public let action: Selector?
                               public let icon: UIImage? }
public struct SeatLabelCell  { public let name: String; public let subtitle: String
                               public let key: String; public let icon: UIImage? }

// MARK: - 转 PSSpecifier

public enum FVSpec {

    public static func group(_ c: GroupCell) -> PSSpecifier {
        let s = PSSpecifier.groupSpecifier()
        s.name = c.name
        s.setProperty(c.footerText, forKey: "footerText")
        s.identifier = c.key
        return s
    }

    public static func staticText(_ c: StaticTextCell) -> PSSpecifier {
        let s = PSSpecifier.preferenceSpecifierNamed(c.name, target: nil, set: nil, get: nil, detail: nil, cell: PSTableCell.self, edit: nil)
        s.identifier = c.key
        return s
    }

    public static func toggle(_ c: ToggleCell) -> PSSpecifier {
        let s = PSSpecifier.preferenceSpecifierNamed(c.name, target: nil,
                                                     set: #selector(FVPrefsValues.setBool(_:specifier:)),
                                                     get: #selector(FVPrefsValues.getBool(_:)),
                                                     detail: nil, cell: PSSwitchCell.self, edit: nil)
        s.identifier = c.key
        s.setProperty(c.key, forKey: "key")
        s.setProperty(c.defaultValue, forKey: "default")
        if let icon = c.icon { s.setProperty(icon, forKey: "iconImage") }
        return s
    }

    public static func slider(_ c: SliderCell) -> PSSpecifier {
        let s = PSSpecifier.preferenceSpecifierNamed(c.name, target: nil,
                                                     set: #selector(FVPrefsValues.setDouble(_:specifier:)),
                                                     get: #selector(FVPrefsValues.getDouble(_:)),
                                                     detail: nil, cell: PSSliderCell.self, edit: nil)
        s.identifier = c.key
        s.setProperty(c.key, forKey: "key")
        s.setProperty(c.defaultValue, forKey: "default")
        s.setProperty(c.min, forKey: "min")
        s.setProperty(c.max, forKey: "max")
        s.setProperty(c.showValue, forKey: "showValue")
        s.setProperty(c.isSegmented, forKey: "isSegmented")
        if let n = c.segmentCount { s.setProperty(n, forKey: "segmentCount") }
        s.setProperty(c.isContinuous, forKey: "isContinuous")
        if let l = c.leftImage  { s.setProperty(l, forKey: "leftImage") }
        if let r = c.rightImage { s.setProperty(r, forKey: "rightImage") }
        return s
    }

    public static func tab(_ c: TabCell) -> PSSpecifier {
        let s = PSSpecifier.preferenceSpecifierNamed(c.name, target: nil,
                                                     set: #selector(FVPrefsValues.setString(_:specifier:)),
                                                     get: #selector(FVPrefsValues.getString(_:)),
                                                     detail: nil, cell: PSSegmentCell.self, edit: nil)
        s.identifier = c.key
        s.setProperty(c.key, forKey: "key")
        s.setProperty(c.values, forKey: "validValues")
        s.setProperty(c.titles, forKey: "validTitles")
        s.setProperty(c.defaultValue, forKey: "default")
        return s
    }

    public static func link(_ c: LinkCell) -> PSSpecifier {
        let s = PSSpecifier.preferenceSpecifierNamed(c.name, target: nil, set: nil, get: nil,
                                                     detail: c.className, cell: PSLinkCell.self, edit: nil)
        s.identifier = c.key
        s.setProperty(c.key, forKey: "key")
        s.setProperty(c.isController, forKey: "isController")
        if let action = c.action { s.setProperty(NSStringFromSelector(action), forKey: "action") }
        if let icon = c.icon { s.setProperty(icon, forKey: "iconImage") }
        return s
    }

    public static func button(_ c: ButtonCell) -> PSSpecifier {
        let s = PSSpecifier.preferenceSpecifierNamed(c.name, target: nil, set: nil, get: nil,
                                                     detail: nil, cell: PSButtonCell.self, edit: nil)
        s.identifier = c.key
        s.setProperty(c.action, forKey: "action")
        if let icon = c.icon { s.setProperty(icon, forKey: "iconImage") }
        return s
    }
}

// MARK: - 读写桥（cell 的 get/set 全部走这里，与主 dylib 同一套 plist）

public final class FVPrefsValues: NSObject {
    @objc public static func getBool(_ spec: PSSpecifier) -> Any? {
        guard let key = spec.property(forKey: "key") as? String else { return nil }
        return FVPrefsStore.shared.bool(key)
    }
    @objc public static func setBool(_ value: Any?, specifier: PSSpecifier) {
        guard let key = specifier.property(forKey: "key") as? String else { return }
        FVPrefsStore.shared.set((value as? NSNumber)?.boolValue ?? false, for: key)
    }
    @objc public static func getDouble(_ spec: PSSpecifier) -> Any? {
        guard let key = spec.property(forKey: "key") as? String else { return nil }
        return FVPrefsStore.shared.double(key)
    }
    @objc public static func setDouble(_ value: Any?, specifier: PSSpecifier) {
        guard let key = specifier.property(forKey: "key") as? String else { return }
        FVPrefsStore.shared.set((value as? NSNumber)?.doubleValue ?? 0, for: key)
    }
    @objc public static func getString(_ spec: PSSpecifier) -> Any? {
        guard let key = spec.property(forKey: "key") as? String else { return nil }
        return FVPrefsStore.shared.string(key)
    }
    @objc public static func setString(_ value: Any?, specifier: PSSpecifier) {
        guard let key = specifier.property(forKey: "key") as? String else { return }
        FVPrefsStore.shared.set(value as? String ?? "", for: key)
    }
}
