import Foundation
import NetworkExtension

/// 用于跨并发边界传输的防火墙事件快照
/// - 仅包含渲染或业务所需字段
/// - 值类型，Sendable，可安全在后台与前台之间传递
struct FirewallEventDTO: Sendable, Identifiable, Hashable {
    let id: String
    let time: Date
    let address: String
    let port: String
    let sourceAppIdentifier: String
    let status: FirewallEvent.Status
    let direction: NETrafficDirection
    let appId: String

    // MARK: - Computed

    var isAllowed: Bool { status == .allowed }

    var timeFormatted: String {
        time.fullDateTime
    }

    var description: String {
        "\(address):\(port)"
    }

    var statusDescription: String {
        switch status {
        case .allowed: "允许"
        case .rejected: "阻止"
        }
    }

    // MARK: - Factories

    static func fromModel(_ m: FirewallEventModel) -> FirewallEventDTO {
        FirewallEventDTO(
            id: m.id,
            time: m.time,
            address: m.address,
            port: m.port,
            sourceAppIdentifier: m.sourceAppIdentifier,
            status: m.status,
            direction: m.direction,
            appId: m.sourceAppIdentifier
        )
    }
}


