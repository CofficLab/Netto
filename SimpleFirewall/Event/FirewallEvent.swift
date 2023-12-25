import Foundation

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
    
    var timeFormatted: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: self.time)
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
