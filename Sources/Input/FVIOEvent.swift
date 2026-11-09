// FVIOEvent.swift
// 对应原版：floatingView.FVIOEvent
// 字段与原版一一对应（顺序也有意义，方便对照内存布局）。
//
// 为什么必须走 IOHID：SpringBoard 里的 UIKit 边缘手势会被系统先吃掉，
// 只有在事件进入系统之前读取原始触摸，才能实现「刘海/角落唤出」。
//
// 底层由 FVHIDEvent（ObjC）负责；Swift 侧只做热区判定/状态机。

import UIKit

public final class FVIOEvent {

    public var ioHIDClient: AnyObject?
    public var ioHIDRunLoopSchedule: CFRunLoop?
    public var mainBounds: CGRect?
    public var width: CGFloat = 0
    public var height: CGFloat = 0

    public var isTouchCustomSize = false
    public var isTouchRight = false
    public var isTouchLeft = false
    public var abs_x: CGFloat = 0
    public var abs_y: CGFloat = 0
    public var right_move_status = false
    public var left_move_status = false
    public var isInit = false

    public var touchType_arc = false
    public var touchType_console = false
    public var eligibleTouchIndex: Int32 = -1
    public var lastTouchObjPoint: [Int32: CGPoint] = [:]
    public var cancelGestureStatus = false

    public var onTouchPhase: ((_ phase: Int, _ point: CGPoint, _ index: Int32) -> Void)?

    private let hid = FVHIDEvent()
    private var isRunning = false

    public init() {
        mainBounds = UIScreen.main.bounds
        width = mainBounds?.width ?? 0
        height = mainBounds?.height ?? 0
    }

    // MARK: - 生命周期

    public func start() {
        guard !isRunning else { return }
        let ok = hid.start(handler: { [weak self] phase, point, index in
            guard let self else { return }
            self.lastTouchObjPoint[index] = point
            self.abs_x = point.x
            self.abs_y = point.y
            self.eligibleTouchIndex = index

            switch phase.rawValue {
            case 0:
                FVGestureUtils.shared.begin(at: point, index: index, io: self)
            case 1:
                FVGestureUtils.shared.move(to: point, index: index, io: self)
            default:
                FVGestureUtils.shared.end(at: point, index: index, io: self)
            }
            self.onTouchPhase?(Int(phase.rawValue), point, index)
        })
        isRunning = ok
        if ok { FVLog.info("IOHID 已启动") }
    }

    public func stop() {
        guard isRunning else { return }
        hid.stop()
        isRunning = false
    }

    deinit { stop() }

    // MARK: - 抢断系统触摸

    public func cancelSystemTouches() {
        guard !cancelGestureStatus else { return }
        cancelGestureStatus = true
        hid.cancelSystemTouches()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.cancelGestureStatus = false
        }
    }

    // MARK: - 热区判定

    /// 原版判定：左右两侧 + 上下角；corner 宽高来自偏好
    public func hitZone(_ p: CGPoint,
                        topCornerWidth: CGFloat,
                        topCornerHeight: CGFloat,
                        bottomCornerHeight: CGFloat) -> FVHotZone {
        let w = mainBounds?.width ?? width
        let h = mainBounds?.height ?? height

        if p.y <= topCornerHeight {
            if p.x <= topCornerWidth { return .leftTopArc }
            if p.x >= w - topCornerWidth { return .rightTopArc }
        }
        if p.y >= h - bottomCornerHeight {
            if p.x <= topCornerWidth { return .leftBottomArc }
            if p.x >= w - topCornerWidth { return .rightBottomArc }
        }
        if p.y >= h - 34, abs(p.x - w / 2) <= w * 0.15 {
            return .bottomCenterConsole
        }
        return .none
    }
}

public enum FVHotZone {
    case none
    case leftTopArc, rightTopArc, leftBottomArc, rightBottomArc
    case bottomCenterConsole

    public var isArc: Bool {
        switch self {
        case .leftTopArc, .rightTopArc, .leftBottomArc, .rightBottomArc: return true
        default: return false
        }
    }
    public var positionType: Int {
        switch self {
        case .leftTopArc, .leftBottomArc: return 0
        case .rightTopArc, .rightBottomArc: return 1
        default: return 0
        }
    }
}
