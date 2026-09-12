# Netto 按 Lumi 架构重构实施方案

> 文档状态：实施蓝图
>
> 适用项目：`/Users/angel/Code/Coffic/Netto`
>
> 参考架构：`/Users/angel/Code/Coffic/Lumi` 当前的 `KernelCore` + `Provider*` + `Plugin*` + `FactoryLumi` + App 组合根
>
> 目标：在保持 Netto 用户功能、数据、Bundle、系统扩展和 StoreKit 行为兼容的前提下，建立可测试、可替换、可按生命周期管理的 Kernel/Provider/Plugin/Factory/App 架构。

## 1. 先读这份文档时必须知道的结论

这不是一次目录重命名，也不是把现有 `Core/Providers` 改名为 `Provider`。Netto 当前已经有插件雏形，但真实的运行时仍然是：

```text
TheApp
  ├─ RootView 在 View 生命周期中创建服务
  ├─ UIProvider / PluginProvider 作为 ObservableObject 全局注入
  ├─ PluginRegistry 通过 Objective-C Runtime 自动发现插件
  ├─ AppDelegate 直接调用 FirewallService.shared
  ├─ FirewallService.shared 持有 AppSettingRepo.shared / EventRepo.shared
  └─ 各个 View 和插件直接访问 singleton、NotificationCenter、具体 Service/Repo
```

目标运行时必须变为：

```text
TheApp / AppDelegate
        │ 只负责创建场景、转发系统事件、展示 Factory 生成的 View
        ▼
FactoryNetto
        │ 创建同一个 Kernel、注册 Provider 实现、静态组装插件、生成主视图
        ▼
KernelCore（每个 App 进程一个实例，不使用全局 singleton）
        │ Provider 注册/解析、插件生命周期、贡献撤回、依赖和失败回滚
        ├─ ProviderFirewall / ProviderFirewallEvents / ProviderAppSettings / ProviderShell ...
        │ 只包含稳定的能力协议和中立值类型
        └─ PluginFirewall / PluginEventStore / PluginAppSettings / PluginStore / PluginGuide ...
           通过 Kernel 注入 Provider，实现业务、持久化、系统 API 和 UI 贡献
```

Network Extension 是独立进程，不能被 App 的 Kernel 直接管理。它保留自己的系统生命周期，只共享一个无 UI、无 App 引用、无 SwiftUI 的 IPC 合约包。

## 2. 当前基线（以仓库现状为准）

### 2.1 工程和运行目标

- Xcode 工程：`TravelMode.xcodeproj`。
- App target 名称当前为 `TavelMode`（工程中的既有拼写），Bundle ID 为 `com.yueyi.TravelMode`。
- System Extension target：`Extension`。
- App Scheme：`TravelMode`、`TravelMode-DEBUG`、`TravelMode-EN`；Extension Scheme：`Extension`。
- App 和 Extension 使用 Swift 6；App 的 macOS 最低版本为 15.0，工程中仍有 12.0 的其他配置基线，迁移时不得擅自统一或删除，须以 `xcodebuild -showBuildSettings` 为准。
- 项目通过 `PBXFileSystemSynchronizedRootGroup` 自动包含 `Core`、`Plugins`、`Bridge`、`Extension`、`AppStore` 和 `docs` 下的文件。
- 当前 `xcodebuild -project TravelMode.xcodeproj -list` 可以解析工程，但 Package Graph 报告：`the target name MagicHTTP has different case on the filesystem and the Package.swift manifest file`。它是重构前必须记录和单独复核的工程基线问题。

### 2.2 当前核心入口和依赖穿透

