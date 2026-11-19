import LumiUI
import ProviderFirewall
import SwiftUI

/// 应用行悬停后展示的详情面板：应用信息、实时网速与联网规则。
///
/// 规则按钮放在这里而不是列表行内，让列表保持干净的整行布局；
/// 点击行本身仍会进入该应用的连接记录。
struct MenuBarAppHoverDetailView: View {
    @LumiTheme private var theme

    let app: SmartApp
    let isDenied: Bool
    let speed: AppNetworkSpeed?
    let hoverID: String
    let onRuleChange: () -> Void

    @State private var shouldAllow: Bool

    init(
        app: SmartApp,
        isDenied: Bool,
        speed: AppNetworkSpeed?,
        hoverID: String,
        onRuleChange: @escaping () -> Void
    ) {
        self.app = app
        self.isDenied = isDenied
        self.speed = speed
        self.hoverID = hoverID
        self.onRuleChange = onRuleChange
        _shouldAllow = State(initialValue: !isDenied)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            speedSection
            ruleSection
            Text("点击应用行查看连接记录")
                .font(.appMicro)
                .foregroundStyle(theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("netto.app.hover.\(app.id)")
        .onChange(of: isDenied) { _, newValue in
            shouldAllow = !newValue
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            app.getIcon()
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
    private var speedSection: some View {
        if let speed, speed.totalBytesPerSecond > 0 {
            HStack(spacing: 24) {
                metric(
                    label: "下载",
                    value: NetworkSpeedFormatter.format(speed.downloadBytesPerSecond),
                    tint: theme.success
                )
                metric(
                    label: "上传",
                    value: NetworkSpeedFormatter.format(speed.uploadBytesPerSecond),
                    tint: theme.primary
                )
                Spacer(minLength: 0)
            }
        } else {
            Text("当前无网络活动")
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

    private var ruleSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("联网权限")
                    .font(.appCaptionEmphasized)

                Text(isDenied ? "当前已禁止该应用联网" : "当前允许该应用联网")
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
            .accessibilityIdentifier("netto.app.hover.rule.\(app.id)")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                .fill(theme.elevatedSurface)
        )
    }
}
