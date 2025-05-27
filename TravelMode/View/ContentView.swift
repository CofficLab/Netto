import SwiftUI
import MagicCore

struct ContentView: View {
    @EnvironmentObject private var app: AppManager
    @EnvironmentObject private var event: EventManager
    @EnvironmentObject private var channel: ChannelProvider

    var body: some View {
        VStack(spacing: 0) {
            VSplitView {
                AppList()

                Divider()

                if app.logVisible {
                    EventList().shadow(radius: 10)
                }
            }.background(.clear)
        }
        .onAppear {
            event.onFilterStatusChanged({
                app.setFilterStatus($0)
            })
            channel.boot()
        }
        .onDisappear {
            channel.viewWillDisappear()
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigation, content: {
                Picker("Type", selection: $app.displayType) {
                    Text("All").tag(DisplayType.All)
                    Text("Allowed").tag(DisplayType.Allowed)
                    Text("Rejected").tag(DisplayType.Rejected)
                }
            })
            ToolbarItem {
                Toolbar()
            }
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 800)
}
