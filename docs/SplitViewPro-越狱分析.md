# Split View Pro 越狱分析
## iOS 15–16 · arm64e · RootHide · 分屏/浮窗 1:1 复刻报告

> 插件名：**Split View Pro**  
> Bundle ID：`com.nailong.split`  
> 作者：**nailong**  
> 目标环境：iOS 15.0–16.6.1，arm64e（A12 及以上），RootHide bootstrap  
> 参照物：`floatingView 1.6.0-6`（`com.be-huge.floating-view`，作者 be-huge）完整逆向包  
> 代号说明：下文 `FV*` 指逆向包中的原始类名；`SVPro*` 指本项目的对应实现。

---

## 0. 结论摘要（先看这 12 条）

1. **能做，而且路线已经被原版验证**：分屏不是“同时启动两个前台 App”，而是把真实 App 的 `FBScene` 从原来的全屏宿主里“摘出来”，重新挂到 SpringBoard 的一个浮窗容器上。原版的核心只有三句话：`FBScene` + `_setPresentationContext:` + `_UISceneLayerHostContainerView`。
2. **iOS 15 和 16 都能走同一条主路径**，但 `FBSceneManager` / `FBSceneWorkspace`、`_allScenesByID`、`SBApplication._scene` 的取法要做多套 fallback；不能把某一个版本的私有 ivar 名写死。
3. **arm64e 不是主要障碍**。A12+ 的 PAC 由 dyld/越狱注入器处理；真正要避免的是“把反编译地址当函数指针调用”和“写死 Mach-O 偏移”。所有私有 API 都应走 `NSClassFromString` + `NSSelectorFromString` + `objc_msgSend`/KVC。
4. **RootHide 的主要障碍是路径，不是 API**：RootHide 把越狱根目录放到随机 `jbroot`，没有固定 `/var/jb`。代码里任何 `/var/jb/...` 都要改成 `jbroot()`（C/ObjC/Swift 均可，Theos 在 rootful/rootless 下会把它编译成空 stub）。
5. **RootHide 默认不向第三方 App 注入 tweak**。但 Split View Pro 只需要注入 **SpringBoard**；被浮窗化的 App 不需要装 tweak，它的画面由 SpringBoard 侧的 scene 容器渲染。这是本方案在 RootHide 上最舒服的一点。
6. **1:1 复刻的核心不是 UI，而是“scene 生命周期”**：找 scene → 建容器 → 设 presentation context → 改 settings（frame / foreground / userInterfaceStyle）→ 挂 subview → 关闭时解绑。任何一步顺序错，表现是黑屏、白屏、App 闪退或 SpringBoard 卡死。
7. **窗口层级只有三层**：`FVWindow` level 27（浮窗主体）、`FVFrontConsoleWindow` level 28（操控台/搜索）、`FVRootWindow` 包 `UIRootSceneWindow`（侧边栏，跟 RootScene 走旋转）。不要把所有东西塞进一个 window。
8. **输入层是第二个难点**：刘海/底部边缘唤出必须走 `IOHIDEventSystemClient`，UIKit 层会被系统手势先吃掉；但 IOHID 的 digitizer 字段号在不同 iOS 15/16 小版本上要实测校准，不能盲信 `0x10000/0x10001`。
9. **“不弹键盘/不进录屏”的基类很关键**：`FVDisabledTaskScreenView : UITextField`，重写 `canBecomeFirstResponder=false`、`canBecomeFocused=false`，并 `isSecureTextEntry=true`。这是原版所有浮层组件的共同父类。
10. **原版骨架代码不能直接当成品**：逆向包里的 `skeleton/` 是“结构骨架”，存在与二进制证据不一致的地方（例如 `FVDynamicHostingView` 在原版是包着 `FVHostingView` 的独立 `UIView`，不是子类；`Tweak.swift` 还用了自定义 `HookGroup`，按 Orion 的规则会导致全部钩子静默失效）。1:1 复刻必须先修正这些。
11. **GitHub macOS 打包可行**：用 `roothide/theos` + `THEOS_PACKAGE_SCHEME=roothide`（或 `rootless`）在 `macos-14` runner 上 `make package`，产物是标准 `.deb`；本项目的 `.github/workflows/build.yml` 已按这个流程写好。
12. **最大风险不是编译，而是“表面能跑、实际没挂上 scene”**：必须用 `scene.isValid`、`scene.settings.frame`、`container.superview` 三层校验；没有 scene 时只能降级为快照占位，绝不能让 SpringBoard 崩。

---

## 1. 材料与证据基础：这份报告是怎么读出来的

### 1.1 逆向包规模

| 项目 | 数量/说明 |
|---|---|
| 主 dylib | `floatingView.dylib`，1.65 MB fat，arm64e 835 KB / arm64 786 KB |
| 函数 | 3,607 个（309 外部导入、350 ObjC 方法、2,925 Swift 内部函数） |
| ObjC 类 | 70 个，181 个方法（带 dylib 内偏移） |
| Swift 类型 | 145 个（索引 130 个可读类型，17 组为 Orion `_Glue`） |
| ObjC selector | 601 条 |
| 偏好键 | 308 个 |
| 设置面板 | `floatingViewPrefs` 943 KB，34 个 ObjC 类，其中 26 个 `PSListController` 子类 |
| 辅助 dylib | `FloatingViewKeyboard.dylib` 37 函数；`floatingViewCamera.dylib` 162 函数 |
| 反编译 | 主 dylib 3,607 函数 / 6.1 MB pdc；prefs 1,242 函数 |

这些数字说明：原版不是“一个简单浮窗”，而是把 **SpringBoard 窗口系统 + FrontBoard scene + IOHID + 设置面板 + 32 个系统开关** 全部做了一遍。要 1:1 复刻，必须按模块拆，不能指望一个文件写完。

### 1.2 证据等级

本报告把证据分为三级：

