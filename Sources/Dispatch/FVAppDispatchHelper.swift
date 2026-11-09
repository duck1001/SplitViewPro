// FVAppDispatchHelper.swift —— 浮窗调度辅助（原版同名类，2 个方法被剥离）
import UIKit

public enum FVAppDispatchHelper {
    /// 判断某个 bundle id 是否已经在浮窗里
    public static func isFloating(_ bid: String) -> Bool {
        FVAmbient.shared.floatingBundleIDs.contains(bid)
    }
}
