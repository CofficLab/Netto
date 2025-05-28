import MagicCore
import OSLog
import SwiftUI

struct TileState: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var app: AppManager

    @State var hovered = false
    @State var isPresented = false

    var body: some View {
        Group {
            switch app.status {
            case .stopped:
                Text("已停止")
            case .indeterminate:
                Text("Indeterminate")
            case .running:
                Text("运行中")
            case .notInstalled:
                Text("Not Installed")
            case .needApproval:
                Text("Need Approval")
            case .waitingForApproval:
                Text("Waiting For Approval")
            case .error:
                Text("Error")
            case .disabled:
                Text("已停用")
            case .extensionNotReady:
                Text("等待配置扩展")
            }
        }
        .font(.footnote)
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
