import SwiftUI

struct Toolbar: View {
    @EnvironmentObject private var app: AppManager
    @EnvironmentObject private var channel: Channel
    
    var body: some View {
        HStack{
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
        }
    }
}

#Preview {
    Toolbar()
}
