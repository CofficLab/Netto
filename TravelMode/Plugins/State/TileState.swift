import MagicCore
import OSLog
import SwiftUI

struct TileState: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var app: AppManager

    @State var hovered = false
    @State var isPresented = false

    var body: some View {
        HStack {
            ZStack {
                switch app.status {
                case .stopped:
                    Text("Stopped")
                case .indeterminate:
                    Text("Indeterminate")
                case .running:
                    Text("Running") 
                case.notInstalled:
                    Text("Not Installed")
                case.needApproval:
                    Text("Need Approval")
                case.waitingForApproval:
                    Text("Waiting For Approval")
                case.error:
                    Text("Error")
                case.disabled:
                    Text("Disabled")
                case.extensionNotReady:
                    Text("Disabled")
                }
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
