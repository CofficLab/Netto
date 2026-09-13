import SwiftUI

struct ApprovalView: View {
    @State private var isAnimating = false

    var body: some View {
        ExtensionNotReady()
    }
}

#Preview {
    DashboardPreviewHost {
        ApprovalView()
    }
    .frame(height: 500)
}

#Preview {
    DashboardPreviewHost {
        ContentView()
    }
    .frame(height: 800)
}