| 当前位置 | 实际职责 | 主要问题 | 目标归属 |
|---|---|---|---|
| `Core/Bootstrap/TheApp.swift` | App 入口、窗口、菜单栏、欢迎页、插件窗口、被禁止应用检查 | 直接访问 Repo、Registry、StoreService；在 Scene 中启动异步任务 | `App/TravelModeApp.swift`，只调用 Factory/Kernel 能力 |
| `Core/Bootstrap/AppDelegate.swift` | AppKit 生命周期 | 直接调用 `FirewallService.shared.runDaemon()` | App Host，调用 Kernel 中的生命周期或 Firewall Provider |
| `Core/Bootstrap/RootView.swift` | 加载态、服务装配、环境注入、插件包装 | 在 View 生命周期中装配 singleton；`onDisappear` 可能误清理共享运行时 | Factory 生成的 Bootstrap/Main Host View |
| `Core/Providers/PluginRegistry.swift` | Objective-C Runtime 扫描、异步注册、构建插件 | 不确定性、重复注册风险、没有生命周期/依赖/回滚 | `Packages/KernelCore` 的静态插件注册与生命周期 |
| `Core/Providers/PluginProvider.swift` | 收集工具栏、设置、RootView、窗口内容 | 把插件注册、UI 聚合、生命周期和 SwiftUI 状态混为一体 | Kernel 的贡献注册 + `ProviderShell` 的 UI 聚合 |
| `Core/Providers/UIProvider.swift` | 弹窗、展示类型、升级引导状态 | 泛化的共享可变 UI 状态，多个 View 直接依赖 | 按功能拆分的 Provider/ViewModel |
| `Core/Providers/AppProvider.swift` | Store/应用界面状态的混合容器 | 与具体功能和 SwiftUI 环境耦合 | `PluginStore` 或具体 Feature 的状态所有者 |
| `Core/Service/FirewallService/*` | NEFilterManager、System Extension、IPC、状态和防火墙动作 | singleton、`@unchecked Sendable`、初始化时副作用、具体 Repo 穿透 | `ProviderFirewall` 契约 + `PluginFirewall` 实现 |
| `Core/Repo/EventRepo.swift` | SwiftData 查询、分页、删除、维护、通知 | 具体数据库类型穿透到 UI/插件；singleton；职责过大 | `ProviderFirewallEvents` 契约 + `PluginEventStore` 实现 |
| `Core/Repo/AppSettingRepo.swift` | AppSetting CRUD、查询和设置通知 | singleton；业务和持久化未分开 | `ProviderAppSettings` 契约 + `PluginAppSettings` 实现 |
| `Core/Model/*` / `Core/DTO/*` | SwiftData 模型、DTO、领域值 | Model/DTO/展示值边界不清 | Schema 留在存储插件，中立 Snapshot 进入 Provider 契约 |
| `Core/View/*` | 主界面、应用列表、事件详情、引导、按钮 | View 直接访问具体 Repo/Service | 按功能拆到对应 Plugin；Shell 只组装区域 |
| `Plugins/*` | 现有按钮、过滤、切换、DB、Store 等 | 插件 actor 只返回 AnyView，实际逻辑在 View/singleton | 真正实现 `SuperPlugin` 生命周期并贡献 Provider/Toolbar/Setting/Window |
| `Bridge/*` / `Extension/*` | App-Extension IPC 和过滤实现 | 必须保持跨进程边界 | `NettoIPCContracts` + App/Extension 各自适配 |

### 2.3 当前插件清单

现有插件目录包括：

`AboutButton`、`AppFilter`、`ClearLogsButton`、`DB`、`DataFolderButton`、`GuideButton`、`InstallExtensionButton`、`QuitButton`、`SettingButton`、`StartButton`、`StopButton`、`Store`、`Switcher`。

它们不是都应继续保持一个目录一个极薄 wrapper。重构时要按“能力所有权”重新分组：按钮只提供入口，防火墙插件拥有防火墙能力，事件存储插件拥有事件查询，商店插件拥有 StoreKit 状态和 Store 窗口，Guide/Onboarding 插件拥有欢迎流程。

## 3. 架构原则（必须作为验收规则）

### 3.1 Kernel 是唯一运行时核心

`KernelCore` 必须是一个可实例化的普通对象/主 actor 容器；每个 App 运行实例创建一个 Kernel。禁止：

- `KernelCore.shared`、`PluginRegistry.shared` 作为生产运行时入口。
- 在 View 的 `init`、`body`、`.task` 中创建核心 Service。
- App 同时持有一套旧 Kernel 和一套新 Kernel。
- 让 `FactoryNetto` 变成第二个 Service Locator 或第二个 Kernel。

Kernel 负责：

1. Provider 按协议类型注册、解析、注销。
2. Plugin 按稳定 ID 注册、依赖排序、生命周期启动和停止。
3. 记录插件拥有的 Provider、观察者、Task、定时器和共享贡献，并在停止/禁用/失败时撤回。
4. 校验重复 ID、缺失依赖、依赖环和不合法生命周期操作。
5. 支持同步轻量插件和异步插件；异步阶段必须支持取消和超时。
6. 启动失败时逆序清理，不留下半启动的 Provider 或插件。

Kernel 不负责：

- SwiftUI View、`AnyView`、`NSView`、`NSWindow`。
- `NEFilterManager`、`OSSystemExtensionManager`、`StoreKit.Product`、SwiftData ModelContext。
- 具体 Repo、Service、Plugin、数据库路径和产品 ID。
- 把所有动态状态通过一个 `ObservableObject` 广播给整个 App。

### 3.2 Provider 是能力契约，不是万能服务容器

Provider 按能力拆分，每个 Provider 有一个明确的事实源和所有权。建议首批契约：

