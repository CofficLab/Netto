import SwiftUI

struct ApprovalView: View {
    @State private var isAnimating = false

    var body: some View {
        ExtensionNotReady()
    }
}

#Preview {
    RootView {
        ApprovalView()
    }
    .frame(height: 500)
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
