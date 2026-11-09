import Orion

class SBAHook: ClassHook<NSObject> {
    static var targetName: String { "SBApplication" }

    func invalidate() {
        if let bid = target.value(forKey: "bundleIdentifier") as? String {
            FVAmbient.shared.closeFloatingView(for: bid)
        }
        orig.invalidate()
    }
}
