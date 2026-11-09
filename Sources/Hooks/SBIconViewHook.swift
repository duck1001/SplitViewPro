import Orion
import UIKit

class SBIVHook: ClassHook<NSObject> {
    static var targetName: String { "SBIconView" }

    // 原版真实 selector：contextMenuInteraction:configurationForMenuAtLocation:
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint)
        -> UIContextMenuConfiguration? {
        let cfg = orig.contextMenuInteraction(interaction,
                                              configurationForMenuAtLocation: location)
        guard FVPrefsStore.shared.bool(FVKey.sbIconOpenFloat) else { return cfg }
        guard let bid = target.value(forKey: "bundleIdentifier") as? String else { return cfg }
        FVAmbient.shared.registerFloatingMenu(for: bid)
        return cfg
    }
}
