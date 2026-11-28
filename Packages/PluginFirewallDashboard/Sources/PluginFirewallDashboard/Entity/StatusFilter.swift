import Foundation

/// 状态筛选选项
public enum StatusFilter: String, CaseIterable {
    case all = "全部"
    case allowed = "允许"
    case rejected = "阻止"

    public var title: String {
        switch self {
        case .all: String(localized: "All")
        case .allowed: String(localized: "Allow")
        case .rejected: String(localized: "Block")
        }
    }
}
