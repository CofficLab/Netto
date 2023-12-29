import NetworkExtension
import os.log

class FilterDataProvider: NEFilterDataProvider {
    private var ipc = IPCConnection.shared

    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        ipc.providerSay("startFilter")
        let filterSettings = NEFilterSettings(rules: [], defaultAction: .filterData)

        apply(filterSettings) { error in
            if let applyError = error {
                os_log("Failed to apply filter settings: %@", applyError.localizedDescription)
            }
            completionHandler(error)
        }
    }
    
    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        ipc.providerSay("stopFilter")
        completionHandler()
    }
    
    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        // Ask the app to prompt the user
        // WWDC2019视频中说，这是一个异步的过程
        let prompted = ipc.promptUser(flow: flow) { allow in
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
