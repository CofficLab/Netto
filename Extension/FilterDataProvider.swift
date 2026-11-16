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

class FilterDataProvider: NEFilterDataProvider, @unchecked Sendable {
    private var ipc = IPCConnection.shared

    /// 等待 App 决策的上限；超时按放行兜底（与 prompt 不可用时的 fail-open 一致）。
    private static let decisionTimeout: Duration = .seconds(5)

    /**
     * 启动网络过滤器
     * 配置过滤规则并启动网络数据过滤功能
     */
    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        ipc.log("🚀 startFilter")

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
        print(report)
    }

    /**
     * 停止过滤器
     * 当系统要求停止过滤器时调用
     */
    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        ipc.log("🤚 stopFilter with reason -> \(reason)")

        completionHandler()
    }

    /**
     * 处理入站数据
     * 当有入站数据需要过滤时调用
     */
    override func handleInboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
        // 数据回调按块触发：这里不做日志与 IPC，保持数据面零额外开销。
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
        ipc.log("🍋 handleNewFlow")
        os_log("🎈 FilterDataProvider | handleNewFlow")

        let gate = FlowDecisionGate()
        let handle = FlowHandle(flow: flow)

        // Ask the app to prompt the user
        let prompted = self.ipc.promptUser(flow: flow) { (allow: Bool) in
            guard gate.claim() else { return }
            let userVerdict: NEFilterNewFlowVerdict = allow ? .allow() : .drop()

            // 用户决策完毕，可能是恢复，也可能是拒绝
            self.resumeFlow(handle.flow, with: userVerdict)
        }

        guard prompted else {
            _ = gate.claim()
            ipc.log("调用promptUser失败，放行")
            return .allow()
        }

        // 每条 pause 的流都必须恰好恢复一次：App 丢失请求或退出时按放行兜底，
        // 避免连接无限悬挂。
        Task { [weak self, gate, handle] in
            try? await Task.sleep(for: Self.decisionTimeout)
            guard !Task.isCancelled, gate.claim() else { return }
            os_log("⏱️ 等待 App 决策超时，放行")
            self?.resumeFlow(handle.flow, with: NEFilterNewFlowVerdict.allow())
        }

        // 因为等待用户决策是异步的，所以这里先暂停，等待决策结果
        return .pause()
    }
}
