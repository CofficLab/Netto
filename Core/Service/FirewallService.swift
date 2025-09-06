import Cocoa
import MagicCore
import NetworkExtension
import OSLog
import SwiftUI
import SystemExtensions

final class FirewallService: NSObject, ObservableObject, SuperLog, SuperEvent, SuperThread, @unchecked Sendable {
    nonisolated static let emoji = "🛡️"

    private var ipc = IPCConnection.shared
    private var extensionManager = OSSystemExtensionManager.shared
    private var extensionBundle = ExtensionConfig.extensionBundle
    private var error: Error?
    private var observer: Any?
    @Published var status: FilterStatus = .indeterminate

    init(repo: AppSettingRepo, reason: String) async {
        os_log("\(Self.onInit)(\(reason))")

        super.init()

        self.emit(.firewallWillBoot)
        self.setObserver()

        // loadFilterConfiguration 然后 filterManager.isEnabled 才能得到正确的值
        do {
            try await loadFilterConfiguration(reason: "Boot")
        } catch {
            os_log(.error, "\(self.t)Boot -> \(error)")
        }

        let isEnabled = NEFilterManager.shared().isEnabled

        os_log("\(self.t)\(isEnabled ? "✅ 过滤器已启用" : "⚠️ 过滤器未启用")")

        updateFilterStatus(isEnabled ? .running : .disabled)
    }

    /// 更新过滤器状态
    /// - Parameter status: 新的过滤器状态
    private func updateFilterStatus(_ status: FilterStatus) {
        if self.status == status { return }

        let oldValue = self.status

        self.status = status

        os_log("\(self.t)🍋 更新状态 -> \(status.description) 原状态 -> \(oldValue.description)")

        // 发送状态变化事件
        self.emit(.firewallStatusChanged, object: status)
        
        // 根据状态发送特定事件
        switch status {
        case .running:
            self.emit(.firewallDidStart)
        case .stopped:
            self.emit(.firewallDidStop)
        case .error:
            // 错误事件已在其他地方发送
            break
        default:
            break
        }
    }

    private func setObserver() {
        os_log("\(self.t)👀 添加监听")
        observer = nc.addObserver(
            forName: .NEFilterConfigurationDidChange,
            object: NEFilterManager.shared(),
            queue: .main
        ) { _ in
            let enabled = NEFilterManager.shared().isEnabled
            os_log("\(self.t)\(enabled ? "👀 监听到 Filter 已打开 " : "👀 监听到 Fitler 已关闭")")

            Task {
                self.updateFilterStatus(enabled ? .running : .stopped)
            }
        }
    }

    /// 过滤器是否已经启动了
    private func ifFilterReady() -> Bool {
        os_log("\(self.t)\(Location.did(.IfReady))")

        if NEFilterManager.shared().isEnabled {
            self.updateFilterStatus(.running)

            return true
        } else {
            return false
        }
    }
}

// MARK: Operator

extension FirewallService {
    func clearError() {
        self.error = nil
    }

    func setError(_ error: Error) {
        self.error = error
    }

    func removeObserver() {
        guard let changeObserver = observer else {
            return
        }

        nc.removeObserver(
            changeObserver,
            name: .NEFilterConfigurationDidChange,
            object: NEFilterManager.shared()
        )
    }

    func installFilter() {
        os_log("\(self.t)\(Location.did(.InstallFilter))")

        self.clearError()
        self.emit(.firewallWillInstall)

        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            self.updateFilterStatus(.stopped)
            return
        }

        // Start by activating the system extension
        let activationRequest = OSSystemExtensionRequest.activationRequest(
            forExtensionWithIdentifier: extensionIdentifier,
            queue: .main
        )
        activationRequest.delegate = self
        extensionManager.submitRequest(activationRequest)
    }

    func startFilter(reason: String) async throws {
        os_log("\(self.t)🚀 开启过滤器 🐛 \(reason)  ➡️ Current Status: \(self.status.description)")

        self.emit(.firewallWillStart)

        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            os_log("\(self.t)extensionBundle.bundleIdentifier 为空")
            self.updateFilterStatus(.stopped)
            return
        }

        // macOS 15， 系统设置 - 网络 - 过滤器，用户能删除过滤器，所以要确保过滤器已加载

        try await loadFilterConfiguration(reason: reason)

        guard !NEFilterManager.shared().isEnabled else {
            os_log("\(self.t)👌 过滤器已启用，直接关联")
            self.emit(.firewallDidStart)
            return
        }

        os_log("\(self.t)🚀 开始激活系统扩展")

        // Start by activating the system extension
        let activationRequest = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: .main)
        activationRequest.delegate = self
        OSSystemExtensionManager.shared.submitRequest(activationRequest)
    }

    func stopFilter(reason: String) async throws {
        os_log("\(self.t)🤚 停止过滤器 🐛 \(reason)")

        self.emit(.firewallWillStop)

        guard NEFilterManager.shared().isEnabled else {
            self.updateFilterStatus(.stopped)
            return
        }

        try await loadFilterConfiguration(reason: reason)

        NEFilterManager.shared().isEnabled = false
        try await NEFilterManager.shared().saveToPreferences()

        self.updateFilterStatus(.stopped)
    }
}

