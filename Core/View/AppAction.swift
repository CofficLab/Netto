import MagicCore
import OSLog
import SwiftUI

struct AppAction: View, SuperLog, SuperEvent {
    @EnvironmentObject private var channel: ChannelProvider
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var app: AppManager
    @EnvironmentObject var data: DataProvider

    @Binding var shouldAllow: Bool

    var appId: String

    private var iconName: String {
        if shouldAllow {
            "xmark.circle.fill"
        } else {
            "checkmark.circle.fill"
        }
    }

    private var title: String {
        if shouldAllow {
            "禁止"
        } else {
            "允许"
        }
    }

    var body: some View {
        MagicButton(icon: iconName, size: .auto, action: {
            shouldAllow ? deny() : allow()
        })
        .magicStyle(.primary)
        .magicShape(.roundedRectangle)
        .magicBackgroundColor(shouldAllow ? .red : .green)
        .frame(width: 30)
        .frame(height: 30)
        .onReceive(self.nc.publisher(for: .didSetDeny), perform: onDidSetDeny)
        .onReceive(self.nc.publisher(for: .didSetAllow), perform: onDidSetAllow)
    }

    private func deny() {
        do {
            try data.deny(appId)
            self.shouldAllow = false
            self.m.toast("已禁止")
        } catch let error {
            os_log("\(self.t)操作失败 -> \(error.localizedDescription)")
            m.error(error)
        }
    }

    private func allow() {
        do {
            try data.allow(appId)
            self.shouldAllow = true
            self.m.done("已允许")
        } catch let error {
            os_log("\(self.t)操作失败 -> \(error.localizedDescription)")
            m.error(error)
        }
    }
}

// MARK: - 事件

extension AppAction {
    func onDidSetDeny(_ n: Notification) {
        if let appId = n.userInfo?["appId"] as? String {
            if appId == self.appId {
                self.shouldAllow = false
            }
        }
    }

    func onDidSetAllow(_ n: Notification) {
        if let appId = n.userInfo?["appId"] as? String {
            if appId == self.appId {
                self.shouldAllow = true
            }
        }
    }
}

#Preview {
    RootView {
        AppAction(shouldAllow: .constant(true), appId: "")
    }
    .frame(width: 300)
    .frame(height: 300)
}

#Preview("APP") {
    RootView {
        ContentView()
    }
}
