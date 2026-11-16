import Foundation
import ProviderFirewallEvents

/// 事件 CSV 导出：内容构建与目录写入分离，失败向上抛出。
///
/// 旧实现在视图内吞掉所有错误并固定提示成功；这里让调用方拿到真实的
/// 成功/失败结果，由 UI 决定 Toast 文案。
enum EventCSVExport {
    enum ExportError: LocalizedError, Equatable {
        case providerUnavailable
        case downloadsUnavailable
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .providerUnavailable:
                return "事件存储不可用"
            case .downloadsUnavailable:
                return "无法访问下载目录"
            case .encodingFailed:
                return "CSV 编码失败"
            }
        }
    }

    static let header = "id,time,address,port,appId,status,direction\n"

    static func csv(events: [FirewallEventSnapshot]) -> String {
        let rows = events.map { event in
            let columns: [String] = [
                event.id,
                event.time.ISO8601Format(),
                event.address,
                event.port,
                event.sourceAppIdentifier,
                (event.status == .allowed ? "allowed" : "rejected"),
                (event.direction == .inbound ? "inbound" : "outbound"),
            ]
            return columns.map { $0.replacingOccurrences(of: ",", with: " ") }.joined(separator: ",")
        }.joined(separator: "\n")
        return header + rows + "\n"
    }

    /// 按筛选条件抓取最近的至多 `maxCount` 条事件（时间倒序）。
    @MainActor
    static func recentEvents(
        provider: (any FirewallEventsProviding)?,
        appId: String,
        status: FirewallEventDecision?,
        direction: FirewallTrafficDirection?,
        maxCount: Int = 1000,
        pageSize: Int = 200
    ) async throws -> [FirewallEventSnapshot] {
        guard let provider else { throw ExportError.providerUnavailable }

        var all: [FirewallEventSnapshot] = []
        var page = 0

        while all.count < maxCount {
            let result = try await provider.fetchPage(FirewallEventQuery(
                appIdentifier: appId,
                status: status,
                direction: direction,
                page: page,
                pageSize: pageSize
            ))

            if result.events.isEmpty { break }

            let remaining = maxCount - all.count
            let itemsToAdd = Array(result.events.prefix(remaining))
            all.append(contentsOf: itemsToAdd)

            if itemsToAdd.count < result.events.count { break }
            page += 1
        }

        return all
    }

    /// 抓取并写入 CSV，返回写入的文件 URL；任一步失败都会抛出。
    @MainActor
    static func export(
        provider: (any FirewallEventsProviding)?,
        appId: String,
        status: FirewallEventDecision?,
        direction: FirewallTrafficDirection?,
        directory: URL?,
        now: Date = Date(),
        maxCount: Int = 1000,
        pageSize: Int = 200
    ) async throws -> URL {
        let events = try await recentEvents(
            provider: provider,
            appId: appId,
            status: status,
            direction: direction,
            maxCount: maxCount,
            pageSize: pageSize
        )

        guard let directory else { throw ExportError.downloadsUnavailable }
        guard let data = csv(events: events).data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        let url = directory.appendingPathComponent("logs-\(appId)-\(Int(now.timeIntervalSince1970)).csv")
        try data.write(to: url)
        return url
    }
}
