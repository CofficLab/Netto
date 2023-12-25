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
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
