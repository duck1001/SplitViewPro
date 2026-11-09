import Orion

class FBSHook: ClassHook<NSObject> {
    static var targetName: String { "FBScene" }

    func invalidate() {
        FVAmbient.shared.onSceneInvalidated(target)
        orig.invalidate()
    }
}
