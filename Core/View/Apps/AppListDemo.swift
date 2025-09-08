import SwiftUI

/// 应用列表演示视图
struct AppListDemo: View {
    /// 最大显示的应用数量，默认为全部
    let maxCount: Int?

    /// 初始化演示视图
    /// - Parameter maxCount: 最大显示数量，nil表示显示全部
    init(maxCount: Int? = nil) {
        self.maxCount = maxCount
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(displayedApps.enumerated()), id: \.element.id) { index, app in
                SimpleAppLine(app: app)
                if index < displayedApps.count - 1 {
                    Divider()
                }
            }
        }
    }

    /// 根据最大数量限制显示的应用列表
    private var displayedApps: [SmartApp] {
        if let maxCount = maxCount {
            return Array(SmartApp.samples.prefix(maxCount))
        } else {
            return SmartApp.samples
        }
    }
}

// MARK: - SimpleAppLine

/// 简单的应用信息展示组件
struct SimpleAppLine: View {
    let app: SmartApp

    var body: some View {
        HStack(spacing: 12) {
            // 应用图标
            app.getIcon()
                .frame(width: 40, height: 40)

            // 应用信息
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.body)
                    .lineLimit(1)

                Text(app.id)
                    .font(.callout)
                    .foregroundColor(app.isSystemApp ? .orange.opacity(0.7) : .primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

// MARK: - Preview

#Preview("App - Large (All)") {
    AppListDemo()
        .frame(width: 600, height: 1000)
}

#Preview("App - Small (All)") {
    AppListDemo()
        .frame(width: 600, height: 600)
}

#Preview("App - Limited (5)") {
    AppListDemo(maxCount: 5)
        .frame(width: 600, height: 400)
}

#Preview("App - Limited (3)") {
    AppListDemo(maxCount: 3)
        .frame(width: 600, height: 300)
}

#Preview("App Store Hero") {
    AppStoreHero()
        .inMagicContainer(.macBook13, scale: 0.5)
}
