import Foundation

enum Location: CaseIterable {
    case Boot
    case IfReady
    case InstallFilter
    case RequestNeedsUserApproval
    case EnableFilterConfiguration
    case LoadFilterConfiguration
    case SaveToPreferences
    case UserChoice
    case UserApproved
    case UserRejected
    
    var name: String {
        String(describing: self)
    }
    
    static func did(_ process: Location) -> String {
        Location.allCases.filter({
            if process == .UserApproved {
                return $0 != .UserRejected && $0 != .UserChoice
            } else if process == .UserRejected {
                return $0 != .UserApproved && $0 != .UserChoice
            } else {
                return $0 != .UserApproved && $0 != .UserRejected
            }
        }).map { location in
            return location == process ? "🚩" + location.name : location.name
        }.joined(separator: " -> ")
    }
}
