// FVObjC.swift
// 轻量 ObjC 运行时桥：Swift 侧不直接对 AnyObject 调 perform。

import Foundation

public enum FVObjC {
    @discardableResult
    public static func perform(_ target: AnyObject?, _ selector: String, _ args: [Any?] = []) -> AnyObject? {
        guard let target else { return nil }
        switch args.count {
        case 0:
            return FVPerform0(target, selector) as AnyObject?
        case 1:
            return FVPerform1(target, selector, args[0]) as AnyObject?
        case 2:
            return FVPerform2(target, selector, args[0], args[1]) as AnyObject?
        default:
            return FVPerform3(target, selector, args[0], args[1], args[2]) as AnyObject?
        }
    }

    public static func bool(_ target: AnyObject?, _ selector: String) -> Bool {
        (perform(target, selector) as? NSNumber)?.boolValue ?? false
    }
}
