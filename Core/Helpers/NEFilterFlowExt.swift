import Foundation
import NetworkExtension
import SwiftUI

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
        return self.value(forKey: "sourceAppIdentifier") as? String ?? ""
    }
    
    func getAppUniqueId() -> String {
        return ""
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
