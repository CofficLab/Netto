import Foundation
import MagicCore
import MagicUI
import OSLog
import SwiftUI

struct StoreBtn: View {
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

// MARK: - Preview

#Preview("Buy") {
    BuySetting()
        .inRootView()
        .frame(height: 800)
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(width: 700)
        .frame(height: 800)
}
