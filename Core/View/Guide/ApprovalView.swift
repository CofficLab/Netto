import SwiftUI

struct ApprovalView: View {
    @State private var isAnimating = false

    var body: some View {
        ExtensionNotReady()
    }
}

#Preview {
    RootView(environment: .preview()) {
        ApprovalView()
    }
    .frame(height: 500)
}

#Preview {
    RootView(environment: .preview()) {
        ContentView()
    }
    .frame(height: 800)
}
