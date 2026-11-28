import LumiUI
import ProviderViewEnvironment
import ProviderShell
import ProviderFirewall
import SwiftUI

public struct BtnStop: View {
    @EnvironmentObject var app: UIProvider
    @EnvironmentObject private var shell: ShellCenter
    @Environment(\.firewallProvider) private var firewall: FirewallProviding?

    private var asToolbarItem: Bool = false
    private var icon: String = "stop.circle"

    public init(asToolbarItem: Bool = false) {
        self.asToolbarItem = asToolbarItem
    }

    public var body: some View {
        if asToolbarItem {
            AppIconButton(systemImage: icon) {
                action()
            }
        } else {
            AppButton("Stop", systemImage: icon, style: .primary, fillsWidth: true, action: {
                action()
            })
            .disabled(firewall?.snapshot.state.isNotRunning() == true)
            .help(firewall?.snapshot.state.isNotRunning() == true ? String(localized: "Not Started") : "")
            .frame(width: 150)
            .frame(height: 50)
        }
    }

    private func action() {
        guard let firewall else { return }
        Task {
            do {
                try await firewall.stop()
            } catch {
                shell.postError(String(localized: "Failed to stop firewall: \(error.localizedDescription)"))
            }
        }
    }
}

#Preview {
    VStack {
        BtnStop()
        BtnStop(asToolbarItem: true)
    }
    .dashboardPreviewRoot()
}

#Preview("App") {
    ContentView()
        .dashboardPreviewRoot()
        .frame(height: 800)
        .frame(width: 500)
}
