# Netto 架构迁移 — 阶段 0 基线与事实地图

> 生成时间：2026-09-11（阶段 0 冻结基线）
>
> 依据：`docs/lumi-architecture-rearchitecture-plan.md` 阶段 0 要求。本文件记录命令、真实结果、已知警告和不能在本次迁移中改变的兼容项。后续 agent 只凭本文件即可复现当前入口、数据目录、target 和工程警告。

## 1. 仓库基线

### 1.1 git 状态（迁移前快照）

```text
$ git status --short
?? docs/lumi-architecture-agent-prompt.md     # 用户提供的重构指令（未跟踪）
?? docs/lumi-architecture-rearchitecture-plan.md  # 实施蓝图（未跟踪）

$ git log -8 --oneline --decorate
3d0a49e (HEAD -> dev, tag: p2.3.10, origin/pre, origin/dev, origin/HEAD) 👷 CI: Bump a new version
3844ff2 💄 UI: Add empty state view for app list
12d528b 📖 Document: Update Swift coding rules and app views
56cbc98 (tag: p2.3.9) 👷 CI: Bump a new version
a510260 💄 UI: Update AppIcon2 with new icon set
76e1974 🆕 Feature: Add plugin system and filter functionality
5f78aa7 🆕 Feature: Add AppIcon2 with iOS and macOS variants
5bf7b69 🎨 Chore: Add missing .gitok directory with icons subfolder
```

- 工作树除两份未跟踪的规划文档外**干净**，无 dirty/staged 改动。迁移期间不得覆盖这两份文档。

### 1.2 Xcode 工程与 Scheme

```text
$ xcodebuild -project TravelMode.xcodeproj -list
Targets:        TavelMode          # App target（工程既有拼写，勿改）
                Extension         # System Extension target
Build Configurations: Debug, Release
Schemes:        Extension, Mock-Store, TravelMode, TravelMode-DEBUG, TravelMode-EN
```

- 注意：App target 名为 **TavelMode**（缺一个 'l'），`PRODUCT_NAME = TavelMode`，`FULL_PRODUCT_NAME = TavelMode.app`。这是既有工程拼写，不得改名。
- Package Graph 基线警告：`the target name MagicHTTP has different case on the filesystem and the Package.swift manifest file`（MagicKit 远程包，非本次迁移引入，迁移期间不处理）。

### 1.3 已解析远程包

```text
ID3TagEditor 4.6.0, AsyncAlgorithms 0.1.0, ZIPFoundation 0.9.19,
MagicKit dev (d04a729)  # 提供 MagicCore/MagicUI/MagicAlert/MagicBackground/MagicContainer/MagicDevice/MagicDesktop/MagicError/MagicAsset
swift-collections 1.2.1
```

### 1.4 App target 关键 build settings（TravelMode-DEBUG / Debug）

```text
PRODUCT_BUNDLE_IDENTIFIER  = com.yueyi.TravelMode
PRODUCT_NAME               = TavelMode
MACOSX_DEPLOYMENT_TARGET   = 15.0
SWIFT_VERSION              = 6.0
INFOPLIST_FILE             = Core/Info.plist
CODE_SIGN_ENTITLEMENTS     = Core/Signing.entitlements
DEVELOPMENT_TEAM           = Y6HZ9JJYV6
SYSTEM_EXTENSIONS_FOLDER_PATH = TavelMode.app/Contents/Library/SystemExtensions
REGISTER_APP_GROUPS        = YES
```

### 1.5 Extension target 关键 build settings（Extension / Debug）

```text
PRODUCT_BUNDLE_IDENTIFIER  = com.yueyi.TravelMode.Extension
FULL_PRODUCT_NAME          = com.yueyi.TravelMode.Extension.systemextension
MACOSX_DEPLOYMENT_TARGET   = 15.0
SWIFT_VERSION              = 6.0
INFOPLIST_FILE             = Extension/Info.plist
CODE_SIGN_ENTITLEMENTS     = Extension/Signing.entitlements
DEVELOPMENT_TEAM           = Y6HZ9JJYV6
```

### 1.6 Entitlements（兼容红线，迁移不得改变）

