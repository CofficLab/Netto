import Foundation
import NetworkExtension
import SwiftData
import SwiftUI
import OSLog

final class Event: ObservableObject {
    enum EventList {
        case Speak
        case NetWorkFilterFlow
        
        var name: String {
            String(describing: self)
        }
    }
    
    func emitNetworkFilterFlow(_ flow: NEFilterFlow) {
        NotificationCenter.default.post(
            name: NSNotification.Name(EventList.NetWorkFilterFlow.name),
            object: flow,
            userInfo: nil
        )
    }
    
    func emitSpeak(_ data: [String: String]) {
        NotificationCenter.default.post(
            name: NSNotification.Name(EventList.Speak.name),
            object: nil,
            userInfo: data
        )
    }
    
    func onSpeak(_ callback: @escaping (_ e: FirewallEvent) -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(EventList.Speak.name),
            object: nil,
            queue: .main,
            using: { notification in
                let data = notification.userInfo as! [String: String]
                callback(FirewallEvent(
                    address: data["address"]!, 
                    port: data["port"]!,
                    sourceAppIdentifier: data["sourceAppIdentifier"]!
                ))
            })
    }
    
    func onNetworkFilterFlow(_ callback: @escaping (_ e: FirewallEvent) -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(EventList.NetWorkFilterFlow.name),
            object: nil,
            queue: .main,
            using: { notification in
                let flow = notification.object as! NEFilterFlow
                let socketFlow = flow as! NEFilterSocketFlow
                let remoteEndpoint = socketFlow.remoteEndpoint as? NWHostEndpoint
                let localEndpoint = socketFlow.localEndpoint as? NWHostEndpoint
                
                callback(FirewallEvent(
                    address: localEndpoint?.hostname ?? "",
                    port: localEndpoint?.port ?? "",
                    sourceAppIdentifier: flow.value(forKey: "sourceAppIdentifier") as! String
                ))
            })
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
