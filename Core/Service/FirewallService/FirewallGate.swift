import Cocoa
import MagicCore
import NetworkExtension
import OSLog
import SwiftUI
import SystemExtensions

/// 负责决定是否允许网络连接，与视图无关，APP启动就运行
final class FirewallGate: NSObject, SuperLog, @unchecked Sendable {
    nonisolated static let emoji = "🚪"

    private let repo: AppSettingRepo
    private let eventRepo: EventRepo

    init(repo: AppSettingRepo, eventRepo: EventRepo, reason: String) async {
        os_log("\(Self.onInit)(\(reason))")

        self.repo = repo
        self.eventRepo = eventRepo

        super.init()

        // loadFilterConfiguration 然后 filterManager.isEnabled 才能得到正确的值
        do {
            try await loadFilterConfiguration(reason: "Boot")
        } catch {
            os_log(.error, "\(self.t)Boot -> \(error)")
        }

        registerWithProvider(reason: "init")
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

        IPCConnection.shared.register(withExtension: ExtensionConfig.extensionBundle, delegate: self) { success in
            if success {
                os_log("\(self.t)⛓️ ChannelProvider 和 Extension 关联成功")
            } else {
                os_log(.error, "\(self.t)💔 ChannelProvider 和 Extension 关联失败")
            }
        }
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
            wrapper.allowed = true
        } else {
            if verbose && printDenied {
                os_log("\(self.t)🈲 \(id)")
            }

            responseHandler(false)
            wrapper.allowed = false
        }

        // 将事件存储到数据库
        let eventRepo = self.eventRepo
        Task {
            do {
                try await eventRepo.createFromDTO(FirewallEventDTO(
                    id: id,
                    time: .now,
                    address: wrapper.getAddress(),
                    port: wrapper.getPort(),
                    sourceAppIdentifier: wrapper.id,
                    status: wrapper.allowed ? .allowed : .rejected,
                    direction: wrapper.direction
                ))
            } catch {
                os_log(.error, "\(Self.t)❌ 存储事件到数据库失败: \(error)")
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
