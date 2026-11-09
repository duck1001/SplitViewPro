import Orion

class FBSSOARHook: ClassHook<NSObject> {
    static var targetName: String { "FBSystemServiceOpenApplicationRequest" }

    func _setPresentationContext(_ context: AnyObject) {
        guard FVPrefsStore.shared.bool(FVKey.universeLinkOpenFloat) else {
            orig._setPresentationContext(context)
            return
        }
        if let bid = target.value(forKey: "bundleIdentifier") as? String,
           !FVPrefsStore.shared.array(FVKey.universeExcludedApps, as: String.self).contains(bid) {
            FVAmbient.shared.openInFloatingView(bundleIdentifier: bid)
            return
        }
        orig._setPresentationContext(context)
    }
}
