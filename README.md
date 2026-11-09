# Split View Pro

**iOS 15–16 · arm64e · RootHide · 分屏/浮窗插件**

- Package：`com.nailong.split`
- Name：`Split View Pro`
- Author：`nailong`
- Version：`1.0.0`
- 目标：iOS 15.0–16.6.1，arm64e（A12+），RootHide bootstrap；同时支持 rootless 构建

> 架构参考 `floatingView 1.6.0-6`（be-huge）的完整逆向分析。详细报告见仓库根目录外的
> `SplitViewPro-越狱分析.md`（或 `docs/` 中同名文件）。

---

## 1. 一键构建 deb（GitHub Actions，macOS）

把本目录推到一个 GitHub 仓库，`.github/workflows/build.yml` 会自动：

1. 在 `macos-14` 上安装 `roothide/theos`；
2. 分别以 `roothide` / `rootless` 两种 scheme 执行 `make package`；
3. 上传 `packages/*.deb` 到 Actions Artifacts。

手动触发：仓库 → Actions → **Build Split View Pro deb** → Run workflow。

产物名称：

```
SplitViewPro-roothide-deb / SplitViewPro-rootless-deb
```

---

## 2. 本地构建

```sh
# 1) 安装 roothide/theos（已安装可跳过）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/roothide/theos/master/bin/install-theos)"
export THEOS=$HOME/theos

# 2) RootHide 包
make package THEOS_PACKAGE_SCHEME=roothide FINALPACKAGE=1

# 3) 普通 Dopamine rootless 包（可选）
make package THEOS_PACKAGE_SCHEME=rootless FINALPACKAGE=1
```

产物在 `packages/`。

### 只构建主 tweak（默认）

`BUILD_PREFS=0` 是默认值，只出 `SplitViewPro.dylib` + filter plist 的 deb。
这样即使 CI 的 SDK 没有 `Preferences` 私有头，也能稳定出包。

### 需要 26 页设置面板

```sh
# 把可选布局合并进 layout
cp -R prefs-layout/Library layout/

# 打开设置 bundle 构建
make package THEOS_PACKAGE_SCHEME=roothide BUILD_PREFS=1 FINALPACKAGE=1
```

`prefs/` 里的 26 个 `PSListController` 页面依赖 `Preferences` 私有框架；
如果 GitHub runner 的 SDK 没有对应模块，先保持 `BUILD_PREFS=0`，把设置面板作为第二阶段。

---

## 3. 安装到 RootHide 设备

```sh
scp packages/com.nailong.split_1.0.0_iphoneos-arm64e.deb root@<device>:/var/mobile/Documents/
ssh root@<device> 'dpkg -i /var/mobile/Documents/com.nailong.split_1.0.0_iphoneos-arm64e.deb'
ssh root@<device> 'killall -9 SpringBoard'
```

RootHide 注意：

- 包会安装到随机 `jbroot`，不要手动 `cp` 到 `/var/jb`；
- 确认 `dpkg -L com.nailong.split` 能看到：
  - `/Library/MobileSubstrate/DynamicLibraries/SplitViewPro.dylib`
  - `/Library/MobileSubstrate/DynamicLibraries/SplitViewPro.plist`
- RootHide 默认不向第三方 App 注入 tweak；本插件只注入 SpringBoard，不需要在 Bootstrap 的 App List 里开任何 App。

---

## 4. 目录结构

```
SplitViewPro/
├── Makefile                      # Theos 构建（roothide/rootless、arm64e）
├── control                       # com.nailong.split
├── .github/workflows/build.yml   # macOS 打包 deb
├── SplitViewPro-Bridging-Header.h
├── Sources/
│   ├── Tweak.swift               # Orion 入口（DefaultGroup）
│   ├── FVBootstrap.swift         # 启动编排 + 悬浮球
│   ├── Core/                     # 窗口 / scene / 基类 / 快照
│   ├── Dispatch/                 # 浮窗卡片 / 三屏 / 悬浮球
│   ├── Arc/                      # 环形菜单
│   ├── SideBar/                  # 侧边栏
│   ├── Input/                    # IOHID 桥 + 手势
│   ├── Tools/                    # 32 个系统动作
│   ├── Hooks/                    # 15 个 Orion hook
│   ├── Prefs/                    # 偏好键 / 默认值 / 热重载
│   └── Support/                  # App 查询 / 日志 / ObjC 桥
├── prefs/                        # 26 页设置面板（可选）
├── prefs-layout/                 # 设置 bundle 的 layout（可选）
└── layout/                       # 主 tweak layout
```