App `Core/Signing.entitlements`：

- `com.apple.developer.networking.networkextension` = `[content-filter-provider]`
- `com.apple.developer.system-extension.install` = true
- `com.apple.security.app-sandbox` = true
- `com.apple.security.application-groups` = `$(TeamIdentifierPrefix)com.yueyi.TravelMode.SimpleFirewall`
- `com.apple.security.files.downloads.read-write`、`com.apple.security.files.user-selected.read-only` = true

Extension `Extension/Signing.entitlements`：app-sandbox、相同 App Group、networkextension content-filter-provider。

### 1.7 IPC 契约（跨进程红线）

- Mach service（`Extension/Info.plist` → `NetworkExtension.NEMachServiceName`）：`$(TeamIdentifierPrefix)com.yueyi.TravelMode.SimpleFirewall.SimpleFirewallExtension`
- NEProvider class：`com.apple.networkextension.filter-data` → `$(PRODUCT_MODULE_NAME).FilterDataProvider`
- `Bridge/Protocols.swift`：`ProviderCommunication`（register）、`AppCommunication`（promptUser / needApproval / extensionLog），均为 `@objc`，方向类型 `NETrafficDirection`。
- `Bridge/IPCConnection.swift`：App 侧 `IPCConnection`（NSXPCListener + 注册），Extension 侧复用同一类。

## 2. 构建基线（阶段 0 冻结结果）

| 命令 | 结果 |
|---|---|
| `xcodebuild -project TravelMode.xcodeproj -scheme Extension -configuration Debug build` | ✅ **BUILD SUCCEEDED**（签名：Apple Development: Yunyue An (VH3S2JVZ37)，profile `Mac Team Provisioning Profile: com.yueyi.TravelMode.Extension`） |
| `xcodebuild -project TravelMode.xcodeproj -scheme TravelMode-DEBUG -configuration Debug build` | ❌ **BUILD FAILED** — 签名/Provisioning 阻塞：`Provisioning profile "Mac Team Provisioning Profile: *" doesn't include the App Groups / Network Extensions / System Extension capability`（3 个能力错误）。**非代码错误**。 |
| `xcodebuild ... build CODE_SIGNING_ALLOWED=NO`（同上 scheme） | ❌ **BUILD FAILED** — 真实代码错误（见 2.1）→ 修复后 ✅ **BUILD SUCCEEDED** |

### 2.1 发现的真实代码错误（迁移前已存在）与阶段 0 启用性修复

```text
Core/Service/FirewallService/FirewallService+SystemExt.swift:292,299,304
error: protocol 'OSSystemExtensionsWorkspaceObserver' requires
'systemExtensionWillBecomeEnabled' to be available in macOS 15.0 and newer
```

- 原因：App 最低部署 15.0，`OSSystemExtensionsWorkspaceObserver` 协议要求方法 15.0 可用，而实现方法标注 `@available(macOS 15.1, *)`，Swift 6 拒绝该一致性。
- 修复（唯一一处阶段 0 改动，**不属业务代码**）：给 `extension FirewallService: OSSystemExtensionsWorkspaceObserver` 整体加 `@available(macOS 15.1, *)`。与 `runDaemon()` 中 `if #available(macOS 15.1, *) { OSSystemExtensionsWorkspace.shared.addObserver(self) }` 的既有运行时门控完全一致，不改变任何行为。
- 修复后无签名 App 编译：✅ **BUILD SUCCEEDED**。
- 签名构建的唯一阻塞仍是 Provisioning profile（wildcard profile 缺能力），属环境/签名问题，不在此次迁移范围；最终验证阶段需用户提供含能力的 profile 或按计划记录完整证据。

## 3. 数据路径事实地图（迁移前运行时）

### 3.1 进程与运行时结构