| 契约 | 所有能力 | 不应包含 |
|---|---|---|
| `FirewallProviding` | 当前过滤状态 Snapshot、安装/启动/停止、刷新、错误诊断、状态观察 | SwiftUI 按钮、数据库查询、StoreKit |
| `FirewallEventsProviding` | 事件分页、过滤、计数、删除、维护、事件观察 | `FirewallService` 的 NE 系统扩展安装逻辑 |
| `AppSettingsProviding` | 应用阻止/允许规则、配置读取写入、设置变更 Snapshot | SwiftUI Popover、通知名称拼接 |
| `AppCatalogProviding` | 从 App 标识符得到应用元数据、图标和展示值 | 防火墙启停、SwiftData Model 类型 |
| `ShellToolbarProviding` | Toolbar item 的稳定 ID、位置、排序和 View 构造闭包 | 防火墙业务、Provider 注册 |
| `SettingsProviding` | 设置入口的 ID、标题、排序和内容构造 | 具体 Store/Firewall 业务状态 |
| `WindowProviding` | 打开/关闭窗口请求、窗口 ID、内容工厂 | 通过 NotificationCenter 传递任意对象 |
| `ToastProviding` | 成功/错误/信息提示值 | 直接依赖 MagicMessageProvider.shared |
| `StoreProviding` | 产品 Snapshot、购买/恢复、订阅状态 | 主窗口布局和防火墙状态 |

Provider 契约优先使用 `Sendable`、`Equatable`、稳定 ID 和不可变 Snapshot。高频或可变对象留在实现插件内，不能因为“方便”把 `ObservableObject`、ModelContext 或 AppKit 对象公开给 Kernel。

### 3.3 Plugin 是能力实现和贡献者

每个插件必须能回答：

- 我的稳定 ID 是什么？
- 我依赖哪些插件/Provider？
- 我在 `onBoot` 注册什么？
- 我在 `onReady` 连接什么跨插件能力？
- 我在 `onShutdown` 停止哪些监听、Task、IPC 或定时器？
- 我向哪个共享 Provider 添加了贡献？如何在禁用时撤回？

插件可以依赖 `KernelCore` 和 Provider 契约，也可以依赖所需的系统 SDK/第三方适配器。插件不可以依赖另一个具体插件的实现；跨插件交互必须通过 Provider 协议。

推荐生命周期：

```text
register   注册静态元数据/目录贡献，不启动外部资源
boot       创建实现、注册自己的 Provider、登记可撤销资源
ready      所有插件 boot 完成后，解析依赖并连接监听/聚合贡献
enable     恢复可配置插件的资源和共享贡献
disable    停止该插件自己的运行资源；Kernel 撤回其贡献
shutdown   停止监听、Task、IPC、定时器并释放外部资源
unregister 撤回 register 阶段的目录贡献并移除 Provider
```

### 3.4 Factory 是唯一静态装配点

`FactoryNetto` 负责：

1. 创建 Kernel。
2. 创建/配置持久化、Firewall、Event、Settings、Shell 等实现。
3. 以稳定顺序返回完整插件数组。
4. 声明插件依赖和默认启用策略。
5. 调用 `kernel.startAsync(...)` 或等价的原子启动入口。
6. 生成主视图、设置视图、插件窗口路由和菜单栏内容。
7. 为测试提供使用 Mock Provider 的 Kernel 工厂。

Factory 不负责：

- 读取 SwiftUI 环境对象。
- 在 View 更新期间重复生成 View 或向 `@Published` 对象注入状态。
- 按 Objective-C Runtime 扫描类。
- 以 `if plugin is StorePlugin` 处理业务分支。

### 3.5 App 是组合根，不是业务层

App 和 AppDelegate 只做以下事情：

- 创建 `FactoryNetto` 生成的 Kernel。
- 启动/停止 App 生命周期。
- 返回 Factory 已装配的主视图和窗口视图。
- 将 AppKit/Launch Services/系统扩展回调转交给契约。
- 执行应用级的 Open、Quit、Update 等真正属于 App 的动作。

App 不得直接 import 或构造 `FirewallService`、`EventRepo`、`AppSettingRepo`、具体插件、`PluginRegistry`。

## 4. 建议的目标目录和依赖图

迁移可以先在现有 Xcode 工程中创建这些目录，稳定后再抽成 local Swift packages。最终建议结构如下：

```text
Netto/
├─ App/
│  ├─ TravelModeApp.swift
│  ├─ AppDelegate.swift
│  ├─ AppScenes.swift
│  └─ AppCommands.swift
├─ Packages/
│  ├─ KernelCore/
│  ├─ NettoIPCContracts/
│  ├─ ProviderFirewall/
│  ├─ ProviderFirewallEvents/
│  ├─ ProviderAppSettings/
│  ├─ ProviderAppCatalog/
│  ├─ ProviderShell/
│  ├─ ProviderStore/
│  ├─ PluginFirewall/
│  ├─ PluginEventStore/
│  ├─ PluginAppSettings/
│  ├─ PluginAppCatalog/
│  ├─ PluginShell/
│  ├─ PluginStore/
│  ├─ PluginGuide/
│  ├─ PluginAppActions/
│  └─ FactoryNetto/
├─ Extension/
├─ Assets.xcassets/
├─ Core/                 # 迁移期兼容区，最终清空或只保留 App-owned UI
├─ Plugins/              # 迁移期兼容区，逐个删除已迁移实现
└─ docs/
```

