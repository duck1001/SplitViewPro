import Orion

class SBLSAHook: ClassHook<NSObject> {
    static var targetName: String { "SBLockStateAggregator" }

    func lockStateAggregate(_ aggregate: AnyObject) {
        orig.lockStateAggregate(aggregate)
        let locked = (aggregate.value(forKey: "isUserLocked") as? NSNumber)?.boolValue ?? false
        FVAmbient.shared.setAllHidden(locked)
    }
}