- **A 级（直接证据）**：字符串、selector、ivar、类名、常量池、Mach-O 导入表。例如 `_setPresentationContext:`、`initWithScene:debugDescription:`、`UIScenePresentationContext`、`_initWithDefaultValues`、`FVHostingView.appScene`、`FVIOEvent.ioHIDClient`。
- **B 级（强推断）**：调用链 + selector 序列 + 字段名能拼出唯一合理解释。例如 `FVHostingView.func.00035e5c` 里先创建 `_UISceneLayerHostContainerView`，再创建 `UIScenePresentationContext`，再 `_setPresentationContext:`，最后 `addSubview:`。
- **C 级（需真机实测）**：IOHID digitizer 字段号、某些私有 selector 在 iOS 15/16 子版本上的存在性、`FBScene` 的 `_allScenesByID` 键格式、`setForeground:` 是否可用。C 级内容在代码里必须 `responds(to:)` + fallback，不能硬调。

### 1.3 方法名被 strip 的事实

原版 `__objc_methname` 只保留了系统 selector；自定义 Swift 方法名在 `swift5` 元数据里被 strip（675 处 `<stripped>`）。所以：

- **类名、字段名、协议一致性**可完整恢复（`__swift5_types/fieldmd/protos` 保留）。
- **方法名不可靠**，只能靠 `sub_xxxx` / `func.000xxxxx` 的 selector 序列和字段访问推断职责。
- 这意味着“1:1 复刻”应复刻**行为与结构**，不应追求函数级逐字节一致；任何声称“每个方法名都还原了”的说法都不可信。

### 1.4 原版骨架与二进制证据的 4 个关键偏差（必须修正）

| # | 骨架写法 | 二进制证据 | 后果 | 修正 |
|---|---|---|---|---|
| 1 | `struct FVGroup: HookGroup {}` + 每个 hook `typealias Group = FVGroup` | 16 个 hook 全部引用 `Orion.DefaultGroup`；二进制里没有自定义 Group 类型 | 按 Orion 规则，自定义 Group 不自动激活，**16 个钩子全部静默不执行**（能编译、能注入、零报错） | 删除自定义 Group，全部走 DefaultGroup；不写 `typealias Group` |
| 2 | `FVDynamicHostingView: FVHostingView` | Swift 元数据：`FVDynamicHostingView : UIView`，字段 `hostingView: FVHostingView?`、`resizeMaskView` | 结构不一致，后续键盘跟随逻辑会错 | 改成独立 `UIView`，内部持有一个 `FVHostingView` |
| 3 | `FVAppDispatchHostingView: FVHostingView` | 元数据：`FVAppDispatchHostingView : UIView`，自己有一整套 `currentActivityApp/hostingView/isDisplay/appScene/appSetting/snapshotView` 字段 | 继承会让场景容器复用错误，卡片关闭时可能带走别的 scene | 改成独立 `UIView`，自己实现 scene 挂载 |
| 4 | `FVSceneHosting.detach` 对 `scene` 调 `_setPresentationContext:` | 反编译显示 `_setPresentationContext:` 的接收者是 `containerView`，不是 scene | 关闭浮窗时解绑无效，App 画面残留/黑屏 | 只移除 container；不要对 scene 发这个方法 |

> 这 4 条是“1:1 复刻”与“照着骨架抄”的分水岭。项目里的 `Sources/` 已经按修正后的结构组织；如果继续沿用旧骨架，至少要把这 4 处改掉。

---

## 2. 什么是 iOS 上的“分屏”：三条路线与选择

### 2.1 路线 A：iPad 原生 Split View / Slide Over

iPad 的 `SBAppLayout`、`SBMainWorkspace` 支持两个 App 同时前台。但 iPhone 的 SpringBoard 没有开放这套布局；而且 RootHide/Dopamine 环境下，强行改 `SBAppLayout` 会牵动 FrontBoard 的窗口管理，稳定性极差。**不选。**

### 2.2 路线 B：FBScene 重挂载（原版路线，推荐）

SpringBoard 里每个 App 的画面不是一个 `UIView`，而是一个 `FBScene`。`FBScene` 由 FrontBoard 管理，渲染层通过 `_UISceneLayerHostContainerView` 挂到某个宿主上。把这个容器从原宿主摘下来，挂到我们的浮窗 `UIView`，App 仍然是真进程、真渲染、可交互。**这就是“分屏”的本质：不是复制画面，而是换宿主。**

优点：
- 不是截图，App 真的在跑，能点击、滚动、输入。
- 不需要改 App 本身，不需要给每个 App 注入 tweak。
- 可以同时挂多个 scene（主屏卡 + 侧边卡），形成“三屏”。

缺点：
- 依赖 FrontBoard/UIKit 私有 API，iOS 大版本会变。
- scene 生命周期必须严格管理，否则黑屏/崩溃。
- 一个 scene 同时只能有一个宿主，挂到浮窗后原全屏界面会消失（这正是我们要的）。

### 2.3 路线 C：截图 / 录屏伪装

定时 `takeScreenshot` 或 ReplayKit 取帧，贴到 `UIImageView`。实现简单，但：
- App 不在前台就停止渲染，画面卡死；
- 不能交互；
- 耗电、闪烁、隐私风险；
- 原版明确没有走这条路（`FVHostingView` 的字段是 `FBScene`，不是 `UIImageView`）。

**结论：Split View Pro 选择 B；C 只作为 scene 不可用时的降级占位（`FVSnapshotView`）。**

---

## 3. 核心机制：FBScene 嵌入的每一步

### 3.1 对象关系

```
FBSceneManager (SpringBoard 进程内单例)
   └─ _workspace : FBSceneWorkspace
        └─ _allScenesByID : [sceneID: FBScene]
FBScene
   ├─ settings : FBSSceneSettings（含 frame / foreground / userInterfaceStyle）
   ├─ _sceneContainerView : UIView（兜底宿主）
   └─ updateSettings:withTransitionContext:completion:
_UISceneLayerHostContainerView
   ├─ initWithScene:debugDescription:
   └─ _setPresentationContext:
UIScenePresentationContext
   └─ _initWithDefaultValues
```

