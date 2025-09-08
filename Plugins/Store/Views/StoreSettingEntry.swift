import Foundation
import MagicCore
import MagicUI
import OSLog
import SwiftUI

struct StoreSettingEntry: View {
    @State private var showBuySheet = false

    var body: some View {
        MagicButton.simple(title: "查看订阅") {
            showBuySheet = true
        }
        .magicIcon("app.gift")
        .magicShape(.circle)
        .magicStyle(.secondary)
        .magicSize(.small)
        .sheet(isPresented: $showBuySheet) {
            BuySetting()
        }
    }
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(height: 600)
}
