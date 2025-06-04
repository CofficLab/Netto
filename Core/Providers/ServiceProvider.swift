import Combine
import Foundation
import MagicCore
import OSLog
import SwiftUI

@MainActor
class ServiceProvider: ObservableObject, SuperLog {
    nonisolated static let emoji = "💾"
    
    let firewallService: FirewallService
    let firewallEventService: EventService
    let versionService: VersionService
    
    init(firewallService: FirewallService, firewallEventService: EventService, versionService: VersionService) {
        self.firewallService = firewallService
        self.firewallEventService = firewallEventService
        self.versionService = versionService
        
        // 注册版本检查通知
        NotificationCenter.default.addObserver(self, selector: #selector(checkVersionForWelcomeWindow), name: .checkVersionForWelcomeWindow, object: nil)
    }
    
    func startFilter(reason: String) async throws {
        try await firewallService.startFilter(reason: reason)
    }
    
    func stopFilter(reason: String) async throws {
        try await firewallService.stopFilter(reason: reason)
    }
    
    func installFilter() {
        firewallService.installFilter()
    }
    
    func viewWillDisappear() {
        firewallService.viewWillDisappear()
    }
    
    func getFirewallServiceStatus() -> FilterStatus {
        firewallService.status
    }
    
    /// 检查是否应该显示欢迎窗口
    /// 基于版本比较逻辑
    func shouldShowWelcomeWindow() -> Bool {
        return versionService.shouldShowWelcomeWindow()
    }
    
    /// 响应版本检查通知，决定是否显示欢迎窗口
    @objc func checkVersionForWelcomeWindow() {
        let shouldShowWelcome = versionService.shouldShowWelcomeWindow()
        
        os_log("\(self.t)🚩 检查版本，shouldShowWelcome: \(shouldShowWelcome)")
        
        if shouldShowWelcome {
            NotificationCenter.default.post(name: .shouldOpenWelcomeWindow, object: nil)
        } else {
            NotificationCenter.default.post(name: .shouldCloseWelcomeWindow, object: nil)
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
