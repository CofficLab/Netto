import Foundation
import SwiftData

/// 防火墙事件持久化模型。
///
/// 兼容红线：实体名 `FirewallEventModel` 与属性
/// `id`(unique)/`time`/`address`/`port`/`sourceAppIdentifier`/
/// `statusRawValue`(0=放行,1=拒绝)/`directionRawValue`(NETrafficDirection.rawValue)
/// 与旧 `Core/Model/FirewallEventModel.swift` 完全一致，保证旧 db.sqlite 直接可读。
@Model
public final class FirewallEventModel {
    @Attribute(.unique)
    public var id: String
    public var time: Date
    public var address: String
    public var port: String
    public var sourceAppIdentifier: String
    /// 0 = 放行（allowed），1 = 拒绝（rejected）。
    public var statusRawValue: Int
    /// `NETrafficDirection` 原始值（inbound=1, outbound=2）。
    public var directionRawValue: Int

    public init(
        id: String = UUID().uuidString,
        time: Date = .now,
        address: String,
        port: String,
        sourceAppIdentifier: String = "",
        statusRawValue: Int,
        directionRawValue: Int
    ) {
        self.id = id
        self.time = time
        self.address = address
        self.port = port
        self.sourceAppIdentifier = sourceAppIdentifier
        self.statusRawValue = statusRawValue
        self.directionRawValue = directionRawValue
    }

    /// 是否放行（旧 `isAllowed` 语义）。
    public var isAllowed: Bool { statusRawValue == 0 }
}
