import Orion

class SBFSGMHook: ClassHook<NSObject> {
    static var targetName: String { "SBFluidSwitcherGestureManager" }

    func grabberTongueCanceledPulling(_ tongue: AnyObject,
                                      withDistance distance: Double,
                                      andVelocity velocity: Double,
                                      andGesture gesture: AnyObject) {
        orig.grabberTongueCanceledPulling(tongue, withDistance: distance,
                                          andVelocity: velocity, andGesture: gesture)
        guard FVPrefsStore.shared.bool(FVKey.switcherEndedEvent) else { return }
        FVAmbient.shared.floatFrontApplication()
    }
}
