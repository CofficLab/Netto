import SwiftUI

struct ApprovalView: View {
    @State private var isAnimating = false

    var body: some View {
        ExtensionNotReady()
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
