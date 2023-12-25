import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var app: AppManager
    @EnvironmentObject private var channel: Channel
    
    var body: some View {
        VStack {
            VSplitView {
                AppList()
                if app.logVisible {
                    EventList()
                }
            }
        }
        .onAppear {
            channel.viewWillAppear()
            EventManager().onFilterStatusChanged({
                app.setFilterStatus($0)
            })
        }
        .toolbar(content: {
            if app.logVisible {
                Button("隐藏日志") {
                    app.logVisible = false
                }
            } else {
                Button("显示日志") {
                    app.logVisible = true
                }
            }
            switch app.status {
            case .stopped:
                Button("开始") {
                    channel.startFilter()
                }
            case .indeterminate:
                Button("开始") {
                    channel.startFilter()
                }
            case .running:
                Button("停止") {
                    channel.stopFilter()
                }
            }
        })
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
