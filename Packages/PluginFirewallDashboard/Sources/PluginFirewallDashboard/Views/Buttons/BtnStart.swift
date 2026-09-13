import MagicCore
import ProviderViewEnvironment
import MagicAlert
import MagicUI
import OSLog
import ProviderFirewall
import SwiftUI

public struct BtnStart: View, SuperLog {
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
            MagicButton.simple(icon: "restart.circle", size: .auto, action: {
                action()
            })
            .magicTitle("开启")
            .magicBackgroundColor(.blue)
            .magicShape(.roundedRectangle)
            .magicDisabled(firewall?.snapshot.state.isRunning() == true ? "已开启" : nil)
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
