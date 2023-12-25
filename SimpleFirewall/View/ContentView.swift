import SwiftUI

struct ContentView: View {
    private var channel = Channel()
    
    var body: some View {
        EventList()
        .toolbar(content: {
            Button("开始") {
                channel.startFilter2()
            }
            
            Button("停止") {
                channel.stopFilter2()
            }
        })
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