```text
TheApp (SwiftUI App, @main)
  ├─ init: StoreService.bootstrap()                      # StoreKit 交易监听 + 权益校准
  ├─ AppDelegate.applicationDidFinishLaunching
  │    └─ Task { await FirewallService.shared.runDaemon() }   # 直接调用 singleton
  ├─ Window "welcome"（id=welcome，500x600）             # 欢迎/升级引导
  ├─ Window "plugin-window"（600x800）                   # 插件窗口（PluginWindowManager.shared）
  └─ MenuBarExtra(.window)
       └─ RootView { ContentView }                        # 在 View 生命周期装配服务
            ├─ UIProvider() / PluginProvider() / MagicMessageProvider.shared
            ├─ EventRepo.shared / AppSettingRepo.shared / FirewallService.shared
            └─ .environmentObject(...) 注入 6 个对象

FirewallService.shared
  ├─ IPCConnection.shared（NSXPC 客户端，注册到 Extension）
  ├─ OSSystemExtensionManager.shared + OSSystemExtensionsWorkspace.shared.addObserver
  ├─ NEFilterManager.shared() observer（NEFilterConfigurationDidChange）
  ├─ AppSettingRepo.shared（shouldAllowSync 决策）
  └─ EventRepo.shared（promptUser 决策后写事件）

Extension 进程（独立）
  ├─ main.swift: NEProvider.startSystemExtensionMode(); IPCConnection.shared.startListener()
  └─ FilterDataProvider (NEFilterDataProvider)
       ├─ startFilter: 规则 = 本地 TCP 端口 8888 inbound，defaultAction=.filterData
       ├─ handleNewFlow → IPCConnection.shared.promptUser(flow:) → App promptUser
       └─ 回调 responseHandler(allow) → .allow()/.drop()，等待期间 .pause()
```

### 3.2 数据流（Extension → App → SwiftData → UI）

```text
Extension FilterDataProvider.handleNewFlow
  → IPCConnection.promptUser(flow:responseHandler:)
  → NSXPC AppCommunication.promptUser(id:hostname:port:direction:)
  → FirewallService.promptUser (App 侧实现)
      ├─ AppSettingRepo.shouldAllowSync(id)      # SwiftData AppSetting 查询（允许则放行，否则丢弃）
      ├─ 构造 FirewallEventDTO → EventRepo.createFromDTO
      │    → EventQueryActor(actor) → ModelContext.save() → SwiftData db.sqlite
      └─ responseHandler(true/false) → Extension .allow()/.drop()

UI 读取路径：
  AppList/AppLine/AppDetail/EventDetailView/EventTableView
    → EventRepo (ObservableObject)  → EventQueryActor  → SwiftData 分页/筛选/统计
  TileFilter/TileSwitcher/Guide 等
    → FirewallService.status (@Published FilterStatus) + NotificationCenter 事件
```

### 3.3 数据库

- 文件：`db.sqlite`；目录：`~/Documents/<debug|production>/db.sqlite`（`AppConfig.getDatabaseURL()`，`#if DEBUG` 分支）。
- Schema：`AppSetting` + `FirewallEventModel`（`Core/Config/AppConfig.swift` 顶层 `container()`，fatalError 失败策略）。
- 迁移必须保留：文件名、Debug/production 目录规则、schema/字段语义、`db.sqlite` 不重名不迁移。

### 3.4 UserDefaults 键（兼容红线）

- `VersionService`：`lastShownWelcomeVersion`（欢迎窗口版本判断，`hasShownWelcome` 语义所在）。
- `StoreState`：`store.purchase`（PurchaseInfo Codable 缓存）、`store.lastCheckedAt`。
- 迁移不得改键名。

### 3.5 StoreKit

- Product IDs（`Packages/PluginStore/Sources/PluginStore/StoreConfig.swift` productTier）：
  - consumable: `consumable.fuel.octane87/89/91`
  - non-consumable: `nonconsumable.car/utilityvehicle/racecar`
  - subscription: `com.coffic.netto.monthly`（.pro）、`com.coffic.netto.annual`（.pro）
- `.storekit` 配置：`Packages/PluginStore/Products.storekit`；Mock-Store scheme 使用它。

## 4. 迁移需要拆解的旧运行时（清单）

### 4.1 Singleton 引用清单（迁移后必须消失）

