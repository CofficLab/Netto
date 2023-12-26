import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var app: AppManager
    @EnvironmentObject private var channel: Channel
    
    var body: some View {
        VStack {
            VSplitView {
                AppList()
                if app.logVisible {
                    EventList().shadow(radius: 10)
                }
            }
        }
        .background(BackgroundView.forest)
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
