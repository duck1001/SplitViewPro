import Orion

class UIKSDHook: ClassHook<NSObject> {
    static var targetName: String { "UIKeyboardSceneDelegate" }

    func keyboardFrameDidChange() {
        orig.keyboardFrameDidChange()
        FVAmbient.shared.onKeyboardFrameChanged()
    }
}
