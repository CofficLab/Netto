import SwiftUI

public enum DisplayType: CaseIterable {
    case All
    case Allowed
    case Rejected
}

#Preview {
    DashboardPreviewHost {
        ContentView()
    }
}