### 3.2 原版调用序列（A 级证据）

`FVHostingView.func.00035e5c` 的反编译顺序：

```objc
// 1) 取 bundleIdentifier
NSString *bid = ...;

// 2) 创建图层宿主容器
Class c = NSClassFromString(@"_UISceneLayerHostContainerView");
id container = [[c alloc] initWithScene:scene debugDescription:nil];

// 3) 创建呈现上下文（不是 UIView！）
Class ctxCls = NSClassFromString(@"UIScenePresentationContext");
id ctx = [[ctxCls alloc] _initWithDefaultValues];

// 4) 把上下文交给容器
[container _setPresentationContext:ctx];

// 5) 保存状态
self.appScene = scene;
self.appSetting = settings;
self.hostingView = container;

// 6) 挂上去
[self addSubview:container];
```

第 3 步是最容易写错的：很多人会把 `host` 或 `scene` 当成参数传给 `_setPresentationContext:`。实际参数必须是 `UIScenePresentationContext` 实例。

### 3.3 场景设置

`FVHostingView` 的另一个函数 `sym.func.00022d8c`（95 行）做了：

```objc
FBSSceneSettings *settings = scene.settings;
UIMutableApplicationSceneSettings *mutable = [settings mutableCopy];
[mutable setForeground:YES];
[mutable setUserInterfaceStyle:host.traitCollection.userInterfaceStyle];
[scene updateSettings:mutable withTransitionContext:nil completion:nil];
```

在 iOS 15/16 上要注意：

- `settings` 可能是 `FBSSceneSettings` 或 `UIMutableApplicationSceneSettings`，用 `mutableCopy` 后按 `responds(to:)` 调 setter。
- `setForeground:` 不是每个子版本都有；没有时用 KVC `setValue:@YES forKey:@"foreground"`，再不行就不设（scene 仍可渲染，只是可能被系统判定后台）。
- `frame` 必须设成浮窗的 bounds；否则 App 会按全屏布局，内容被裁切。
- `userInterfaceStyle` 要同步，否则浮窗里的 App 是浅色、外面是深色。

### 3.4 场景查找的 4 级 fallback

原版并没有只靠一个 key；1:1 复刻应实现：

```objc
+ (FBScene *)sceneForBundleID:(NSString *)bid {
    // L1: FBSceneManager.sharedInstance._workspace._allScenesByID
    // L2: FBSceneManager.sharedInstance.workspace.allScenesByID
    // L3: FBSceneWorkspace.sharedInstance._allScenesByID (iOS 16)
    // L4: SBApplicationController -> applicationWithBundleIdentifier: -> _scene / scene
}
```

匹配规则：sceneID 通常形如 `com.apple.mobilesafari-<UUID>`，用 `hasPrefix:bid`；如果直接等于 bid 也接受。要检查 `scene.isValid`（BOOL），无效的 scene 不能挂。

### 3.5 关闭与解绑

正确顺序：

1. `[container removeFromSuperview]`；
2. `self.hostingView = nil`；
3. `self.appScene = nil`（不要对 scene 调 `_setPresentationContext:`）；
4. 如果这个 App 是我们启动的，且没有别的宿主，考虑 `[app terminate]` 或让它回到后台；
5. 不要 `destroyScene`，那是系统管理的 scene，销毁会导致 App 崩溃。

### 3.6 黑屏/白屏排查表

| 现象 | 最可能原因 | 检查 |
|---|---|---|
| 白屏，无 App 画面 | `_setPresentationContext:` 参数错 / 没调 | 打印 container 的 class、ctx 的 class；确认 selector 返回 |
| 黑屏 | scene 无效 / settings.frame 为 0 | `scene.isValid`、`settings.frame`、container.frame |
| App 画面全屏盖住浮窗 | scene 没有从原宿主摘下 / 另一个 host 还在 | 检查 `container.superview` 是否是我们的 host |
| 浮窗内 App 不能点击 | container 的 `userInteractionEnabled=false` 或被父视图挡住 | 逐层打印 `isUserInteractionEnabled`、`hitTest` |
| 旋转后错位 | 只改了 container.frame，没改 scene.settings.frame | 在 `layoutSubviews` 同步 settings |
| 关闭后 SpringBoard 卡死 | 在 dealloc/关闭时对 scene 发了私有消息 | 只移除 container，不碰 scene 生命周期 |

---

## 4. iOS 15 与 iOS 16 的差异清单

| 能力 | iOS 15 | iOS 16 | 复刻策略 |
|---|---|---|---|
| `FBSceneManager` | 存在，`sharedInstance` | 仍存在；部分版本走 `FBSceneWorkspace` | 两套都试 |
| `_workspace` | 常见 | 可能改名/换层 | try `_workspace` / `workspace` |
| `_allScenesByID` | 常见 | 部分版本仍是这个 key | try `_allScenesByID` / `allScenesByID` |
| `SBApplication._scene` | 可用 | 部分版本返回 `FBApplicationSceneHandle` 而非 `FBScene` | 取 `scene` / `_scene` / `sceneHandle.scene` 多级 |
| `_UISceneLayerHostContainerView` | 可用 | 可用，但初始化方法可能多一个参数 | `responds(to:)` 选择 `initWithScene:debugDescription:` |
| `UIScenePresentationContext` | 可用 | 可用 | `_initWithDefaultValues` fallback `init` |
| `setForeground:` | 多数可用 | 部分版本无 | KVC / 跳过 |
| `UIWindowScene.keyWindow` | iOS 15+ | 可用 | 取 `windows.first` 兜底 |
| `_UIKeyboardLayerHostView` | 存在 | 存在，层级可能变 | 只做通知，不强依赖 |
| `SBIconView` 上下文菜单 | `contextMenuInteraction:configurationForMenuAtLocation:` | 同上，但 cell 结构变 | 用真实 selector，不要用骨架里的 `configurationForIcon:` |
| `BNContentViewController` / `NCNotificationShortLookViewController` | 存在 | 存在 | 通知横幅功能可保留，但要单独测试 |
| `DNDState` | 存在 | 可能改成 `DNDStateService` | 双 targetName fallback 或放弃该 hook |

