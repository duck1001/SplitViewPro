// FVGestureUtils.swift
// 对应原版：floatingView.FVGestureUtils
// 字段：currentIsTouchFloatingViewInnerRect: Bool、_SBIconScrollView: SBIconScrollView?
// 职责：把 FVIOEvent 的原始触摸翻译成「唤出 arc / 唤出 console / 拖动浮窗」三种意图。

import UIKit

public final class FVGestureUtils {
    public static let shared = FVGestureUtils()

    public var currentIsTouchFloatingViewInnerRect = false
    public var _SBIconScrollView: UIScrollView?

    private var startPoint: CGPoint = .zero
    private var startZone: FVHotZone = .none
    private var startTime: CFTimeInterval = 0
    private var hasMoved = false
    private var activeIndex: Int32 = -1

    // MARK: - 外部钩子

    public var onArcTrigger: ((_ point: CGPoint, _ positionType: Int) -> Void)?
    public var onConsoleTrigger: ((_ point: CGPoint) -> Void)?
    public var onTapOutside: ((_ point: CGPoint) -> Void)?

    // MARK: - 状态机

    public func begin(at p: CGPoint, index: Int32, io: FVIOEvent) {
        activeIndex = index
        startPoint = p
        startTime = CACurrentMediaTime()
        hasMoved = false

        let store = FVPrefsStore.shared
        let cornerW = CGFloat(store.double(FVKey.topCornerTouchWidth))
        let bottomH = CGFloat(store.double(FVKey.bottomCornerTouchWidth))
        let statusBarH = FVScreenUtils.shared.statusBarHeight

        startZone = io.hitZone(p, topCornerWidth: cornerW,
                               topCornerHeight: statusBarH, bottomCornerHeight: bottomH)

        switch startZone {
        case .leftTopArc, .rightTopArc, .leftBottomArc, .rightBottomArc:
            io.touchType_arc = true
            io.isInit = true
        case .bottomCenterConsole:
            io.touchType_console = true
        case .none:
            // 不在热区：判断是否点在浮窗内（决定是否要抢断系统手势）
            currentIsTouchFloatingViewInnerRect = FVScreenUtils.shared.contains(p)
        }
    }

    public func move(to p: CGPoint, index: Int32, io: FVIOEvent) {
        guard index == activeIndex else { return }
        let dist = hypot(p.x - startPoint.x, p.y - startPoint.y)
        if dist > 12 { hasMoved = true }

        if io.touchType_arc {
            // 走到一定距离才认为「真的要唤出」，避免误触
            if hasMoved && dist > 20 {
                onArcTrigger?(p, startZone.positionType)
                // 抢断系统触摸，防止触发 Home 指示条
                io.cancelSystemTouches()
            }
        } else if io.touchType_console {
            if hasMoved && p.y < startPoint.y - 30 {
                onConsoleTrigger?(p)
                io.cancelSystemTouches()
            }
        }
    }

    public func end(at p: CGPoint, index: Int32, io: FVIOEvent) {
        guard index == activeIndex else { return }
        defer {
            startZone = .none
            io.touchType_arc = false
            io.touchType_console = false
            io.isInit = false
            activeIndex = -1
            hasMoved = false
        }

        let dt = CACurrentMediaTime() - startTime
        let dist = hypot(p.x - startPoint.x, p.y - startPoint.y)

        // 快速点击（<0.3s 且位移 <12）→ 视为点击
        if dt < 0.3 && dist < 12 {
            if startZone == .none && currentIsTouchFloatingViewInnerRect {
                onTapOutside?(p)
            }
        }
    }
}
