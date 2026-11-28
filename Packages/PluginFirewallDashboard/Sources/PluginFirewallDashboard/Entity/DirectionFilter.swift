import Foundation

/// 方向筛选选项
enum DirectionFilter: String, CaseIterable {
    case all = "全部"
    case inbound = "入"
    case outbound = "出"

    var title: String {
        switch self {
        case .all: String(localized: "All")
        case .inbound: String(localized: "In")
        case .outbound: String(localized: "Out")
        }
    }
}
