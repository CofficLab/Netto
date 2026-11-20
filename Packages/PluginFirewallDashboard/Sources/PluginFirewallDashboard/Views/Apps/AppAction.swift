import ProviderViewEnvironment
import OSLog
import ProviderShell
import ProviderAppSettings
import ProviderStore
import ProviderStoreKit
import SwiftUI

private struct AppActionContent: View, LogPrefixed {
    @EnvironmentObject private var shell: ShellCenter
    @Environment(\.settingsProvider) private var repo: AppSettingsProviding?
    @Environment(\.storeProvider) private var store: StoreProviding?
    @EnvironmentObject var ui: UIProvider

    @Binding var shouldAllow: Bool

    var appId: String
    var showsTitle: Bool = false
    var onRuleChange: (() -> Void)?

    private var iconName: String {
        if shouldAllow {
            "xmark.circle.fill"
        } else {
            "checkmark.circle.fill"
        }
    }

    private var title: String {
        shouldAllow ? "禁止联网" : "允许联网"
    }

    private var tint: Color {
        shouldAllow ? .red : .green
    }

    var body: some View {
        Button {
            shouldAllow ? deny() : allow()
        } label: {
            if showsTitle {
                HStack(spacing: 6) {
                    Image(systemName: iconName)
                        .font(.system(size: 12, weight: .semibold))

                    Text(title)
                        .font(.appCaptionEmphasized)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(tint)
                )
            } else {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(tint)
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

/// Public dashboard control used by settings and App Host contributions.
public struct AppAction: View {
    @Binding private var shouldAllow: Bool
    private let appId: String
    private let showsTitle: Bool
    private let onRuleChange: (() -> Void)?

    public init(
        shouldAllow: Binding<Bool>,
        appId: String,
        showsTitle: Bool = false,
        onRuleChange: (() -> Void)? = nil
    ) {
        self._shouldAllow = shouldAllow
        self.appId = appId
        self.showsTitle = showsTitle
        self.onRuleChange = onRuleChange
    }

    public var body: some View {
        AppActionContent(
            shouldAllow: $shouldAllow,
            appId: appId,
            showsTitle: showsTitle,
            onRuleChange: onRuleChange
        )
    }
}

// MARK: - Action

extension AppActionContent {
    private func deny() {
        guard let repo else { return }
        let entitlement = store?.entitlement ?? .none
        Task {
            do {
                let outcome = try await DenyOperation(
                    repo: repo,
                    entitlement: entitlement,
                    ui: ui,
                    shell: shell,
                    appId: appId,
                    onRuleChange: onRuleChange
                ).run()
                if outcome == .denied {
                    self.shouldAllow = false
                }
            } catch let error {
                os_log("\(self.t)操作失败 -> \(error.localizedDescription)")
                shell.postError(error.localizedDescription)
            }
        }
    }

    private func allow() {
        guard let repo else { return }
        Task {
            do {
                try await repo.setAllow(appId)
                self.shouldAllow = true
                self.onRuleChange?()
                shell.post(ToastMessage(description: "已允许"))
            } catch let error {
                os_log("\(self.t)操作失败 -> \(error.localizedDescription)")
                shell.postError(error.localizedDescription)
            }
        }
    }
    
}

#Preview("APP") {
    ContentView().dashboardPreviewRoot()
        .frame(width: 500)
        .frame(height: 500)
}