> 结论：**不要把 iOS 15 的私有 ivar 名写死**。所有 `valueForKey:` 都要 `@try/@catch`，所有私有 selector 都要 `responds(to:)`。这样同一份 binary 可以覆盖 15.0–16.6.1。

---

## 5. arm64e 专题

### 5.1 架构与设备

- arm64e：A12（iPhone XS/XR）及以后，含 A13–A16；iOS 15–16.6.1 的 Dopamine/RootHide 主要覆盖这一类。
- arm64：A11 及以前（iPhone 8/X）。如果只发 `iphoneos-arm64e`，A11 装不上；如果要兼容，`ARCHS = arm64 arm64e`，control 用 `iphoneos-arm64`。
- 本项目按用户要求只构建 **arm64e**；`Makefile` 里 `ARCHS = arm64e`。

### 5.2 PAC 与指针认证

- arm64e 的函数指针/对象指针带 PAC（Pointer Authentication Code）。**不要**把反编译里的地址（如 `0x3d938`）强转成函数指针调用；那些地址只在原始 dylib 的基址+偏移下有效，且 PAC 未签名。
- 正确做法：`NSClassFromString` + `NSSelectorFromString` + `objc_msgSend` / `perform` / KVC。这样调用由 ObjC runtime 负责签名与转发。
- 如果确实要调用 C 函数（IOHID、BKS），用 `dlsym(RTLD_DEFAULT, "symbol")` 取指针，再 `unsafeBitCast` 到正确的 `@convention(c)` 类型；不要写死地址。

### 5.3 Swift ABI 与 Orion

- iOS 12.2+ 自带 Swift runtime；iOS 15/16 没问题。
- Orion 用 Swift 写 hook，编译出的 dylib 依赖 Swift runtime；RootHide 的 ElleKit 能注入。
- 如果 Orion 版本与 Xcode Swift 版本不匹配，可能出现 `symbol not found`；GitHub Actions 用 `roothide/theos` 自带工具链，尽量固定 Xcode 版本（`macos-14` 自带 Xcode 15.x）。
- 1:1 复刻的核心 scene 代码建议用 **ObjC 动态调用**，不要用 Swift 直接 `import FrontBoard`；这样即使 SDK 没有私有头也能编译。本项目 `FVSceneHosting.swift` 已按这个原则写。

### 5.4 签名与注入

- Tweak dylib 不需要单独签名（越狱注入器会处理）；但 RootHide 对 Mach-O 的加载位置有要求：**不能放在 `jbroot:/var` 或 `jbroot:/tmp`**，否则 iOS 安全机制拒绝加载。放在 `jbroot:/Library/MobileSubstrate/DynamicLibraries`。
- RootHide 下所有二进制默认被 sandbox；tweak 注入 SpringBoard 后继承 SpringBoard 的权限，一般不需要额外 entitlements。若做独立 App/daemon，加 `platform-application`、`com.apple.private.security.no-sandbox`、`com.apple.private.security.storage.AppBundles`、`com.apple.private.security.storage.AppDataContainers`。

---

## 6. RootHide 专题：路径、打包、注入

### 6.1 RootHide 与 rootless 的根本区别

| 维度 | rootless（Dopamine 普通版） | RootHide |
|---|---|---|
| 越狱根目录 | 固定 `/var/jb` | 每次越狱随机 `jbroot` 目录 |
| 依赖库 install_name | `/var/jb/usr/lib/...` | `@loader_path/.jbroot/usr/lib/...` |
| 目录符号链接 | `/var/jb` 固定 | 每个含 Mach-O 的目录自动生成 `.jbroot` 符号链接指向 jbroot |
| 命令行工具根 | iOS rootfs | jbroot；用 `rootfs` 符号链接访问 iOS 原根 |
| 源码取路径 | 直接拼 `/var/jb` | `jbroot("/path")` |
| 第三方 App 注入 | 默认注入 | **默认不注入**，需在 Bootstrap App List 里逐个打开 |

### 6.2 `jbroot()` 的正确用法

RootHide 官方文档给出的写法：

```c
#include <roothide.h>

const char *c_path = jbroot("/path/to/jb/file");
NSString *objc_path = jbroot(@"/path/to/jb/file");
std::string cpp_path = jbroot(std::string("/path/to/jb/file"));
```

要点：
- `jbroot()` 返回的是**当前这次越狱**的随机根目录下的绝对路径；不要缓存到跨重启的 plist 里。
- Theos 在 rootful/rootless 下会把 `jbroot()` 编译成空 stub（即返回原路径），所以同一份代码可以三环境共用。
- Swift 项目建议用 bridging header `#include <roothide.h>`，不要在 Swift 源文件里 `import roothide`；这样 rootful/rootless 也能编译。
- 不要写 `/var/jb`；RootHide 没有这个固定路径。也不要写 `NSHomeDirectory()` 拼 jailbreak 路径。

### 6.3 Split View Pro 的路径策略

