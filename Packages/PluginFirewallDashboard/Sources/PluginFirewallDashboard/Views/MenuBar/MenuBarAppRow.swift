import LumiUI
import ProviderFirewall
import ProviderViewEnvironment
import SwiftUI

/// 菜单栏弹窗里的紧凑应用行：点击进入事件详情，右侧常驻允许/禁止开关。
struct MenuBarAppRow: View {
    @EnvironmentObject private var ui: UIProvider
    @LumiTheme private var theme

    let app: SmartApp
    let isDenied: Bool
    let speed: AppNetworkSpeed?
    let onRuleChange: () -> Void

    @State private var shouldAllow: Bool
    @State private var hovering = false

    init(
        app: SmartApp,
        isDenied: Bool,
        speed: AppNetworkSpeed? = nil,
        onRuleChange: @escaping () -> Void
    ) {
        self.app = app
        self.isDenied = isDenied
        self.speed = speed
        self.onRuleChange = onRuleChange
        _shouldAllow = State(initialValue: !isDenied)
    }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                ui.selectApp(app.id)
            } label: {
                HStack(spacing: 10) {
                    app.getIcon()
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text(app.name)
                                .font(.appBodyEmphasized)
                                .lineLimit(1)

                            if isDenied {
                                Text("已阻止")
                                    .font(.appMicroEmphasized)
                                    .foregroundStyle(theme.error)
                            }
                        }

                        Text(app.id)
                            .font(.appCaption)
                            .foregroundStyle(app.isSystemApp ? theme.warning : theme.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("netto.app.row.\(app.id)")
            .accessibilityLabel(accessibilityText)

            if let speed, speed.totalBytesPerSecond > 0 {
                speedBadge(speed)
            }

            if app.isNotSample {
                AppAction(shouldAllow: $shouldAllow, appId: app.id, onRuleChange: onRuleChange)
                    .accessibilityIdentifier("netto.app.action.\(app.id)")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                .fill(hovering ? theme.elevatedSurface : .clear)
        )
        .onHover { hovering = $0 }
        .onChange(of: isDenied) {
            shouldAllow = !isDenied
        }
    }

    private func speedBadge(_ speed: AppNetworkSpeed) -> some View {
        HStack(spacing: 4) {
            if speed.downloadBytesPerSecond > 0 {
                Text("↓\(NetworkSpeedFormatter.compactFormat(speed.downloadBytesPerSecond))")
                    .foregroundStyle(theme.success)
            }
            if speed.uploadBytesPerSecond > 0 {
                Text("↑\(NetworkSpeedFormatter.compactFormat(speed.uploadBytesPerSecond))")
                    .foregroundStyle(theme.primary)
            }
        }
        .font(.appMicro)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityHidden(true)
    }

    private var accessibilityText: String {
        var parts = [app.name, isDenied ? "已阻止" : "允许联网"]
        if let speed, speed.totalBytesPerSecond > 0 {
            if speed.downloadBytesPerSecond > 0 {
                parts.append("下载 \(NetworkSpeedFormatter.format(speed.downloadBytesPerSecond))")
            }
            if speed.uploadBytesPerSecond > 0 {
                parts.append("上传 \(NetworkSpeedFormatter.format(speed.uploadBytesPerSecond))")
            }
        }
        return parts.joined(separator: "，")
    }
}
