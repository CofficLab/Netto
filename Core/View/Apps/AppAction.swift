import MagicCore
import MagicAlert
import MagicUI
import OSLog
import SwiftUI

struct AppAction: View, SuperLog, SuperEvent {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var repo: AppSettingRepo
    @EnvironmentObject var store: StoreProvider

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
        if self.store.currentSubscription == nil {
            m.error("请订阅后继续")
            return
        }
        
        let repo = self.repo
        Task {
            do {
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
}

#Preview("APP") {
    ContentView().inRootView()
        .frame(width: 500)
        .frame(height: 500)
}