| 内容 | 路径 | 说明 |
|---|---|---|
| 主 dylib | `jbroot/Library/MobileSubstrate/DynamicLibraries/SplitViewPro.dylib` | Theos `INSTALL_PATH` 自动处理 |
| 过滤器 plist | 同目录 `SplitViewPro.plist` | `Bundles: com.apple.springboard` |
| 设置 bundle | `jbroot/Library/PreferenceBundles/SplitViewProPrefs.bundle` | 可选；见 `prefs-layout/` |
| 设置入口 plist | `jbroot/Library/PreferenceLoader/Preferences/SplitViewProPrefs.plist` | 可选 |
| 运行数据（浮窗位置/归一化坐标） | `jbroot("/var/mobile/Library/SplitViewPro")` | RootHide 文档明确建议 tweak 数据放 jbroot 的 `/var` 下 |
| 偏好 plist | `CFPreferences` 域 `com.nailong.split` | 由 cfprefsd 落在 rootfs 的 `Preferences`，跨 Settings/SpringBoard 可读；不要手拼 jbroot 路径 |
| 音效资源 | 设置 bundle 内 `Sounds/arc_sound.aif` | 用 `Bundle` 定位，不要拼 `/var/jb` |

> 注意：RootHide 文档说“除了 jbroot 的 `/var/`，tweak 可能无法写其他 jailbreak 目录（即使通过 libSandy）”。所以运行数据统一放 `jbroot("/var/mobile/Library/SplitViewPro")`，不要写 `jbroot/Library/...` 下的可写文件。

### 6.4 RootHide 打包

官方推荐：

```sh
# 安装支持 roothide 的 theos
bash -c "$(curl -fsSL https://raw.githubusercontent.com/roothide/theos/master/bin/install-theos)"

# 构建
make package THEOS_PACKAGE_SCHEME=roothide
```

Theos 会自动：
- 把安装路径放到 jbroot；
- 处理 `@loader_path/.jbroot/...` 的 install_name；
- 生成 `.jbroot` 符号链接；
- 在 rootless/rootful 下把 `jbroot()` 变成 stub。

如果从旧的 rootless 工程迁移，Theos 会提示 rootless path macro 警告；确认代码里没有 `/var/jb` 后可定义 `DISABLE_ROOTLESS_COMPAT_WARNING` 消掉。

### 6.5 RootHide 注入

- `SplitViewPro.plist` 只写 `Bundles: com.apple.springboard`。SpringBoard 是系统进程，RootHide 不会把它当“第三方 App”。
- 被浮窗化的 App **不需要**注入：scene 渲染发生在 SpringBoard 进程，App 进程只负责自己的内容。不要把 filter 写成 `Executables` 或全 App，否则 RootHide 的 App List 会让你逐个开，且增加崩溃面。
- 如果以后要做“在每个 App 内显示浮窗按钮”，才需要给目标 App 开注入；那是另一个产品决策。

### 6.6 RootHide 常见坑

| 坑 | 现象 | 解法 |
|---|---|---|
| 写死 `/var/jb` | RootHide 下资源找不到、dylib 不加载 | 全部改 `jbroot()` |
| 把 dylib 放 `jbroot/var` 或 `jbroot/tmp` | iOS 拒绝加载 Mach-O | 放 `Library/MobileSubstrate/DynamicLibraries` |
| 用 `NSHomeDirectory()` 找 jbroot | 拿到 App 容器，不是 jbroot | 用 `jbroot()` |
| 在 rootfs 写运行数据 | RootHide 可能拦截/污染系统 | 写 `jbroot("/var/mobile/Library/...")` |
| 缓存 jbroot 路径 | 重启越狱后路径变了 | 每次启动重新 `jbroot()` |
| 设置 bundle 不显示 | PreferenceLoader 没注入 Settings / 路径不对 | 确认 `PreferenceBundles` 与 `PreferenceLoader` 都在 jbroot；Settings 需允许 tweak 注入 |
| 只构建 arm64 | arm64e 设备装不上/不加载 | `ARCHS = arm64e` 或 fat |
| 直接复用 rootless deb | 依赖 `/var/jb` 的 `Pre-Depends: rootless-compat` 可能不满足 | 用 `THEOS_PACKAGE_SCHEME=roothide` 重新打包 |

---

## 7. 窗口、层级与“不抢焦点”

### 7.1 三层窗口

| 类 | level | 职责 | 注意 |
|---|---|---|---|
| `FVWindow : UIWindow` | **27.0** | 浮窗主体容器 | `initWithWindowScene:`，不要用 `init(frame:)`；`hidden=NO` 即可，未必需要 `makeKeyAndVisible` |
| `FVFrontConsoleWindow : UIWindow` | **28.0** | 操控台/搜索面板 | 必须盖住浮窗；默认隐藏，呼出时显示 |
| `FVRootWindow`（包 `UIRootSceneWindow`） | RootScene 层级 | 侧边栏，贴物理屏幕边缘、跟随旋转 | 不是 `UIWindow`，内部做反向 transform |

原版的 `setWindowLevel:` 立即数直接暴露了 27/28（见 `DEEP_DIVE_ALGORITHMS` 常量表）。复刻时不要用 `UIWindowLevelAlert`（2000）之类的系统层级，会把状态栏/弹窗全盖住。

### 7.2 为什么侧边栏要挂 RootScene

普通 `UIWindow` 的坐标系会跟随界面旋转；侧边栏要求“永远贴物理屏幕左/右边缘、不跟着转”，只能挂到 `UIRootSceneWindow` 的 rootView 上，再在内部对内容做反向旋转。`FVRootWindow` 只有 708 字节，但它是横竖屏体验的关键。

### 7.3 不抢焦点基类

```swift
open class FVDisabledTaskScreenView: UITextField {
    public override var canBecomeFirstResponder: Bool { false }
    public override var canBecomeFocused: Bool { false }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        isSecureTextEntry = true   // 不进录屏/截屏
        backgroundColor = .clear
        tintColor = .clear
        textColor = .clear
    }
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let v = super.hitTest(point, with: event)
        return v === self ? nil : v   // 自己不吃触摸，只让子视图吃
    }
}
```

