import MagicCore
import OSLog
import SwiftData
import SwiftUI

struct RootView<Content>: View, SuperLog, SuperEvent where Content: View {
    nonisolated static var emoji: String { "🌳" }

    private var content: Content
    private var app = UIProvider.shared
    private var p = PluginProvider.shared

    // 核心服务
    @State private var data: DataProvider?
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
            } else if let data = data, let service = service, let eventRepo = eventRepo, let settingRepo = settingRepo {
                content
                    .withMagicToast()
                    .modelContainer(DBManager.container())
                    .environmentObject(app)
                    .environmentObject(data)
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
            addDeniedApps()
        }
    }
}

// MARK: - Action

extension RootView {
    private func addDeniedApps() {
        guard let data = self.data else { return }
        guard let appSettingRepo = self.settingRepo else { return }

        Task {
            // 添加被禁止的应用到apps列表中
            do {
                let deniedAppIds = try await appSettingRepo.getDeniedApps()
                for appId in deniedAppIds {
                    let smartApp = SmartApp.fromId(appId)
                    if !data.apps.contains(where: { $0.id == smartApp.id }) {
                        data.apps.append(smartApp)
                    }
                }
            } catch {
                os_log(.error, "\(self.t)获取被禁止应用列表失败: \(error)")
            }
        }
    }

    /// 异步初始化所有服务
    private func initializeServices() async {
        os_log("\(self.t)开始初始化服务...")

        // Repos
        let eventRepo = EventRepo()
        let appSettingRepo = AppSettingRepo()

        // Services
        let appPermissionService = PermissionService(repo: appSettingRepo)
        let firewallEventService = EventService(repo: eventRepo)
        let firewallService = await FirewallService(repo: appSettingRepo, reason: Self.author)
        let versionService = VersionService()

        // Providers
        let dataProvider = DataProvider(appPermissionService: appPermissionService, firewallEventService: firewallEventService, eventRepo: eventRepo, settingRepo: appSettingRepo)
        let serviceProvider = ServiceProvider(firewallService: firewallService, firewallEventService: firewallEventService, versionService: versionService)

        await MainActor.run {
            self.data = dataProvider
            self.service = serviceProvider
            self.eventRepo = eventRepo
            self.settingRepo = appSettingRepo
            self.isLoading = false
            self.initializationError = nil
        }

        os_log("\(self.t)服务初始化完成")
    }
}

// MARK: - Event Handler

extension RootView {
    func onAppear() {
        guard let data = data, let service = service else { return }
        data.status = service.getFirewallServiceStatus()
    }

    func onFilterStatusChanged(_ n: Notification) {
        if let status = n.object as? FilterStatus {
            os_log("\(self.t)状态变更为 -> \(status.description)")
            self.data?.status = status
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