| 引用 | 位置 | 归属 |
|---|---|---|
| `FirewallService.shared` | AppDelegate、RootView、FirewallService 内部 | PluginFirewall |
| `EventRepo.shared` | RootView、ClearLogsButton | PluginEventStore |
| `AppSettingRepo.shared` | RootView、TheApp、FirewallService | PluginAppSettings |
| `PluginRegistry.shared` | 全部 13 个插件 Registrant、PluginProvider、TheApp | KernelCore + FactoryNetto |
| `PluginWindowManager.shared` | TheApp | WindowProviding / Window Host |
| `IPCConnection.shared` | FirewallService、Extension main/FilterDataProvider | NettoIPCContracts 适配器 |
| `OSSystemExtensionManager.shared` | FirewallService | PluginFirewall |
| `MagicMessageProvider.shared` | RootView + 7 个 View/Plugin | ToastProviding |
| `StoreService.bootstrap()` | TheApp.init | PluginStore |
| `OSSystemExtensionsWorkspace.shared` | FirewallService+Daemon | PluginFirewall |

### 4.2 NotificationCenter 事件清单（按 Name）

- AppDelegate：`appDidFinishLaunching`
- FirewallService+Event：`firewallWillBoot`、`firewallStatusChanged`、`firewallWillInstall`、`firewallWillStart`、`firewallWillStop`、`firewallConfigurationChanged`、`firewallDidFailWithError`、`firewallDidStart`、`firewallDidStop`、`firewallDidInstall`、`firewallUserApproved`、`firewallUserRejected`、`firewallWillRegisterWithProvider`、`firewallDidRegisterWithProvider`、`firewallNetWorkFilterFlow`、`firewallNeedApproval`、`firewallWaitingForApproval`、`firewallPermissionDenied`、`firewallProviderSaid`、`firewallDidSetAllow`、`firewallDidSetDeny`
- EventRepo：`firewallEventCreated`、`firewallEventDeleted`
- TheApp/Store：`shouldOpenPluginWindow`、`shouldOpenWelcomeWindow`、`storeTransactionUpdated`、`showPluginWindow`、`hidePluginWindow`

### 4.3 @EnvironmentObject 注入面

RootView 注入：`UIProvider`(app)、`MagicMessageProvider`(m)、`PluginProvider`(p)、`EventRepo`、`AppSettingRepo`、`FirewallService`；Store 插件经 StoreRootView 另注入 Store 状态。26 个文件消费。

### 4.4 插件清单（旧 SuperPlugin actor + Objective-C 自动注册）

| 插件 label | Order | 注册机制 | 说明 |
|---|---|---|---|
| StartButton | 10 | StartButtonRegistrant | 工具栏按钮（BtnStart） |
| Switcher | 10 | SwitcherRegistrant | 左按钮（TileSwitcher） |
| Filter | 20 | FilterRegistrant | 中按钮（TileFilter） |
| DBPlugin | 20 | DBPluginRegistrant | 设置按钮（DBSheetButton，Debug） |
| SettingButton | 30 | SettingButtonRegistrant | 设置入口（BtnSetting） |
| StopButton | 20 | StopButtonRegistrant | 按钮 |
| ClearLogsButton | 35 | ClearLogsButtonRegistrant | 按钮，直接调 EventRepo.shared.deleteAll |
| DataFolderButton | 35 | DataFolderButtonRegistrant | 按钮 |
| GuideButton | 40 | GuideButtonRegistrant | 按钮 |
| InstallExtensionButton | 40 | InstallExtensionButtonRegistrant | 按钮 |
| Store | 40 | StoreRegistrant | 设置按钮 + RootView 包装 + 插件窗口 |
| AboutButton | 50 | AboutButtonRegistrant | 按钮 |
| QuitButton | 60 | QuitButtonRegistrant | 按钮 |

注册机制（`Core/Providers/PluginRegistry.swift`）：`objc_copyClassList` 扫描 `PluginRegistrant` 类 → 异步 `PluginRegistry.shared.register` → `PluginProvider.init` 中 `buildAll()` 按 order 实例化并收集 UI 贡献。**这是阶段 8 必须删除的 Objective-C 自动发现生产路径。**

## 5. 迁移中不能改变的兼容项（红线复核）