三个收益：
1. `canBecomeFirstResponder=false`：里面即使有输入框也不弹系统键盘；
2. `canBecomeFocused=false`：不抢遥控/焦点；
3. `isSecureTextEntry=true`：Secure Text Entry 层默认不进截屏/录屏，浮窗内容天然不被录进去。

> 注意：`isSecureTextEntry` 会让系统认为这是密码输入，某些辅助功能/截图行为会变化；这是原版的取舍，复刻时保留，但要在关于页说明。

---

## 8. 输入层：IOHID 与手势

### 8.1 为什么 UIKit 不行

iOS 的刘海两侧/底部 Home 指示条区域被 SpringBoard 的系统手势占用。在 `UIWindow` 上加 `UIPanGestureRecognizer`，触摸会先被系统吃掉；只有 `IOHIDEventSystemClient` 能在事件进入系统手势识别之前拿到原始 digitizer 数据。

### 8.2 原版字段（A 级证据）

`FVIOEvent` 的 17 个字段：

```
ioHIDClient: OpaquePointer?
ioHIDRunLoopSchedule: CFRunLoop?
mainBounds: CGRect?
width / height: CGFloat
isTouchCustomSize / isTouchRight / isTouchLeft: Bool
abs_x / abs_y: CGFloat
right_move_status / left_move_status: Bool
isInit: Bool
touchType_arc: Bool
touchType_console: Bool
eligibleTouchIndex: Int32
lastTouchObjPoint: [Int32: CGPoint]
cancelGestureStatus: Bool
```

导入的符号：`IOHIDEventSystemClientCreate/RegisterEventCallback/ScheduleWithRunLoop/UnscheduleWithRunLoop/UnregisterEventCallback`、`IOHIDEventGetType/GetIntegerValue/GetFloatValue/GetChildren`、`BKSHIDServicesCancelTouchesOnAllDisplays`。

### 8.3 实现要点

- `IOHIDEventSystemClientCreate(kCFAllocatorDefault)`；
- 注册回调，`IOHIDEventGetChildren(event)` 逐根手指；
- `IOHIDEventGetFloatValue(child, 0x10000/0x10001)` 取 X/Y（**必须实测校准**）；
- `IOHIDEventGetIntegerValue(child, 0x10008)` 取 touch down/up（同样是经验值）；
- `IOHIDEventSystemClientScheduleWithRunLoop(client, CFRunLoopGetMain(), kCFRunLoopDefaultMode)`；
- 需要抢断时调 `BKSHIDServicesCancelTouchesOnAllDisplays()`，并用 `cancelGestureStatus` 做 0.15s 冷却，避免把系统手势搞坏。

### 8.4 风险与建议

- IOHID 能读取**全局触摸坐标**，属于敏感能力；只在本机处理，不要上传、不要写日志到磁盘。
- 抢断系统触摸会影响 Home 指示条、控制中心、通知中心；只在“确实要从边缘唤出”时抢断，且加冷却。
- iOS 15/16 的 digitizer 字段号可能不同；第一版建议把 IOHID 做成**可开关的实验特性**，默认用悬浮球/卡片手势，IOHID 只做边缘唤出。
- 如果 IOHID 初始化失败，必须静默降级，不影响悬浮球和卡片。

---

## 9. 卡片、三屏与手势数学

### 9.1 三屏布局

原版不是三个进程，而是同一个 `FVAppDispatchView` 里放 3 个 `FVAppDispatchItem`：

```
主屏浮窗（center，1 个）
+ 侧边小窗（left/right，N 个，N = dispatchHostingView_sideViewItemCount）
```

`multipleScreenRenderPosition` 决定竖屏三屏还是横屏浮窗；`dispatchHostingView_mainItem_closed_donotAutoLayout` 关闭时，关掉主屏会把最后一个侧窗拉回主屏。

### 9.2 拖动算法（原版实证）

不是 `center += translation`，而是二维旋转矩阵补偿：

```
Δx = tx·cosθ − ty·sinθ
Δy = tx·sinθ + ty·cosθ
newCenter = center + (Δx, Δy) · k
k = 1.0（侧边卡）或 (rectMaxX / bounds.height) · scale（主屏卡）
```

θ 是 `FVAppDispatchView.angle`。不做这个补偿，斜置浮窗拖动会“走歪”。

### 9.3 弹簧参数（常量池实证）

| 参数 | 值 | 证据 |
|---|---|---|
| damping | **0.4** | `0x3fd999999999999a` @ `0x89954` |
| duration | **0.45** | `0x3fdccccccccccccd` @ `0x8995c` |
| velocity | 运行时从手势算 | `d9` |
| 拖动后归零 | 0.1s 动画 + `setTranslation(.zero)` | `0x3fb999999999999a` |

### 9.4 拖到底部全屏

原版用真实的 `FVDragLabelView`（带 `interfaceNum` ivar）做底部热区，不是硬编码 `screen.height - 34`：

```objc
CGRect cardRect = [self convertRect:self.bounds toView:window];
CGRect targetRect = [dragLabelView convertRect:dragLabelView.bounds toView:window];
BOOL hit = CGRectIntersectsRect(cardRect, targetRect);
self.intersectWithDragLabel = hit;
```

这样不同机型/横竖屏都准。

### 9.5 位置持久化

原版写到 `/var/mobile/Library/FloatingViewInfo/` 下的 6 个 txt，值都是 0–1 归一化：

```
floatingViewVCenterX.txt / Y.txt
floatingViewHCenterX.txt / Y.txt
floatingViewVScale.txt / HScale.txt
```

归一化的好处：换分辨率/旋转不丢位置。RootHide 下改到 `jbroot("/var/mobile/Library/SplitViewPro")`。

---

## 10. 1:1 复刻模块清单（原版类 → 本项目文件）

### 10.1 核心层

