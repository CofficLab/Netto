import Foundation
import SwiftUI

extension SmartApp {
    /// 示例应用列表
    static let samples: [SmartApp] = SmartApp.allSystemApps
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 600)
}
