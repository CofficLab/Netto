import MagicCore
import OSLog
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
struct RootView<Content>: View, SuperLog where Content: View {
    nonisolated static var emoji: String { "🌳" }

    /// 内容构建器（仅在 `phase == .running` 时求值一次/每次重绘时求值）。
    private let contentBuilder: () -> Content

    /// App 装配环境；状态由组合根持有，Host shell 只负责观察。
    private let environment: AppEnvironment
    /// Kernel 就绪后由 App 绑定窗口路由等宿主回调。
    private let onRunning: () -> Void

    init(
        environment: AppEnvironment,
        onRunning: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        os_log("\(Self.onInit)")
        self.environment = environment
        self.onRunning = onRunning
        self.contentBuilder = content
    }

    var body: some View {
        RootEnvironmentHost(environment: environment, onRunning: onRunning, contentBuilder: contentBuilder)
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
                // Factory 的视图装配器负责注入共享 Provider 环境。
                contentBuilder()
            }
        }
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
