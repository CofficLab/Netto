import Network
import NetworkExtension
import os.log

class FilterDataProvider: NEFilterDataProvider {
    @MainActor
    private var ipc = IPCConnection.shared

    /**
     * 启动网络过滤器
     * 配置过滤规则并启动网络数据过滤功能
     */
    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        //        Task { @MainActor in
        //            ipc.log("🚀 startFilter")
        //        }

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

                //                Task { @MainActor in
                //                    ipc.log("⚠️ Failed to apply filter settings: \(applyError.localizedDescription)")
                //                }
            } else {
                //                Task { @MainActor in
                //                    ipc.log("🎉 Success to apply filter settings")
                //                }
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
        //        Task { @MainActor in
        //            ipc.log("🤚 stopFilter with reason -> \(reason)")
        //        }

        completionHandler()
    }

    /**
     * 处理入站数据
     * 当有入站数据需要过滤时调用
     */
    override func handleInboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
        //        Task { @MainActor in
        //            ipc.log("handleInboundData")
        //        }

        return .allow()
    }

    /**
     * 处理出站数据
     * 当有出站数据需要过滤时调用
     */
    override func handleOutboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
        //        Task { @MainActor in
        //            ipc.log("handleOutboundData")
        //        }

        return .allow()
    }

    /**
     * 处理入站数据完成
     * 当入站数据传输完成时调用
     */
    override func handleInboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
        //        Task { @MainActor in
        //            ipc.log("handleInboundDataComplete")
        //        }

        return .allow()
    }

    /**
     * 处理出站数据完成
     * 当出站数据传输完成时调用
     */
    override func handleOutboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
        //        Task { @MainActor in
        //            ipc.log("handleOutboundDataComplete")
        //        }

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
//        ipc.log("🍋 handleNewFlow")

        // Ask the app to prompt the user
        // WWDC2019视频中说，这是一个异步的过程
//        DispatchQueue.main.async {
//            let prompted = self.ipc.promptUser(flow: f) { (allow: Bool) in
//                let userVerdict: NEFilterNewFlowVerdict = allow ? .allow() : .drop()
//                
//                // 用户决策完毕，可能是恢复，也可能是拒绝
//                self.resumeFlow(flow, with: userVerdict)
//            }
//        }

//        guard prompted else {
//            ipc.log("调用promptUser失败，放行")
            return .allow()
//        }

        // 因为等待用户决策是异步的，所以这里先暂停，等待决策结果
        return .pause()
    }
}
