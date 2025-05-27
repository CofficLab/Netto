import MagicCore
import OSLog
import SwiftUI

struct AppLine: View, SuperEvent {
    var app: SmartApp

    @State private var hovering: Bool = false
    @State var shouldAllow: Bool

    init(app: SmartApp) {
        self.app = app
        self.shouldAllow = AppSetting.shouldAllow(app.id)
    }

    private var background: some View {
        ZStack {
            if hovering {
                BackgroundView.type1.opacity(0.4)
            } else {
                if !shouldAllow {
                    Color.red.opacity(0.1)
                }
            }
        }
    }

    var body: some View {
        HStack {
            app.icon.frame(width: 40, height: 40)

            VStack(alignment: .leading) {
                Text(app.name)
                HStack(alignment: .top) {
                    Text("\(app.events.count)").font(.callout)
                    Text(app.id)
                }
            }

            Spacer()

            if hovering {
                BtnDeny(appId: app.id)
                    .labelStyle(.titleOnly)
                    .disabled(!shouldAllow)
                BtnAllow(appId: app.id)
                    .labelStyle(.titleOnly)
                    .disabled(shouldAllow)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(background)
        .scaleEffect(hovering ? 1 : 1)
        .onHover(perform: { hovering in
            self.hovering = hovering
        })
        .frame(height: 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(self.nc.publisher(for: .didSetDeny), perform: onDidSetDeny)
        .onReceive(self.nc.publisher(for: .didSetAllow), perform: onDidSetAllow)
    }
}

extension AppLine {
    func onDidSetDeny(_ n: Notification) {
        if let appId = n.userInfo?["appId"] as? String {
            if appId == app.id {
                self.shouldAllow = false
            }
        }
    }

    func onDidSetAllow(_ n: Notification) {
        if let appId = n.userInfo?["appId"] as? String {
            if appId == app.id {
                self.shouldAllow = true
            }
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
