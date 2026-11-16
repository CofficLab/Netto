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
            return "暂无应用"
        case .Allowed:
            return "暂无网络活动"
        case .Rejected:
            return "暂无被拒绝的应用"
        }
    }

    private var description: String {
        switch displayType {
        case .All:
            return "当前没有应用产生网络活动"
        case .Allowed:
            return "当前没有网络活动"
        case .Rejected:
            return "当前没有拒绝访问网络的应用"
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
