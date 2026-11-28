import LumiUI
import SwiftUI

// MARK: - 版本对比

/// 版本对比卡片：并排展示免费版与 Pro 版的权益差异。
///
/// 放在「应用内购买」分组顶部：用户在看到价格之前，先看到差异。
struct StoreVersionComparisonView: View {
    @LumiTheme private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.md) {
            HStack(spacing: AppUI.Spacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundStyle(theme.primary)
                    .accessibilityHidden(true)

                Text("Unlock the Full Experience")
                    .font(AppUI.Typography.bodyEmphasized)
                    .foregroundStyle(theme.textPrimary)
            }

            HStack(alignment: .top, spacing: AppUI.Spacing.sm) {
                StoreVersionCard(
                    title: String(localized: "Free"),
                    icon: "person.fill",
                    tint: theme.textTertiary,
                    features: freeFeatures,
                    isHighlighted: false
                )

                StoreVersionCard(
                    title: String(localized: "Pro"),
                    icon: "crown.fill",
                    tint: theme.primary,
                    features: proFeatures,
                    isHighlighted: true
                )
            }
        }
        .padding(AppUI.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface(
            style: .custom(theme.elevatedSurface.opacity(0.5)),
            cornerRadius: DesignTokens.Radius.md,
            borderColor: theme.primary.opacity(0.16),
            lineWidth: 1
        )
    }

    // MARK: - Features

    /// 免费版权益：与 `AppAction` 的免费限制一致（最多禁止 5 个应用）。
    private var freeFeatures: [StoreVersionFeature] {
        [
            StoreVersionFeature(icon: "tray.full", title: String(localized: "Block up to 5 apps")),
            StoreVersionFeature(icon: "lock.shield", title: String(localized: "Per-app network control")),
        ]
    }

    /// Pro 版权益。
    private var proFeatures: [StoreVersionFeature] {
        [
            StoreVersionFeature(icon: "infinity", title: String(localized: "Block unlimited apps")),
            StoreVersionFeature(icon: "heart.fill", title: String(localized: "Support ongoing development")),
        ]
    }
}

// MARK: - 权益条目

struct StoreVersionFeature: Identifiable {
    /// 用「图标 + 标题」派生标识：内容不变则标识不变，`ForEach` 才能复用行。
    var id: String { "\(icon)|\(title)" }

    let icon: String
    let title: String
}

// MARK: - 版本卡片

/// 版本对比卡片：单侧（免费版 / Pro 版）的权益列表。
private struct StoreVersionCard: View {
    @LumiTheme private var theme

    let title: String
    let icon: String
    let tint: Color
    let features: [StoreVersionFeature]
    let isHighlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.sm) {
            HStack(spacing: AppUI.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isHighlighted ? tint : theme.textTertiary)
                    .accessibilityHidden(true)

                Text(title)
                    .font(AppUI.Typography.bodyEmphasized)
                    .foregroundStyle(isHighlighted ? theme.textPrimary : theme.textSecondary)
            }

            Divider()
                .background(theme.divider)

            VStack(alignment: .leading, spacing: AppUI.Spacing.xs) {
                ForEach(features) { feature in
                    HStack(alignment: .top, spacing: AppUI.Spacing.xs) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(isHighlighted ? tint : theme.textTertiary)
                            .frame(width: 14)
                            .accessibilityHidden(true)

                        Text(feature.title)
                            .font(AppUI.Typography.caption1)
                            .foregroundStyle(isHighlighted ? theme.textPrimary : theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(AppUI.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                .fill(isHighlighted ? tint.opacity(0.10) : theme.textSecondary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                .stroke(
                    isHighlighted ? tint.opacity(0.28) : theme.divider.opacity(0.6),
                    lineWidth: 1
                )
        )
    }
}
