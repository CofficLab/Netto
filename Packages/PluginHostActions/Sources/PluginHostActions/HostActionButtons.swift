import AppKit
import LumiUI
import ProviderFirewall
import ProviderViewEnvironment
import SwiftUI

struct HostOpenSystemSettingsButton: View {
    var body: some View {
        AppButton("打开系统设置", systemImage: "gearshape", style: .secondary, fillsWidth: true) {
            guard let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?extensionPointIdentifier=com.apple.system_extension.network_extension.extension-point") else { return }
            NSWorkspace.shared.open(url)
        }
        .frame(width: 150, height: 50)
    }
}

struct HostInstallExtensionButton: View {
    @Environment(\.firewallProvider) private var service: FirewallProviding?

    var body: some View {
        AppButton("安装系统扩展", systemImage: "puzzlepiece.extension", style: .primary, fillsWidth: true) {
            guard let service else { return }
            Task { await service.installSystemExtension() }
        }
        .frame(width: 150, height: 50)
    }
}
