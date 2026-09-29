import LumiUI
import OSLog
import ProviderViewEnvironment
import ProviderFirewall
import SwiftUI

public struct BtnStart: View {
    @Environment(\.firewallProvider) private var firewall: FirewallProviding?

    private var asToolbarItem: Bool = false

    public init(asToolbarItem: Bool = false) {
        self.asToolbarItem = asToolbarItem
    }

    public var body: some View {
        if asToolbarItem {
            Button {
                action()
            } label: {
                Label {
                    Text("开始")
                } icon: {
                    Image(systemName: "restart.circle")
                }
            }
            .buttonStyle(.plain)
        } else {
            AppButton("开启", systemImage: "restart.circle", style: .primary, fillsWidth: true, action: {
                action()
            })
            .disabled(firewall?.snapshot.state.isRunning() == true)
            .help(firewall?.snapshot.state.isRunning() == true ? "已开启" : "")
            .frame(width: 150)
            .frame(height: 50)
        }
    }

    private func action() {
        guard let firewall else { return }
        Task {
            try? await firewall.start()
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
