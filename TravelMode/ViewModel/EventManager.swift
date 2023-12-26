import Foundation
import NetworkExtension
import SwiftData
import SwiftUI
import OSLog

final class EventManager: ObservableObject {
    struct FlowWrapper {
        var flow: NEFilterFlow
        var allowed: Bool
    }
    
    enum EventList {
        case NetWorkFilterFlow
        case FilterStatusChanged
        
        var name: String {
            String(describing: self)
        }
    }
    
    func emitFilterStatusChanged(_ status: FilterStatus) {
        NotificationCenter.default.post(
            name: NSNotification.Name(EventList.FilterStatusChanged.name),
            object: status,
            userInfo: nil
        )
    }
    
    func emitNetworkFilterFlow(_ flow: NEFilterFlow, allowed: Bool) {
        NotificationCenter.default.post(
            name: NSNotification.Name(EventList.NetWorkFilterFlow.name),
            object: FlowWrapper(flow: flow, allowed: allowed),
            userInfo: nil
        )
    }
    
    func onNetworkFilterFlow(_ callback: @escaping (_ e: FirewallEvent) -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(EventList.NetWorkFilterFlow.name),
            object: nil,
            queue: .main,
            using: { notification in
                let wrapper = notification.object as! FlowWrapper
                let flow = wrapper.flow
                
                callback(FirewallEvent(
                    address: flow.getHostname(),
                    port: flow.getLocalPort(),
                    sourceAppIdentifier: flow.getAppId(),
                    status: wrapper.allowed ? .allowed : .rejected,
                    direction: flow.direction
                ))
            })
    }
    
    func onFilterStatusChanged(_ callback: @escaping (_ e: FilterStatus) -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(EventList.FilterStatusChanged.name),
            object: nil,
            queue: .main,
            using: { notification in
                let status = notification.object as! FilterStatus
                callback(status)
            })
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
