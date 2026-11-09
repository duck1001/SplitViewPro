import Orion
import UIKit

class BNCVCHook: ClassHook<NSObject> {
    static var targetName: String { "BNContentViewController" }

    func viewWillAppear(_ animated: Bool) {
        orig.viewWillAppear(animated)
        guard FVPrefsStore.shared.bool(FVKey.notifOpenFloat) else { return }
        FVAmbient.shared.registerBanner(target)
    }
}
