import LumiUI
import SwiftUI

/// 应用列表空视图（按当前筛选维度给出不同文案）。
struct AppListEmptyView: View {
    let displayType: DisplayType

    var body: some View {
        AppEmptyState(icon: "app.badge", title: title, description: description)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var title: String {
        switch displayType {
        case .All:
            return String(localized: "No apps")
        case .Allowed:
            return String(localized: "No network activity")
        case .Rejected:
            return String(localized: "No denied apps")
        }
    }

    private var description: String {
        switch displayType {
        case .All:
            return String(localized: "No apps currently have network activity")
        case .Allowed:
            return String(localized: "No network activity right now")
        case .Rejected:
            return String(localized: "No apps are currently denied network access")
        }
    }
}

// MARK: - Preview
#Preview("App") {
    ContentView()
        .dashboardPreviewRoot()
        .frame(width: 600, height: 600)
}

#Preview("AppListEmptyView - All") {
    AppListEmptyView(displayType: .All)
        .frame(width: 600, height: 400)
}

#Preview("AppListEmptyView - Allowed") {
    AppListEmptyView(displayType: .Allowed)
        .frame(width: 600, height: 400)
}

#Preview("AppListEmptyView - Rejected") {
    AppListEmptyView(displayType: .Rejected)
        .frame(width: 600, height: 400)
}
