import Foundation
import ProviderFirewall

/// 应用实时网速监视器：接收 Extension 的周期字节增量，归一化为速率并平滑发布。
///
/// 数据流：
/// 1. Extension 每秒把 `appId → 字节增量` 经 XPC `reportNetworkTraffic` 送到 App；
/// 2. 本类按 `elapsed` 还原每秒速率，并对每个应用保留最近 3 个点做移动平均；
/// 3. 快照通过 `observe()` 的 AsyncStream 推给菜单栏弹窗。
///
/// 时钟：Extension 每个 tick 都会上报（空闲时为空数组），因此本类无需自带
/// 定时器；未出现的应用按 0 速率衰减，窗口内全部归零后从快照中移除。
///
/// 线程/actor：`@MainActor`。
@MainActor
final class AppNetworkSpeedMonitor: NetworkSpeedProviding {
    /// Extension 上报的一条应用增量。
    struct Sample: Sendable {
        let appId: String
        let bytesIn: Double
        let bytesOut: Double
        let elapsed: TimeInterval
    }

    private(set) var snapshot: [AppNetworkSpeed] = []

    private var continuations: [UUID: AsyncStream<[AppNetworkSpeed]>.Continuation] = [:]
    private var history: [String: [(download: Double, upload: Double)]] = [:]
    private var lastIngestAt: Date?

    /// 上报间隔上限：超过说明扩展/过滤器发生过启停或 App 被挂起，
    /// 旧窗口不再代表当前速率，直接丢弃。
    private let resetGap: TimeInterval = 5

    /// 与 Lumi 的进程网速一致：3 点移动平均，平滑抖动但保留秒级响应。
    private let smoothingWindow = 3

    /// 处理一个采样 tick 的全部应用增量（可为空数组，用于衰减）。
    func ingest(_ samples: [Sample]) {
        let now = Date()
        if let lastIngestAt, now.timeIntervalSince(lastIngestAt) > resetGap {
            history.removeAll()
        }
        lastIngestAt = now

        var rates: [String: (download: Double, upload: Double)] = [:]
        for sample in samples where !sample.appId.isEmpty {
            let seconds = max(sample.elapsed, 0.1)
            let download = max(sample.bytesIn, 0) / seconds
            let upload = max(sample.bytesOut, 0) / seconds
            let existing = rates[sample.appId] ?? (0, 0)
            rates[sample.appId] = (existing.download + download, existing.upload + upload)
        }

        let tracked = Set(history.keys).union(rates.keys)
        var nextHistory: [String: [(download: Double, upload: Double)]] = [:]
        var published: [AppNetworkSpeed] = []

        for appId in tracked {
            var values = history[appId] ?? []
            values.append(rates[appId] ?? (0, 0))
            if values.count > smoothingWindow {
                values.removeFirst()
            }

            let avgDownload = values.reduce(0.0) { $0 + $1.download } / Double(values.count)
            let avgUpload = values.reduce(0.0) { $0 + $1.upload } / Double(values.count)

            // 窗口内已全零的应用直接移出，避免长期保留无流量条目。
            guard values.contains(where: { $0.download > 0 || $0.upload > 0 }) else {
                continue
            }

            nextHistory[appId] = values
            published.append(AppNetworkSpeed(
                appId: appId,
                downloadBytesPerSecond: avgDownload,
                uploadBytesPerSecond: avgUpload
            ))
        }

        history = nextHistory

        let nextSnapshot = published.sorted { lhs, rhs in
            if lhs.totalBytesPerSecond != rhs.totalBytesPerSecond {
                return lhs.totalBytesPerSecond > rhs.totalBytesPerSecond
            }
            return lhs.appId < rhs.appId
        }

        snapshot = nextSnapshot
        for continuation in continuations.values {
            continuation.yield(nextSnapshot)
        }
    }

    func observe() -> AsyncStream<[AppNetworkSpeed]> {
        let observerID = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
            continuations[observerID] = continuation
            continuation.yield(snapshot)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.continuations.removeValue(forKey: observerID)
                }
            }
        }
    }
}
