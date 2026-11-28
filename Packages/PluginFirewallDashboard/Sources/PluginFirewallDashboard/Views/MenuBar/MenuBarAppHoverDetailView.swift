import LumiUI
import ProviderFirewall
import SwiftUI

/// 应用行悬停后展示的详情面板：应用信息、实时网速与联网规则。
///
/// 规则按钮放在这里而不是列表行内，让列表保持干净的整行布局。
/// 面板内容绑定行模型，网速与规则变化在面板打开期间也能实时反映。
struct MenuBarAppHoverDetailView: View {
    @LumiTheme private var theme

    let row: MenuBarAppRowModel
    let hoverID: String
    let onRuleChange: () -> Void

    @State private var shouldAllow: Bool

    init(
        row: MenuBarAppRowModel,
        hoverID: String,
        onRuleChange: @escaping () -> Void
    ) {
        self.row = row
        self.hoverID = hoverID
        self.onRuleChange = onRuleChange
        _shouldAllow = State(initialValue: !row.isDenied)
    }

    private var app: SmartApp { row.app }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            speedSection(row.speed)
            ruleSection(isDenied: row.isDenied)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("netpause.app.hover.\(app.id)")
        .onChange(of: row.isDenied) { _, newValue in
            shouldAllow = !newValue
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            AppIcon(app: app)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.appBodyEmphasized)
                    .lineLimit(1)

                Text(app.id)
                    .font(.appCaption)
                    .foregroundStyle(app.isSystemApp ? theme.warning : theme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Speed

    @ViewBuilder
    private func speedSection(_ speed: AppNetworkSpeed?) -> some View {
        if let speed, speed.totalBytesPerSecond > 0 {
            HStack(spacing: 24) {
                metric(
                    label: String(localized: "Download"),
                    value: NetworkSpeedFormatter.format(speed.downloadBytesPerSecond),
                    tint: theme.success
                )
                metric(
                    label: String(localized: "Upload"),
                    value: NetworkSpeedFormatter.format(speed.uploadBytesPerSecond),
                    tint: theme.primary
                )
                Spacer(minLength: 0)
            }
        } else {
            Text("No network activity right now")
                .font(.appCaption)
                .foregroundStyle(theme.textSecondary)
        }
    }

    private func metric(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.appCaptionEmphasized)
                .foregroundStyle(tint)
                .monospacedDigit()

            Text(label)
                .font(.appMicro)
                .foregroundStyle(theme.textTertiary)
        }
    }

    // MARK: - Rule

    private func ruleSection(isDenied: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Network Access")
                    .font(.appCaptionEmphasized)

                Text(isDenied ? String(localized: "Network access is currently blocked for this app") : String(localized: "Network access is currently allowed for this app"))
                    .font(.appMicro)
                    .foregroundStyle(isDenied ? theme.error : theme.textSecondary)
            }

            Spacer(minLength: 0)

            AppAction(
                shouldAllow: $shouldAllow,
                appId: app.id,
                showsTitle: true
            ) {
                HoverCoordinator.shared.close(id: hoverID)
                onRuleChange()
            }
            .accessibilityIdentifier("netpause.app.hover.rule.\(app.id)")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                .fill(theme.elevatedSurface)
        )
    }
}