import SwiftUI

struct Toolbar: View {
    @EnvironmentObject private var app: AppManager
    @EnvironmentObject private var channel: Channel

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
                }.opacity(app.status == .stopped || app.status == .indeterminate ? 1 : 0)
                Button("停止") {
                    channel.stopFilter()
                }.opacity(app.status == .running ? 1 : 0)
            }

            ZStack {
                Image("dot_green")
                    .opacity(app.status == .running ? 1 : 0)
                    .scaleEffect(0.7)
                Image("dot_red")
                    .opacity(app.status == .stopped ? 1 : 0)
                    .scaleEffect(0.7)
                Image("dot_yellow")
                    .opacity(app.status == .indeterminate ? 1 : 0)
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
