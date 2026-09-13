# 给重构 Agent 的实施提示词

下面的内容可以原样发送给负责实施的另一个 agent。

```text
你现在负责重构 /Users/angel/Code/Coffic/Netto。目标不是只让工程换一套目录，而是把它按 /Users/angel/Code/Coffic/Lumi 的实际 KernelCore + Provider + Plugin + Factory + App 组合根架构迁移，同时保持 Netto 当前用户功能、数据、App/Extension Bundle、StoreKit 和系统扩展行为兼容。

首先完整阅读：

1. /Users/angel/Code/Coffic/Netto/docs/lumi-architecture-rearchitecture-plan.md
2. /Users/angel/Code/Coffic/Netto/README.md
3. /Users/angel/Code/Coffic/Netto/README-DEV.md
4. /Users/angel/Code/Coffic/Netto/.trae/rules/project_rules.md
5. /Users/angel/Code/Coffic/Netto/docs/plugin-architecture.md
6. /Users/angel/Code/Coffic/Lumi/Packages/KernelCore/Sources/KernelCore/Contracts/SuperPlugin.swift
7. /Users/angel/Code/Coffic/Lumi/Packages/KernelCore/Sources/KernelCore/KernelCore+Plugin.swift
8. /Users/angel/Code/Coffic/Lumi/Packages/FactoryLumi/Sources/FactoryLumi/KernelFactory.swift
9. /Users/angel/Code/Coffic/Lumi/LumiApp/LumiApp.swift

不要把 Lumi 当作可直接复制的依赖。只借鉴边界、生命周期、Provider 注册/解析、贡献撤回、Factory 装配和 App 组合根；Netto 仍是独立项目，继续使用自己的 MagicKit、SwiftData、Network Extension 和 StoreKit。

硬性规则：

- 先做事实核对，再改代码。不得凭文件名猜职责。
- 先运行 git status --short、git log -8 --oneline --decorate、xcodebuild -project TravelMode.xcodeproj -list，并记录完整基线。
- 不覆盖、重置、删除用户已有 dirty/staged 改动；不要执行 git reset --hard、git checkout -- 或广泛删除。
- 不修改 com.yueyi.TravelMode、Extension Bundle ID、entitlements、App Group、db.sqlite 路径、Debug/production 目录、StoreKit product ID 或 Extension IPC 语义，除非先证明现状错误并单独报告。
- 每完成一个阶段都必须保持可编译，并执行与该阶段对应的测试/构建。
- 使用真实代码路径证明迁移完成；协议存在不代表功能已接通。
- 不要把一个大重构伪装成“创建空协议”。每个 Provider 必须有实现、注册、真实调用方和测试/验证。
- 不要把所有东西塞进 Kernel、NettoService、AppProvider 或 PluginProvider。
- KernelCore 禁止 import SwiftUI、AppKit、NetworkExtension、SwiftData、StoreKit、MagicKit、具体 Plugin。
- KernelCore 不允许 shared singleton；生产 App 只能由 Factory 创建一个 Kernel 实例。
- 禁止使用 Objective-C Runtime 自动扫描作为新生产注册机制。Factory 必须显式返回稳定顺序的插件数组。
- 插件之间禁止直接依赖具体插件类型；跨插件调用只能通过 Provider 契约。
- 插件和 View 禁止新增或保留生产路径中的 FirewallService.shared、EventRepo.shared、AppSettingRepo.shared、PluginRegistry.shared、MagicMessageProvider.shared。
- 不要用 @unchecked Sendable 掩盖并发问题。明确 @MainActor、actor、Sendable DTO 和取消边界。
- View 不得在 body/onAppear/.task 中创建或首次启动核心服务。主视图和设置视图要在 Factory/App 初始化时装配并缓存，避免 SwiftUI 更新期间发布状态。
- Network Extension 是独立进程。App 的 Kernel 不能进入 Extension；只允许共享独立的 NettoIPCContracts。
- 所有函数按项目规则添加函数级注释。注释说明所有权、线程/actor 和副作用，不写空泛注释。
- 发生构建失败时，跑到最终退出，保留完整错误；区分代码错误、Package Graph、签名、工程配置、磁盘/环境问题。

实施顺序必须遵循下面的阶段，不要跳到最后一次性替换：

阶段 0：基线和事实地图

- 检查现有工作树、Scheme、target、build settings、Package Graph 和当前 Debug App/Extension build。
- 扫描所有 singleton、NotificationCenter、EnvironmentObject、具体 Repo/Service 引用和插件注册器。
- 追踪真实数据路径：Extension flow → IPC → FirewallService → EventRepo/AppSettingRepo → SwiftData → AppList/EventDetail。
- 产出 docs/architecture-baseline.md，记录命令、结果、已知警告和不能在本次架构迁移中改变的兼容项。
- 这一阶段不改业务代码。

阶段 1：KernelCore

- 建立独立 KernelCore local package/target，只有 Foundation 和必要的基础运行库。
- 实现 typed Provider register/resolve/unregister。
- 实现 SuperPlugin：id、order、dependencies、metadata、onRegister、onBoot、onReady、onShutdown、onUnregister、onEnable、onDisable。
- 实现依赖排序、重复 ID/缺失依赖/依赖环错误、启动失败回滚、逆序停止、贡献 owner 跟踪和清理。
- 异步插件支持取消和阶段超时；不能启动后留下后台任务。
- 用测试内 Mock Provider/Plugin 写单元测试。此时可以保留旧 PluginRegistry，但 KernelCore 不得依赖它。

阶段 2：Provider 和 IPC 契约

- 建立 ProviderFirewall、ProviderFirewallEvents、ProviderAppSettings、ProviderAppCatalog、ProviderShell、ProviderStore 等中立契约。
- Snapshot、错误、方向、状态、分页、稳定 ID 都要明确并优先 Sendable/Equatable。
- 建立 NettoIPCContracts；只放 App/Extension 共享的无 UI IPC 合约和值类型。
- Provider 契约不能暴露 SwiftData ModelContext、StoreKit.Product、NEFilterManager、NSView、AnyView 或具体 Repo/Service。
- 写契约测试，验证缺失 Provider 时是明确 unavailable，而不是强制解包。

阶段 3：FactoryNetto

- 创建 FactoryNetto.makeKernel()、makePlugins()、makeMainView(kernel:)、makeSettingsView(kernel:)。
- 显式列出插件数组、稳定 order、硬依赖和默认启用策略。
- Factory 是唯一静态装配点，不要让它变成第二个 Kernel 或万能 Service Locator。
- 支持注入 Mock Provider 的测试 Factory。
- 先可以生成兼容的旧 UI，但不能在 App body 中重复装配。

阶段 4：持久化和 Settings

- 将 ModelContainer/SwiftData schema 归入 EventStore/AppSettings 实现插件；Repo 改为注入实例，删除 singleton 使用。
- 保留 db.sqlite、Debug/production 数据目录和现有 schema/字段语义。
- 逐项保留 EventRepo 的分页、筛选、统计、删除、导出、定时维护行为。
- 逐项保留 AppSettingRepo 的规则读写和通知/观察行为。
- 迁移 hasShownWelcome、版本检查和 Store 状态所用 UserDefaults 键，不改键名。
- 用旧数据库做只读回归，不要因为迁移方便改变数据格式。

阶段 5：Firewall

- 将 Core/Service/FirewallService 迁移为 PluginFirewall 实现 FirewallProviding。
- NEFilterManager、OSSystemExtensionManager、IPC adapter、observer、daemon 和后台 Task 都由 PluginFirewall 拥有。
- Provider 在 onBoot 注册，真实系统监听/daemon 在 onReady 启动，onShutdown 移除 observer/取消 Task/停止 IPC。
- 保留 FilterStatus 的所有有意义状态：安装、审批、未激活、未安装、需要更新、Applications 目录、权限拒绝、错误等，不要全部合并成 stopped。
- 删除 @unchecked Sendable，修正 actor/主线程边界。
- Start/Stop/Filter/Switcher UI 只能依赖 FirewallProviding/AppSettingsProviding。

阶段 6：主界面和 UI 贡献

- RootView 只保留启动态/错误态/Host shell，不再创建 EventRepo.shared、AppSettingRepo.shared、FirewallService.shared、UIProvider、PluginProvider。
- Topbar 通过 ShellToolbarProviding 聚合稳定 ID/位置/排序的贡献。
- BtnSettings 通过 SettingsProviding 获取设置入口，不查 Registry。
- 插件窗口通过 WindowProviding/Window Host，过渡期可以保留旧通知 adapter，但新插件不要继续发送任意 NotificationCenter 对象。
- AppList、AppDetail、Guide、Diagram 等 View 按数据所有权移动到对应插件或 App Host；View 不依赖具体 Repo/Service。
- 保留窗口 ID、尺寸、菜单栏、颜色、间距、空状态和用户可见交互。

阶段 7：Store/Guide/App Actions

- StoreService、StoreState、DTO、购买/恢复/订阅 UI 归入 PluginStore，并通过 StoreProviding 暴露中立 Snapshot。
- Guide/Welcome/Upgrade 归入 PluginGuide。
- About/Quit/DataFolder/InstallExtension 作为 App Actions 贡献实现。
- 迁移完成后清理旧插件注册器和 singleton 引用。

阶段 8：唯一入口和旧层清理

- App 只使用 FactoryNetto + KernelCore。
- 删除或隔离旧 Core/Providers/PluginRegistry.swift、PluginProvider.swift 和 Objective-C 自动注册路径。
- 更新 docs/plugin-architecture.md，不能继续教新开发者使用旧注册机制。
- 增加依赖扫描脚本，阻止 Kernel import UI/业务 SDK、Plugin import 具体 Plugin、App 直连 Repo/Service。
- 任何暂时保留的 adapter 都要有 owner、删除条件和测试。

阶段 9：最终验证

- swift test：KernelCore、Provider 契约、Plugin、Factory 所有可测试 package。
- xcodebuild -project TravelMode.xcodeproj -scheme TravelMode-DEBUG -configuration Debug build。
- xcodebuild -project TravelMode.xcodeproj -scheme TravelMode -configuration Release build（若被签名/环境阻塞，保留完整证据）。
- xcodebuild -project TravelMode.xcodeproj -scheme Extension -configuration Debug build。
- git diff --check。
- 静态扫描 shared、旧 Registry、App 直连 Repo/Service、Kernel 非法 import。
- 真实启动验证：主界面、启动失败、安装/审批/启动/停止防火墙、事件列表/筛选/分页/清空、设置、Store、Guide、插件窗口、退出和 Extension IPC。
- 分别报告 package build/test、App build、Extension build、真实运行时验证；不要用其中一类代替其他类别。

每次工作循环都使用以下格式向我汇报：

1. 当前阶段和本次真实改动。
2. 变更文件及每个文件的所有权变化。
3. 已执行的验证命令和最终结果。
4. 尚未验证的内容以及原因。
5. 下一步最小安全动作。

遇到阻塞时：先阅读完整错误并做三次以内的安全定位（文件、依赖、工程设置、环境），不要通过删代码、改 Bundle/entitlements、关闭功能或引入全局 singleton 绕过。只有在无法继续时，明确报告阻塞点、已验证证据和需要的决定。

不要自动 commit，除非我明确要求提交。不要修改与本次重构无关的 dirty/staged 文件。
```
