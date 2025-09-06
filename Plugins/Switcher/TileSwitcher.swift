import MagicCore
import OSLog
import SwiftUI

struct TileSwitcher: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var app: UIProvider
    @EnvironmentObject var s: ServiceProvider
    
    @State var hovered = false
    @State var isPresented = false

    var body: some View {
        HStack {
            if s.getFirewallServiceStatus().isRunning() {
                BtnStop(asToolbarItem: true).labelStyle(.iconOnly)
            } else {
                BtnStart(asToolbarItem: true)
                    .labelStyle(.iconOnly)
                    .disabled(!s.getFirewallServiceStatus().canStart())
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
    RootView {
        ContentView()
    }.frame(width: 700)
}
