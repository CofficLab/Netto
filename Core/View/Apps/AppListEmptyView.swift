import SwiftUI
import MagicCore

/**
 * 应用列表空视图
 * 
 * 当应用列表为空时显示的空状态视图。
 * 根据显示类型（全部/允许/拒绝）显示相应的提示信息。
 */
struct AppListEmptyView: View {
    /// 显示类型
    let displayType: DisplayType
    
    /// 构建空视图
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "app.badge")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            if let description = description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// 空状态标题
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
    
    /// 空状态描述
    private var description: String? {
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
        .inRootView()
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

