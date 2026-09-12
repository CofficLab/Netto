import MagicCore
import MagicAlert
import MagicUI
import OSLog
import PluginShell
import ProviderAppSettings
import ProviderShell
import ProviderStore
import SwiftUI

struct AppAction: View, SuperLog, SuperEvent {
    @EnvironmentObject private var shell: ShellCenter
    @Environment(\.settingsProvider) private var repo: AppSettingsProviding?
    @Environment(\.storeProvider) private var store: StoreProviding?
    @EnvironmentObject var ui: UIProvider

    @Binding var shouldAllow: Bool

    var appId: String

    private var iconName: String {
        if shouldAllow {
            "xmark.circle.fill"
        } else {
            "checkmark.circle.fill"
        }
    }

    var body: some View {
        MagicButton.simple(icon: iconName, size: .auto, action: {
            shouldAllow ? deny() : allow()
        })
        .magicStyle(.primary)
        .magicShape(.roundedRectangle)
        .magicBackgroundColor(shouldAllow ? .red : .green)
        .frame(width: 30)
        .frame(height: 30)
    }
}

// MARK: - Action

extension AppAction {
    private func deny() {
        guard let repo else { return }
        Task {
            do {
                // 阶段 7：经 StoreProviding 契约读取权益快照（替代 StoreService 静态访问）
                let entitlement = store?.entitlement ?? .none

                os_log("\(self.t)🔐 当前权限 tier -> \(entitlement.tier.rawValue)")
                os_log("\(self.t)⏰ 过期时间 -> \(String(describing: entitlement.expiresAt))")

                // 如果不是 Pro，检查禁止数量限制
                if !entitlement.isProOrHigher {
                    let deniedCount = try await repo.deniedAppsCount()
                    if deniedCount >= 5 {
                        await MainActor.run {
                            self.showUpgradeGuide()
                        }
                        return
                    }
                }
                
                try await repo.setDeny(appId)
                self.shouldAllow = false
                shell.post(ToastMessage(description: "已禁止"))
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
                shell.post(ToastMessage(description: "已允许"))
            } catch let error {
                os_log("\(self.t)操作失败 -> \(error.localizedDescription)")
                shell.postError(error.localizedDescription)
            }
        }
    }
    
    private func showUpgradeGuide() {
        // 显示升级引导界面
        ui.showUpgradeGuide()
    }
}

#Preview("APP") {
    ContentView().inRootView()
        .frame(width: 500)
        .frame(height: 500)
}
