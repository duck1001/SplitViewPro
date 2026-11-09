import Foundation
import os.log

public enum FVLog {
    private static let log = OSLog(subsystem: "com.nailong.split", category: "core")
    public static var enabled = true

    public static func info(_ s: String) {
        guard enabled else { return }
        os_log("%{public}@", log: log, type: .info, s)
    }
    public static func warn(_ s: String) {
        guard enabled else { return }
        os_log("%{public}@", log: log, type: .error, s)
    }
}
