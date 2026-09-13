import MagicAlert
import ProviderViewEnvironment
import MagicCore
import OSLog
import ProviderFirewall
import SwiftUI

struct TileSwitcher: View, SuperLog, SuperThread {
    @EnvironmentObject var app: UIProvider
    @Environment(\.firewallProvider) private var firewall: FirewallProviding?

    @State private var hovered = false

    var body: some View {
        Group {
            if firewall?.snapshot.state.isRunning() == true {
                BtnStop(asToolbarItem: true).labelStyle(.iconOnly)
            } else {
                BtnStart(asToolbarItem: true)
                    .labelStyle(.iconOnly)
                    .disabled(firewall?.snapshot.canStart != true)
            }
        }
        .frame(maxHeight: .infinity)
        .onHover { hovered = $0 }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }
}
