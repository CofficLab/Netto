import Foundation
import NetworkExtension

extension NEFilterFlow {
    func getLocalPort() -> String {
        guard let socketFlow = self as? NEFilterSocketFlow else {
            return ""
        }
        
        let localEndpoint = socketFlow.localEndpoint as? NWHostEndpoint
        
        return localEndpoint?.port ?? ""
    }
    
    func getHostname() -> String {
        guard let socketFlow = self as? NEFilterSocketFlow else {
            return ""
        }
        
        let localEndpoint = socketFlow.localEndpoint as? NWHostEndpoint
        
        return localEndpoint?.hostname ?? ""
    }
    
    func getAppId() -> String {
        self.value(forKey: "sourceAppIdentifier") as! String
    }
}
