import Orion
import UIKit

class USWHook: ClassHook<NSObject> {
    static var targetName: String { "UIRootSceneWindow" }

    func didAddSubview(_ view: UIView) {
        orig.didAddSubview(view)
        FVAmbient.shared.attachSideBarIfNeeded(in: target)
    }
}
