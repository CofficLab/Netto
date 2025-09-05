import MagicCore
import OSLog
import SwiftUI

struct TileMore: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MagicMessageProvider

    @State var hovered = false
    @State var isPresented = false

    var body: some View {
        HStack {
            Image(systemName: "ellipsis")
        }
        .frame(maxHeight: .infinity)
        .onHover(perform: { hovering in
            self.hovered = hovering
        })
        .onTapGesture {
            self.isPresented.toggle()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .popover(isPresented: $isPresented, content: {
            VStack {
                BtnInstall()
                BtnStop()
                BtnStart()
                BtnToggleSysApp()
                BtnSetting()
                BtnGuide()
                BtnAbout()
                BtnQuit()
            }.padding()
        })
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(width: 500)
}
