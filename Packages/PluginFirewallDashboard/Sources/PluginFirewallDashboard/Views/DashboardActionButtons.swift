import AppKit
import LumiUI
import ProviderFirewall
import ProviderViewEnvironment
import SwiftUI

struct DashboardOpenSystemSettingsButton: View {
    var body: some View {
        AppButton("打开系统设置", systemImage: "gearshape", style: .secondary, fillsWidth: true) {
            guard let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?extensionPointIdentifier=com.apple.system_extension.network_extension.extension-point") else { return }
            NSWorkspace.shared.open(url)
        }
        .frame(width: 150, height: 50)
        .accessibilityIdentifier("netto.extension.system-settings")
    }
}

struct DashboardInstallExtensionButton: View {
    var title = "安装系统扩展"
    var busyTitle = "安装中…"
    var style: AppButton.Style = .primary

    @Environment(\.firewallProvider) private var service: FirewallProviding?

    @State private var isBusy = false

    var body: some View {
        AppButton(isBusy ? busyTitle : title, systemImage: "puzzlepiece.extension", style: style, fillsWidth: true) {
            guard let service, !isBusy else { return }
            isBusy = true
            Task {
                await service.installSystemExtension()
                isBusy = false
            }
        }
        .disabled(isBusy)
        .frame(width: 150, height: 50)
        .accessibilityIdentifier("netto.extension.install")
    }
}
