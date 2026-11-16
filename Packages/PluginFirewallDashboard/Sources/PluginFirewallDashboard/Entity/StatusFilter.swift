import Foundation

/// 状态筛选选项
public enum StatusFilter: String, CaseIterable {
    case all = "全部"
    case allowed = "允许"
    case rejected = "阻止"
}