| 原版类 | 职责 | 本项目文件 | 状态 |
|---|---|---|---|
| `FVDisabledTaskScreenView` | 不抢焦点基类 | `Sources/Core/FVDisabledTaskScreenView.swift` | ✅ |
| `FVSceneHosting`（原版无此类名，逻辑在 FVHostingView） | scene 查找/挂载 | `Sources/Core/FVSceneHosting.swift` | ✅ 已改为 AnyObject + KVC |
| `FVHostingView` | 单个 App 画面宿主 | `Sources/Core/FVHostingView.swift` | ✅ |
| `FVDynamicHostingView` | 跟随键盘的变体 | `Sources/Core/FVDynamicHostingView.swift` | 🟡 需改成独立 UIView（见 1.4） |
| `FVSnapshotView` | 首帧占位 | `Sources/Core/FVSnapshotView.swift` | ✅ |
| `FVWindow` | level 27 | `Sources/Core/FVWindow.swift` | ✅ |
| `FVFrontConsoleWindow` | level 28 | `Sources/Core/FVFrontConsoleWindow.swift` | ✅ |
| `FVRootWindow` | RootScene 包壳 | `Sources/Core/FVRootWindow.swift` | ✅ |
| `FVScreenUtils` | 屏幕几何/方向 | `Sources/Core/FVScreenUtils.swift` | ✅ |

### 10.2 调度/卡片层

| 原版类 | 职责 | 本项目文件 | 状态 |
|---|---|---|---|
| `FVAppDispatchView` | 三屏调度核心（20,056 B） | `Sources/Dispatch/FVAppDispatchView.swift` | ✅ 结构 |
| `FVAppDispatchItem` | 卡片四组手势（10,856 B） | `Sources/Dispatch/FVAppDispatchItem.swift` | ✅ 结构 |
| `FVAppDispatchHostingView` | 卡片内 scene 容器 | `Sources/Dispatch/FVAppDispatchHostingView.swift` | 🟡 需独立 UIView |
| `FVAppDispatchSideMarkView` | 三条边缘提示条 | `Sources/Dispatch/FVAppDispatchSideMarkView.swift` | ✅ |
| `FVFloatingActionView` | 悬浮球（13,112 B） | `Sources/Dispatch/FVFloatBallView.swift` | ✅ 已接入 FVBootstrap |
| `FVBroadsideView` | 侧边横排浮窗 | 无独立文件 | 🟡 可选 |

### 10.3 输入/菜单/侧栏

| 原版类 | 职责 | 本项目文件 | 状态 |
|---|---|---|---|
| `FVIOEvent` | IOHID 采集 | `Sources/Input/FVIOEvent.swift` + `FVHIDEvent.m` | ✅ 桥接版 |
| `FVGestureUtils` | 热区/状态机 | `Sources/Input/FVGestureUtils.swift` | ✅ |
| `FVArcContainerView` | 环形菜单容器（13,232 B） | `Sources/Arc/FVArcContainerView.swift` | ✅ |
| `FVArcTerraceItem` | 单层 collectionView | `Sources/Arc/FVArcTerraceItem.swift` | ✅ |
| `FVArcLayout` | 极坐标布局 | `Sources/Arc/FVArcLayout.swift` | ✅ |
| `FVArcItem` | cell | `Sources/Arc/FVArcItem.swift` | ✅ |
| `FVSideBarContainerView` | 侧边栏（9,588 B） | `Sources/SideBar/FVSideBarContainerView.swift` | ✅ |
| `FVSideBarContentView` | 图标列表 | `Sources/SideBar/FVSideBarContentView.swift` | ✅ |

### 10.4 工具/钩子/设置

| 原版 | 职责 | 本项目 | 状态 |
|---|---|---|---|
| `FVSysButtonUtils` | 32 个系统动作（1,203 行） | `Sources/Tools/FVSysButtonUtils.swift` | ✅ 结构，部分 selector 需实测 |
| `FVToolAction` | 32 个动作枚举 | `Sources/Tools/FVToolAction.swift` | ✅ |
| `FVFeedback` | 振动/音效 | `Sources/Tools/FVFeedback.swift` | ✅ |
| 16 个 Orion hook | SpringBoard/FrontBoard/通知/键盘 | `Sources/Hooks/` | ✅ 已改为 NSObject+targetName |
| 26 页设置 | `PSListController` | `prefs/` | 🟡 可选 bundle，需 Preferences 私有头 |

### 10.5 设置面板

`prefs/` 里 26 页、238 个控件、94 个键是原版的完整设置树。由于 `Preferences` 是私有框架，GitHub Actions 的 SDK 不一定带模块；本项目默认 `BUILD_PREFS=0`，先保证主 deb 能出。需要完整设置面板时：

1. 把 `prefs-layout/Library` 合并到 `layout/Library`；
2. `make package BUILD_PREFS=1 THEOS_PACKAGE_SCHEME=roothide`；
3. 如果 `import Preferences` 失败，在 Theos 里补 `Preferences` 私有头/模块，或把设置页改成 ObjC + `PSListController`（同样需要头文件）。

---

## 11. 1:1 复刻的实施顺序（P0–P4）

### P0：scene 挂载 Demo（1–2 天）

目标：在 SpringBoard 里把 Safari 的 scene 挂到一个 300×400 的 UIView 上，能点击。

验收：
- `scene.isValid == YES`；
- `container.superview == host`；
- 浮窗里的 Safari 能滚动；
- 关闭浮窗后 SpringBoard 不崩。

### P1：单卡片浮窗（2–3 天）

- `FVWindow` level 27；
- 顶部/底部拖动，四角缩放；
- 拖到底部半透明 + 全屏；
- 位置归一化落盘。

### P2：多卡片/三屏（3–5 天）

- `FVAppDispatchView` 管理 `[FVAppDispatchItem]`；
- 主屏 + 左右侧卡；
- 交换主次屏、自动布局、关闭回收；
- 侧边栏 `FVSideBarContainerView`。

### P3：入口与工具（3–5 天）

