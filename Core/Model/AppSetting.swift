import Foundation
import SwiftData
import SwiftUI
import OSLog
import MagicCore

@Model
final class AppSetting: SuperLog, SuperEvent {
    @Transient let emoji = "🦆"

    @Attribute(.unique)
    var appId: String
    var allowed: Bool
    
    // MARK: - Initialization
    
    /// 初始化AppSetting实例
    /// - Parameters:
    ///   - appId: 应用程序的唯一标识符
    ///   - allowed: 是否允许该应用程序访问网络
    init(appId: String, allowed: Bool) {
        self.appId = appId
        self.allowed = allowed
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
