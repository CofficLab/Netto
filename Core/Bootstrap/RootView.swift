import PluginFirewallDashboard
import MagicAlert
import MagicCore
import OSLog
import SwiftData
import SwiftUI

/// 主界面 Host 壳 —— 只保留启动态 / 失败态 / 运行态装配。
///
/// 阶段 6 迁移后：
/// - 不再创建 `UIProvider` / `PluginProvider` / `EventRepo.shared` /
///   `AppSettingRepo.shared` / `FirewallService.shared` / `MagicMessageProvider.shared`；
/// - 所有核心服务由 `AppEnvironment` 在 App 启动期装配并缓存，
///   视图只消费注入的契约环境对象；
/// - 运行态按 `AppEnvironment.phase` 呈现：加载 / 失败 / 内容；
/// - 内容在 `.running` 时**惰性求值**（`contentBuilder`）：App 传入
///   `FactoryNetto.makeMainView` 的闭包在 Kernel 就绪后才被调用，
///   避免 bootstrap 完成前解析 nil Kernel。
///
/// 线程/actor：`@MainActor`（SwiftUI View）。无副作用；`inRootView()` 只用于预览。
struct RootView<Content>: View, SuperLog, SuperEvent where Content: View {
    nonisolated static var emoji: String { "🌳" }

    /// 内容构建器（仅在 `phase == .running` 时求值一次/每次重绘时求值）。
    private let contentBuilder: () -> Content

    /// 显式注入的环境（App 启动路径）；预览可传 `AppEnvironment.preview()`。
    private let providedEnvironment: AppEnvironment?
    /// Kernel 就绪后由 App 绑定窗口路由等宿主回调。
    private let onRunning: () -> Void

    /// 环境对象（场景级注入；App 通过 `environmentObject` 提供）。
    @EnvironmentObject private var appEnv: AppEnvironment

    init(
        environment: AppEnvironment? = nil,
        onRunning: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        os_log("\(Self.onInit)")
        self.providedEnvironment = environment
        self.onRunning = onRunning
        self.contentBuilder = content
    }

    var body: some View {
        let env = providedEnvironment ?? appEnv
        RootEnvironmentHost(environment: env, onRunning: onRunning, contentBuilder: contentBuilder)
    }
}

/// 显式观察所选环境对象，保证 bootstrap 更新 phase 后立即切换根视图状态。
private struct RootEnvironmentHost<Content: View>: View {
    @ObservedObject var environment: AppEnvironment
    let onRunning: () -> Void
    let contentBuilder: () -> Content

    var body: some View {
        Group {
            switch environment.phase {
            case .booting:
                RootLoadingView()
            case let .failed(message):
                // 启动失败必须显式呈现（不可静默降级为内容视图）
                RootFailureView(message: message)
            case .running:
                // 惰性求值：Kernel 就绪后才调用 contentBuilder（Factory 装配
                // 的 KernelHostRootView），并注入 AppEnvironment 持有的契约
                // 环境（与 KernelHostRootView 内部注入同值、幂等覆盖）。
                if let shell = environment.shell {
                    contentBuilder()
                        .environmentObject(shell)
                        .environmentObject(environment.ui)
                        .environmentObject(environment.appProvider)
                        .environment(\.firewallProvider, environment.firewall)
                        .environment(\.eventsProvider, environment.events)
                        .environment(\.settingsProvider, environment.settings)
                        .environment(\.storeProvider, environment.store)
                        .environment(\.sessionStartDate, environment.sessionStartDate)
                } else {
                    RootFailureView(message: "Shell 中心未装配")
                }
            }
        }
        .environmentObject(environment)
        .onAppear {
            if environment.phase == .running {
                onRunning()
            }
        }
        .onChange(of: environment.phase) { _, phase in
            if phase == .running {
                onRunning()
            }
        }
    }
}

/// 启动失败视图：展示内核装配错误（与旧 `error.makeView()` 语义等价）。
private struct RootFailureView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("初始化失败")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

extension View {
    /// 将当前视图包裹在 RootView 中（预览用；注入预览环境）。
    /// - Returns: 被RootView包裹的视图
    func inRootView() -> some View {
        RootView(environment: .preview()) {
            self
        }
    }
}

// MARK: - Loading View

struct RootLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在初始化服务...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Preview

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(width: 700)
}
