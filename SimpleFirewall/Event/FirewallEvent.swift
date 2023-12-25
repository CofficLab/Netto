import Foundation

struct FirewallEvent: Hashable {
    var time: Date = .now
    var address: String
    var port: String
    
    var timeFormatted: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: self.time)
    }
    
    var description: String {
        "\(address):\(port)"
    }
}
