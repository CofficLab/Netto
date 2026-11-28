import LumiUI
import ProviderFirewall
import ProviderViewEnvironment
import SwiftUI

/// 菜单栏弹窗里的应用行：整行占满宽度，悬停由上层容器展开详情面板，
/// 点击进入该应用的连接记录。
///
/// 行内直接绑定 `MenuBarAppRowModel`：网速逐秒变化只失效本行，
/// 不会让整个列表随 1Hz 刷新重建。
struct MenuBarAppRow: View {
    @EnvironmentObject private var ui: UIProvider
    @LumiTheme private var theme

    let row: MenuBarAppRowModel

    var body: some View {
        let app = row.app
        Button {
            HoverCoordinator.shared.closeAll()
            ui.selectApp(app.id)
        } label: {
            HStack(spacing: 10) {
                AppIcon(app: app)
                    .frame(width: 28, height: 28)

                HStack(spacing: 6) {
                    Text(app.name)
                        .font(.appBodyEmphasized)
                        .lineLimit(1)

                    if row.isDenied {
                        Text("Blocked")
                            .font(.appMicroEmphasized)
                            .foregroundStyle(theme.error)
                    }
                }

                Spacer(minLength: 8)

                if let speed = row.speed, speed.totalBytesPerSecond > 0 {
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
        .accessibilityIdentifier("netpause.app.row.\(app.id)")
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
        var parts = [row.app.name, row.isDenied ? String(localized: "Blocked") : String(localized: "Allowed")]
        if let speed = row.speed, speed.totalBytesPerSecond > 0 {
            if speed.downloadBytesPerSecond > 0 {
                parts.append(String(localized: "Download \(NetworkSpeedFormatter.format(speed.downloadBytesPerSecond))"))
            }
            if speed.uploadBytesPerSecond > 0 {
                parts.append(String(localized: "Upload \(NetworkSpeedFormatter.format(speed.uploadBytesPerSecond))"))
            }
        }
        return parts.joined(separator: ", ")
    }
}