import Cocoa
import MagicCore
import NetworkExtension
import OSLog
import SwiftUI
import SystemExtensions

/// 负责决定是否允许网络连接，与视图无关，APP启动就运行
final class FirewallDaemon: NSObject, SuperLog, @unchecked Sendable {
    nonisolated static let emoji = "🚪"

    private let repo: AppSettingRepo
    private let eventRepo: EventRepo

    init(repo: AppSettingRepo, eventRepo: EventRepo, reason: String) async {
        os_log("\(Self.onInit)(\(reason))")

        self.repo = repo
        self.eventRepo = eventRepo

        super.init()

        if #available(macOS 15.1, *) {
            os_log("\(self.t)🚩 监听系统扩展状态")
            do {
                try OSSystemExtensionsWorkspace.shared.addObserver(self)
            } catch {
                os_log(.error, "\(error)")
            }
        } else {
            // Fallback on earlier versions
        }

        // loadFilterConfiguration 然后 filterManager.isEnabled 才能得到正确的值
        do {
            try await loadFilterConfiguration(reason: "Boot")
        } catch {
            os_log(.error, "\(self.t)Boot -> \(error)")
        }

        // 不管系统扩展是否激活，尝试关联，失败了也没关系
        registerWithProvider(reason: "init")
    }
}

// MARK: Content Filter Configuration Management

extension FirewallDaemon {
    private func loadFilterConfiguration(reason: String) async throws {
        os_log("\(self.t)🚩 读取过滤器配置 🐛 \(reason)")

        // You must call this method at least once before calling saveToPreferencesWithCompletionHandler: for the first time after your app launches.
        try await NEFilterManager.shared().loadFromPreferences()
    }

    private func registerWithProvider(reason: String) {
        os_log("\(self.t)🛫 registerWithProvider，让 ChannelProvider 和 Extension 关联起来 🐛 (\(reason))")

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

extension FirewallDaemon: AppCommunication {
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
        let printAllowed = true
        let printDenied = false

        let shouldAllow = self.repo.shouldAllowSync(id)
        let dto = FirewallEventDTO(
            id: id,
            time: .now,
            address: hostname,
            port: port,
            sourceAppIdentifier: id,
            status: shouldAllow ? .allowed : .rejected,
            direction: direction,
            appId: id
        )

        if shouldAllow {
            #if DEBUG
            if verbose && printAllowed {
                os_log("\(self.t)✅ \(id)")
            }
            #endif
            
            responseHandler(true)
        } else {
            #if DEBUG
            if verbose && printDenied {
                os_log("\(self.t)🈲 \(id)")
            }
            #endif

            responseHandler(false)
        }

        // 将事件存储到数据库
        let eventRepo = self.eventRepo
        Task {
            do {
                try await eventRepo.createFromDTO(dto)
            } catch {
                os_log(.error, "\(Self.t)❌ 存储事件到数据库失败: \(error)")
            }
        }
    }
}

// MARK: - OSSystemExtensionsWorkspaceObserver

extension FirewallDaemon: OSSystemExtensionsWorkspaceObserver {
    @available(macOS 15.1, *)
    func systemExtensionWillBecomeEnabled(_ systemExtensionInfo: OSSystemExtensionInfo) {
        os_log("\(self.t)🍋 systemExtensionWillBecomeEnabled")
        
        self.registerWithProvider(reason: "systemExtensionWillBecomeEnabled")
    }

    @available(macOS 15.1, *)
    func systemExtensionWillBecomeDisabled(_ systemExtensionInfo: OSSystemExtensionInfo) {
        os_log("\(self.t)🍋 systemExtensionWillBecomeDisabled")
    }

    @available(macOS 15.1, *)
    func systemExtensionWillBecomeInactive(_ systemExtensionInfo: OSSystemExtensionInfo) {
        os_log("\(self.t)🍋 systemExtensionWillBecomeInactive")
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 600)
}