当前工程使用 `PBXFileSystemSynchronizedRootGroup`，并没有自动包含未来新增的 `App/` 和 `Packages/`。因此“创建目录”不等于“进入编译”：每次新增 package 或 App Host 目录后，必须在 `TravelMode.xcodeproj` 中建立正确的 local package reference/target dependency 或同步文件组，并通过 `xcodebuild -showBuildSettings`、`xcodebuild -list` 和实际 build 证明文件已经被目标编译。迁移早期也可以暂时把 App Host 放在 `Core/Bootstrap`，待 Factory/package 接通后再移动；禁止留下未被 target 编译的“影子实现”。

依赖方向：

```text
KernelCore
    ▲
Provider contracts / neutral models
    ▲
Plugin implementations ────── MagicUI/MagicAlert/StoreKit/SwiftData/System SDK
    ▲
FactoryNetto ──────────────── all selected plugins and providers
    ▲
App

NettoIPCContracts ───── App IPC adapter
                   └── Extension IPC adapter
```

硬规则：

| 层 | 可以依赖 | 禁止依赖 |
|---|---|---|
| `KernelCore` | Foundation，必要的并发/日志基础设施 | SwiftUI、AppKit、NetworkExtension、SwiftData、StoreKit、MagicKit、插件 |
| Provider 契约 | Foundation、KernelCore（仅在需要注册语义时） | 具体 Service/Repo、具体插件、SwiftUI View |
| Provider 实现/业务 Plugin | KernelCore、Provider 契约、自身系统 SDK | 其他插件的具体类型、App 入口 |
| `FactoryNetto` | KernelCore、所有选定 Provider/Plugin | 业务实现分支、全局 singleton 初始化 |
| App | FactoryNetto、少量 AppKit/SwiftUI | Repo/Service/具体 Plugin/Registry |
| `NettoIPCContracts` | Foundation、必要的 NetworkExtension 值类型 | SwiftUI、SwiftData、App、Plugin |
| Extension | `NettoIPCContracts`、NetworkExtension、Network、Foundation | App 的 Kernel、SwiftUI、SwiftData、StoreKit |

CI 必须扫描 `Package.swift`、工程 target 依赖和 Swift `import`，阻止依赖回退。

## 5. 中立契约设计建议

以下是方向性接口，实施时必须以现有调用点和编译器反馈为准，不要直接复制成没有真实数据路径的空协议。

### 5.1 KernelCore

```swift
@MainActor
public protocol SuperPlugin: AnyObject {
    var id: String { get }
    var order: Int { get }
    var dependencies: [String] { get }
    var metadata: PluginMetadata { get }

    func onRegister(kernel: KernelCoreContainer) throws
    func onBoot(kernel: KernelCoreContainer) throws
    func onReady(kernel: KernelCoreContainer) throws
    func onShutdown(kernel: KernelCoreContainer) throws
    func onUnregister(kernel: KernelCoreContainer) throws
    func onEnable(kernel: KernelCoreContainer) async throws
    func onDisable(kernel: KernelCoreContainer) async throws
}
```

需要支持异步启动的插件使用 `AsyncSuperPlugin` 或等价设计。Kernel 至少必须测试：

- 重复插件 ID 被拒绝。
- 缺失依赖被拒绝。
- 依赖环被拒绝。
- Boot/Ready 失败会逆序 Shutdown 并清空注册的 Provider。
- 停止时贡献按逆序撤回。
- 禁用插件后其 Provider/共享贡献不可继续被解析。
- 启动和停止支持取消和阶段超时，不留下后台 Task。
- 非法的生命周期重入会得到明确错误。

### 5.2 Firewall Provider

使用中立状态，不把 `NEFilterManager` 或 `FilterStatus.error(Error)` 直接暴露给上层：

```swift
public enum FirewallState: Equatable, Sendable {
    case unknown
    case stopped
    case running
    case installing
    case waitingForApproval
    case systemExtensionNotInstalled
    case systemExtensionNeedsUpdate
    case filterNotInstalled
    case permissionDenied
    case failed(FirewallFailure)
}

public struct FirewallSnapshot: Equatable, Sendable {
    public let state: FirewallState
    public let canStart: Bool
    public let canStop: Bool
    public let lastUpdated: Date
}

@MainActor
public protocol FirewallProviding: AnyObject {
    var snapshot: FirewallSnapshot { get }
    func refresh() async
    func install() async throws
    func start() async throws
    func stop() async throws
}
```

系统错误保留 domain/code/完整描述，展示层再映射本地化文案。不要在 Provider 中为了 UI 方便丢掉原始错误。

### 5.3 Firewall Events Provider

现有 `EventRepo` 的分页、过滤、统计、删除和维护能力必须逐项保留，但 UI 只能看到中立 DTO：

```swift
public struct FirewallEventSnapshot: Identifiable, Equatable, Sendable {
    public let id: String
    public let time: Date
    public let address: String
    public let port: String
    public let sourceAppIdentifier: String
    public let status: FirewallEventDecision
    public let direction: FirewallTrafficDirection
}

public struct FirewallEventQuery: Equatable, Sendable {
    public var appIdentifier: String?
    public var status: FirewallEventDecision?
    public var direction: FirewallTrafficDirection?
    public var page: Int
    public var pageSize: Int
}

public struct FirewallEventPage: Equatable, Sendable {
    public let events: [FirewallEventSnapshot]
    public let totalCount: Int
    public let page: Int
    public let pageSize: Int
}
```

