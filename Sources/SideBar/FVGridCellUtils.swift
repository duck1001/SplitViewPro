// FVGridCellUtils.swift —— 侧边栏网格工具（原版同名类，方法全剥离）
import UIKit

public enum FVGridCellUtils {
    public static func itemSize(width: CGFloat, iconSize: CGFloat) -> CGSize {
        CGSize(width: width - 8, height: iconSize + 8)
    }
}
