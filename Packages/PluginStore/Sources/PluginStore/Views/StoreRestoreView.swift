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
                    title: String(localized: "Cross-Device Restore"),
                    description: String(localized: "Recover purchases made on other devices")
                )

                StoreRestoreInfoRow(
                    icon: "person.circle",
                    title: String(localized: "Apple ID Verification"),
                    description: String(localized: "Use the Apple ID you purchased with")
                )

                StoreRestoreInfoRow(
                    icon: "checkmark.circle",
                    title: String(localized: "Entitlement Restore"),
                    description: String(localized: "Unlock purchased features as soon as restore succeeds")
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

            Text("Restore Purchases")
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
            .accessibilityLabel("Close")
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
                title: "Restoring Purchases",
                message: "Verifying your purchase history…"
            )
        case .success:
            AppStatusBanner(
                kind: .success,
                title: "Restore Complete",
                message: "Purchases recovered. Relevant features are now unlocked."
            )
        case .nothingFound:
            // 「恢复调用成功」不等于「找回了权益」——免费用户同样会走到这里。
            AppStatusBanner(
                kind: .warning,
                title: "No Purchases to Restore",
                message: "No purchase history was found for this Apple ID. If you purchased on another device, sign in with the same Apple ID and try again."
            )
        case .failed:
            AppStatusBanner(
                kind: .error,
                title: "Restore Failed",
                message: error?.localizedDescription ?? String(localized: "Something went wrong during restore. Try again later.")
            )
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch state {
        case .success, .nothingFound:
            HStack(spacing: AppUI.Spacing.sm) {
                AppButton("Done", systemImage: "checkmark.circle.fill", style: .primary, fillsWidth: true) {
                    dismiss()
                }

                AppButton("Retry", systemImage: "arrow.clockwise", style: .secondary, fillsWidth: true) {
                    onReset()
                    onRestore()
                }
            }
        case .failed, .idle:
            AppButton(
                state == .failed ? String(localized: "Restore Again") : String(localized: "Restore Purchases"),
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
