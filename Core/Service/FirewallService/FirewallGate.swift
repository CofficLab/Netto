import Cocoa
import MagicCore
import NetworkExtension
import OSLog
import SwiftUI
import SystemExtensions

final class FirewallGate: NSObject, SuperLog, SuperEvent, SuperThread, @unchecked Sendable {
    nonisolated static let emoji = "🛡️"

    private var ipc = IPCConnection.shared
    private var extensionBundle = ExtensionConfig.extensionBundle
    private var observer: Any?
    private var repo: AppSettingRepo
    private var eventRepo: EventRepo
    var status: FilterStatus = .indeterminate

    init(repo: AppSettingRepo, eventRepo: EventRepo, reason: String) async {
        os_log("\(Self.onInit)(\(reason))")

        self.repo = repo
        self.eventRepo = eventRepo

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
        if oldValue.isNotRunning() && status.isRunning() {
            registerWithProvider(reason: "not running -> running")
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

            self.updateFilterStatus(enabled ? .running : .stopped)
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

// MARK: Content Filter Configuration Management

extension FirewallGate {
    private func loadFilterConfiguration(reason: String) async throws {
        os_log("\(self.t)🚩 读取过滤器配置 🐛 \(reason)")

        // You must call this method at least once before calling saveToPreferencesWithCompletionHandler: for the first time after your app launches.
        try await NEFilterManager.shared().loadFromPreferences()
    }

    private func registerWithProvider(reason: String) {
        os_log("\(self.t)🛫 registerWithProvider，让 ChannelProvider 和 Extension 关联起来(\(reason))")

        self.emit(.firewallWillRegisterWithProvider)

        ipc.register(withExtension: extensionBundle, delegate: self) { success in
            if success {
                os_log("\(self.t)🎉 ChannelProvider 和 Extension 关联成功")

                NotificationCenter.default.post(name: .firewallDidRegisterWithProvider, object: nil)

                self.updateFilterStatus(.running)
            } else {
                os_log("\(self.t)💔 ChannelProvider 和 Extension 关联失败")

                self.updateFilterStatus(.extensionNotReady)
            }
        }
    }
}

// MARK: OSSystemExtensionActivationRequestDelegate

extension FirewallGate: OSSystemExtensionRequestDelegate {
    nonisolated func request(
        _ request: OSSystemExtensionRequest,
        didFinishWithResult result: OSSystemExtensionRequest.Result
    ) {
        switch result {
        case .completed:
            os_log("\(self.t)🍋 OSSystemExtensionRequestDelegate -> completed")
        case .willCompleteAfterReboot:
            os_log("\(self.t)🍋 willCompleteAfterReboot")
        @unknown default:
            os_log("\(self.t)\(result.rawValue)")
        }

//            self.enableFilterConfiguration(reason: "didFinishWithResult")
    }

    nonisolated func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        os_log(.error, "\(self.t)didFailWithError -> \(error.localizedDescription)")

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

// MARK: AppCommunication

extension FirewallGate: AppCommunication {
    nonisolated func extensionLog(_ words: String) {
        let verbose = false

        if verbose {
            os_log("\(self.t)💬 Extension said -> \(words)")
        }
    }

    nonisolated func needApproval() {
        NotificationCenter.default.post(
            name: .firewallNeedApproval,
            object: nil,
            userInfo: nil
        )
    }

    /// 提示用户是否允许网络连接
    /// - Parameters:
    ///   - id: 应用标识符
    ///   - hostname: 主机名
    ///   - port: 端口号
    ///   - direction: 网络流量方向
    ///   - responseHandler: 响应处理回调
    nonisolated func promptUser(id: String, hostname: String, port: String, direction: NETrafficDirection, responseHandler: @escaping (Bool) -> Void) {
        let verbose = true
        let printAllowed = false
        let printDenied = true

        let shouldAllow = self.repo.shouldAllowSync(id)
        var wrapper = FlowWrapper(
            id: id,
            hostname: hostname,
            port: port,
            allowed: false,
            direction: direction
        )

        if shouldAllow {
            if verbose && printAllowed {
                os_log("\(self.t)✅ \(id)")
            }
            responseHandler(true)

            DispatchQueue.main.sync {
                NotificationCenter.default.post(name: .firewallNetWorkFilterFlow, object: FlowWrapper(
                    id: id,
                    hostname: hostname,
                    port: port,
                    allowed: true,
                    direction: direction
                ))
            }
            wrapper.allowed = true
        } else {
            if verbose && printDenied {
                os_log("\(self.t)🈲 \(id)")
            }
            
            DispatchQueue.main.sync {
                NotificationCenter.default.post(name: .firewallNetWorkFilterFlow, object: FlowWrapper(
                    id: id,
                    hostname: hostname,
                    port: port,
                    allowed: false,
                    direction: direction
                ))
            }
            responseHandler(false)
            wrapper.allowed = false
        }
        
        let event = FirewallEvent(
            address: wrapper.getAddress(),
            port: wrapper.getPort(),
            sourceAppIdentifier: wrapper.id,
            status: wrapper.allowed ? .allowed : .rejected,
            direction: wrapper.direction
        )
        
        // 将事件存储到数据库
        Task {
            do {
                try await eventRepo.create(event)
            } catch {
                os_log(.error, "\(self.t)❌ 存储事件到数据库失败: \(error)")
            }
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 600)
}
