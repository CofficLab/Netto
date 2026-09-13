import SwiftUI

struct UnknownView: View {
    var body: some View {
        Popview(
            iconName: "questionmark.circle",
            title: "当前状态未知"
        ) {
            EmptyView()
        }
    }
}

#Preview {
    DashboardPreviewHost {
        UnknownView()
    }
    .frame(height: 500)
}

#Preview {
    DashboardPreviewHost {
        ContentView()
    }
    .frame(height: 800)
}