// MARK: Content Filter Configuration Management

extension FirewallService {
    private func loadFilterConfiguration(reason: String) async throws {
        os_log("\(self.t)🚩 读取过滤器配置 🐛 \(reason)")

        // You must call this method at least once before calling saveToPreferencesWithCompletionHandler: for the first time after your app launches.
        try await NEFilterManager.shared().loadFromPreferences()
    }

    private func enableFilterConfiguration(reason: String) async {
        os_log("\(self.t)🦶 \(Location.did(.EnableFilterConfiguration))")

        self.emit(.firewallConfigurationChanged)

        guard !NEFilterManager.shared().isEnabled else {
            os_log("\(self.t)FilterManager is Disabled, registerWithProvider")
            return
        }

        do {
            try await loadFilterConfiguration(reason: reason)

            os_log("\(self.t)🎉 加载过滤器配置成功")

            if NEFilterManager.shared().providerConfiguration == nil {
                let providerConfiguration = NEFilterProviderConfiguration()
                providerConfiguration.filterSockets = true
                providerConfiguration.filterPackets = false
                NEFilterManager.shared().providerConfiguration = providerConfiguration
                if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
                    NEFilterManager.shared().localizedDescription = appName
                }
            }

            // 如果true，加载到系统设置中后就是启动状态
            NEFilterManager.shared().isEnabled = true

            // 将过滤器加载到系统设置中
            os_log("\(self.t)📺 将要弹出授权对话框来加载到系统设置中")
            os_log("\(self.t)🦶 \(Location.did(.SaveToPreferences))")
            NEFilterManager.shared().saveToPreferences { saveError in
                if let error = saveError {
                    os_log(.error, "\(self.t)授权对话框报错 -> \(error.localizedDescription)")
                    self.updateFilterStatus(.disabled)
                    return
                } else {
                    os_log("\(self.t)🦶 \(Location.did(.UserApproved))")
                    self.emit(.firewallUserApproved)
                }
            }
        } catch {
            os_log("\(self.t)APP: 加载过滤器配置失败")
            self.updateFilterStatus(.stopped)
        }
    }
}

// MARK: OSSystemExtensionActivationRequestDelegate

extension FirewallService: OSSystemExtensionRequestDelegate {
    nonisolated func request(
        _ request: OSSystemExtensionRequest,
        didFinishWithResult result: OSSystemExtensionRequest.Result
    ) {
        switch result {
        case .completed:
            os_log("\(self.t)🍋 OSSystemExtensionRequestDelegate -> completed")
            self.emit(.firewallDidInstall)
        case .willCompleteAfterReboot:
            os_log("\(self.t)🍋 willCompleteAfterReboot")
        @unknown default:
            os_log("\(self.t)\(result.rawValue)")
        }

//            self.enableFilterConfiguration(reason: "didFinishWithResult")
    }

    nonisolated func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        os_log(.error, "\(self.t)didFailWithError -> \(error.localizedDescription)")

        self.setError(error)
        self.updateFilterStatus(.error(error))

        self.emit(.firewallDidFailWithError, userInfo: ["error": error])
    }

    nonisolated func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        os_log("\(self.t)🦶 \(Location.did(.RequestNeedsUserApproval))")

        self.updateFilterStatus(.needApproval)
    }

    nonisolated func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension extension: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        os_log("\(self.t)actionForReplacingExtension")

        return .replace
    }
}


// MARK: - Firewall Service Events

/// 防火墙服务相关事件通知名称扩展
extension Notification.Name {
    /// 防火墙即将启动
    static let firewallWillBoot = Notification.Name("firewallWillBoot")
    
    /// 防火墙状态变化
    static let firewallStatusChanged = Notification.Name("firewallStatusChanged")
    
    /// 防火墙即将安装
    static let firewallWillInstall = Notification.Name("firewallWillInstall")
    
    /// 防火墙即将启动
    static let firewallWillStart = Notification.Name("firewallWillStart")
    
    /// 防火墙即将停止
    static let firewallWillStop = Notification.Name("firewallWillStop")
    
