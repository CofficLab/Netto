import LumiUI
import ProviderViewEnvironment
import SwiftUI

/// 菜单栏弹窗里的紧凑应用行：点击进入事件详情，右侧常驻允许/禁止开关。
struct MenuBarAppRow: View {
    @EnvironmentObject private var ui: UIProvider
    @LumiTheme private var theme

    let app: SmartApp
    let isDenied: Bool
    let onRuleChange: () -> Void

    @State private var shouldAllow: Bool
    @State private var hovering = false

    init(app: SmartApp, isDenied: Bool, onRuleChange: @escaping () -> Void) {
        self.app = app
        self.isDenied = isDenied
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
            .accessibilityLabel("\(app.name)，\(isDenied ? "已阻止" : "允许联网")")

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
}