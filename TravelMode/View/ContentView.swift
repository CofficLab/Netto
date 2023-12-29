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
            }
        }
        .onAppear {
            channel.viewWillAppear()
            event.onFilterStatusChanged({
                app.setFilterStatus($0)
            })
            
            event.onNeedApproval {
                app.setFilterStatus(.needApproval)
            }
            
            event.onWaitingForApproval {
                app.setFilterStatus(.waitingForApproval)
            }
            
            event.onPermissionDenied {
                app.setFilterStatus(.rejected)
            }
        }
        .onDisappear {
            channel.viewWillDisappear()
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
