import MagicCore
import MagicAlert
import OSLog
import ProviderFirewall
import SwiftUI

struct TileSwitcher: View, SuperLog, SuperThread {
    @EnvironmentObject var app: UIProvider
    @Environment(\.firewallProvider) private var firewall: FirewallProviding?
    
    @State var hovered = false
    @State var isPresented = false

    var body: some View {
        HStack {
            if firewall?.snapshot.state.isRunning() == true {
                BtnStop(asToolbarItem: true).labelStyle(.iconOnly)
            } else {
                BtnStart(asToolbarItem: true)
                    .labelStyle(.iconOnly)
                    .disabled(firewall?.snapshot.canStart != true)
            }
        }
        .frame(maxHeight: .infinity)
        .onHover(perform: { hovering in
            hovered = hovering
        })
        .onTapGesture {
            self.isPresented.toggle()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }
}

#Preview("APP") {
    RootView(environment: .preview()) {
        ContentView()
    }.frame(width: 700)
}