- 悬浮球 `FVFloatingActionView`；
- 环形菜单 `FVArcContainerView`（极坐标 + 4 层）；
- 搜索面板 `FVSearchVC`；
- 32 个工具动作（先做飞行/WiFi/低电量/手电筒/注销/重启）。

### P4：钩子与设置（5–7 天）

- 16 个 Orion hook（按 `DEEP_DIVE_ORION_PITFALLS` 的 5 条铁律）；
- 26 页设置面板；
- 通知横幅、键盘跟随、通用链接、图标菜单；
- RootHide 真机回归。

> 总计约 3–4 周（与原版 `DEEP_DIVE_COMPONENTS` 的估算一致）。任何“1 天复刻全部”的说法都不现实。

---

## 12. 安全、稳定性与合规

1. **私有 API**：`FBScene`、`_UISceneLayerHostContainerView`、`UIScenePresentationContext`、`_setPresentationContext:` 都是私有 API；只能用于越狱环境，不能上 App Store。
2. **IOHID 全局触摸**：能读取整屏触摸坐标，属于敏感能力；不要上传、不要持久化、不要在关于页隐瞒。
3. **KVC 穿透**：`_workspace`、`_allScenesByID`、`_sceneContainerView` 等私有 ivar 在 iOS 17+ 可能消失；所有 KVC 包 `@try/@catch`，失败降级。
4. **相机/麦克风**：原版有一个 `floatingViewCamera.dylib` 注入 `mediaserverd` 判断相机权限；Split View Pro 的分屏不需要它。**不要**默认带上，减少攻击面。
5. **键盘 dylib**：原版 `FloatingViewKeyboard.dylib` 只监听 `com.be-huge.floating-view-keyboard.dismiss`；如果 1:1 需要键盘跟随，再做，且只注入 `UIKeyboardImpl` 宿主。
6. **可疑白名单文件**：原版 prefs bundle 里有一个 `wlist/ssssvpbmd.txt`（330 KB，1062 项 `"32位hex:64位hex"`），形态像授权/白名单校验表，且主 dylib 字符串表里没有路径引用。Split View Pro **不要**继承这个文件；如果要做授权，必须明确告知用户并遵守当地法律。
7. **稳定性优先**：所有私有调用都要 `responds(to:)`；scene 找不到就显示快照占位，绝不能让 SpringBoard 崩。SpringBoard 崩了就是安全模式，用户体验比“没分屏”更差。
8. **开源/分发**：如果参考了 be-huge 的原版实现，请在 README 里注明“架构参考 floatingView 1.6.0-6 逆向分析”，并遵守原作者的许可；不要把原版二进制改名后当成自己的作品分发。

---

## 13. GitHub macOS 打包（本项目已配好）

### 13.1 工作流

`.github/workflows/build.yml`：

- runner：`macos-14`；
- 安装 `roothide/theos`；
- matrix：`roothide` / `rootless`；
- `make package FINALPACKAGE=1`；
- 上传 `packages/*.deb` 为 artifact。

### 13.2 本地等价命令

```sh
export THEOS=$HOME/theos
make package THEOS_PACKAGE_SCHEME=roothide FINALPACKAGE=1
# 或
make package THEOS_PACKAGE_SCHEME=rootless FINALPACKAGE=1
```

### 13.3 安装

```sh
scp packages/com.nailong.split_1.0.0_iphoneos-arm64e.deb root@<device>:/var/mobile/Documents/
ssh root@<device> 'dpkg -i /var/mobile/Documents/com.nailong.split_1.0.0_iphoneos-arm64e.deb && killall -9 SpringBoard'
```

### 13.4 构建失败排查

| 错误 | 原因 | 解法 |
|---|---|---|
| `THEOS not set` | 工作流没把 `$HOME/theos` 导出到后续 step | `echo "THEOS=$HOME/theos" >> $GITHUB_ENV` |
| `xcrun: error: SDK "iphoneos" cannot be located` | Xcode 没选对 | `sudo xcode-select -s /Applications/Xcode.app` |
| `Orion` 找不到 | Theos 没装 Orion / 版本不对 | 用 `dev.theos.orion` 对应版本，或先把 hooks 改为 Logos/ObjC |
| `Preferences` 模块找不到 | 私有头缺失 | `BUILD_PREFS=0` 先出主 deb，或补私有头 |
| `arm64e` 不支持 | Xcode 太旧 | 用 `macos-14` + Xcode 15+ |
| deb 安装后无效果 | filter plist 没进包 / SpringBoard 没重启 | `dpkg -c` 检查 `/Library/MobileSubstrate/DynamicLibraries`；`killall -9 SpringBoard` |

---

## 14. 最终判断

**Go。** 技术路线成立，原版已经证明 `FBScene` 重挂载在 iOS 15/16 上可行；Split View Pro 只要坚持三件事：

1. **真 scene，不截图**；
2. **所有私有 API 运行时解析 + 多版本 fallback**；
3. **RootHide 路径全部走 `jbroot()`，不写死 `/var/jb`**。

**最大的三个风险**（按优先级）：

| 风险 | 影响 | 缓解 |
|---|---|---|
| `FBScene` 私有结构在 16.x 子版本变化 | 浮窗黑屏/挂不上 | 4 级 fallback + 快照降级 + 真机矩阵 |
| IOHID 字段号/权限问题 | 边缘唤出失效或误抢系统手势 | 默认关闭，悬浮球兜底；实测校准 |
| RootHide 设置 bundle/路径 | 设置面板不显示、资源找不到 | `jbroot()` + 可选 prefs bundle + 三环境构建 |

> 这份报告对应的工程在 `SplitViewPro/`：`Makefile`、`control`、filter plist、62 个 Swift 源文件、HID/ObjC 桥、GitHub Actions 都已就位。先跑 `P0` 的 scene 挂载 Demo，再逐层加卡片和菜单；不要一上来就抄 26 页设置面板。
