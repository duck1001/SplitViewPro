import Orion
import UIKit

class _UIKLHVHook: ClassHook<NSObject> {
    static var targetName: String { "_UIKeyboardLayerHostView" }

    func setFrame(_ frame: CGRect) {
        orig.setFrame(frame)
        FVAmbient.shared.onKeyboardLayerFrameChanged(frame)
    }
}
