import LumiUI
import SwiftUI

/// 未知状态引导。
struct UnknownView: View {
    var body: some View {
        DashboardGuidePanel(
            iconName: "questionmark.circle",
            title: "Status Unknown"
        ) {
            Text("Unable to read the firewall status right now. Try again later.")
                .font(.appBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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
