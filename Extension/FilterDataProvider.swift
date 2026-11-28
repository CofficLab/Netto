import Foundation
import Network
import NetworkExtension
import os.log

/// 单流决策的一次性回复门闩：App 回复与超时兜底只有一方能恢复该流。
private final class FlowDecisionGate: @unchecked Sendable {
    private let lock = NSLock()
    private var didRespond = false

    /// - Returns: 是否是第一次回复（true 时由调用方负责恢复流）。
    func claim() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !didRespond else { return false }
        didRespond = true
        return true
    }
}

/// 超时兜底需要跨并发域持有非 Sendable 的 `NEFilterFlow`；仅在门闩胜出时使用一次。
private struct FlowHandle: @unchecked Sendable {
    let flow: NEFilterFlow
}

/// 按应用累计统计报告里的字节增量，每秒由定时器取走并上报。
///
/// 放行流不再进入数据面：新流 verdict 设置 `statisticsReportFrequency`
/// 后，系统通过 `NEFilterReport` 周期上报每个流的累计字节。报告可能来自
/// 多个队列，因此按流记录上一次的累计值并在锁内做差；`flowClosed` 报告
/// 用于补齐短连接的尾量并释放流状态。
private final class TrafficCounter: @unchecked Sendable {
    private struct FlowState {
        var appId: String
        var inbound: Int64
        var outbound: Int64
        var lastSeen: UInt64
    }

    private let lock = NSLock()
    private var bytes: [String: (inbound: Int64, outbound: Int64)] = [:]
    private var flows: [UUID: FlowState] = [:]
    private var lastFlush = DispatchTime.now()

    /// 流状态在无报告后保留的上限，防止丢失 close 报告时无限累积。
    private static let flowStateLifetime: UInt64 = 60 * 1_000_000_000

    func record(_ report: NEFilterReport) {
        guard report.event == .statistics || report.event == .flowClosed,
              let flow = report.flow else { return }

        let flowID = flow.identifier
        let currentIn = Int64(report.bytesInboundCount)
        let currentOut = Int64(report.bytesOutboundCount)
        let now = DispatchTime.now().uptimeNanoseconds

        lock.lock()
        defer { lock.unlock() }

        let state = flows[flowID]
        var appId = state?.appId ?? ""
        if appId.isEmpty {
            appId = flow.getAppId()
        }

        let deltaIn = max(currentIn - (state?.inbound ?? 0), 0)
        let deltaOut = max(currentOut - (state?.outbound ?? 0), 0)
        if !appId.isEmpty {
            addLocked(deltaIn, deltaOut, appId: appId)
        }

        if report.event == .flowClosed {
            flows.removeValue(forKey: flowID)
        } else {
            flows[flowID] = FlowState(
                appId: appId,
                inbound: currentIn,
                outbound: currentOut,
                lastSeen: now
            )
        }
    }

    /// 调用方必须持有锁。
    private func addLocked(_ inbound: Int64, _ outbound: Int64, appId: String) {
        guard inbound > 0 || outbound > 0 else { return }
        var entry = bytes[appId] ?? (0, 0)
        entry.inbound += inbound
        entry.outbound += outbound
        bytes[appId] = entry
    }

    /// 过滤器启停时清空残留字节并重置计时起点，避免启停间隙的旧数据被算进首秒。
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        bytes.removeAll(keepingCapacity: true)
        flows.removeAll(keepingCapacity: true)
        lastFlush = DispatchTime.now()
    }

    /// 取走累计值并清零；返回 `appId / bytesIn / bytesOut / elapsed` 字典数组。
    func flush() -> [[String: Any]] {
        lock.lock()
        defer { lock.unlock() }

        let now = DispatchTime.now()
        let uptime = now.uptimeNanoseconds
        let elapsed = Double(uptime - lastFlush.uptimeNanoseconds) / 1_000_000_000
        lastFlush = now

        flows = flows.filter { uptime - $0.value.lastSeen < Self.flowStateLifetime }

        let snapshot = bytes
        bytes.removeAll(keepingCapacity: true)

        return snapshot.map { appId, value in
            [
                "appId": appId,
                "bytesIn": value.inbound,
                "bytesOut": value.outbound,
                "elapsed": elapsed,
            ]
        }
    }
}

class FilterDataProvider: NEFilterDataProvider, @unchecked Sendable {
    private var ipc = IPCConnection.shared

    private let trafficCounter = TrafficCounter()
    private let trafficQueue = DispatchQueue(label: "com.coffic.netpause.traffic", qos: .utility)
    private var trafficTimer: DispatchSourceTimer?

    /// 网速上报周期；与菜单栏 UI 的刷新节奏一致。
    private static let trafficInterval: TimeInterval = 1.0

    /// 等待 App 决策的上限；超时按放行兜底（与 prompt 不可用时的 fail-open 一致）。
    private static let decisionTimeout: Duration = .seconds(5)

    /**
     * 启动网络过滤器
     * 配置过滤规则并启动网络数据过滤功能
     */
    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        ipc.log("🚀 startFilter")
        startTrafficReporting()

