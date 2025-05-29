import Foundation
import NetworkExtension
import MagicCore

struct FirewallEvent: Hashable, Identifiable {
    enum Status {
        case allowed
        case rejected
    }
    
    var id: String = UUID().uuidString
    var time: Date = .now
    var address: String
    var port: String
    var sourceAppIdentifier: String = ""
    var status: Status
    var direction: NETrafficDirection
    
    var isAllowed: Bool {
        status == .allowed
    }
    
    var timeFormatted: String {
        self.time.compactDateTime
    }
    
    var description: String {
        "\(address):\(port)"
    }
    
    var statusDescription: String {
        switch status {
        case .allowed:
            "允许"
        case .rejected:
            "阻止"
        }
    }
}