    /// 防火墙配置变化
    static let firewallConfigurationChanged = Notification.Name("firewallConfigurationChanged")
    
    /// 防火墙发生错误
    static let firewallDidFailWithError = Notification.Name("firewallDidFailWithError")
    
    /// 防火墙已启动
    static let firewallDidStart = Notification.Name("firewallDidStart")
    
    /// 防火墙已停止
    static let firewallDidStop = Notification.Name("firewallDidStop")
    
    /// 防火墙已安装
    static let firewallDidInstall = Notification.Name("firewallDidInstall")
    
    /// 用户已授权
    static let firewallUserApproved = Notification.Name("firewallUserApproved")
    
    /// 用户拒绝授权
    static let firewallUserRejected = Notification.Name("firewallUserRejected")
    
    /// 即将注册提供者
    static let firewallWillRegisterWithProvider = Notification.Name("firewallWillRegisterWithProvider")
    
    /// 已注册提供者
    static let firewallDidRegisterWithProvider = Notification.Name("firewallDidRegisterWithProvider")
    
    /// 网络流量过滤事件
    static let firewallNetWorkFilterFlow = Notification.Name("firewallNetWorkFilterFlow")
    
    /// 需要用户批准
    static let firewallNeedApproval = Notification.Name("firewallNeedApproval")
    
    /// 等待用户批准
    static let firewallWaitingForApproval = Notification.Name("firewallWaitingForApproval")
    
    /// 权限被拒绝
    static let firewallPermissionDenied = Notification.Name("firewallPermissionDenied")
    
    /// 提供者消息
    static let firewallProviderSaid = Notification.Name("firewallProviderSaid")
    
    /// 设置允许操作完成
    static let firewallDidSetAllow = Notification.Name("firewallDidSetAllow")
    
    /// 设置拒绝操作完成
    static let firewallDidSetDeny = Notification.Name("firewallDidSetDeny")
}

// MARK: - View Extensions

extension View {
    /// 监听防火墙状态变化
    /// - Parameter action: 状态变化时的回调，参数为新的 FilterStatus
    func onFirewallStatusChange(_ action: @escaping (FilterStatus) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallStatusChanged)) { notification in
            if let status = notification.object as? FilterStatus {
                action(status)
            }
        }
    }
    
    /// 监听防火墙启动事件
    /// - Parameter action: 启动时的回调
    func onFirewallWillStart(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallWillStart)) { _ in
            action()
        }
    }
    
    /// 监听防火墙已启动事件
    /// - Parameter action: 已启动时的回调
    func onFirewallDidStart(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallDidStart)) { _ in
            action()
        }
    }
    
    /// 监听防火墙停止事件
    /// - Parameter action: 停止时的回调
    func onFirewallWillStop(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallWillStop)) { _ in
            action()
        }
    }
    
    /// 监听防火墙已停止事件
    /// - Parameter action: 已停止时的回调
    func onFirewallDidStop(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallDidStop)) { _ in
            action()
        }
    }
    
    /// 监听防火墙安装事件
    /// - Parameter action: 安装时的回调
    func onFirewallWillInstall(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallWillInstall)) { _ in
            action()
        }
    }
    
    /// 监听防火墙已安装事件
    /// - Parameter action: 已安装时的回调
    func onFirewallDidInstall(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallDidInstall)) { _ in
            action()
        }
    }
    
    /// 监听防火墙配置变化事件
    /// - Parameter action: 配置变化时的回调
    func onFirewallConfigurationChanged(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallConfigurationChanged)) { _ in
            action()
        }
    }
    
    /// 监听防火墙错误事件
    /// - Parameter action: 错误发生时的回调，参数为错误信息
    func onFirewallError(_ action: @escaping (Error) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallDidFailWithError)) { notification in
            if let userInfo = notification.userInfo,
               let error = userInfo["error"] as? Error {
                action(error)
            }
        }
    }
    
    /// 监听用户授权事件
    /// - Parameter action: 用户授权时的回调
    func onFirewallUserApproved(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallUserApproved)) { _ in
            action()
        }
    }
    
    /// 监听用户拒绝授权事件
    /// - Parameter action: 用户拒绝授权时的回调
    func onFirewallUserRejected(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallUserRejected)) { _ in
            action()
        }
    }
    
    /// 监听防火墙启动事件
    /// - Parameter action: 启动时的回调
    func onFirewallWillBoot(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .firewallWillBoot)) { _ in
            action()
        }
    }
}

// MARK: - Preview

#Preview("App - Large") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 600, height: 1000)
}

#Preview("App - Small") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 600, height: 600)
}
