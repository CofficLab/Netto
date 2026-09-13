import AppKit
import Combine
import LumiUI
import OSLog
import ProviderSettingView
import ProviderShell
import SwiftUI

/// TravelMode 的 SwiftUI 场景装配器。App Target 只创建共享环境并把场景交给
/// SwiftUI；窗口内容、路由、启动引导和插件视图都由 Factory 负责。
@MainActor
public struct NettoAppScenes: Scene {
    private let environment: AppEnvironment

    public init(environment: AppEnvironment) {
        self.environment = environment
    }

    public var body: some Scene {
        Group {
            Window(AppConfig.welcomeWindowTitle, id: AppConfig.welcomeWindowId) {
                WelcomeWindowHost(environment: environment)
            }
            .windowStyle(.hiddenTitleBar)
            .windowResizability(.contentSize)
            .defaultPosition(.center)
            .defaultSize(width: 500, height: 600)

            Window("设置", id: AppConfig.settingsWindowId) {
                SettingsWindowHost(environment: environment)
            }
            .windowStyle(.hiddenTitleBar)
            .windowResizability(.contentSize)
            .defaultPosition(.center)
            .defaultSize(width: 720, height: 480)

            Window("Plugin Window", id: AppConfig.pluginWindowId) {
                PluginWindowHost(environment: environment)
            }
            .windowStyle(.hiddenTitleBar)
            .windowResizability(.contentSize)
            .defaultPosition(.center)
            .defaultSize(width: 600, height: 800)
        }
    }
}

@MainActor
private struct WelcomeWindowHost: View {
    @ObservedObject var environment: AppEnvironment
    @State private var shouldShowLoading = true
    private let versionService = VersionService()

    var body: some View {
        Group {
            if shouldShowLoading && !environment.shouldShowWelcomeWindow {
                ProgressView("正在检查版本…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        let shouldShowWelcome = versionService.shouldShowWelcomeWindow()
                        os_log("🐦 检查版本，shouldShowWelcome: \(shouldShowWelcome)")
                        environment.shouldShowWelcomeWindow = shouldShowWelcome
                        shouldShowLoading = false
                    }
            }

            if environment.shouldShowWelcomeWindow {
                FactoryNetto.makeWelcomeGuideView()
                    .onAppear {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        if let window = NSApplication.shared.windows.first(where: {
                            $0.title == AppConfig.welcomeWindowTitle
                        }) {
                            window.level = .floating
                            window.orderFrontRegardless()
                        }
                    }
            }
        }
    }
}

@MainActor
private struct SettingsWindowHost: View {
    @ObservedObject var environment: AppEnvironment
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            if let settingsWindowView = environment.settingsWindowView {
                settingsWindowView.appThemedAppearance()
            } else {
                ProgressView("启动中…")
                    .frame(minWidth: 720, minHeight: 460)
            }
        }
        .onAppear(perform: connectRunningEnvironment)
        .onChange(of: environment.phase) { _, phase in
            if phase == .running {
                connectRunningEnvironment()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .shouldOpenWelcomeWindow)) { _ in
            os_log("🖥️ 打开欢迎窗口")
            environment.shouldShowWelcomeWindow = true
            openWindow(id: AppConfig.welcomeWindowId)
        }
        .onReceive(NotificationCenter.default.publisher(for: SettingViewNavigation.openSettingsNotification)) { notification in
            if let settings = environment.kernel?.resolveProvider(SettingViewProviding.self),
               let entryID = notification.userInfo?[SettingViewNavigation.entryIDUserInfoKey] as? String,
               settings.entries.contains(where: { $0.id == entryID }) {
                settings.selectEntry(id: entryID)
            }
            openSettingsWindow()
        }
        .onReceive(NotificationCenter.default.publisher(for: .firewallDidSetDeny)) { _ in
            Task { await environment.refreshDeniedAppIndicator() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .firewallDidSetAllow)) { _ in
            Task { await environment.refreshDeniedAppIndicator() }
        }
    }

    private func connectRunningEnvironment() {
        guard environment.phase == .running else { return }
        let openWindowAction = openWindow
        let settingsWindowID = AppConfig.settingsWindowId
        environment.shell?.onRequestOpen = { request in
            if request.windowID == settingsWindowID,
               let window = NSApp.windows.first(where: { $0.title == "设置" && $0.isVisible }) {
                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
            } else {
                openWindowAction(id: request.windowID)
            }
        }
        Task { await environment.refreshDeniedAppIndicator() }
    }

    private func openSettingsWindow() {
        if let window = NSApp.windows.first(where: { $0.title == "设置" && $0.isVisible }) {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: AppConfig.settingsWindowId)
        }
    }
}

@MainActor
private struct PluginWindowHost: View {
    @ObservedObject var environment: AppEnvironment

    var body: some View {
        Group {
            if let shell = environment.shell {
                PluginShellWindowHost(shell: shell)
            } else {
                Text("请选择一个插件功能")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

@MainActor
private struct PluginShellWindowHost: View {
    @ObservedObject var shell: ShellCenter

    var body: some View {
        Group {
            if let content = shell.currentContent {
                content.makeView()
                    .onAppear {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        if let window = NSApplication.shared.windows.first(where: { $0.title == content.title }) {
                            window.level = .floating
                            window.orderFrontRegardless()
                        }
                    }
            } else {
                Text("请选择一个插件功能")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
