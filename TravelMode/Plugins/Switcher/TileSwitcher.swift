import MagicCore
import OSLog
import SwiftUI

struct TileSwitcher: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var app: AppManager

    @State var hovered = false
    @State var isPresented = false

    var body: some View {
        HStack {
            if app.status.isStopped() {
                BtnStart(asToolbarItem: true).labelStyle(.iconOnly)
            }
            
            if app.status.isRunning() {
                BtnStop(asToolbarItem: true).labelStyle(.iconOnly)
            }
        }
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
