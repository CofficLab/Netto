import Foundation
import SwiftUI

extension SmartApp {
    /// 示例应用列表
    public static let samples: [SmartApp] = SmartApp.allSystemApps
}

#Preview("APP") {
    DashboardPreviewHost { ContentView() }
    .frame(width: 700)
    .frame(height: 600)
}
