import Combine
import Foundation
import MagicCore
import OSLog
import SwiftUI

@MainActor
class ServiceProvider: ObservableObject, SuperLog {
    nonisolated static let emoji = "💾"
    
    @Published var firewallStatus: FilterStatus = .disabled
    
    let firewallService: FirewallService
    let versionService: VersionService
    
    init(firewallService: FirewallService, versionService: VersionService) {
        self.firewallService = firewallService
        self.versionService = versionService
        self.firewallStatus = firewallService.status
    }
    
    func startFilter(reason: String) async throws {
        try await firewallService.startFilter(reason: reason)
        firewallStatus = firewallService.status
    }
    
    func stopFilter(reason: String) async throws {
        try await firewallService.stopFilter(reason: reason)
        firewallStatus = firewallService.status
    }
    
    func installFilter() {
        firewallService.installFilter()
    }
    
    func getFirewallServiceStatus() -> FilterStatus {
        firewallService.status
    }
    
    /// 清理资源，释放内存
    func cleanup() {
        firewallService.removeObserver()
    }
}

// MARK: - Setter

extension ServiceProvider {
    func updateFirewallStatus() {
        firewallStatus = firewallService.status
    }
}

// MARK: - Preview

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 600)
}