SwiftData `FirewallEventModel` 只留在 `PluginEventStore`。Repository 可以内部继续使用 ModelContext，但不能成为环境对象或在其他插件中被 `shared` 访问。

### 5.4 App Settings Provider

`AppSettingRepo` 的允许/阻止规则、查询和计数要以命令和 Snapshot 方式公开。变更回调使用类型安全的 observation/AsyncStream/Provider 自有 publisher；系统级 NotificationCenter 只作为过渡适配，不作为新插件之间的协议。

### 5.5 UI/窗口贡献

不要让 Kernel 认识 `AnyView`。可以采用 `@MainActor` 的贡献工厂放在 `ProviderShell` 或 `FactoryNetto`：

```swift
public struct ToolbarContribution {
    public let id: String
    public let position: ToolbarPosition
    public let order: Int
    public let makeView: @MainActor () -> AnyView
}
```

Kernel 只记录贡献所有者和撤回 token；SwiftUI View 的聚合由 Shell Provider/Host 完成。每个贡献必须有稳定 ID、owner plugin ID、位置和排序规则，不能用数组 index 作为身份。

## 6. 现有代码的迁移归属

### 6.1 App 与启动

1. `TheApp` 迁移为 App-owned `TravelModeApp`，保留现有窗口 ID、默认尺寸、欢迎页和菜单栏行为。
2. App 初始化阶段调用 `FactoryNetto.makeRuntime()`，获得一个 Kernel 和已缓存的主视图/设置视图。
3. 不在 `body` 中装配服务，不在 `RootView.onAppear` 中第一次注册插件，不在视图消失时清理 App 级运行时。
4. `AppDelegate.applicationDidFinishLaunching` 只通知 Kernel/App Host；防火墙 daemon 的启动由 `PluginFirewall.onBoot/onReady` 管理。
5. App 如果启动失败，必须显示持久、完整、可复制的错误；不能静默展示没有数据的空界面。

### 6.2 Firewall

将 `Core/Service/FirewallService` 的责任拆成：

- `ProviderFirewall`：`FirewallProviding`、状态 Snapshot、错误模型。
- `PluginFirewall`：实现 `FirewallProviding`，拥有 NEFilterManager、OSSystemExtensionManager、IPCConnection adapter、状态观察者和后台 Task。
- `NettoIPCContracts`：App 与 Extension 共享的 `ProviderCommunication` / `AppCommunication` 中立定义。
- `PluginFirewallUI` 或 `PluginFirewall` 的 UI 部分：Start、Stop、Filter、Switcher 的按钮和状态视图。

关键行为：

- 不在 `FirewallService.init` 中启动 `Task`、发送 boot 事件或添加永久 observer。
- 在 `onBoot` 注册 Provider，在 `onReady` 确认依赖已就绪后启动状态同步/daemon。
- 在 `onShutdown` 移除 `NEFilterConfigurationDidChange` observer、停止 IPC/后台 Task、释放系统扩展请求状态。
- 删除 `@unchecked Sendable`，明确哪些方法是 `@MainActor`，哪些 IPC 回调需要切回主 actor。
- 保留现有 `FilterStatus` 到新 `FirewallState` 的完整映射，不得把安装审批、系统扩展未激活、未安装在 Applications 等状态合并为 stopped。

### 6.3 Events / Database

- `FirewallEventModel` 和 SwiftData Schema 留在存储插件。
- `EventRepo` 迁移为注入式 `EventStore`，构造参数接收 `ModelContainer` 或抽象存储依赖，不使用 `.shared`。
- 现有分页、筛选、统计、删除、定时清理、导出和通知行为逐项建立测试。
- `DBPlugin` 不再只是 Debug 设置按钮，而是注册 Event Store Provider；Debug UI 是它的一个可选贡献。
- `ClearLogsButton` 只解析 `FirewallEventsProviding`，不能直接调用 `EventRepo.shared`。
- DB 维护要有明确的启动/停止生命周期，停止时取消 timer/task。

### 6.4 App Settings / App Catalog

- `AppSetting`、`AppSettingDTO`、`AppSettingRepo` 的持久化 schema/键名保持兼容。
- 设置 Provider 负责规则和配置；应用列表/图标/展示信息拆成 App Catalog 能力。
- `AppList`、`AppLine`、`AppAction` 只依赖 Provider Snapshot 和命令，不依赖 SwiftData Model 或 FirewallService 具体类型。
- `UIProvider.displayType`、`activePopoverAppId` 等状态按实际消费者拆到列表 ViewModel/Feature Provider，不能继续扩成一个新的全局状态袋。

### 6.5 Toolbar / Settings / Windows

