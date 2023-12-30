import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var app: AppManager
    @EnvironmentObject private var event: EventManager
    @EnvironmentObject private var channel: Channel

    var body: some View {
        ZStack {
            BackgroundView.type1.opacity(0.2)

            VSplitView {
                AppList()
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
                Picker("类型", selection: $app.displayType) {
                    Text("全部").tag(DisplayType.All)
                    Text("允许的").tag(DisplayType.Allowed)
                    Text("禁止的").tag(DisplayType.Rejected)
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
    }).frame(width: 700)
}
