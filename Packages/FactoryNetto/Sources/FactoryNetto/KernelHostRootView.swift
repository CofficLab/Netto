import Foundation
import ProviderViewEnvironment
import KernelCore
import PluginFirewallDashboard
import ProviderShell
import ProviderAppSettings
import ProviderFirewall
import ProviderFirewallEvents
import ProviderStore
import SwiftUI

/// 主视图装配 —— FactoryNetto 生成的真实主界面（阶段 6 起替代阶段 3 占位）。
///
/// 职责：在 Factory 装配点一次解析全部 Provider 契约并注入环境，
/// 渲染 `ContentView`（TopBar + AppList，TopBar 内部消费 Shell 工具栏贡献）。
/// 不在 body 中创建/启动任何核心服务；契约缺失时显式失败（不静默降级）。
///
/// 环境注入（与 App RootView 的 Host 注入同值、幂等覆盖，双路径均可用）：
/// shell / ui / appProvider / firewall / events / settings / store / sessionStartDate。
///
/// 线程/actor：`View`；body 求值无副作用；`ui`/`appProvider`/`sessionStartDate`
/// 由调用方（App 组合根或 Factory 默认实例）持有。
struct KernelHostRootView: View {
    let kernel: KernelCoreContainer
    let shell: ShellCenter?
    let ui: UIProvider
    let appProvider: AppProvider
    let sessionStartDate: Date

    var body: some View {
        if let shell,
           let firewall = kernel.resolveProvider(FirewallProviding.self),
           let events = kernel.resolveProvider(FirewallEventsProviding.self),
           let settings = kernel.resolveProvider(AppSettingsProviding.self),
           let store = kernel.resolveProvider(StoreProviding.self) {
            ContentView()
                .environmentObject(shell)
                .environmentObject(ui)
                .environmentObject(appProvider)
                .environment(\.firewallProvider, firewall)
                .environment(\.eventsProvider, events)
                .environment(\.settingsProvider, settings)
                .environment(\.storeProvider, store)
                .environment(\.sessionStartDate, sessionStartDate)
        } else {
            BootstrapFailureView(
                title: "主视图装配失败",
                message: "Shell / Provider 契约未全部装配"
            )
        }
    }
}

/// 启动失败视图（与 Lumi BootstrapFailureView 语义一致：失败必须显式呈现）。
struct BootstrapFailureView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(title)
                .font(.headline)
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
