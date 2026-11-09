// SpringBoardHook.swift
// 对应原版 floatingView.SBHook : ClassHook<SpringBoard>
// 私有类没有头文件，按 DEEP_DIVE_ORION_PITFALLS 坑 2 使用 NSObject + targetName。
// 注意：绝不自定义 HookGroup，全部走 Orion 的 DefaultGroup（自动激活）。

import Orion
import UIKit

class SpringBoardHook: ClassHook<NSObject> {
    static var targetName: String { "SpringBoard" }

    func applicationDidFinishLaunching(_ application: UIApplication) {
        orig.applicationDidFinishLaunching(application)
        FVBootstrap.shared.start()
    }
}
