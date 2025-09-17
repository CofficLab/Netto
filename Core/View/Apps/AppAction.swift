import MagicCore
import MagicAlert
import MagicUI
import OSLog
import SwiftUI

struct AppAction: View, SuperLog, SuperEvent {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var repo: AppSettingRepo
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
        let repo = self.repo
        Task {
            do {
                let purchaseInfo = StoreService.cachedPurchaseInfo()
                
                os_log("\(self.t)🔐 当前权限 tier -> \(purchaseInfo.tier.rawValue)")
                os_log("\(self.t)⏰ 过期时间 -> \(purchaseInfo.expiresAtString)")

                // 如果不是 Pro，检查禁止数量限制
                if purchaseInfo.isNotProOrHigher {
                    let deniedCount = try await repo.getDeniedAppsCount()
                    if deniedCount >= 5 {
                        await MainActor.run {
                            self.showUpgradeGuide()
                        }
                        return
                    }
                }
                
                try await repo.setDeny(appId)
                self.shouldAllow = false
                self.m.info("已禁止")
            } catch let error {
                os_log("\(self.t)操作失败 -> \(error.localizedDescription)")
                m.error(error)
            }
        }
    }

    private func allow() {
        let repo = self.repo
        Task {
            do {
                try await repo.setAllow(appId)
                self.shouldAllow = true
                self.m.info("已允许")
            } catch let error {
                os_log("\(self.t)操作失败 -> \(error.localizedDescription)")
                m.error(error)
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
