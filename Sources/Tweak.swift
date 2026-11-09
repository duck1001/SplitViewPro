// Tweak.swift
// Orion 入口。
//
// 重要（DEEP_DIVE_ORION_PITFALLS 坑 1）：
//   不要定义 struct Xxx: HookGroup，也不要把 hook 指定到自定义 Group。
//   Orion 只会自动激活 DefaultGroup；自定义 Group 必须手动 activate()，
//   否则所有钩子全部“能编译、能注入、但静默不执行”。
//
// 这里使用默认 Tweak（不指定 Group），并在 init 里做一次兜底启动：
// 即使 SpringBoardHook 没有命中，悬浮球也会在 1 秒后出现。

import Orion
import UIKit

final class FVTweak: Tweak {
    required init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            FVBootstrap.shared.start()
        }
    }
}
