import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var app:AppManager
    private var angel = Channel()
    private var firewallEvents: [FirewallEvent] {
        app.events.reversed()
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(firewallEvents, id: \.self) { e in
                    HStack(content: {
                        Text(e.timeFormatted)
                        Text(e.address)
                        Spacer()
                        Text(e.port)
                    })
                }
            }
        }
        .padding()
        .onAppear {
            angel.viewWillAppear()
            Event().onSpeak({
                app.appendEvent($0)
            })
        }
        .toolbar(content: {
            Button("开始") {
                angel.startFilter2()
            }
            
            Button("停止") {
                angel.stopFilter2()
            }
        })
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
