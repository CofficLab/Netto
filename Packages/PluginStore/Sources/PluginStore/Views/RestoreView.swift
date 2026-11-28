import OSLog
import ProviderShell
import StoreKit
import SwiftUI

struct RestoreView: View, LogPrefixed {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @EnvironmentObject private var shell: ShellCenter

    @State private var subscriptions: [Product] = []
    @State private var refreshing = false
    @State private var error: Error? = nil

    nonisolated static let emoji = "🖥️"

    var body: some View {
        VStack {
            ZStack {
                Text("Restore Purchases").font(.title3)
            }

            Divider()

            Text("If you purchased a subscription on another device, you can restore it by clicking \"Restore Purchases\" below.\n\nMake sure you are signed in with the Apple ID used for the purchase.\n\nOnce restored, all purchased features will be available again.")
                .padding()
                .multilineTextAlignment(.center)

            Button("Restore Purchases", action: {
                Task {
                    // This call displays a system prompt that asks users to authenticate with their App Store credentials.
                    // Call this function only in response to an explicit user action, such as tapping a button.
                    do {
                        os_log("\(self.t)恢复购买")
                        try await AppStore.sync()
                        os_log("\(self.t)恢复购买完成")
                        postRestore()
                    } catch {
                        shell.postError(error.localizedDescription)
                    }
                }
            })
        }
    }
}

// MARK: Event Name

extension Notification.Name {
    static let Restored = Notification.Name("Restored")
}

// MARK: Event Emitter

extension RestoreView {
    func postRestore() {
        NotificationCenter.default.post(name: .Restored, object: nil)
    }
}

// MARK: - Preview




