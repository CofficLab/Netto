import Foundation

extension Date {
    /// 完整日期时间字符串 "yyyy-MM-dd HH:mm:ss"（原生实现，替代 MagicCore 扩展）
    var fullDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
}