- `PluginProvider` 被拆除为三个概念：插件生命周期由 Kernel 管，Toolbar/Settings/Window 贡献由 Shell Provider 管，View 由 Factory/Host 缓存和呈现。
- `Topbar.swift` 只读取 `ShellToolbarProviding` 的排序后贡献。
- `BtnSettings` 只读取 `SettingsProviding` 的入口，不自己查 Registry。
- `PluginWindowManager.shared` 替换为注入的 `WindowProviding`/Window Host；保留现有插件窗口标题和打开行为。
- `NotificationCenter` 的 `.shouldOpenPluginWindow` 仅在兼容期由 `WindowRequestAdapter` 接收，新的插件使用 typed request。

### 6.6 Store

- `StoreService`、`StoreState`、DTO、购买/恢复/订阅 UI 全部归入 `PluginStore`。
- StoreKit 的产品 ID、交易监听、恢复购买、UserDefaults 键和 `.storekit` 配置保持不变。
- Store plugin 通过 `StoreProviding` 暴露产品和订阅 Snapshot；View 不直接创建 StoreService singleton。
- `AppProvider` 中与 Store 无关的状态必须移出。

### 6.7 Guide、App Actions 和其他插件

- `GuideButton` 迁移为 `PluginGuide`，拥有欢迎页/升级引导状态和打开窗口贡献。
- `AboutButton`、`QuitButton`、`DataFolderButton`、`InstallExtensionButton` 归入 `PluginAppActions` 或保持独立小插件，但动作依赖 App Host/Provider 契约。
- `StartButton`、`StopButton`、`AppFilter`、`Switcher` 统一改为通过 `FirewallProviding` 和 `AppSettingsProviding` 操作。
- 每个插件的 View 不得出现 `FirewallService.shared`、`EventRepo.shared`、`AppSettingRepo.shared`、`MagicMessageProvider.shared` 等跨层 singleton。

## 7. 迁移阶段和逐阶段验收

重构必须小步进行。每一阶段都应保持工程可编译，且在进入下一阶段前保存基线和验证结果。

### 阶段 0：冻结基线和事实地图

任务：

- 记录 `git status --short`、最近 commit、Xcode Scheme、build settings、Package Graph 和当前构建结果。
- 运行 `xcodebuild -project TravelMode.xcodeproj -list`。
- 运行 App 和 Extension 的最小 Debug build，记录真实失败位置；如果被签名、网络或环境阻塞，要保留完整错误。
- 统计所有 `shared`、`NotificationCenter`、`@EnvironmentObject`、具体 Service/Repo import 和所有插件注册器。
- 画出当前数据流：Extension flow → IPC → FirewallService → Repo → SwiftData → AppList/EventDetail。
- 不修改业务代码。

交付物：`docs/architecture-baseline.md`、依赖扫描输出和构建日志摘要。

通过标准：后续 agent 可以只看基线文档复现当前入口、数据目录、target 和已知工程警告。

### 阶段 1：建立 KernelCore 和测试，不迁业务

任务：

- 创建没有 SwiftUI/AppKit/NetworkExtension/SwiftData/MagicKit 依赖的 `KernelCore`。
- 实现 Provider 注册/解析/注销、Plugin 注册、依赖排序、生命周期、贡献跟踪、失败回滚和取消/超时。
- 编写 KernelCore 单元测试，使用测试内私有 Provider 协议和 Mock Plugin。
- 先保留旧 `PluginRegistry`，但不让新 Kernel 依赖它。

通过标准：KernelCore package tests 全部通过；KernelCore 的 import 扫描通过；没有第二个全局核心。

### 阶段 2：建立 Provider 契约和 IPC 契约

任务：

- 建立 Firewall、Events、AppSettings、AppCatalog、Shell、Store 的中立协议和 Snapshot。
- 建立 `NettoIPCContracts`，只放跨进程必须共享的 Objective-C compatible 契约和值类型。
- 将错误、枚举、状态、方向、分页和稳定 ID 定义清楚，补充 Equatable/Sendable 测试。
- 不在协议包中加入 View、ModelContext、StoreKit.Product、具体系统对象。

通过标准：Provider 契约可以在没有 App target 的情况下测试和构建；Extension 只依赖 IPC 契约；SwiftData/SwiftUI 类型没有越过边界。

### 阶段 3：建立 FactoryNetto，先并行装配空/Mock 运行时

任务：

- 创建 `FactoryNetto.makeKernel()`、`makePlugins()`、`makeMainView(kernel:)`、`makeSettingsView(kernel:)`。
- 明确处理 Xcode 工程集成：local package 必须出现在工程的 package references/target product dependencies 中，新 App Host 目录必须被 App target 编译；不能只在文件系统中创建目录。
- 以静态数组显式列出插件和依赖，不再使用 Objective-C Runtime 自动发现。
- 加入启动错误 View 和诊断信息。
- 让测试 Factory 可以注入内存 Provider/Mock Provider。

通过标准：同一个 Factory 生成的所有窗口使用同一个 Kernel；Factory 测试能验证插件顺序、Provider 数量和启动状态。

### 阶段 4：迁移持久化和 App Settings

任务：

