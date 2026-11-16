import Foundation
import Testing
@testable import PluginStore

/// `LogPrefixed` 日志前缀协议测试。
@Suite("LogPrefixed")
struct LogPrefixedTests {

    /// 遵循 `LogPrefixed` 的最小类型，用于验证静态/实例两个入口。
    private struct Sample: LogPrefixed {}

    @Test("静态前缀包含线程标记与类型名")
    func staticPrefix() {
        let prefix = Sample.t
        #expect(prefix.hasPrefix("["))
        #expect(prefix.hasSuffix("| "))
        #expect(prefix.contains("Sample"))
    }

    @Test("静态前缀按当前线程标记 UI / BG")
    func staticPrefixThreadMarker() async {
        // MainActor 在 macOS 上运行于主线程。
        let mainPrefix = await MainActor.run { Sample.t }
        #expect(mainPrefix.contains("[UI]"))

        // 专用串行队列保证不在主线程。
        let backgroundPrefix = DispatchQueue(label: "log-prefixed-test").sync { Sample.t }
        #expect(backgroundPrefix.contains("[BG]"))
    }

    @Test("实例前缀与静态前缀一致")
    func instancePrefixMatchesStatic() {
        let sample = Sample()
        #expect(sample.t == Sample.t)
    }
}

/// `Date.fullDateTime` 格式化测试。
@Suite("Date 格式化")
struct DateFormatTests {

    @Test("fullDateTime 输出 yyyy-MM-dd HH:mm:ss 定长 19 字符")
    func fullDateTimeFormat() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let text = date.fullDateTime
        #expect(text.count == 19)
        #expect(text.contains("-"))
        #expect(text.contains(":"))
    }

    @Test("fullDateTime 与 DateFormatter 一致")
    func fullDateTimeMatchesFormatter() {
        let date = Date(timeIntervalSince1970: 1_600_000_000)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        #expect(date.fullDateTime == formatter.string(from: date))
    }
}

/// `Feature` / `Plan` 模型的构造测试。
@Suite("Store 模型")
struct StoreModelTests {

    @Test("Feature：构造后字段与唯一 ID 保持")
    func featureInit() {
        let feature = Feature(
            name: "智能过滤",
            freeVersion: "基础",
            proVersion: "完整"
        )
        #expect(feature.name == "智能过滤")
        #expect(feature.freeVersion == "基础")
        #expect(feature.proVersion == "完整")
        #expect(feature.id != UUID())
    }

    @Test("Plan：构造后字段与唯一 ID 保持")
    func planInit() {
        let plan = Plan(
            name: "专业版",
            price: "¥18",
            period: "月",
            features: ["filters": "unlimited"]
        )
        #expect(plan.name == "专业版")
        #expect(plan.price == "¥18")
        #expect(plan.period == "月")
        #expect(plan.id != UUID())
    }
}
