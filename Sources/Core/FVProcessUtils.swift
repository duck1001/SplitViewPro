// FVProcessUtils.swift —— 进程工具（原版同名类）
import UIKit

public enum FVProcessUtils {
    /// 当前前台应用 bundle id
    public static var frontmostBundleID: String? {
        guard let cls = NSClassFromString("SBApplicationController") as? NSObject.Type,
              let any = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
              let ctrl = any.takeUnretainedValue() as? NSObject else { return nil }
        // 原版 selector：_accessibilityFrontMostApplication
        if let app = ctrl.perform(NSSelectorFromString("_accessibilityFrontMostApplication"))?
                        .takeUnretainedValue() as? NSObject {
            return app.value(forKey: "bundleIdentifier") as? String
        }
        return nil
    }
}
