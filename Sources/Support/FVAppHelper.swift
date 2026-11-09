// FVAppHelper.swift
// 对应原版：floatingView.FVAppHelper（NSObject，18 个方法全被剥离）
// 这里放所有「跨进程查 App / 查图标 / 查 SpringBoard 窗口」的工具方法。

import UIKit
import ObjectiveC

public enum FVAppHelper {

    // MARK: - 私有 selector 安全调用

    public static func selIfResponds(_ obj: NSObject, _ name: String) -> Selector? {
        let sel = NSSelectorFromString(name)
        return obj.responds(to: sel) ? sel : nil
    }

    // MARK: - SpringBoard

    /// 拿 SpringBoard 的 UIRootSceneWindow / rootView
    public static func springBoardWindow() -> NSObject? {
        guard let cls = NSClassFromString("SpringBoard") as? NSObject.Type,
              let sharedAny = (cls as AnyObject).perform(NSSelectorFromString("sharedApplication")),
              let app = sharedAny.takeUnretainedValue() as? NSObject
        else { return nil }

        for key in ["_accessibilityFrontMostApplication", "rootWindow"] {
            if let v = app.value(forKey: key) as? NSObject { return v }
        }
        // 兜底：遍历 connectedScenes
        if let scenes = app.value(forKey: "connectedScenes") as? Set<UIWindowScene>,
           let first = scenes.first {
            return first.windows.first?.rootViewController?.view as NSObject?
        }
        return nil
    }

    // MARK: - SBApplication

    public static func sbApplication(_ bundleIdentifier: String) -> NSObject? {
        guard let cls = NSClassFromString("SBApplication") as? NSObject.Type else { return nil }

        // iOS 15/16: [SBApplicationController sharedInstance] applicationWithBundleIdentifier:
        if let ctrlCls = NSClassFromString("SBApplicationController") as? NSObject.Type,
           let ctrlAny = (ctrlCls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
           let ctrl = ctrlAny.takeUnretainedValue() as? NSObject {
            let sel = NSSelectorFromString("applicationWithBundleIdentifier:")
            if ctrl.responds(to: sel),
               let any = ctrl.perform(sel, with: bundleIdentifier),
               let app = any.takeUnretainedValue() as? NSObject {
                return app
            }
        }

        // 老路线：[SBApplicationController applicationsWithBundleIdentifier:]
        if let dtCls = NSClassFromString("SBApplicationController") as? NSObject.Type,
           let dtAny = (dtCls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
           let ctrl = dtAny.takeUnretainedValue() as? NSObject {
            for name in ["applicationsWithBundleIdentifier:", "allApplications"] {
                let sel = NSSelectorFromString(name)
                guard ctrl.responds(to: sel) else { continue }
                if let any = ctrl.perform(sel, with: bundleIdentifier) {
                    if let arr = any.takeUnretainedValue() as? [NSObject], let first = arr.first { return first }
                }
            }
        }
        _ = cls
        return nil
    }

    // MARK: - 图标

    public static func icon(for bundleIdentifier: String) -> UIImage? {
        // 优先 SBApplication 的图标接口（原版 selector：_applicationIconImageForBundleIdentifier:format:scale:）
        if let cls = NSClassFromString("SBApplicationController") as? NSObject.Type,
           let clsAny = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
           let ctrl = clsAny.takeUnretainedValue() as? NSObject {
            let sel = NSSelectorFromString("_applicationIconImageForBundleIdentifier:format:scale:")
            if ctrl.responds(to: sel) {
                typealias Fn = @convention(c) (AnyObject, Selector, NSString, Int, CGFloat) -> AnyObject?
                if let imp = class_getMethodImplementation(type(of: ctrl), sel) {
                    let f = unsafeBitCast(imp, to: Fn.self)
                    if let img = f(ctrl, sel, bundleIdentifier as NSString, 0, 3.0) as? UIImage { return img }
                }
            }
        }
        // 兜底：LSApplicationProxy + UIImage from icon
        if let proxyCls = NSClassFromString("LSApplicationProxy") as? NSObject.Type,
           let proxy = proxyCls.perform(NSSelectorFromString("applicationProxyForIdentifier:"),
                                        with: bundleIdentifier)?.takeUnretainedValue() as? NSObject,
           let url = proxy.perform(NSSelectorFromString("iconDataURL"))?.takeUnretainedValue() as? URL,
           let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }

    // MARK: - 所有已安装应用

    public static func installedApps() -> [(name: String, id: String, icon: UIImage?)] {
        var out: [(String, String, UIImage?)] = []
        guard let cls = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type,
              let wsAny = (cls as AnyObject).perform(NSSelectorFromString("defaultWorkspace")),
              let ws = wsAny.takeUnretainedValue() as? NSObject,
              let allAny = ws.perform(NSSelectorFromString("allInstalledApplications")),
              let all = allAny.takeUnretainedValue() as? [NSObject]
        else { return out }

        for proxy in all {
            guard let bid = proxy.value(forKey: "applicationIdentifier") as? String else { continue }
            let name = (proxy.value(forKey: "localizedName") as? String) ?? bid
            out.append((name, bid, icon(for: bid)))
        }
        return out
    }
}
