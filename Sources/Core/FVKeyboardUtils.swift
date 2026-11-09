// FVKeyboardUtils.swift —— 键盘相关工具（原版同名类，11 个方法全剥离）
import UIKit

public enum FVKeyboardUtils {
    /// 外置键盘是否连接
    public static var isExternalKeyboardConnected: Bool {
        // 通过 GSEvent / UIKeyboardImpl 判定外置键盘
        if let cls = NSClassFromString("UIKeyboardImpl") as? NSObject.Type,
           let impl = (cls as AnyObject).perform(NSSelectorFromString("activeInstance"))?
                        .takeUnretainedValue() as? NSObject,
           let v = impl.value(forKey: "isInHardwareKeyboardMode") as? NSNumber {
            return v.boolValue
        }
        return false
    }

    /// 当前键盘 frame（屏幕坐标）
    public static func currentKeyboardFrame() -> CGRect? {
        guard let cls = NSClassFromString("UIKeyboardImpl") as? NSObject.Type,
              let impl = (cls as AnyObject).perform(NSSelectorFromString("activeInstance"))?
                            .takeUnretainedValue() as? NSObject,
              let layer = impl.perform(NSSelectorFromString("_layout"))?.takeUnretainedValue() as? UIView
        else { return nil }
        return layer.convert(layer.bounds, to: nil)
    }
}
