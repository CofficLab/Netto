import SwiftUI

struct BtnToggleLog: View {
    @EnvironmentObject var app: AppManager
    
    var body: some View {
        Button {
            app.logVisible.toggle()
        } label: {
            Label(
                app.logVisible ? "隐藏日志" : "显示日志",
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
