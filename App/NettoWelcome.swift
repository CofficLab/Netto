import AppKit
import Combine
import Foundation
import KernelCore
import LumiFactory
import OSLog
import PluginHostActions
import ProviderShell
import ProviderTheme
import SwiftUI

/// App 场景内部通知名（从旧 FirewallService+Event.swift 迁出）。
///
/// 所有权：仅宿主（监听）与 HostGuidePlugin/BtnGuide（发送）使用；
/// 均为无负载的壳内信号，不跨插件传对象。
extension Notification.Name {
    /// 打开欢迎引导窗口（宿主监听，BtnGuide 发送）。
    static let shouldOpenWelcomeWindow = Notification.Name("shouldOpenWelcomeWindow")
}

/// 欢迎窗口路由宿主（常驻；生命周期 = App 生命周期）。
///
/// 共享壳的 `HostWindowOpener` 已持有 SwiftUI 开窗动作（由 `HostCommands`
/// 在场景构建期捕获，捕获前的请求排队补发），这里只负责欢迎窗口的两条触发来源：
/// - 首次安装 / major/minor 升级（`TheApp.init` 启动时 `checkVersionOnce`）；
/// - 插件主动请求（`.shouldOpenWelcomeWindow` 通知，常驻监听）。
@MainActor
final class NettoWelcomeRouter: ObservableObject {
    private let logger = Logger(subsystem: "com.yueyi.TravelMode", category: "welcome")
    private var cancellables: Set<AnyCancellable> = []
    private var didCheckVersion = false

    init() {
        cancellables.insert(
            NotificationCenter.default
                .publisher(for: .shouldOpenWelcomeWindow)
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    MainActor.assumeIsolated {
                        self?.openWelcome()
                    }
                }
        )
    }

    /// 首次安装或重要版本升级时打开欢迎引导窗口（幂等）。
    func checkVersionOnce() {
        guard !didCheckVersion else { return }
        didCheckVersion = true
        guard VersionService().shouldShowWelcomeWindow() else { return }
        openWelcome()
    }

    /// 打开欢迎窗口（共享开窗器排队补发，无需视图层 openWindow）。
    func openWelcome() {
        logger.info("打开欢迎引导窗口")
        HostWindowOpener.shared.openWindow(id: ShellWindowID.welcome)
    }
}

/// 欢迎窗口内容：内核就绪后以主题感知视图渲染引导页。
///
/// 欢迎窗是独立 `Window` 场景，不在共享主窗口壳的主题包装内，这里自行
/// 桥接 `ThemeProviding`；窗口仅在 requested 时打开，内容无需额外开关。
@MainActor
struct NettoWelcomeWindowHost: View {
    @ObservedObject var bootstrapper: KernelBootstrapper

    var body: some View {
        Group {
            if let kernel = bootstrapper.kernel,
               let theme = kernel.resolveProvider((any ThemeProviding).self) {
                HostThemeView(theme: theme, content: WelcomeGuideView())
            } else {
                WelcomeGuideView()
            }
        }
        .onAppear {
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let window = NSApplication.shared.windows.first(where: {
                $0.identifier?.rawValue == ShellWindowID.welcome
            }) {
                window.level = .floating
                window.orderFrontRegardless()
            }
        }
    }
}

/// 版本服务：处理应用版本比较，决定首次安装 / 重要升级时展示欢迎窗。
final class VersionService {
    private static let emoji = "🏷️"

    /// 用于存储上次显示欢迎窗口的版本号的键。
    private let lastShownVersionKey = "lastShownWelcomeVersion"

    /// 判断是否应该显示欢迎窗口：
    /// - 首次安装：显示
    /// - patch 版本更新（x.y.z -> x.y.z+1）：不显示
    /// - minor 版本更新（x.y.z -> x.y+1.0）：显示
    /// - major 版本更新（x.y.z -> x+1.0.0）：显示
    func shouldShowWelcomeWindow() -> Bool {
        let lastShownVersion = UserDefaults.standard.string(forKey: lastShownVersionKey)
        let currentVersion = getCurrentAppVersion()

        os_log("\(Self.emoji)🆚 last: \(lastShownVersion ?? "nil"), current: \(currentVersion)")

        guard let lastVersion = lastShownVersion, !lastVersion.isEmpty else {
            os_log("\(Self.emoji) 首次安装，显示欢迎窗口，并记录当前版本：\(currentVersion)")
            UserDefaults.standard.set(currentVersion, forKey: lastShownVersionKey)
            return true
        }

        let shouldShow = isSignificantVersionUpdate(from: lastVersion, to: currentVersion)
        if shouldShow {
            os_log("\(Self.emoji) 重要版本更新，显示欢迎窗口，并记录当前版本：\(currentVersion)")
            UserDefaults.standard.set(currentVersion, forKey: lastShownVersionKey)
        }
        return shouldShow
    }

    /// 当前应用版本号（Bundle 的 CFBundleShortVersionString）。
    func getCurrentAppVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    /// 是否为重要版本更新（major 或 minor）。
    func isSignificantVersionUpdate(from oldVersion: String, to newVersion: String) -> Bool {
        let oldComponents = parseVersion(oldVersion)
        let newComponents = parseVersion(newVersion)

        if newComponents.major > oldComponents.major {
            return true
        }
        if newComponents.major == oldComponents.major && newComponents.minor > oldComponents.minor {
            return true
        }
        return false
    }

    /// 解析版本号字符串为 (major, minor, patch)。
    func parseVersion(_ version: String) -> (major: Int, minor: Int, patch: Int) {
        let components = version.split(separator: ".").compactMap { Int($0) }
        let major = components.count > 0 ? components[0] : 0
        let minor = components.count > 1 ? components[1] : 0
        let patch = components.count > 2 ? components[2] : 0
        return (major, minor, patch)
    }
}