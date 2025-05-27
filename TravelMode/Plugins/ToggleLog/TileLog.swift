import MagicCore
import OSLog
import SwiftUI

struct TileLog: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var app: AppManager

    @State var hovered = false
    @State var isPresented = false

    private var shouldShowLogButton: Bool {
        switch app.status {
        case .stopped:
            true
        case .indeterminate:
            false
        case .running:
            true
        case .notInstalled:
            false
        case .needApproval:
            false
        case .waitingForApproval:
            false
        case .error:
            false
        case .disabled, .extensionNotReady:
            false
        }
    }

    var body: some View {
        HStack {
            BtnToggleLog(asToolbarItem: true)
                .labelStyle(.iconOnly)
                .disabled(!shouldShowLogButton)
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
