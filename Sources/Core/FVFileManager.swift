// FVFileManager.swift —— 位置/配置落盘（原版同名类）
// 原版把浮窗 6 个归一化值写到 /var/mobile/Library/FloatingViewInfo/*.txt
import Foundation

public enum FVFileManager {
    public static var infoDir: String {
        // RootHide 下 jbroot 每次越狱随机；运行时由 /var/mobile 根文件系统路径承载。
        // 不写死 /var/jb（RootHide 没有这个固定路径）。
        return "/var/mobile/Library/SplitViewPro/FloatingViewInfo"
    }

    public static func ensureDir() {
        try? FileManager.default.createDirectory(atPath: infoDir,
                                                 withIntermediateDirectories: true)
    }

    @discardableResult
    public static func write(_ value: String, name: String) -> Bool {
        ensureDir()
        let path = "\(infoDir)/\(name)"
        do { try value.write(toFile: path, atomically: true, encoding: .utf8); return true }
        catch { FVLog.warn("写失败 \(path): \(error)"); return false }
    }

    public static func read(name: String) -> String? {
        try? String(contentsOfFile: "\(infoDir)/\(name)", encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
