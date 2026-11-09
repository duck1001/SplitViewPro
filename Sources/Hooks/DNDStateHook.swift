import Orion

class DNDSHook: ClassHook<NSObject> {
    static var targetName: String { "DNDState" }

    func activeModeConfiguration() -> AnyObject? {
        let configuration = orig.activeModeConfiguration()
        FVAmbient.shared.setDNDActive(configuration != nil)
        return configuration
    }
}
