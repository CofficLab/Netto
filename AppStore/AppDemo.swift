import SwiftUI

/// 应用演示视图
struct AppDemo: View {
    /// 最大显示的应用数量，默认为全部
    let maxCount: Int?
    
    /// 尺寸水平，数字越大，内部的文字、图片等越大，默认为1.0
    let scaleLevel: Double

    /// 在指定序号的应用右侧显示“禁止联网”按钮（基于 0 的索引）。nil 表示不显示。
    let showBlockButtonAt: Int?

    /// 初始化演示视图
    /// - Parameters:
    ///   - maxCount: 最大显示数量，nil表示显示全部
    ///   - scaleLevel: 尺寸水平，数字越大，内部的文字、图片等越大，默认为1.0
    init(maxCount: Int? = nil, scaleLevel: Double = 1.0, showBlockButtonAt: Int? = nil) {
        self.maxCount = maxCount
        self.scaleLevel = scaleLevel
        self.showBlockButtonAt = showBlockButtonAt
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(displayedApps.enumerated()), id: \.element.id) { index, app in
                SimpleAppLine(
                    app: app,
                    scaleLevel: scaleLevel,
                    showBlockButton: index == showBlockButtonAt
                )
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
    let scaleLevel: Double
    let showBlockButton: Bool

    var body: some View {
        HStack(spacing: 12 * scaleLevel) {
            // 应用图标
            app.getIcon()
                .frame(width: 40 * scaleLevel, height: 40 * scaleLevel)

            // 应用信息
            VStack(alignment: .leading, spacing: 4 * scaleLevel) {
                Text(app.name)
                    .font(.system(size: 16 * scaleLevel, weight: .regular))
                    .lineLimit(1)

                Text(app.id)
                    .font(.system(size: 14 * scaleLevel, weight: .regular))
                    .foregroundColor(app.isSystemApp ? .orange.opacity(1) : .primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            if showBlockButton {
                HStack(spacing: 6 * scaleLevel) {
                    Text("禁止联网")
                        .foregroundColor(.white)
                }
                .font(.system(size: 14 * scaleLevel, weight: .semibold))
                .padding(.vertical, 6 * scaleLevel)
                .padding(.horizontal, 10 * scaleLevel)
                .background(
                    RoundedRectangle(cornerRadius: 8 * scaleLevel, style: .continuous)
                        .fill(Color.red)
                )
            }
        }
        .padding(.vertical, 8 * scaleLevel)
        .padding(.horizontal, 12 * scaleLevel)
    }
}

// MARK: - Preview

#Preview("App - Normal Scale") {
    AppDemo(maxCount: 5, scaleLevel: 1.0, showBlockButtonAt: 1)
        .frame(width: 600, height: 400)
}

#Preview("App - Large Scale") {
    AppDemo(maxCount: 5, scaleLevel: 1.5)
        .frame(width: 600, height: 500)
}

#Preview("App - Small Scale") {
    AppDemo(maxCount: 5, scaleLevel: 0.7)
        .frame(width: 600, height: 350)
}

#Preview("App - Extra Large Scale") {
    AppDemo(maxCount: 3, scaleLevel: 2.0)
        .frame(width: 600, height: 400)
}

#Preview("App Store Hero") {
    AppStoreHero()
        .inMagicContainer(.macBook13, scale: 0.5)
}
