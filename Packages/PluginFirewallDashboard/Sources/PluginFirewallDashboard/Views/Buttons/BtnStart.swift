import LumiUI
import ProviderShell
import ProviderViewEnvironment
import ProviderFirewall
import SwiftUI

public struct BtnStart: View {
    @Environment(\.firewallProvider) private var firewall: FirewallProviding?
    @EnvironmentObject private var shell: ShellCenter

    @State private var isBusy = false

    private var asToolbarItem: Bool = false
    private var title: String = String(localized: "Start")

    public init(asToolbarItem: Bool = false, title: String = String(localized: "Start")) {
        self.asToolbarItem = asToolbarItem
        self.title = title
    }

    public var body: some View {
        if asToolbarItem {
            AppIconButton(systemImage: "restart.circle") {
                action()
            }
            .disabled(isBusy)
        } else {
            AppButton(isBusy ? String(localized: "Starting…") : title, systemImage: "restart.circle", style: .primary, fillsWidth: true, action: {
                action()
            })
            .disabled(isBusy || firewall?.snapshot.state.isRunning() == true)
            .help(isBusy ? String(localized: "Starting…") : (firewall?.snapshot.state.isRunning() == true ? String(localized: "Started") : ""))
            .frame(width: 150)
            .frame(height: 50)
        }
    }

    private func action() {
        guard let firewall, !isBusy else { return }
        isBusy = true
        Task {
            do {
                try await firewall.start()
            } catch {
                shell.postError(String(localized: "Failed to start firewall: \(error.localizedDescription)"))
            }
            isBusy = false
        }
    }
}

#Preview("APP") {
    ContentView()
        .dashboardPreviewRoot()
        .frame(height: 500)
}

#Preview {
    BtnStart()
        .dashboardPreviewRoot()
}
