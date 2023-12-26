import SwiftUI
import SwiftData

struct RootView<Content>: View where Content: View {
    private var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environmentObject(AppManager())
            .environmentObject(Channel())
            .environmentObject(EventManager())
            .modelContainer(DBConfig.container)
            .frame(minWidth: 500, minHeight: 200)
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
