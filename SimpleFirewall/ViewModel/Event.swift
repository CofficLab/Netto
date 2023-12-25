import Foundation
import SwiftData
import SwiftUI
import OSLog

final class Event: ObservableObject {
    enum EventList {
        case Speak
        
        var name: String {
            String(describing: self)
        }
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
}

#Preview {
    RootView {
        ContentView()
    }
}
