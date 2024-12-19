import MagicKit
import OSLog
import SwiftUI

struct MessageTable: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MessageProvider

    @State var hovered = false
    @State var isPresented = false
    @State var live = false
    @State private var selection: Set<SmartMessage.ID> = []
    @State private var selectedChannel: String = "all"
    
    var messages: [SmartMessage] {
        m.messages.filter { selectedChannel == "all" || $0.channel == selectedChannel }
    }

    var body: some View {
        GroupBox {
            HStack {
                Picker("", selection: $selectedChannel) {
                    Text("全部").tag("all")
                    ForEach(m.getAllChannels(), id: \.self) { channel in
                        Text(channel)
                    }
                }

                Spacer()
                Button(action: {
                    m.clearMessages()
                }) {
                    Text("清空")
                }
            }
            Table(messages, selection: $selection, columns: {
                TableColumn("类型") { message in
                    Text(message.channel)
                }
                .width(80)

                TableColumn("消息") { message in
                    Text(message.description)
                        .foregroundColor(message.isError ? .red : .primary)
                }

                TableColumn("时间") { message in
                    Text(message.createdAt.string)
                }
                .width(180)
            })
        }
        .padding(10)
        .background(BackgroundView.type1.opacity(0.1))
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }.frame(width: 700)
}
