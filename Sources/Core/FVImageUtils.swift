// FVImageUtils.swift —— 图像工具（原版同名类）
import UIKit

public enum FVImageUtils {
    public static func circle(_ image: UIImage, diameter: CGFloat) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        UIBezierPath(ovalIn: rect).addClip()
        image.draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    public static func resized(_ image: UIImage, to size: CGSize) -> UIImage {
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }
}
