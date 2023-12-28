import SwiftUI

struct Toolbar: View {
    @EnvironmentObject private var app: AppManager
    @EnvironmentObject private var channel: Channel
    
    var iconName: String {
        switch app.status {
        case .stopped:
            "dot_red"
        case .indeterminate:
            "dot_yellow"
        case .running:
            "dot_green"
        case .rejected:
            "dot_red"
        case .notInstalled:
            "dot_yellow"
        case .needApproval:
            "dot_yellow"
        }
    }

    var body: some View {
        HStack {
//            Button("数据库") {
//                app.databaseVisible.toggle()
//            }
//            .popover(isPresented: $app.databaseVisible, arrowEdge: .bottom) {
//                DatabaseView()
//                    .frame(width: 500, height: 500)
//                    .background(BackgroundView.type1)
//                    .cornerRadius(10)
//            }

            if app.logVisible {
                Button("隐藏日志") {
                    app.logVisible = false
                }
            } else {
                Button("显示日志") {
                    app.logVisible = true
                }
            }

            ZStack {
                Button("开始") {
                    channel.startFilter()
                }.opacity(app.status == .running ? 0 : 1)
                Button("停止") {
                    channel.stopFilter()
                }.opacity(app.status == .running ? 1 : 0)
            }

            ZStack {
                Image(iconName)
                    .scaleEffect(0.7)
            }
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
