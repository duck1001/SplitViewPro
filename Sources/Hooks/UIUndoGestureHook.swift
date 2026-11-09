import Orion

class UIUGIHook: ClassHook<NSObject> {
    static var targetName: String { "UIUndoGestureInteraction" }

    func _handlePan(_ gesture: AnyObject) {
        if FVAmbient.shared.shouldConsumeUndoGesture(gesture) { return }
        orig._handlePan(gesture)
    }
}
