import Foundation

/// 网速格式化工具：列表行与无障碍文案共用。
enum NetworkSpeedFormatter {
    /// 完整格式：B/s / KB/s / MB/s / GB/s，保留一位小数避免读数跳动过宽。
    static func format(_ bytesPerSecond: Double) -> String {
        let units = ["B/s", "KB/s", "MB/s", "GB/s"]
        var value = max(bytesPerSecond, 0)
        var unitIndex = 0
        while value >= 1024, unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        if unitIndex == 0 {
            return String(format: "%.0f %@", value, units[unitIndex])
        }
        return String(format: "%.1f %@", value, units[unitIndex])
    }

    /// 行内极简格式：`1.2M`、`840K`；单位不带 `/s`，箭头已表达网速语境。
    static func compactFormat(_ bytesPerSecond: Double) -> String {
        let units = ["B", "K", "M", "G"]
        var value = max(bytesPerSecond, 0)
        var unitIndex = 0
        while value >= 1024, unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        if unitIndex == 0 || value >= 100 {
            return String(format: "%.0f%@", value, units[unitIndex])
        }
        return String(format: "%.1f%@", value, units[unitIndex])
    }
}