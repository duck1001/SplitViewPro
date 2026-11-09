// FVDynamicHostingView.swift
// 对应原版：floatingView.FVDynamicHostingView
// 与 FVHostingView 的区别：挂钩 _UIKeyboardLayerHostView，
// 让浮窗内容跟随键盘层上下移动（浮窗内键盘不被遮挡的底层手段）。

import UIKit

public final class FVDynamicHostingView: FVHostingView {
    private var keyboardOffset: CGFloat = 0

    /// 由 UIKeyboardSceneHook / UIKeyboardLayerHook 调用
    public func updateKeyboardFrame(_ frame: CGRect, screenBounds: CGRect) {
        guard frame.height > 0 else {
            keyboardOffset = 0
            applyOffset(0)
            return
        }
        let bottomInset = max(0, screenBounds.maxY - frame.minY)
        keyboardOffset = bottomInset
        applyOffset(-bottomInset)
    }

    private func applyOffset(_ dy: CGFloat) {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.beginFromCurrentState]) {
            self.transform = CGAffineTransform(translationX: 0, y: dy)
        }
    }
}
