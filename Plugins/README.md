# 插件系统架构文档（阶段 8 迁移后）

> 本文档描述 Netto 当前的 KernelCore + Provider + Plugin + Factory + App 组合根架构。
> 旧的 `Core/Contract/SuperPlugin.swift`、`PluginRegistry`、`PluginProvider`、
> Objective-C 自动注册（`PluginRegistrant` / `autoRegisterPlugins`）已在阶段 8 删除，
> 不再作为任何插件的注册方式。

## 架构分层

```
App 组合根（Core/Bootstrap、Core/AppHost）
   └─ FactoryNetto（Packages/FactoryNetto）——唯一静态装配点
        └─ KernelCore（Packages/KernelCore）——内核容器
             ├─ Provider 契约包（ProviderFirewall / ProviderFirewallEvents /
             │  ProviderAppSettings / ProviderAppCatalog / ProviderShell /
             │  ProviderStore / ProviderMenuBar / ProviderPersistence /
             │  ProviderViewEnvironment / ProviderSettingsUI）
             ├─ Plugin 实现包（PluginPersistence / PluginAppSettings /
             │  PluginEventStore / PluginFirewall / PluginStore /
             │  PluginFirewallDashboard / PluginHostActions）
             └─ NettoIPCContracts（App / Extension 共享 IPC 契约）
```

macOS Host 只保留 SwiftUI App 入口、启动环境、少量系统集成与 AppKit
状态栏控制器。状态栏由 `NSStatusItem + NSPopover` 承载；插件通过
`ProviderMenuBar.MenuBarProviding` 注册常驻状态栏项或 popover 区块，Factory
在 Kernel 启动前注册 Provider，Host 监听 Kernel 启动态并显示插件贡献。

- **KernelCore**：只允许 `Foundation` 与基础运行库；禁止 import SwiftUI、
  AppKit、NetworkExtension、SwiftData、StoreKit、MagicKit 或任何具体插件。
  提供 typed Provider 的 register / resolve / unregister、依赖排序、
  重复 ID / 缺失依赖 / 依赖环错误、启动失败回滚、逆序停止、贡献 owner 跟踪与清理。
- **Provider 契约包**：中立接口与 Sendable 值类型（Snapshot / 错误 / 分页 / 稳定 ID）。
  `ProviderPersistence` 持有跨存储插件共享的 SwiftData schema/config 与容器接口；
  `ProviderViewEnvironment` 持有 SwiftUI Provider 环境键；`ProviderSettingsUI` 提供可复用的设置控件。
  Provider 不暴露 `StoreKit.Product`、`NEFilterManager`、`NSView`、`ModelContext`；
  `ProviderShell` 的 UI 贡献契约保留 `AnyView`。
- **Plugin 实现包**：实现 Provider 契约与生命周期（onBoot / onReady / onShutdown），
  跨插件调用只能走 Provider 契约，禁止 import 同级其他 Plugin 包。
- **FactoryNetto**：`makeKernelAsync()` / `makePlugins()` /
  `makeMainView(kernel:)` / `makeMenuBarPopupView(kernel:)` /
  `makeSettingsView(kernel:)`；显式返回稳定顺序的插件数组，App 只通过它装配内核。
- **App 组合根**：`AppEnvironment.bootstrap()` 调用 FactoryNetto 创建唯一 Kernel 实例，
  Provider 注册后安装状态栏，缓存契约到环境键；`RootView` 只保留启动态 / 错误态 / Host shell。

## SuperPlugin 生命周期（KernelCore）

```swift
protocol SuperPlugin: Sendable {
    var id: String { get }
    var order: Int { get }
    var dependencies: [String] { get }
    var metadata: PluginMetadata { get }
    func onRegister(kernel: KernelCoreContainer) async throws
    func onBoot(kernel: KernelCoreContainer) async throws
    func onReady(kernel: KernelCoreContainer) async throws
    func onShutdown(kernel: KernelCoreContainer) async
    func onUnregister(kernel: KernelCoreContainer) async
    func onEnable(kernel: KernelCoreContainer) async throws
    func onDisable(kernel: KernelCoreContainer) async
}
```

- 启动顺序按 `order` + `dependencies` 拓扑排序；重复 ID、缺失依赖、依赖环直接报错。
- 启动失败触发已启动插件的逆序回滚；停止按注册逆序执行。
- 异步插件支持取消与阶段超时，不允许启动后遗留后台任务（onShutdown 必须取消 Task / 移除 observer / 停止 IPC）。
- 贡献（toolbar / settings entry / window content / toast）记录 owner，插件卸载时按 owner 清理。

## Provider 契约注册 / 解析

插件在 `onBoot` 中注册自己的 Provider：

```swift
func onBoot(kernel: KernelCoreContainer) throws {
    kernel.registerProvider(FirewallProviding.self, instance: self)
    kernel.registerProvider(FirewallEventsProviding.self, instance: eventStore)
}
```

消费方在 `onBoot` / `onReady` 中显式解析（缺失即明确报错，不允许强制解包）：