        // Filter incoming TCP connections on port 8888
        let filterRules = ["0.0.0.0", "::"].map { address -> NEFilterRule in
            let inboundNetworkRule: NENetworkRule

            // Use new NWEndpoint-based initializers for macOS 15.0+
            let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(address), port: NWEndpoint.Port("8888")!)
            inboundNetworkRule = NENetworkRule(remoteNetworkEndpoint: nil,
                                               remotePrefix: 0,
                                               localNetworkEndpoint: endpoint,
                                               localPrefix: 0,
                                               protocol: .TCP,
                                               direction: .inbound)

            return NEFilterRule(networkRule: inboundNetworkRule, action: .filterData)
        }

        let filterSettings = NEFilterSettings(rules: filterRules, defaultAction: .filterData)

        apply(filterSettings) { error in
            if let applyError = error {
                os_log("Failed to apply filter settings: %@", applyError.localizedDescription)

                IPCConnection.shared.log("⚠️ Failed to apply filter settings: \(applyError.localizedDescription)")

            } else {
                IPCConnection.shared.log("🎉 Success to apply filter settings")
            }

            completionHandler(error)
        }
    }

    /**
     * 处理过滤报告
     * 当系统生成过滤报告时调用
     */
    override func handle(_ report: NEFilterReport) {
        // 只消费统计/关流报告里的字节数；其余报告（新流、数据决策）无需处理。
        trafficCounter.record(report)
    }

    /**
     * 停止过滤器
     * 当系统要求停止过滤器时调用
     */
    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        ipc.log("🤚 stopFilter with reason -> \(reason)")
        stopTrafficReporting()

        completionHandler()
    }

    // MARK: - 网速上报

    /// 放行新流并订阅周期统计报告。
    ///
    /// 不能使用 `filterDataVerdict`：那会把所有放行流量拖进数据面，回调
    /// 处理不及时会挂起整机网络。`allowVerdict` 让流量直接通过，
    /// `statisticsReportFrequency` 只旁路上报每个流的累计字节。
    private static func allowedVerdict() -> NEFilterNewFlowVerdict {
        let verdict = NEFilterNewFlowVerdict.allow()
        verdict.shouldReport = true
        verdict.statisticsReportFrequency = .medium
        return verdict
    }

    private func startTrafficReporting() {
        guard trafficTimer == nil else { return }

        trafficCounter.reset()

        let timer = DispatchSource.makeTimerSource(queue: trafficQueue)
        timer.schedule(
            deadline: .now() + Self.trafficInterval,
            repeating: Self.trafficInterval,
            leeway: .milliseconds(100)
        )
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            // 空闲 tick 也上报空数组：App 侧据此把无流量应用衰减为 0。
            self.ipc.reportNetworkTraffic(self.trafficCounter.flush())
        }
        timer.resume()
        trafficTimer = timer
    }

    private func stopTrafficReporting() {
        trafficTimer?.cancel()
        trafficTimer = nil
        trafficCounter.reset()
    }

    /**
     * 处理入站数据
     * 当有入站数据需要过滤时调用
     */
    override func handleInboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
        return .allow()
    }

    /**
     * 处理出站数据
     * 当有出站数据需要过滤时调用
     */
    override func handleOutboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
        return .allow()
    }

    /**
     * 处理入站数据完成
     * 当入站数据传输完成时调用
     */
    override func handleInboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
        return .allow()
    }

    /**
     * 处理出站数据完成
     * 当出站数据传输完成时调用
     */
    override func handleOutboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
        return .allow()
    }

    /**
     * 处理新的网络流连接
     * 当有新的网络连接时，此方法会被调用来决定是否允许该连接
     *
     * @param flow 新的网络流对象
     * @return 过滤决策结果
     */
    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        let gate = FlowDecisionGate()
        let handle = FlowHandle(flow: flow)

        // Ask the app to prompt the user
        let prompted = self.ipc.promptUser(flow: flow) { (allow: Bool) in
            guard gate.claim() else { return }
            let userVerdict: NEFilterNewFlowVerdict = allow ? Self.allowedVerdict() : .drop()

            // 用户决策完毕，可能是恢复，也可能是拒绝
            self.resumeFlow(handle.flow, with: userVerdict)
        }

        guard prompted else {
            _ = gate.claim()
            ipc.log("调用promptUser失败，放行")
            return Self.allowedVerdict()
        }

        // 每条 pause 的流都必须恰好恢复一次：App 丢失请求或退出时按放行兜底，
        // 避免连接无限悬挂。
        Task { [weak self, gate, handle] in
            try? await Task.sleep(for: Self.decisionTimeout)
            guard !Task.isCancelled, gate.claim() else { return }
            os_log("⏱️ 等待 App 决策超时，放行")
            self?.resumeFlow(handle.flow, with: Self.allowedVerdict())
        }

        // 因为等待用户决策是异步的，所以这里先暂停，等待决策结果
        return .pause()
    }
}
