import Network
import NetworkExtension
import os.log

class FilterDataProvider: NEFilterDataProvider {
    private var ipc = IPCConnection.shared

    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        ipc.providerSay("startFilter 🚛")

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

        apply(filterSettings) { [self] error in
            if let applyError = error {
                os_log("Failed to apply filter settings: %@", applyError.localizedDescription)

                ipc.providerSay("⚠️ Failed to apply filter settings: \(applyError.localizedDescription)")
            } else {
                ipc.providerSay("Success to apply filter settings 🎉")
            }

            completionHandler(error)
        }
    }

    override func handle(_ report: NEFilterReport) {
        print(report)
    }

    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        ipc.providerSay("stopFilter 📢 with reason -> \(reason)")

        completionHandler()
    }

    override func handleInboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
        ipc.providerSay("handleInboundData")

        return .allow()
    }

    override func handleOutboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
        ipc.providerSay("handleOutboundData")

        return .allow()
    }

    override func handleInboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
        ipc.providerSay("handleInboundDataComplete")

        return .allow()
    }

    override func handleOutboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
        ipc.providerSay("handleOutboundDataComplete")

        return .allow()
    }

    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
//        ipc.providerSay("handleNewFlow")

        // Ask the app to prompt the user
        // WWDC2019视频中说，这是一个异步的过程
        let prompted = ipc.promptUser(flow: flow) { (allow: Bool) in
            let userVerdict: NEFilterNewFlowVerdict = allow ? .allow() : .drop()

            // 用户决策完毕，可能是恢复，也可能是拒绝
            self.resumeFlow(flow, with: userVerdict)
        }

        guard prompted else {
            ipc.providerSay("调用promptUser失败，放行")
            return .allow()
        }

        // 因为等待用户决策是异步的，所以这里先暂停，等待决策结果
        return .pause()
    }
}
