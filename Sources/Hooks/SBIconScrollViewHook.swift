import Orion
import UIKit

class SBISVHook: ClassHook<NSObject> {
    static var targetName: String { "SBIconScrollView" }

    func gestureRecognizer(_ recognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        return orig.gestureRecognizer(recognizer, shouldRecognizeSimultaneouslyWith: other)
    }
}
