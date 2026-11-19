import Testing
@testable import PluginFirewallDashboard

@Suite("网速格式化")
struct NetworkSpeedFormatTests {
    @Test("B/s")
    func bytesPerSecond() {
        #expect(NetworkSpeedFormatter.format(0) == "0 B/s")
        #expect(NetworkSpeedFormatter.format(999) == "999 B/s")
    }

    @Test("KB/s 与 MB/s 保留一位小数")
    func largerUnits() {
        #expect(NetworkSpeedFormatter.format(1024) == "1.0 KB/s")
        #expect(NetworkSpeedFormatter.format(1536) == "1.5 KB/s")
        #expect(NetworkSpeedFormatter.format(1024 * 1024) == "1.0 MB/s")
        #expect(NetworkSpeedFormatter.format(2.5 * 1024 * 1024 * 1024) == "2.5 GB/s")
    }

    @Test("行内紧凑格式")
    func compactUnits() {
        #expect(NetworkSpeedFormatter.compactFormat(0) == "0B")
        #expect(NetworkSpeedFormatter.compactFormat(840 * 1024) == "840K")
        #expect(NetworkSpeedFormatter.compactFormat(1.2 * 1024 * 1024) == "1.2M")
    }
}