1. Bundle ID：App `com.yueyi.TravelMode`，Extension `com.yueyi.TravelMode.Extension`；`PRODUCT_NAME = TavelMode`（既有拼写）。
2. Entitlements：App Group `$(TeamIdentifierPrefix)com.yueyi.TravelMode.SimpleFirewall`、networkextension content-filter-provider、system-extension.install（App 与 Extension 均不得改）。
3. Mach service：`...SimpleFirewall.SimpleFirewallExtension`；Extension `NEProviderClasses`；`NEProvider.startSystemExtensionMode()` 与 IPC listener 时序。
4. 数据库：`db.sqlite`、`~/Documents/debug|production`、SwiftData schema（AppSetting/FirewallEventModel）、ModelContainer 单容器语义。
5. UserDefaults：`lastShownWelcomeVersion`、`store.purchase`、`store.lastCheckedAt`。
6. StoreKit：product IDs（见 3.5）、交易监听/恢复购买/`.storekit` 配置。
7. 窗口：welcome 窗口 id `welcome`（500×600）、plugin-window（600×800）、菜单栏行为、欢迎/升级版本判断。
8. Extension IPC 语义：`promptUser` 决策 → allow/drop/pause、`resumeFlow` 时序、`needApproval`/`extensionLog`。
9. `FilterStatus` 全部状态语义（安装、审批、未激活、未安装、需更新、Applications 目录、权限拒绝、错误等）不得合并为 stopped。

## 6. 迁移期必须保留的既有行为（逐项回归目标）

- EventRepo：分页（page×pageSize offset/limit）、筛选（status=0 allowed/1 rejected、direction rawValue）、计数、按 appId 删除、清空、按天数清理（30 天）、定时维护（每小时）、健康检查、导出（EventDetailView）、通知。
- AppSettingRepo：create/find/update/delete/fetchAll/fetchDeniedApps/getDeniedAppsCount/shouldAllow(Async|Sync)/setDeny/setAllow + 通知 `firewallDidSetAllow/Deny`。
- FirewallService：refreshStatus 的状态机、install/start/stop、system extension 激活/属性/替换、observer（NEFilterConfigurationDidChange）、daemon（workspace observer + loadFromPreferences + registerWithProvider）。
- 主界面：窗口尺寸、TopBar 左/中/右排序、设置弹窗、菜单栏图标（`hasDeniedApps` 红绿）、空状态、颜色间距。

## 7. 已知问题与警告（阶段 0 冻结）

1. `MagicHTTP` target 名大小写与 Package.swift 不一致（MagicKit 包）——重构前已存在，记录待复核，不属本迁移。
2. App 签名被 wildcard Provisioning profile 阻塞（缺 App Groups/Network Extensions/System Extension 能力）——环境问题；最终验证需正确 profile 或记录完整证据。
3. App 最低部署 15.0 与 `OSSystemExtensionsWorkspaceObserver` 15.1 要求冲突——已在阶段 0 以 availability 门控修复（不改行为）。
4. 旧工程基线曾使用 `PBXFileSystemSynchronizedRootGroup` 自动包含 `Core`、`Plugins`、`Bridge`、`Extension`、`AppStore`、`docs`；当前插件实现由 `Packages/` 下的 Swift Package 管理。新增 `App/`、`Packages/` 目录**不会自动进入编译**，必须显式加入工程或建立 local package reference（见蓝图 4 节）。
5. `EventRepo`/`AppSettingRepo` 的 `@unchecked Sendable`（`DatabaseMaintenanceManager`）与 `FirewallService` 的 `@unchecked Sendable` 为阶段 4/5 待修正项。
6. `StoreService.bootstrap()` 在 `TheApp.init` 启动；迁移后必须保持"启动即监听交易 + 权益校准"语义。

## 8. 阶段 0 结论

- 基线已冻结：干净工作树、Extension Debug 构建通过、App 代码编译通过（签名除外）、完整事实地图如上。
- 阶段 1 起点：新建 `Packages/KernelCore`（local package，仅 Foundation），实现 Provider 注册/解析/注销、SuperPlugin 生命周期、依赖排序、贡献撤回、失败回滚、取消/超时，并写单元测试；保留旧 PluginRegistry 但 KernelCore 不依赖它。
