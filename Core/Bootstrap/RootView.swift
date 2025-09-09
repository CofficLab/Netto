import MagicAlert
import MagicCore
import OSLog
import SwiftData
import SwiftUI

struct RootView<Content>: View, SuperLog, SuperEvent where Content: View {
    nonisolated static var emoji: String { "🌳" }

    private var content: Content

    // 核心服务 - 改为实例对象
    @StateObject private var app = UIProvider()
    @StateObject private var p = PluginProvider()
    @State private var eventRepo: EventRepo?
    @State private var settingRepo: AppSettingRepo?
    @State private var firewall: FirewallService?
    @StateObject private var m = MagicMessageProvider.shared
    @State private var isLoading = true
    @State private var initializationError: Error?

    init(@ViewBuilder content: () -> Content) {
        os_log("\(Self.onInit)")
        self.content = content()
    }

    var body: some View {
        Group {
            if isLoading {
                RootLoadingView()
            } else if let error = initializationError {
                error.makeView()
            } else if let eventRepo = eventRepo, let settingRepo = settingRepo, let firewall = self.firewall {
                // 将内容视图包裹在插件的 RootView 中
                p.wrapContent(
                    content
                        .withMagicToast()
                        .environmentObject(app)
                        .environmentObject(m)
                        .environmentObject(p)
                        .environmentObject(eventRepo)
                        .environmentObject(settingRepo)
                        .environmentObject(firewall)
                        .onAppear(perform: onAppear)
                )
            }
        }
        .task {
            await initializeServices()
        }
        .onDisappear(perform: onDisappear)
    }
}

// MARK: - Action

extension RootView {
    /// 异步初始化所有服务
    private func initializeServices() async {
        os_log("\(self.i)初始化服务...")

        // Repos
        let eventRepo = EventRepo.shared
        let appSettingRepo = AppSettingRepo()

        // Services
        let firewallService = await FirewallService(repo: appSettingRepo)

        await MainActor.run {
            self.eventRepo = eventRepo
            self.settingRepo = appSettingRepo
            self.isLoading = false
            self.firewall = firewallService
            self.initializationError = nil
        }

        os_log("\(self.t)✅ 服务初始化完成")
    }
}

// MARK: - Event Handler

extension RootView {
    func onAppear() {
    }

    func onDisappear() {
        os_log("\(self.t)📴 视图消失，清理和释放内存")

        self.app.cleanup()
        self.p.cleanup()
        self.firewall?.removeObserver()

        // 清理状态变量，强制释放引用
        self.eventRepo = nil
        self.settingRepo = nil
        self.firewall = nil
        self.initializationError = nil
    }
}

extension View {
    /// 将当前视图包裹在RootView中
    /// - Returns: 被RootView包裹的视图
    func inRootView() -> some View {
        RootView {
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
                .foregroundColor(.secondary)
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
