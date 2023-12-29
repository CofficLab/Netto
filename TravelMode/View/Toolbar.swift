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
        case .notInstalled:
            "dot_yellow"
        case .needApproval:
            "dot_yellow"
        case .waitingForApproval:
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
                switch app.status {
                case .stopped:
                    Button("开始") {
                        channel.startFilter()
                    }
                case .indeterminate:
                    Button("状态未知") {}
                case .running:
                    Button("停止") {
                        channel.stopFilter()
                    }
                case .notInstalled:
                    Button("安装") {
                        channel.installFilter()
                    }
                case .needApproval:
                    Button("需要授权") { }
                case .waitingForApproval:
                    Button("等待授权") { }
                }
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
