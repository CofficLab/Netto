import SwiftUI

struct BtnToggleLog: View {
    @EnvironmentObject var app: AppManager
    
    var body: some View {
        Button {
            app.logVisible.toggle()
        } label: {
            Label(
                app.logVisible ? "Hide Log" : "Show Log",
                systemImage: app.logVisible ? "list.bullet.rectangle" : "list.bullet.rectangle"
            )
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
