import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var app: AppManager
    private var channel = Channel()
    
    var body: some View {
        EventList()
            .onAppear {
                Event().onFilterStatusChanged({
                    app.setFilterStatus($0)
                })
            }
        .toolbar(content: {
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