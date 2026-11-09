// FVArcDataSource.swift
// 环形菜单的数据源：应用环取 allApps（或全部已安装），工具环取 selectedTools。
// 原版对应：FVArcItemType.app(FVAppBtnInfo) / .tool(FVToolBtnInfo) 的构造。

import UIKit

public final class FVArcDataSource {
    public static let shared = FVArcDataSource()
    private init() {}

    private var cachedApps: [FVAppBtnInfo] = []

    /// 第 level 层的应用项
    public func appItems(level: Int) -> [FVArcItemType?] {
        if cachedApps.isEmpty {
            cachedApps = FVAppHelper.installedApps().map {
                FVAppBtnInfo(icon: $0.icon, appName: $0.name, appBundleId: $0.id, size: 22)
            }
        }
        // 优先用用户自定义排序（偏好 allApps）
        let custom = FVPrefsStore.shared.array(FVKey.allApps, as: String.self)
        var list: [FVAppBtnInfo]
        if custom.isEmpty {
            list = cachedApps
        } else {
            list = custom.compactMap { bid in cachedApps.first { $0.appBundleId == bid } }
        }
        let perLevel = perLevelCount(level: level, total: list.count, kind: .app)
        return slice(list, level: level, perLevel: perLevel).map { .app($0) }
    }

    /// 第 level 层的工具项
    public func toolItems(level: Int) -> [FVArcItemType?] {
        let selected = FVPrefsStore.shared.array(FVKey.selectedTools, as: Int.self)
        let actions: [FVToolAction] = selected.isEmpty
            ? FVToolAction.allCases
            : selected.compactMap { FVToolAction(rawValue: $0) }
        let infos = actions.map {
            FVToolBtnInfo(icon: UIImage(systemName: $0.symbolName),
                          iconName: $0.symbolName, isImg: false, size: 22)
        }
        let perLevel = perLevelCount(level: level, total: infos.count, kind: .tool)
        return slice(infos, level: level, perLevel: perLevel).map { .tool($0) }
    }

    private enum Kind { case app, tool }
    private func perLevelCount(level: Int, total: Int, kind: Kind) -> Int {
        let store = FVPrefsStore.shared
        let key = kind == .app ? FVKey.arcAppDisplayCount(level) : FVKey.arcToolDisplayCount(level)
        let fixed = store.int(key)
        if fixed > 0 { return fixed }
        // 0 = 自动：按总数为平均分配到各层（原版就是这种「满圆均分」）
        return max(1, total)
    }

    private func slice<T>(_ all: [T], level: Int, perLevel: Int) -> [T] {
        let start = (level - 1) * perLevel
        guard start < all.count else { return [] }
        return Array(all[start..<min(all.count, start + perLevel)])
    }
}