- 把 ModelContainer 创建移入 `PluginEventStore`/`PluginAppSettings` 的实现边界。
- 将 Repo 改为依赖注入实例，消除 `.shared`。
- 保留 `AppConfig.databaseURL` 的实际路径规则、`db.sqlite` 文件名、Debug/production 目录和 SwiftData schema。
- 对现有数据库做只读备份和迁移测试，不进行字段重命名或删除。
- 迁移 `hasShownWelcome`、版本检查和 Store 状态所用 UserDefaults 键。

通过标准：用旧数据库启动新运行时后，已有设置、事件、计数、分页和清理功能保持一致；没有重复 ModelContainer 指向同一数据库。

### 阶段 5：迁移 Firewall 和 System Extension App 端

任务：

- 将 FirewallService 改为 PluginFirewall 实现，注入 IPC、Extension Manager、Repo Provider。
- 把 observer、daemon、状态刷新、install/start/stop 的启动和停止放进生命周期。
- 逐项映射现有 FilterStatus，保持错误完整性和用户审批引导。
- AppDelegate 和所有按钮改为依赖 FirewallProviding。

通过标准：Debug build 通过；启动/停止/安装/审批状态路径可手动验证；插件停止后没有 observer、IPC 或后台 Task 泄漏。

### 阶段 6：迁移主界面和 UI 贡献

任务：

- 用 Factory 生成 Main View；RootView 只保留 bootstrap/error/host shell。
- 将 `TopBar`、设置 Popover、插件窗口改为读取 Shell/Settings/Window Provider。
- 将 AppList、AppDetail、Guide、Diagram 等 View 按数据所有权迁入对应插件或 App Host。
- 保留现有窗口大小、菜单栏交互、颜色、间距、快捷动作和空状态。
- 解决 View 更新期间发布状态的问题：主视图在 App init/Factory 阶段缓存，不在 `body` 中装配并发布。

通过标准：UI 关键流程无空壳；工具栏/设置/窗口贡献顺序稳定；运行时状态更新能刷新正确视图；没有重复订阅。

### 阶段 7：迁移 Store、Guide 和动作插件

任务：

- StoreKit 服务、状态、交易监听、产品 UI 迁移到 PluginStore。
- Guide/Welcome/Upgrade 迁移到 PluginGuide。
- About/Quit/DataFolder/InstallExtension 迁移为 App Action contributions。
- 删除所有迁移插件中的具体 singleton 引用。

通过标准：购买、恢复、订阅状态、欢迎页版本判断和退出/打开数据目录等行为保持兼容；StoreKit 测试和插件契约测试通过。

### 阶段 8：切换唯一生产入口和删除旧层

任务：

- 让 App 只使用 FactoryNetto + KernelCore。
- 删除/移出旧 `Core/Providers/PluginRegistry.swift`、`PluginProvider.swift`、直接初始化链和旧插件注册器。
- 将没有业务所有权的 `Core` 文件归入 App Host，其他文件移动到对应 Provider/Plugin package。
- 更新 `Plugins/README.md`，删除会误导新开发者的旧自动发现示例。
- 增加依赖规则和 singleton 回归检查脚本。

通过标准：不存在两套生产入口；没有旧 Registry 被调用；没有新代码依赖具体 Repo/Service；Extension 仍可独立构建。

### 阶段 9：回归、性能、数据和发布验证

任务：

- Debug App build、Release App build、Extension build。
- 每个 local package 的 `swift test`，以及 Factory/Kernel 集成测试。
- 使用真实旧数据库做只读回归。
- 测试启动失败、Provider 缺失、插件禁用、审批中断、Extension 未安装、网络错误、数据库损坏、StoreKit 失败和窗口关闭。
- 测量启动到主界面、首次事件列表、事件分页和状态切换时间；与阶段 0 基线比较。
- 验证签名 entitlements、App/Extension Bundle ID、嵌入路径和应用安装流程没有被改变。

通过标准：所有失败都能归类为代码、工程配置、签名、依赖解析、数据或环境问题；没有使用“能编译”掩盖未验证的运行时行为。

## 8. 数据和兼容性红线

除非单独获得明确需求，以下内容不得在架构迁移中改变：

- App Bundle ID：`com.yueyi.TravelMode`。
- Extension Bundle ID、App Group、entitlements 和系统扩展嵌入关系。
- 数据库文件名 `db.sqlite`、Debug/production 目录规则和现有 SwiftData 模型含义。
- 现有 UserDefaults 键，尤其是欢迎页和版本检查键。
- StoreKit product ID、交易验证和恢复购买行为。
- 欢迎窗口、插件窗口、主界面和菜单栏的窗口 ID/默认尺寸，除非已有行为本身是 bug 且明确记录。
- Extension 的 `NEProvider.startSystemExtensionMode()`、IPC listener 和流量处理时序。

必须做兼容适配的内容：

- 旧插件 ID 到新插件 ID 的映射。
- 旧通知到新 typed request 的桥接。
- 旧错误字符串到新 `Failure` 值类型的完整保留。
- 旧 Repo API 到新 Provider API 的迁移期 adapter。

