import Foundation
import NetworkExtension
import SwiftData
import SwiftUI
import OSLog

final class EventManager: ObservableObject {
    static let shared = EventManager()
    private init() {}
    
    
    
    enum EventList {
        case FilterStatusChanged
        case NeedApproval
        case WaitingForApproval
        case PermissionDenied
        case ProviderSaid
        case NetWorkFilterFlow
        
        var name: String {
            String(describing: self)
        }
    }
    
    func emitProviderSaid(_ words: String) {
        os_log("provider said: \(words)")
        NotificationCenter.default.post(
            name: NSNotification.Name(EventList.WaitingForApproval.name),
            object: words,
            userInfo: nil
        )
    }
    
    func emitWaitingForApproval() {
        NotificationCenter.default.post(
            name: NSNotification.Name(EventList.WaitingForApproval.name),
            object: nil,
            userInfo: nil
        )
    }
    
    func emitPermissionDenied() {
        NotificationCenter.default.post(
            name: NSNotification.Name(EventList.PermissionDenied.name),
            object: nil,
            userInfo: nil
        )
    }
    
    func emitFilterStatusChanged(_ status: FilterStatus) {
        NotificationCenter.default.post(
            name: NSNotification.Name(EventList.FilterStatusChanged.name),
            object: status,
            userInfo: nil
        )
    }
    
    func emitNeedApproval() {
        NotificationCenter.default.post(
            name: NSNotification.Name(EventList.NeedApproval.name),
            object: nil,
            userInfo: nil
        )
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
    
    func onNeedApproval(_ callback: @escaping () -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(EventList.NeedApproval.name),
            object: nil,
            queue: .main,
            using: { _ in
                callback()
            })
    }
    
    func onWaitingForApproval(_ callback: @escaping () -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(EventList.WaitingForApproval.name),
            object: nil,
            queue: .main,
            using: { _ in
                callback()
            })
    }
    
    func onPermissionDenied(_ callback: @escaping () -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(EventList.PermissionDenied.name),
            object: nil,
            queue: .main,
            using: { _ in
                callback()
            })
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
