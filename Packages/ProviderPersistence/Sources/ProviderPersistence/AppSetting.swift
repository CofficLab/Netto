import Foundation
import SwiftData

/// 应用允许/阻止规则持久化模型。
///
/// 兼容红线：实体名 `AppSetting`、属性 `appId`（unique）/`allowed` 与旧
/// `Core/Model/AppSetting.swift` 完全一致，保证旧 db.sqlite 直接可读。
@Model
public final class AppSetting {
    @Attribute(.unique)
    public var appId: String
    public var allowed: Bool

    public init(appId: String, allowed: Bool) {
        self.appId = appId
        self.allowed = allowed
    }
}
