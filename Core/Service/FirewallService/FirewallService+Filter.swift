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
    func isFilterEnabled() async -> Bool {
        let nm = NEFilterManager.shared()

        do {
            // You must call this method at least once before calling saveToPreferencesWithCompletionHandler: for the first time after your app launches.
            try await nm.loadFromPreferences()
        } catch {
            os_log(.error, "\(self.t)❌ 加载过滤器配置出错 \(error)")
            await self.updateStatus(.error(error))
        }

        return nm.isEnabled
    }

    func installFilter(reason: String) async throws {
        os_log("\(self.t)🚀 安装过滤器 🐛 \(reason)  ➡️ Current Status: \(self.status.description)")

        do {
            // You must call this method at least once before calling saveToPreferencesWithCompletionHandler: for the first time after your app launches.
            try await NEFilterManager.shared().loadFromPreferences()
        } catch {
            os_log(.error, "\(self.t)❌ 加载过滤器配置出错 \(error)")
            await self.updateStatus(.error(error))
            
            throw error
        }

        self.emit(.firewallConfigurationChanged)

        guard !NEFilterManager.shared().isEnabled else {
            await self.updateStatus(.filterNotInstalled)
            return
        }

        do {
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
            NEFilterManager.shared().isEnabled = false

            // 将过滤器加载到系统设置中
            os_log("\(self.t)📺 将要弹出授权对话框来加载到系统设置中")
            try await NEFilterManager.shared().saveToPreferences()
            os_log("\(self.t)🎉 用户授权成功")
            self.emit(.firewallUserApproved)
        } catch {
            os_log(.error, "\(self.t)❌ 请求用户授权失败 -> \(error.localizedDescription)")
            await self.updateStatus(.filterNeedApproval)
            
            throw error
        }
    }

    func startFilter(reason: String) async {
        os_log("\(self.t)🚀 开启过滤器 🐛 \(reason)  ➡️ Current Status: \(self.status.description)")
        
        if await self.isFilterEnabled() {
            os_log("\(self.t)✅ 已经是开启状态")
            return
        }

        self.emit(.firewallWillStart)

        // 确保系统扩展已经激活
        self.activateSystemExtension()
        
        // 确保过滤器已安装
        do {
            try await self.installFilter(reason: reason)
        } catch {
            os_log(.error, "\(self.t)❌ 启动过滤器 - 安装过滤器失败 \(error)")
            await self.updateStatus(.error(error))
            return
        }

        do {
            // You must call this method at least once before calling saveToPreferencesWithCompletionHandler: for the first time after your app launches.
            try await NEFilterManager.shared().loadFromPreferences()
        } catch {
            os_log(.error, "\(self.t)❌ 加载过滤器配置出错 \(error)")
            await self.updateStatus(.error(error))
        }

        do {
            NEFilterManager.shared().isEnabled = true
            try await NEFilterManager.shared().saveToPreferences()
        } catch {
            os_log(.error, "\(self.t)❌ 开启过滤器出错 \(error)")
            await self.updateStatus(.error(error))
        }
    }

    func stopFilter(reason: String) async throws {
        os_log("\(self.t)🤚 停止过滤器 🐛 \(reason)")

        self.emit(.firewallWillStop)

        guard NEFilterManager.shared().isEnabled else {
            await self.updateStatus(.stopped)
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
