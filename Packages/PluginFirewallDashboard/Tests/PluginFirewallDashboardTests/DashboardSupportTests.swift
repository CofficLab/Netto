import Foundation
import Testing
@testable import PluginFirewallDashboard

/// 筛选枚举与日期格式化测试。
@Suite("Dashboard 支撑类型")
struct DashboardSupportTests {

    // MARK: - 筛选枚举

    @Test("StatusFilter rawValue 与全部 case 稳定")
    func statusFilter() {
        #expect(StatusFilter.allCases == [.all, .allowed, .rejected])
        #expect(StatusFilter.all.rawValue == "全部")
        #expect(StatusFilter.allowed.rawValue == "允许")
        #expect(StatusFilter.rejected.rawValue == "阻止")
        // rawValue 即持久化/展示文案，不可随意改动。
        #expect(StatusFilter(rawValue: "允许") == .allowed)
        #expect(StatusFilter(rawValue: "不存在") == nil)
    }

    @Test("DirectionFilter rawValue 与全部 case 稳定")
    func directionFilter() {
        #expect(DirectionFilter.allCases == [.all, .inbound, .outbound])
        #expect(DirectionFilter.all.rawValue == "全部")
        #expect(DirectionFilter.inbound.rawValue == "入")
        #expect(DirectionFilter.outbound.rawValue == "出")
        #expect(DirectionFilter(rawValue: "入") == .inbound)
        #expect(DirectionFilter(rawValue: "出站") == nil)
    }

    @Test("DisplayType 覆盖全部/允许/阻止三种展示态")
    func displayType() {
        #expect(DisplayType.allCases.count == 3)
        #expect(DisplayType.allCases.contains(.All))
        #expect(DisplayType.allCases.contains(.Allowed))
        #expect(DisplayType.allCases.contains(.Rejected))
    }

    // MARK: - 日期格式化

    @Test("fullDateTime 输出 yyyy-MM-dd HH:mm:ss")
    func fullDateTimeFormat() {
        // 用固定时区构造，避免断言随运行机器时区漂移。
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let date = formatter.date(from: "2026-03-05 09:07:03")!
        // 生产实现使用 TimeZone.current，此处只校验“始终是合法且定长的 19 字符格式”。
        let rendered = date.fullDateTime
        let chars = Array(rendered)
        #expect(chars.count == 19)
        #expect(chars[4] == "-" && chars[7] == "-")
        #expect(chars[10] == " " && chars[13] == ":" && chars[16] == ":")
    }

    @Test("fullDateTime 对不同时间产出不同结果")
    func fullDateTimeDistinguishesDates() {
        #expect(Date(timeIntervalSince1970: 0).fullDateTime != Date().fullDateTime)
    }

    // MARK: - 日志前缀

    @Test("LogPrefixed 前缀含类型名且以分隔符收尾")
    func logPrefixShape() {
        struct Probe: LogPrefixed {}
        let prefix = Probe.t
        #expect(prefix.contains("Probe"))
        #expect(prefix.hasSuffix(" | "))
        // 线程标记由 Thread.isMainThread 推导（UI/BG），此处只校验二者之一，
        // 避免因测试线程调度差异而偶发失败。
        #expect(prefix.hasPrefix("[UI] | ") || prefix.hasPrefix("[BG] | "))
    }
}
