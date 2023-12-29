import NetworkExtension
import os.log

class FilterDataProvider: NEFilterDataProvider {
    private var ipc = IPCConnection.shared

    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        let filterSettings = NEFilterSettings(rules: [], defaultAction: .filterData)

        apply(filterSettings) { error in
            if let applyError = error {
                os_log("Failed to apply filter settings: %@", applyError.localizedDescription)
            }
            completionHandler(error)
        }
    }
    
    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        // Ask the app to prompt the user
        let prompted = ipc.promptUser(flow: flow) { allow in
            let userVerdict: NEFilterNewFlowVerdict = allow ? .allow() : .drop()

            self.resumeFlow(flow, with: userVerdict)
        }

        guard prompted else {
            os_log("FilterDataProvider->调用promptUser失败，放行")
            return .allow()
        }

        os_log("FilterDataProvider->暂停")
        return .pause()
    }
}
