// FVSwitcherUtils.swift —— 多任务切换器工具（原版同名类）
import UIKit

public enum FVSwitcherUtils {
    /// 当前是否停留在 App 切换器
    public static var isSwitcherVisible: Bool {
        guard let cls = NSClassFromString("SBAppSwitcherController") as? NSObject.Type,
              let any = (cls as AnyObject).perform(NSSelectorFromString("sharedInstance")),
              let ctrl = any.takeUnretainedValue() as? NSObject else { return false }
        for key in ["isMainSwitcherVisible", "isAnySwitcherVisible"] {
            if let v = ctrl.value(forKey: key) as? NSNumber { return v.boolValue }
        }
        return false
    }
}
