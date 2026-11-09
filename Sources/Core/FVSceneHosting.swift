// FVSceneHosting.swift
// 全项目最核心的一段：把真实 App 的 FBScene 嵌进浮窗。
//
// 关键私有 API 链（逐行来自反编译 method.floatingView.FVHostingView.func.00035e5c）：
//
//   1. NSClassFromString("_UISceneLayerHostContainerView")
//        -alloc -initWithScene:debugDescription:   (debugDescription 传 nil)
//   2. NSClassFromString("UIScenePresentationContext")
//        -alloc -_initWithDefaultValues            ← ★ 这是「呈现上下文」对象
//   3. containerView -_setPresentationContext:(ctx)  ← ★ 参数是 Context，不是 UIView
//   4. scene.settings -mutableCopy → setForeground: / setUserInterfaceStyle:
//        -updateSettings:withTransitionContext:completion:
//   5. host -addSubview:(containerView)
//
// ⚠️ iOS 15/16 的 FBScene 类都在 FrontBoard 私有框架里。为了让同一份源码能在
//    RootHide / rootless / 无私有头文件环境下编译，这里全部用 AnyObject + KVC，
//    不在编译期 import FrontBoard，也不写死任何 ivar 偏移。

import UIKit

public enum FVSceneHosting {

    private static var workspaceCache: AnyObject?

    // MARK: - Step 1：拿 FBSceneWorkspace

    public static func workspace() -> AnyObject? {
        if let workspaceCache { return workspaceCache }

        guard let managerClass = NSClassFromString("FBSceneManager") as? NSObject.Type,
              let managerObject = FVObjC.perform(managerClass, "sharedInstance"),
              let manager = managerObject as? NSObject else { return nil }

        for key in ["_workspace", "workspace"] {
            if let workspace = manager.value(forKey: key) as AnyObject? {
                workspaceCache = workspace
                return workspace
            }
        }
        return nil
    }

    // MARK: - Step 2：按 bundleIdentifier 找 FBScene

    public static func scene(for bundleIdentifier: String) -> AnyObject? {
        guard let workspace = workspace() as? NSObject else { return nil }

        // 场景 ID 通常形如 "com.apple.mobilesafari-<uuid>"；不同系统版本也可能
        // 直接是 bundleIdentifier，所以用前缀匹配。
        let dictionaries = ["_allScenesByID", "allScenesByID"]
        for key in dictionaries {
            guard let dict = workspace.value(forKey: key) as? [String: Any] else { continue }
            for (sceneID, value) in dict where sceneID.hasPrefix(bundleIdentifier) {
                if let scene = value as AnyObject? { return scene }
            }
        }

        // 兜底：SBApplication -> _scene / scene
        if let app = FVAppHelper.sbApplication(bundleIdentifier) {
            for selector in ["_scene", "scene"] {
                if let scene = FVObjC.perform(app, selector) { return scene }
            }
        }
        return nil
    }

    // MARK: - Step 3：核心 —— 把 scene 挂到 host 上

    @discardableResult
    public static func attach(_ scene: AnyObject,
                              to host: UIView,
                              size: CGSize,
                              outSettings: inout NSObject?) -> UIView? {

        // ---- 1) 创建图层宿主容器 ----
        var container: AnyObject?
        if let containerClass = NSClassFromString("_UISceneLayerHostContainerView") as? NSObject.Type,
           let allocated = FVObjC.perform(containerClass, "alloc") {
            container = FVObjC.perform(allocated, "initWithScene:debugDescription:", [scene, nil])
        }
        // iOS 16 某些版本上私有类不可用：退回 scene 自己的 _sceneContainerView
        if container == nil {
            container = FVObjC.perform(scene, "_sceneContainerView")
        }
        guard let containerView = container as? UIView else {
            FVLog.warn("_UISceneLayerHostContainerView 不可用")
            return nil
        }

        // ---- 2) 创建 UIScenePresentationContext 并交给容器（★ 易错点）----
        if let contextClass = NSClassFromString("UIScenePresentationContext") as? NSObject.Type,
           let allocated = FVObjC.perform(contextClass, "alloc"),
           let context = FVObjC.perform(allocated, "_initWithDefaultValues") {
            _ = FVObjC.perform(containerView, "_setPresentationContext:", [context])
        }

        // ---- 3) 更新场景设置 ----
        if let settings = FVObjC.perform(scene, "settings") as? NSObject,
           let mutable = FVObjC.perform(settings, "mutableCopy") as? NSObject {
            mutable.setValue(NSValue(cgRect: CGRect(origin: .zero, size: size)), forKey: "frame")
            mutable.setValue(host.traitCollection.userInterfaceStyle.rawValue,
                             forKey: "userInterfaceStyle")
            if mutable.responds(to: NSSelectorFromString("setForeground:")) {
                mutable.setValue(true, forKey: "foreground")
            }
            outSettings = mutable
            _ = FVObjC.perform(scene, "updateSettings:withTransitionContext:completion:",
                               [mutable, nil, nil])
        }

        // ---- 4) 挂上去 ----
        containerView.frame = CGRect(origin: .zero, size: size)
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(containerView)
        return containerView
    }

    // MARK: - Step 4：解绑

    /// 关闭浮窗时必须调，否则 App 画面挂在一个已释放的容器上（会黑屏/崩溃）。
    /// 注意：_setPresentationContext: 是容器的方法，不是 scene 的方法；这里只移除容器。
    public static func detach(_ scene: AnyObject?, container: UIView?) {
        container?.removeFromSuperview()
    }
}
