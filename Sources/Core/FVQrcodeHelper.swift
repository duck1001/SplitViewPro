// FVQrcodeHelper.swift —— 二维码生成（原版同名类，对应「微信/支付宝扫码收付款」）
import UIKit
import CoreImage

public enum FVQrcodeHelper {
    public static func make(_ content: String, size: CGFloat = 240) -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(content.utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let out = filter.outputImage else { return nil }
        let scale = size / out.extent.width
        let scaled = out.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let ctx = CIContext()
        guard let cg = ctx.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
