import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var app: AppManager
    @EnvironmentObject private var event: EventManager
    @EnvironmentObject private var channel: ChannelProvider

    var body: some View {
        ZStack {
            BackgroundView.type1.opacity(0.2)

            VStack {
                VSplitView {
                    AppList()
                    Divider()
                    if app.logVisible {
                        EventList().shadow(radius: 10)
                    }
                }.background(.clear)
                
                StatusBar()
            }
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
    })
    .frame(width: 700)
    .frame(height: 800)
}
