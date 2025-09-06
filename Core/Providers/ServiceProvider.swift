import Combine
import Foundation
import MagicCore
import OSLog
import SwiftUI

class ServiceProvider: ObservableObject, SuperLog {
    nonisolated static let emoji = "💾"
    
    let firewallService: FirewallService
    let versionService: VersionService
    
    init(firewallService: FirewallService, versionService: VersionService) {
        self.firewallService = firewallService
        self.versionService = versionService
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
        firewallService.removeObserver()
    }
    
    func getFirewallServiceStatus() -> FilterStatus {
        firewallService.status
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 600)
}
