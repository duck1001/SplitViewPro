// FVArcUtils.swift —— 环形菜单几何工具（原版同名类）
import UIKit

public enum FVArcUtils {
    /// 给定中心点、半径、角度 -> 坐标
    public static func point(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }
    /// 两点角度（弧度）
    public static func angle(from center: CGPoint, to p: CGPoint) -> CGFloat {
        atan2(p.y - center.y, p.x - center.x)
    }
    /// 把角度归一到 [start, end]
    public static func normalized(_ a: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
        var x = a
        while x < start { x += .pi * 2 }
        while x > end   { x -= .pi * 2 }
        return x
    }
}
