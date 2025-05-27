import MagicCore
import OSLog
import SwiftUI

struct TileMessage: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MessageProvider

    @State var hovered = false
    @State var isPresented = false
    @State var live = false
    @State private var selection: Set<SmartMessage.ID> = []
    @State private var selectedChannel: String = "all"
    @State private var messages: [SmartMessage] = []

    var firstFlashMessage: SmartMessage? { m.messages.first(where: { $0.shouldFlash }) }

    var body: some View {
        HStack {
            if let m = firstFlashMessage, live {
                Text(m.description).onAppear {
                    main.asyncAfter(deadline: .now() + 3, execute: {
                        self.live = false
                    })
                }
            } else {
                Image(systemName: "message")
            }
        }
        .frame(maxHeight: .infinity)
        .onChange(of: firstFlashMessage, {
            if firstFlashMessage != nil {
                self.live = true
            }
        })
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
        .popover(isPresented: $isPresented, content: {
            MessageTable()
                .frame(height: 500)
                .frame(width: 1000)
        })
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }.frame(width: 700)
}
