import Orion

class NCNSLCHook: ClassHook<NSObject> {
    static var targetName: String { "NCNotificationShortLookViewController" }

    func viewWillAppear(_ animated: Bool) {
        orig.viewWillAppear(animated)
        guard FVPrefsStore.shared.bool(FVKey.notifOpenFloat) else { return }
        FVAmbient.shared.registerShortLook(target)
    }
}
