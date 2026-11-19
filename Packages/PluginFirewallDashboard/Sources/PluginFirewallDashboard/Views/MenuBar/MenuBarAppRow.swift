import LumiUI
import ProviderFirewall
import ProviderViewEnvironment
import SwiftUI

/// 菜单栏弹窗里的应用行：整行占满宽度，悬停由上层容器展开详情面板，
/// 点击进入该应用的连接记录。
struct MenuBarAppRow: View {
    @EnvironmentObject private var ui: UIProvider
    @LumiTheme private var theme

    let app: SmartApp
    let isDenied: Bool
    let speed: AppNetworkSpeed?

    var body: some View {
        Button {
            HoverCoordinator.shared.closeAll()
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

                Spacer(minLength: 8)

                if let speed, speed.totalBytesPerSecond > 0 {
                    speedBadge(speed)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("netto.app.row.\(app.id)")
        .accessibilityLabel(accessibilityText)
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
