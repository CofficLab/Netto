import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var app: AppManager
    @EnvironmentObject private var channel: Channel
    
    var body: some View {
        ZStack {
            BackgroundView.type1.opacity(0.2)
            
            VSplitView {
                AppList()
                if app.logVisible {
                    EventList().shadow(radius: 10)
                }
            }
        }
        .onAppear {
            channel.viewWillAppear()
            EventManager().onFilterStatusChanged({
                app.setFilterStatus($0)
            })
        }
        .toolbar{
            Toolbar()
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
