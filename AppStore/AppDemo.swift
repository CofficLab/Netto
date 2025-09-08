import SwiftUI
import MagicUI

/// 统一的 App 演示视图：支持应用列表、列表带“禁止联网”示意、菜单栏示意
struct AppDemo: View {
    /// 最大显示的应用数量，nil 表示显示全部（仅列表模式有效）
    let maxCount: Int?
    /// 尺寸缩放（对列表模式内元素生效）
    let scaleLevel: Double
    /// 在指定序号的应用右侧显示“禁止联网”标签（基于 0 的索引），nil 表示不显示（仅列表模式有效）
    let showBlockButtonAt: Int?
    /// 是否显示菜单栏静态示意（为 true 时忽略列表相关参数）
    let showMenuBar: Bool

    init(maxCount: Int? = nil, scaleLevel: Double = 1.0, showBlockButtonAt: Int? = nil, showMenuBar: Bool = false) {
        self.maxCount = maxCount
        self.scaleLevel = scaleLevel
        self.showBlockButtonAt = showBlockButtonAt
        self.showMenuBar = showMenuBar
    }

    var body: some View {
        Group {
            if showMenuBar {
                MenuBarStaticMock()
            } else {
                AppListDemoInternal(maxCount: maxCount, scaleLevel: scaleLevel, showBlockButtonAt: showBlockButtonAt)
            }
        }
    }
}

// MARK: - 列表模式（内部）

private struct AppListDemoInternal: View {
    let maxCount: Int?
    let scaleLevel: Double
    let showBlockButtonAt: Int?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(displayedApps.enumerated()), id: \.element.id) { index, app in
                SimpleAppLine(app: app, scaleLevel: scaleLevel, showBlockButton: index == showBlockButtonAt)
                if index < displayedApps.count - 1 { Divider() }
            }
        }
    }

    private var displayedApps: [SmartApp] {
        if let maxCount = maxCount {
            return Array(SmartApp.samples.prefix(maxCount))
        } else {
            return SmartApp.samples
        }
    }
}

private struct SimpleAppLine: View {
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

// MARK: - 菜单栏模式（内部）

private struct MenuBarStaticMock: View {
    var body: some View {
        VStack(spacing: 0) {
            // 顶部菜单栏条
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(height: 96)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                    )

                HStack(spacing: 24) {
                    // 左侧 Apple 菜单等（占位）
                    HStack(spacing: 20) {
                        Image(systemName: "applelogo")
                        Text("File")
                        Text("Edit")
                        Text("View")
                        Text("Window")
                        Text("Help")
                    }
                    .foregroundColor(.secondary)
                    .font(.system(size: 24, weight: .regular))

                    Spacer()

                    // 右侧状态项（包括我们的 App 图标）
                    HStack(spacing: 16) {
                        // 我们的 App 图标（高亮）
                        HStack(spacing: 6) {
                            Image(systemName: "network")
                                .foregroundColor(.black)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                        )
                        
                        Image(systemName: "wifi")
                        Image(systemName: "bolt.fill")
                        Image(systemName: "moon")
                    }
                    .font(.system(size: 24, weight: .medium))
                }
                .padding(.horizontal, 16)
            }

            // 下方弹出面板（静态）
            VStack(alignment: .leading, spacing: 28) {
                // 列表中展示数个应用的快速状态（静态）
                VStack(spacing: 20) {
                    ForEach(0..<3) { i in
                        HStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.secondary.opacity(0.2))
                                .frame(width: 36, height: 36)
                                .overlay(Image(systemName: "app.fill").font(.system(size: 22)).foregroundStyle(.secondary))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("示例应用 \(i+1)").font(.system(size: 20))
                                Text("com.example.app\(i+1)").font(.system(size: 16)).foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(i == 0 ? "已禁止" : "允许")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(i == 0 ? .white : .secondary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(i == 0 ? Color.red : Color.secondary.opacity(0.15))
                                )
                        }
                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
            )
            .padding(.top, 18)

            Spacer()
        }
        .padding(32)
    }
}

// MARK: - Preview

#Preview("AppDemo - List") {
    AppDemo(maxCount: 5, scaleLevel: 1.2)
        .frame(width: 900, height: 600)
}

#Preview("AppDemo - List with Block") {
    AppDemo(maxCount: 5, scaleLevel: 1.2, showBlockButtonAt: 2)
        .frame(width: 900, height: 600)
}

#Preview("AppDemo - MenuBar") {
    AppDemo(showMenuBar: true)
        .frame(width: 1000, height: 800)
}

