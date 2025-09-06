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
    @State private var service: ServiceProvider?
    @State private var eventRepo: EventRepo?
    @State private var settingRepo: AppSettingRepo?

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
                RootErrorView(error: error) {
                    Task {
                        await initializeServices()
                    }
                }
            } else if let service = service, let eventRepo = eventRepo, let settingRepo = settingRepo {
                content
                    .withMagicToast()
                    .environmentObject(app)
                    .environmentObject(m)
                    .environmentObject(p)
                    .environmentObject(eventRepo)
                    .environmentObject(settingRepo)
                    .environmentObject(service)
                    .onAppear(perform: onAppear)
                    .onReceive(self.nc.publisher(for: .FilterStatusChanged), perform: onFilterStatusChanged)
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
        os_log("\(self.i)开始初始化服务...")

        // Repos
        let eventRepo = EventRepo.shared
        let appSettingRepo = AppSettingRepo()

        // Services
        let firewallService = await FirewallService(repo: appSettingRepo, reason: Self.author)
        let versionService = VersionService()

        // Providers
        let serviceProvider = ServiceProvider(firewallService: firewallService, versionService: versionService)

        await MainActor.run {
            self.service = serviceProvider
            self.eventRepo = eventRepo
            self.settingRepo = appSettingRepo
            self.isLoading = false
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
        
        self.service?.viewWillDisappear()
        self.app.cleanup()
        self.p.cleanup()
    }

    func onFilterStatusChanged(_ n: Notification) {
        if let status = n.object as? FilterStatus {
            os_log("\(self.t)状态变更为 -> \(status.description)")
        }
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

// MARK: - Loading & Error Views

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

struct RootErrorView: View {
    let error: Error
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text("初始化失败")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("重试") {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Preview

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
