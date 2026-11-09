import Orion

class SBMWHook: ClassHook<NSObject> {
    static var targetName: String { "SBMainWorkspace" }

    func _addAppLayoutToFront(_ layout: AnyObject) {
        orig._addAppLayoutToFront(layout)
        FVAmbient.shared.onAppLayoutAdded(layout)
    }

    func _removeAppLayout(_ layout: AnyObject, forReason reason: Int64) {
        orig._removeAppLayout(layout, forReason: reason)
        FVAmbient.shared.onAppLayoutRemoved(layout)
    }
}
