import LumiUI
import SwiftUI

// MARK: - 恢复购买面板

/// 恢复购买面板：说明前提，并明确呈现恢复结果。
///
/// 恢复是低频但高影响的操作：用户点它通常因为刚换机或重装，期望找回
/// 权益。失败或「没找到」必须有明确反馈，否则用户无法判断到底发生了什么。
struct StoreRestoreView: View {
    @LumiTheme private var theme

    @Environment(\.dismiss) private var dismiss

    let state: StoreRestoreState
    let error: Error?
    let onRestore: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.md) {
            header

            VStack(alignment: .leading, spacing: AppUI.Spacing.sm) {
                StoreRestoreInfoRow(
                    icon: "desktopcomputer.and.arrow.down",
                    title: "跨设备恢复",
                    description: "找回在其他设备上完成的购买"
                )

                StoreRestoreInfoRow(
                    icon: "person.circle",
                    title: "Apple ID 验证",
                    description: "请使用购买时所用的 Apple ID"
                )

                StoreRestoreInfoRow(
                    icon: "checkmark.circle",
                    title: "权益恢复",
                    description: "恢复成功后立即解锁已购功能"
                )
            }
            .padding(AppUI.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                    .fill(theme.textSecondary.opacity(0.06))
            )

            statusBanner
            actions
        }
        .padding(AppUI.Spacing.lg)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(theme.elevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .stroke(theme.appSubtleBorder, lineWidth: 1)
        )
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(spacing: AppUI.Spacing.sm) {
            Image(systemName: "icloud.and.arrow.down.fill")
                .font(.system(size: 22))
                .foregroundStyle(theme.primary)
                .accessibilityHidden(true)

            Text("恢复购买")
                .font(AppUI.Typography.title3)
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(theme.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("关闭")
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch state {
        case .idle:
            EmptyView()
        case .restoring:
            AppStatusBanner(
                kind: .loading,
                title: "正在恢复购买",
                message: "正在验证你的购买记录…"
            )
        case .success:
            AppStatusBanner(
                kind: .success,
                title: "恢复成功",
                message: "已找回购买记录，相关功能已解锁"
            )
        case .nothingFound:
            // 「恢复调用成功」不等于「找回了权益」——免费用户同样会走到这里。
            AppStatusBanner(
                kind: .warning,
                title: "未找到可恢复的购买",
                message: "当前 Apple ID 下没有购买记录。如果你在另一台设备上购买，请使用同一 Apple ID 后重试。"
            )
        case .failed:
            AppStatusBanner(
                kind: .error,
                title: "恢复失败",
                message: error?.localizedDescription ?? "恢复过程中出错，请稍后重试"
            )
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch state {
        case .success, .nothingFound:
            HStack(spacing: AppUI.Spacing.sm) {
                AppButton("完成", systemImage: "checkmark.circle.fill", style: .primary, fillsWidth: true) {
                    dismiss()
                }

                AppButton("重试", systemImage: "arrow.clockwise", style: .secondary, fillsWidth: true) {
                    onReset()
                    onRestore()
                }
            }
        case .failed, .idle:
            AppButton(
                state == .failed ? "重新恢复" : "恢复购买",
                systemImage: "arrow.clockwise",
                style: .primary,
                fillsWidth: true
            ) {
                onRestore()
            }
        case .restoring:
            EmptyView()
        }
    }
}

// MARK: - 说明行

private struct StoreRestoreInfoRow: View {
    @LumiTheme private var theme

    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: AppUI.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(theme.primary)
                .frame(width: 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppUI.Typography.bodyEmphasized)
                    .foregroundStyle(theme.textPrimary)

                Text(description)
                    .font(AppUI.Typography.caption1)
                    .foregroundStyle(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
