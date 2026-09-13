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
/// - 运行态按 `AppEnvironment.phase` 呈现：加载 / 失败 / 内容。
///
/// 线程/actor：`@MainActor`（SwiftUI View）。无副作用；`inRootView()` 只用于预览。
struct RootView<Content>: View, SuperLog, SuperEvent where Content: View {
    nonisolated static var emoji: String { "🌳" }

    private var content: Content

    /// 显式注入的环境（App 启动路径）；预览可传 `AppEnvironment.preview()`。
    private let providedEnvironment: AppEnvironment?
    /// Kernel 就绪后由 App 绑定窗口路由等宿主回调。
    private let onRunning: () -> Void

    /// 环境对象（场景级注入；App 通过 `environmentObject` 提供）。
    @EnvironmentObject private var appEnv: AppEnvironment

    init(
        environment: AppEnvironment? = nil,
        onRunning: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        os_log("\(Self.onInit)")
        self.providedEnvironment = environment
        self.onRunning = onRunning
        self.content = content()
    }

    var body: some View {
        let env = providedEnvironment ?? appEnv
        RootEnvironmentHost(environment: env, onRunning: onRunning, content: content)
    }
}

/// 显式观察所选环境对象，保证 bootstrap 更新 phase 后立即切换根视图状态。
private struct RootEnvironmentHost<Content: View>: View {
    @ObservedObject var environment: AppEnvironment
    let onRunning: () -> Void
    let content: Content

    var body: some View {
        Group {
            switch environment.phase {
            case .booting:
                RootLoadingView()
            case let .failed(message):
                // 启动失败必须显式呈现（不可静默降级为内容视图）
                RootFailureView(message: message)
            case .running:
                HostContent(environment: environment, content: content)
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

/// 运行态内容装配：注入契约环境对象后渲染子内容。
///
/// 仅在 `phase == .running` 时渲染；bootstrap 已保证 shell 非空，
/// 但这里仍用 if-let 兜底，避免强解包（不在此处创建任何对象）。
private struct HostContent<Content: View>: View {
    @ObservedObject var environment: AppEnvironment
    let content: Content

    var body: some View {
        if let shell = environment.shell {
            content
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
