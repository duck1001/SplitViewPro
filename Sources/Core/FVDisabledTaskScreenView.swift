// FVDisabledTaskScreenView.swift
// 对应原版：floatingView.FVDisabledTaskScreenView（继承 UITextField）
//
// 原版把「环形菜单 / 侧边栏 / 悬浮球 / 弧形背景」全部继承这个类，目的有三个：
//   1. canBecomeFirstResponder = false  → 永不弹系统键盘
//   2. canBecomeFocused = false         → 不抢焦点 / 遥控
//   3. isSecureTextEntry = true         → Secure Text Entry 层默认不进录屏/截屏
//
// ⚠️ 这是整套方案里最不起眼但最关键的设计，务必保留。

import UIKit

open class FVDisabledTaskScreenView: UITextField {

    public override var canBecomeFirstResponder: Bool { false }
    public override var canBecomeFocused: Bool { false }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        isSecureTextEntry = true          // ← 录屏屏蔽 + 不弹键盘的双保险
        backgroundColor = .clear
        tintColor = .clear
        textColor = .clear
        keyboardType = .asciiCapable
        autocorrectionType = .no
        autocapitalizationType = .none
        spellCheckingType = .no
        isUserInteractionEnabled = true
        // 不要设 isUserInteractionEnabled = false，子视图还需要收触摸
    }

    // MARK: - 彻底屏蔽文本编辑

    public override func caretRect(for position: UITextPosition) -> CGRect { .zero }
    public override func firstRect(for range: UITextRange) -> CGRect { .zero }
    public override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] { [] }
    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool { false }
    public override func becomeFirstResponder() -> Bool { false }
    public override func resignFirstResponder() -> Bool { true }

    // 屏蔽所有可能触发输入框行为的点击
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let v = super.hitTest(point, with: event)
        if v === self { return nil }      // 自己不吃触摸，只让子视图吃
        return v
    }

    // MARK: - 布局

    open override func layoutSubviews() {
        super.layoutSubviews()
        // 子类自行布局；这里只保证自身始终铺满
        contentMode = .redraw
    }
}
