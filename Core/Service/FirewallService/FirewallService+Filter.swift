import Foundation
import NetworkExtension
import OSLog
import SwiftUI

// MARK: - 过滤器配置管理
// 过滤器：指的是系统设置 - 网络 - VPN与过滤条件 - 过滤条件与代理
// 负责管理 NEFilterManager 的配置，包括：
// - 创建和配置过滤器提供者
// - 请求用户授权
// - 将过滤器加载到系统设置中

extension FirewallService {
    func enableFilterConfiguration(reason: String) async {
        self.emit(.firewallConfigurationChanged)

        guard !NEFilterManager.shared().isEnabled else {
            os_log("\(self.t)FilterManager is Disabled, registerWithProvider")
            return
        }
        
        do {
            os_log("\(self.t)🚀 请求用户授权")

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
            try await NEFilterManager.shared().saveToPreferences()
            os_log("\(self.t)🎉 用户授权成功")
            self.emit(.firewallUserApproved)
        } catch {
            os_log(.error, "\(self.t)❌ 请求用户授权失败 -> \(error.localizedDescription)")
            await self.updateFilterStatus(.needSystemExtensionApproval)
        }
    }

    func startFilter(reason: String) async throws {
        os_log("\(self.t)🚀 开启过滤器 🐛 \(reason)  ➡️ Current Status: \(self.status.description)")

        self.emit(.firewallWillStart)

        guard !NEFilterManager.shared().isEnabled else {
            os_log("\(self.t)👌 过滤器已启用")
            self.emit(.firewallDidStart)
            return
        }
        
        // 确保系统扩展已经激活
        self.activateSystemExtension()
        
        NEFilterManager.shared().isEnabled = true
        try await NEFilterManager.shared().saveToPreferences()
    }

    func stopFilter(reason: String) async throws {
        os_log("\(self.t)🤚 停止过滤器 🐛 \(reason)")

        self.emit(.firewallWillStop)

        guard NEFilterManager.shared().isEnabled else {
            await self.updateFilterStatus(.stopped)
            return
        }

        NEFilterManager.shared().isEnabled = false
        try await NEFilterManager.shared().saveToPreferences()
    }
}

// MARK: - Preview

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(width: 700)
}