兼容层只能是临时、可定位、可测试的 adapter，不能变成长期第二套架构。

## 9. 测试和静态检查矩阵

### 9.1 Kernel/Provider 契约测试

- Provider 注册同类型重复失败。
- 缺失 Provider 返回明确的 unavailable 状态，而不是强制解包。
- 插件依赖顺序稳定，依赖环可诊断。
- Boot/Ready/Shutdown 失败全部回滚。
- Contribution token 按 owner 撤回，且撤回顺序可预测。
- 运行时 disable/enable 不产生重复 observer、重复 toolbar item 或重复 Task。
- 所有异步操作支持 Task cancellation。

### 9.2 数据回归测试

- 旧数据库读取和新增事件。
- 允许/阻止规则读取、更新、计数。
- 事件筛选、分页边界、空页、删除和定时维护。
- 数据库路径 Debug/Release 分离。

### 9.3 Firewall/IPC 测试

- 状态转换完整。
- IPC 注册成功/失败、连接中断、回调切换 actor。
- promptUser 的 allow/drop/resume 行为。
- Extension 未安装、未批准、未激活和更新状态。

### 9.4 UI/集成检查

- 主界面启动成功、启动失败持久显示。
- Toolbar 左/中/右排序和设置入口。
- App 列表、详情、空状态、筛选、分页。
- Store、Guide、插件窗口和菜单栏行为。
- 主题、文本选择、错误完整显示、无 clipped border/toolbar。

### 9.5 每次改动后至少执行

```bash
git diff --check
rg -n "PluginRegistry\.shared|FirewallService\.shared|EventRepo\.shared|AppSettingRepo\.shared|MagicMessageProvider\.shared" App Packages Plugins Core
rg -n "import (SwiftUI|AppKit|NetworkExtension|SwiftData|StoreKit|Magic)" Packages/KernelCore
xcodebuild -project TravelMode.xcodeproj -list
```

在目标 packages 建立后，再执行对应的：

```bash
swift test --package-path Packages/KernelCore
swift test --package-path Packages/ProviderFirewall
swift test --package-path Packages/ProviderFirewallEvents
swift test --package-path Packages/ProviderAppSettings
swift test --package-path Packages/FactoryNetto
xcodebuild -project TravelMode.xcodeproj -scheme TravelMode-DEBUG -configuration Debug build
xcodebuild -project TravelMode.xcodeproj -scheme Extension -configuration Debug build
```

命令必须跑到最终退出并报告真实结果；不能只截取中间的 `CompileSwift` 或把 package test 当成 App/Extension 运行时验证。

## 10. 不允许的实现捷径

1. 不得一次性删除 `Core`、`Plugins` 后从空壳重新开始。
2. 不得为了通过编译把所有旧类型塞进一个 `NettoService`、`AppProvider` 或 `Kernel`。
3. 不得把 `AnyView`、`ObservableObject`、SwiftData Model、AppKit 对象放进 Kernel 契约。
4. 不得保留 Objective-C Runtime 自动扫描作为生产注册机制。
5. 不得让插件 import 另一个插件的具体 module/type。
6. 不得用 NotificationCenter 替代所有 Provider 观察关系。
7. 不得把 `@unchecked Sendable` 当作 Swift 6 并发修复。
8. 不得在 `init`/`body`/`onAppear` 中用 singleton 创建并启动核心服务。
9. 不得修改 Bundle ID、entitlements、数据库路径、产品 ID 或 Extension IPC 语义来规避错误。
10. 不得把未验证的成功称为“重构完成”；必须分别报告 package、App、Extension 和真实运行时证据。

## 11. 最终完成定义

当且仅当以下条件全部满足，才可以说 Netto 已按 Lumi 架构完成迁移：

- App 只有一个由 Factory 创建的 Kernel 实例。
- KernelCore 不依赖 UI、系统业务 SDK、数据库或具体插件。
- Provider 契约按能力拆分，Provider 实现拥有真实数据路径。
- 所有生产插件通过显式 Factory 进入 Kernel，并有完整生命周期和依赖。
- App 不直接访问具体 Repo/Service/Plugin/Registry。
- UI 只依赖 Provider Snapshot/commands，不依赖 singleton。
- Extension 与 App 通过独立 IPC 契约构建，两个进程边界清晰。
- 旧数据库、UserDefaults、StoreKit、Bundle、entitlements 和用户可见行为兼容。
- Kernel、Provider、Plugin、Factory、App、Extension 各有测试或明确的集成验证。
- 静态依赖扫描、`git diff --check`、Debug/Release build、Extension build 和关键运行时流程均有记录。
- 旧 `PluginRegistry`、`PluginProvider` 和重复运行时入口已删除，或有带删除条件的临时 adapter 记录。

这份计划是迁移顺序的约束，不要求另一个 agent 一次完成所有阶段。每完成一个阶段，应更新本文对应复选项、记录验证命令和结果，再继续下一阶段。
