// FVPointUtils.swift —— 坐标工具（原版同名类）：归一化 / 反归一化
import UIKit

public enum FVPointUtils {
    public static func normalize(_ p: CGPoint, in bounds: CGRect) -> CGPoint {
        guard bounds.width > 0, bounds.height > 0 else { return .zero }
        return CGPoint(x: p.x / bounds.width, y: p.y / bounds.height)
    }
    public static func denormalize(_ p: CGPoint, in bounds: CGRect) -> CGPoint {
        CGPoint(x: p.x * bounds.width, y: p.y * bounds.height)
    }
}