---

## 5. 当前实现状态（务必按 `SplitViewPro-越狱分析.md` §10 阅读）

| 模块 | 状态 | 说明 |
|---|---|---|
| `FBScene` 嵌入核心 | ✅ 已按反编译证据重写 | `FVSceneHosting.swift`：`_UISceneLayerHostContainerView` + `UIScenePresentationContext` + `_setPresentationContext:` |
| 窗口层级 27/28 | ✅ | `FVWindow` / `FVFrontConsoleWindow` |
| 不抢焦点基类 | ✅ | `FVDisabledTaskScreenView : UITextField` |
| 浮窗卡片 / 三屏 | ✅ 结构 | `FVAppDispatchView` / `FVAppDispatchItem` |
| 悬浮球 | ✅ 已接入 | `FVBootstrap` 创建 `FVFloatingActionView` |
| 环形菜单 / 侧边栏 | ✅ 结构 | 极坐标布局、侧边手势 |
| IOHID | ✅ ObjC 桥 | `FVHIDEvent.m`，字段号需真机校准 |
| 32 个系统动作 | 🟡 部分 selector 需实测 | `FVSysButtonUtils.swift` |
| 16 个 Orion hook | ✅ 已修正 Group/targetName | 详见 `DEEP_DIVE_ORION_PITFALLS` |
| 26 页设置面板 | 🟡 可选 bundle | 需 `Preferences` 私有头 |

> 这不是“复制原版二进制”，而是按逆向证据重写的可编译工程骨架 + 核心实现。
> 首次真机建议先做 `P0`：只挂一个 Safari scene，确认能点击、能关闭、不崩 SpringBoard。

---

## 6. RootHide 路径规范（改代码前必读）

| 内容 | 正确写法 | 错误写法 |
|---|---|---|
| dylib / bundle | Theos `INSTALL_PATH` 自动放 jbroot | 手写 `/var/jb` |
| 运行数据 | `jbroot("/var/mobile/Library/SplitViewPro")` | `jbroot/Library/...` 写文件 |
| 读配置 | `CFPreferences` 域 `com.nailong.split` | 手拼 plist 路径 |
| 音效 | `Bundle`/bundle 内 `Sounds/` | `/var/jb/Library/...` |
| Mach-O 位置 | `Library/MobileSubstrate/DynamicLibraries` | `jbroot/var` 或 `jbroot/tmp`（iOS 拒绝加载） |

RootHide 的 `jbroot` 每次越狱随机；不要缓存到 plist。`jbroot()` 在 rootless/rootful 下是空 stub，
所以同一份代码三环境可编译。

---

## 7. 调试

```sh
# 看 dylib 是否加载
ssh root@<device> 'grep -i SplitViewPro /var/log/syslog | tail -50'

# 看包内容
dpkg -c packages/*.deb

# 看 filter plist
plutil -p /Library/MobileSubstrate/DynamicLibraries/SplitViewPro.plist

# 崩溃日志
ls -lt /var/mobile/Library/Logs/CrashReporter/ | head
```

建议在 `FVSceneHosting.attach` 里加临时日志：

```
[SplitViewPro] scene=<id> valid=<bool> container=<class> settings=<class>
```

如果日志里 `container=<null>`，说明 `_UISceneLayerHostContainerView` 不可用，检查 iOS 版本/类名。

---

## 8. 合规声明

本项目仅用于**已越狱设备**的系统级定制研究。使用 `FBScene`、`_UISceneLayerHostContainerView`、
`UIScenePresentationContext` 等私有 API 违反 App Store 审核规则，禁止用于上架应用。
请勿把原版 `floatingView` 的二进制改名后分发；架构参考请注明出处。