```swift
let firewall = try kernel.requireProvider(FirewallProviding.self)
```

## 创建新插件

### 方式 A：功能插件（独立 Package，推荐）

1. 在 `Packages/` 下新建 Swift Package，依赖 `KernelCore` 与所需 Provider 契约包。
2. 实现 `SuperPlugin` 与对应 Provider 契约。
3. 在 `FactoryNetto`（Packages/FactoryNetto/Sources/FactoryNetto/DefaultPluginAssembly.swift）
   的 `makePlugins()` 显式加入实例，声明 `order` 与 `dependencies`。
4. 写契约 / 行为测试；`cd Packages/<包名> && swift test`。

### 方式 B：Host 操作插件（聚合 Package）

macOS 宿主操作（About / Quit / DataFolder / InstallExtension / Guide / 设置入口）
和通用设置/调试面板在 `Packages/PluginHostActions` 中实现，视图、插件与贡献
均由该 Package 持有。它依赖 `ProviderShell`、`ProviderSettingsUI` 和其他中立契约，
不依赖 Dashboard 插件。

### 菜单栏 popover 贡献

功能插件在 `onBoot` 中解析 `MenuBarProviding` 并调用 `addPopup(_:)`；插件停用、
卸载或关闭时按 `ownerPluginID` 撤回。AppKit `MenuBarController` 只负责状态栏按钮、
Popover 生命周期与根视图托管，不包含业务面板实现。

## 视图访问数据的正确姿势

- 视图不创建、不首启任何核心服务；通过 `@Environment(\.firewallProvider)` 等环境键
  读取 App 启动期缓存的契约实例。
- 窗口内容贡献（WindowProviding）由 `TheApp` 的 plugin-window Scene 渲染，
  插件不直接操作窗口对象。
- 主视图 / 设置视图在 Factory / App 初始化时装配并缓存，避免 SwiftUI 更新期间发布状态。

## 依赖扫描

`Scripts/check_architecture.py`（python3 直接运行）在 CI / 开发前检查：

- R1 KernelCore 禁止 import UI / 业务 SDK
- R2 包内禁止 shared 单例
- R3 Plugin 包禁止 import 同级 Plugin 包
- R4 App 目标禁止直连旧 Repo/Service（EventRepo.shared 等）
- R5 禁止 `@unchecked Sendable`
- R6 禁止 Objective-C 运行时自动注册

## 现有插件清单（新形态）

| 插件 | 类型 | 位置 / 贡献 | Order |
|------|------|------|-------|
| KernelCore | 内核包 | 容器 + SuperPlugin | - |
| FactoryNetto | 装配包 | makeKernel / makePlugins | - |
| ProviderShell（ShellCenter） | Provider/UI 聚合 | Toolbar / Settings / Window / Toast 聚合 | - |
| ProviderPersistence | Provider 契约 | 共享 SwiftData schema / db URL / 容器协议 | - |
| ProviderViewEnvironment | Provider/UI 辅助 | SwiftUI 中共享 Provider 环境键 | - |
| ProviderSettingsUI | Provider/UI 组件 | 系统设置与扩展操作的复用控件 | - |
| PluginPersistence | 功能包 | SwiftData ModelContainer 的唯一创建者 | 1 |
| PluginAppSettings | 功能包 | AppSettingsProviding | 10（依赖 persistence） |
| PluginEventStore | 功能包 | FirewallEventsProviding | 10（依赖 persistence） |
| PluginFirewall | 功能包 | FirewallProviding（NE / 系统扩展 / IPC / daemon） | 30 |
| PluginStore | 功能包 | StoreProviding（StoreKit 购买 / 订阅 / 恢复） | 40 |
| FirewallDashboardPlugin | 功能包 | 菜单栏 popover 主面板 + Switcher / Filter 工具栏项 | 60 |
| ThemePackPlugin | 功能包 | 主题注册与外观设置入口 | 100 |
| PluginHostActions | 聚合功能包 | About / Quit / DataFolder / Guide / 通用设置 / DB（DEBUG）及对应视图 | 20–80 |

## 与 Extension 的关系

App 内核不会进入 Network Extension 进程；App 与 Extension 只共享
`NettoIPCContracts` 中的无 UI 契约与值类型，以及 `Bridge/` 下的 IPC 通道
（Extension 二进制兼容红线，未迁移）。

## 注意事项

1. 不要在新代码中引入 `Xxx.shared` 单例；生产 App 只允许 Factory 创建的一个 Kernel 实例。
2. 插件之间禁止直接依赖具体插件类型；需要协作时定义 Provider 契约。
3. 视图不在 `body` / `onAppear` / `.task` 中创建或首次启动核心服务。
4. 并发边界用 `@MainActor` / `actor` / Sendable DTO 明确表达，禁止 `@unchecked Sendable` 掩盖问题。
5. 每完成一个阶段保持可编译，并执行对应测试 / 构建；改动架构前先跑 `Scripts/check_architecture.py`。
