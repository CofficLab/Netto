import Cocoa
import MagicCore
import NetworkExtension
import OSLog
import SwiftUI
import SystemExtensions

final class FirewallService: NSObject, ObservableObject, SuperLog, SuperEvent, SuperThread, @unchecked Sendable {
    nonisolated static let emoji = "🛡️"
    nonisolated static let verbose = false
    
    static let shared = FirewallService()

    var ipc = IPCConnection.shared
    var extensionManager = OSSystemExtensionManager.shared
    var extensionBundle = ExtensionConfig.extensionBundle
    var error: Error?
    var observer: Any?
    let settingRepo: AppSettingRepo
    let eventRepo: EventRepo

    @Published var status: FilterStatus = .indeterminate

    private init(repo: AppSettingRepo = .shared, eventRepo: EventRepo = .shared) {
        os_log("\(Self.onInit)")

        self.settingRepo = repo
        self.eventRepo = eventRepo

        super.init()

        self.emit(.firewallWillBoot)
        self.setObserver()
        Task {
            await self.refreshStatus()
        }
    }

    @MainActor func refreshStatus() async {
        // 检查系统扩展的状态，系统会异步通知
        self.requestSystemExtensionStatus()

        let isEnabled = await self.isFilterEnabled()

        os_log("\(self.t)\(isEnabled ? "✅ 过滤器已启用" : "⚠️ 过滤器未启用")")

        if isEnabled {
            self.updateStatus(.running)
            return
        }

        // 默认处于停止状态
        self.updateStatus(.stopped)
    }

    /// 更新状态
    /// - Parameter status: 新的过滤器状态
    @MainActor
    func updateStatus(_ status: FilterStatus) {
        if self.status == status { return }

        let oldValue = self.status

        self.status = status

        os_log("\(self.t)🍋 更新状态 \(oldValue.description) -> \(status.description)")

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
            
            if Self.verbose {
                os_log("\(self.t)\(enabled ? "👀 监听到 Filter 已打开 " : "👀 监听到 Fitler 已关闭")")
            }

            Task {
                await self.updateStatus(enabled ? .running : .stopped)
            }
        }
    }

    /// 过滤器是否已经启动了
    @MainActor private func ifFilterReady() -> Bool {
        if NEFilterManager.shared().isEnabled {
            self.updateStatus(.running)

            return true
        } else {
            return false
        }
    }
}

// MARK: - 基础操作

// 负责 FirewallService 的基础操作，包括：
// - 错误处理（设置和清除错误）
// - 观察者管理（添加和移除观察者）
// - 其他基础工具方法

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
