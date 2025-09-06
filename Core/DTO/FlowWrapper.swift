import NetworkExtension

struct FlowWrapper: Sendable {
    var id: String
    var hostname: String
    var port: String
    var allowed: Bool
    var direction: NETrafficDirection
    
    func getPort() -> String {
        if port.isEmpty {
            return "0" // 默认端口
        } else if let portNumber = Int(self.port), portNumber > 0 && portNumber <= 65535 {
            return self.port
        } else {
            return "0" // 无效端口时使用默认值
        }
    }
    
    func getAddress() -> String {
        self.hostname.isEmpty ? "unknown" : self.hostname
    }
    
    func getApp() -> SmartApp {
        SmartApp.fromId(self.id)
    }
}
