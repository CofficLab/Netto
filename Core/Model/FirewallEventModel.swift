import PluginFirewallDashboard
import Foundation
import SwiftData
import SwiftUI
import OSLog
import MagicCore
import NetworkExtension

@Model
final class FirewallEventModel: SuperLog, SuperEvent {
    @Transient let emoji = "🔥"
    
    @Attribute(.unique)
    var id: String
    var time: Date
    var address: String
    var port: String
    var sourceAppIdentifier: String
    var statusRawValue: Int // 存储Status枚举的原始值
    var directionRawValue: Int // 存储NETrafficDirection枚举的原始值
    
    // MARK: - Computed Properties
    
    /// 防火墙事件状态
    var status: FirewallEvent.Status {
        get {
            return statusRawValue == 0 ? .allowed : .rejected
        }
        set {
            statusRawValue = newValue == .allowed ? 0 : 1
        }
    }
    
    /// 网络流量方向
    var direction: NETrafficDirection {
        get {
            return NETrafficDirection(rawValue: directionRawValue) ?? .outbound
        }
        set {
            directionRawValue = newValue.rawValue
        }
    }
    
    /// 是否被允许
    var isAllowed: Bool {
        status == .allowed
    }
    
    /// 格式化的时间字符串
    var timeFormatted: String {
        self.time.fullDateTime
    }
    
    /// 事件描述
    var description: String {
        "\(address):\(port)"
    }
    
    /// 状态描述
    var statusDescription: String {
        switch status {
        case .allowed:
            "允许"
        case .rejected:
            "阻止"
        }
    }
    
    // MARK: - Initialization
    
    /// 初始化FirewallEventModel实例
    /// - Parameters:
    ///   - id: 事件唯一标识符，默认生成UUID
    ///   - time: 事件发生时间，默认为当前时间
    ///   - address: 目标地址
    ///   - port: 目标端口
    ///   - sourceAppIdentifier: 源应用程序标识符
    ///   - status: 防火墙处理状态
    ///   - direction: 网络流量方向
    init(
        id: String = UUID().uuidString,
        time: Date = .now,
        address: String,
        port: String,
        sourceAppIdentifier: String = "",
        status: FirewallEvent.Status,
        direction: NETrafficDirection
    ) {
        self.id = id
        self.time = time
        self.address = address
        self.port = port
        self.sourceAppIdentifier = sourceAppIdentifier
        self.statusRawValue = status == .allowed ? 0 : 1
        self.directionRawValue = direction.rawValue
    }
    
    /// 从FirewallEvent结构体创建FirewallEventModel实例
    /// - Parameter event: FirewallEvent结构体实例
    /// - Returns: 对应的FirewallEventModel实例
    static func from(_ event: FirewallEvent) -> FirewallEventModel {
        return FirewallEventModel(
            id: event.id,
            time: event.time,
            address: event.address,
            port: event.port,
            sourceAppIdentifier: event.sourceAppIdentifier,
            status: event.status,
            direction: event.direction
        )
    }
    
    /// 从 FirewallEventDTO 创建 FirewallEventModel 实例
    /// - Parameter dto: FirewallEventDTO 实例
    /// - Returns: 对应的 FirewallEventModel 实例
    static func fromDTO(_ dto: FirewallEventDTO) -> FirewallEventModel {
        return FirewallEventModel(
            time: dto.time,
            address: dto.address,
            port: dto.port,
            sourceAppIdentifier: dto.sourceAppIdentifier,
            status: dto.status,
            direction: dto.direction
        )
    }
    
    /// 转换为FirewallEvent结构体
    /// - Returns: 对应的FirewallEvent结构体实例
    func toFirewallEvent() -> FirewallEvent {
        return FirewallEvent(
            id: self.id,
            time: self.time,
            address: self.address,
            port: self.port,
            sourceAppIdentifier: self.sourceAppIdentifier,
            status: self.status,
            direction: self.direction
        )
    }
}

#Preview("App") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
        .frame(height: 600)
}

#Preview("防火墙事件视图") {
    RootView(environment: .preview()) {
        DBEventView()
    }
    .frame(width: 600, height: 700)
}
