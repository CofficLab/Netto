import Cocoa
import MagicCore
import NetworkExtension
import OSLog
import SwiftUI
import SystemExtensions

final class FirewallService: NSObject, ObservableObject, SuperLog, SuperEvent, SuperThread, @unchecked Sendable {
    nonisolated static let emoji = "🛡️"

    var ipc = IPCConnection.shared
    var extensionManager = OSSystemExtensionManager.shared
    var extensionBundle = ExtensionConfig.extensionBundle
    var error: Error?
    var observer: Any?
    @Published var status: FilterStatus = .indeterminate

    init(repo: AppSettingRepo) async {
        os_log("\(Self.onInit)")

        super.init()

        self.emit(.firewallWillBoot)
        self.setObserver()

        // 检查系统扩展的状态
        self.requestSystemExtensionStatus()

        // 检查系统扩展的标识符
        let id = self.getExtensionIdentifier()

        os_log("\(Self.t)🆔 系统扩展的标识符是：\(id)")

        let isEnabled = NEFilterManager.shared().isEnabled

        os_log("\(self.t)\(isEnabled ? "✅ 过滤器已启用" : "⚠️ 过滤器未启用")")

        await updateFilterStatus(isEnabled ? .running : .disabled)
    }

    /// 更新过滤器状态
    /// - Parameter status: 新的过滤器状态
    @MainActor
    func updateFilterStatus(_ status: FilterStatus) {
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
            os_log("\(self.t)\(enabled ? "👀 监听到 Filter 已打开 " : "👀 监听到 Fitler 已关闭")")

            Task {
                await self.updateFilterStatus(enabled ? .running : .stopped)
            }
        }
    }

    /// 过滤器是否已经启动了
    @MainActor private func ifFilterReady() -> Bool {
        if NEFilterManager.shared().isEnabled {
            self.updateFilterStatus(.running)

            return true
        } else {
            return false
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
