import Foundation
import MagicCore
import OSLog
import StoreKit
import SwiftData
import SwiftUI

@MainActor
class PluginProvider: ObservableObject, SuperLog, SuperThread {
    let emoji = "🧩"
    private let plugins: [any SuperPlugin] = [
        SwitcherPlugin(),
        FilterPlugin(),
        MorePlugin(),
    ]

    func getPlugins() -> some View {
        let buttons: [(id: String, view: AnyView)] = plugins.flatMap { plugin in
            plugin.addToolBarButtons()
        }

        return HStack(spacing: 0) {
            ForEach(Array(buttons.enumerated()), id: \.element.id) { index, button in
                button.view
                if index < buttons.count - 1 {
                    Spacer()
                }
            }
        }
    }
    
    /// 清理资源，释放内存
    func cleanup() {
        // PluginProvider 目前没有需要清理的状态
        // 如果将来添加了状态，可以在这里清理
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(width: 800)
    .frame(height: 800)
}
