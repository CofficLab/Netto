import LumiUI
import SwiftUI

/// 引导浮层外壳：图标 + 标题 + 内容，统一使用 LumiUI 主题表面。
///
/// 替代旧的 `Popview`（黑底渐变 + 蓝色阴影 + 手写圆角）。浮层由 `GuideView`
/// 负责居中与遮罩，本视图只渲染面板本身。
struct DashboardGuidePanel<Content: View>: View {
    @LumiTheme private var theme

    private let iconName: String
    private let title: LocalizedStringKey
    private let iconColor: Color
    private let content: Content

    init(
        iconName: String,
        title: LocalizedStringKey,
        iconColor: Color = .accentColor,
        @ViewBuilder content: () -> Content
    ) {
        self.iconName = iconName
        self.title = title
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        VStack(spacing: AppUI.Spacing.md) {
            Image(systemName: iconName)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 64, height: 64)
                .background(iconColor.opacity(0.14), in: Circle())
                .overlay(Circle().stroke(iconColor.opacity(0.25), lineWidth: 1))

            Text(title)
                .font(.appTitle)
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)

            content
        }
        .padding(AppUI.Spacing.lg)
        .frame(maxWidth: 420)
        .appSurface(
            style: .custom(theme.elevatedSurface),
            cornerRadius: DesignTokens.Radius.md,
            borderColor: theme.appSubtleBorder,
            lineWidth: 1
        )
    }
}

/// 引导浮层里的有序步骤列表（「1. … 2. …」形态）。
struct DashboardGuideSteps: View {
    @LumiTheme private var theme

    private let title: LocalizedStringKey
    private let steps: [LocalizedStringKey]

    init(_ title: LocalizedStringKey = "Setup Steps", steps: [LocalizedStringKey]) {
        self.title = title
        self.steps = steps
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.sm) {
            AppSectionLabel(title)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: AppUI.Spacing.sm) {
                    Text("\(index + 1)")
                        .font(.appMicroEmphasized)
                        .foregroundStyle(theme.primary)
                        .frame(width: 18, height: 18)
                        .background(theme.primary.opacity(0.12), in: Circle())

                    Text(step)
                        .font(.appBody)
                        .foregroundStyle(theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(AppUI.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(
            style: .custom(theme.elevatedSurface.opacity(0.6)),
            cornerRadius: DesignTokens.Radius.sm,
            borderColor: theme.appSubtleBorder,
            lineWidth: 1
        )
    }
}

#Preview {
    DashboardPreviewHost {
        ExtensionNotReady()
    }
    .frame(height: 500)
}

#Preview("APP") {
    DashboardPreviewHost {
        ContentView()
    }
    .frame(height: 800)
}
