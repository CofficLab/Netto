import Foundation

/// 日志前缀协议（原生实现，替代 MagicCore.SuperLog）
///
/// 为 `os_log` 输出提供统一线程与类型名前缀。
public protocol LogPrefixed {
    /// 获取带线程信息的完整日志前缀
    static var t: String { get }
}

public extension LogPrefixed {
    static var t: String {
        let name = String(describing: Self.self)
        let type = name.split(separator: "<").first.map(String.init) ?? name
        let thread = Thread.isMainThread ? "UI" : "BG"
        return "[\(thread)] | \(type) | "
    }

    /// 实例访问入口（`self.t`）
    var t: String { Self.t }
}
