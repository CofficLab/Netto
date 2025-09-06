import Foundation
import SwiftUI

/// 用于跨并发边界传输的应用设置快照
/// - 仅包含渲染或业务所需字段
/// - 值类型，Sendable，可安全在后台与前台之间传递
struct AppSettingDTO: Sendable, Identifiable, Hashable {
    let appId: String
    let allowed: Bool
    
    // MARK: - Computed Properties
    
    /// 应用ID作为标识符
    var id: String { appId }
    
    /// 是否被拒绝访问
    var isDenied: Bool { !allowed }
    
    /// 状态描述
    var statusDescription: String {
        allowed ? "允许" : "拒绝"
    }
    
    /// 状态图标
    var statusIcon: String {
        allowed ? "✅" : "❌"
    }
    
    // MARK: - Factories
    
    /// 从 AppSetting 模型创建 DTO
    /// - Parameter model: AppSetting 模型实例
    /// - Returns: 对应的 AppSettingDTO 实例
    static func fromModel(_ model: AppSetting) -> AppSettingDTO {
        AppSettingDTO(
            appId: model.appId,
            allowed: model.allowed
        )
    }
    
    /// 创建新的 DTO 实例
    /// - Parameters:
    ///   - appId: 应用程序ID
    ///   - allowed: 是否允许访问
    /// - Returns: 新的 AppSettingDTO 实例
    static func create(appId: String, allowed: Bool) -> AppSettingDTO {
        AppSettingDTO(appId: appId, allowed: allowed)
    }
}

// MARK: - Preview

#Preview("App - Large") {
    ContentView()
        .inRootView()
        .frame(width: 600, height: 1000)
}

#Preview("App - Small") {
    ContentView()
        .inRootView()
        .frame(width: 600, height: 600)
}
