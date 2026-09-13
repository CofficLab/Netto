import Foundation
import ProviderPersistence
import ProviderFirewallEvents
import SwiftData

/// 方向 → `NETrafficDirection` raw value 映射。
/// 断言依据：`NETrafficDirection` NS_ENUM（Any=0, Inbound=1, Outbound=2）。
extension FirewallTrafficDirection {
    var storageRawValue: Int {
        switch self {
        case .inbound: return 1
        case .outbound: return 2
        }
    }
}

/// 事件存储与契约快照的映射（保持旧存储语义）。
extension FirewallEventSnapshot {
    /// 存储 raw value：allowed=0、rejected=1（与旧 `FirewallEvent.Status` 一致）。
    var statusStorageRawValue: Int { status.storageRawValue }

    /// `NETrafficDirection` raw value（inbound=1、outbound=2）。
    var directionStorageRawValue: Int { direction.storageRawValue }

    /// 转换为持久化模型（`fromDTO` 语义：不携带 id，由模型自动生成）。
    func toModel() -> FirewallEventModel {
        FirewallEventModel(
            time: time,
            address: address,
            port: port,
            sourceAppIdentifier: sourceAppIdentifier,
            statusRawValue: statusStorageRawValue,
            directionRawValue: directionStorageRawValue
        )
    }
}

extension FirewallEventModel {
    /// 转换为中立快照（`FirewallEventDTO.fromModel` 语义）。
    var toSnapshot: FirewallEventSnapshot {
        FirewallEventSnapshot(
            id: id,
            time: time,
            address: address,
            port: port,
            sourceAppIdentifier: sourceAppIdentifier,
            status: statusRawValue == 0 ? .allowed : .rejected,
            direction: directionRawValue == 1 ? .inbound : .outbound,
            appId: sourceAppIdentifier
        )
    }
}
