import Foundation
import XCTest
@testable import PluginFirewall

@MainActor
final class AppNetworkSpeedMonitorTests: XCTestCase {
    func testIngestNormalizesElapsedAndSortsByTotalSpeed() {
        let monitor = AppNetworkSpeedMonitor()

        monitor.ingest([
            AppNetworkSpeedMonitor.Sample(appId: "slower", bytesIn: 1024, bytesOut: 0, elapsed: 1),
            AppNetworkSpeedMonitor.Sample(appId: "faster", bytesIn: 4096, bytesOut: 0, elapsed: 1),
        ])

        XCTAssertEqual(monitor.snapshot.map(\.appId), ["faster", "slower"])
        XCTAssertEqual(monitor.snapshot[0].downloadBytesPerSecond, 4096, accuracy: 0.001)

        let monitor2 = AppNetworkSpeedMonitor()
        monitor2.ingest([
            AppNetworkSpeedMonitor.Sample(appId: "twoSeconds", bytesIn: 2048, bytesOut: 0, elapsed: 2),
        ])
        XCTAssertEqual(monitor2.snapshot.first?.downloadBytesPerSecond ?? 0, 1024, accuracy: 0.001)
    }

    func testSmoothingWindowAveragesAndDecaysToEmpty() {
        let monitor = AppNetworkSpeedMonitor()

        monitor.ingest([
            AppNetworkSpeedMonitor.Sample(appId: "app", bytesIn: 3000, bytesOut: 0, elapsed: 1),
        ])
        XCTAssertEqual(monitor.snapshot.first?.downloadBytesPerSecond ?? 0, 3000, accuracy: 0.001)

        // 空闲 tick 上报空数组：窗口补零，均值下降。
        monitor.ingest([])
        XCTAssertEqual(monitor.snapshot.first?.downloadBytesPerSecond ?? 0, 1500, accuracy: 0.001)

        monitor.ingest([])
        XCTAssertEqual(monitor.snapshot.first?.downloadBytesPerSecond ?? 0, 1000, accuracy: 0.001)

        // 窗口内全零后应用从快照移除。
        monitor.ingest([])
        XCTAssertTrue(monitor.snapshot.isEmpty)
    }

    func testObserveYieldsCurrentSnapshotAndUpdates() async {
        let monitor = AppNetworkSpeedMonitor()
        monitor.ingest([
            AppNetworkSpeedMonitor.Sample(appId: "first", bytesIn: 1024, bytesOut: 0, elapsed: 1),
        ])

        var iterator = monitor.observe().makeAsyncIterator()
        let initial = await iterator.next()
        XCTAssertEqual(initial?.first?.appId, "first")

        monitor.ingest([
            AppNetworkSpeedMonitor.Sample(appId: "second", bytesIn: 2048, bytesOut: 0, elapsed: 1),
        ])
        let update = await iterator.next()
        XCTAssertEqual(update?.first?.appId, "second")
    }

    func testPromptBridgeParsesTrafficDictionaries() async throws {
        let monitor = AppNetworkSpeedMonitor()
        let bridge = PromptUserBridge(controller: nil, speedMonitor: monitor)

        let samples: NSArray = [
            ["appId": "com.example.app", "bytesIn": 1024, "bytesOut": 512, "elapsed": 1.0],
            ["appId": "", "bytesIn": 999, "bytesOut": 999, "elapsed": 1.0],
        ]
        bridge.reportNetworkTraffic(samples)

        // 桥接内部通过 Task { @MainActor } 跳转，让出主线程等待到达。
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(monitor.snapshot.count, 1)
        let speed = try XCTUnwrap(monitor.snapshot.first)
        XCTAssertEqual(speed.appId, "com.example.app")
        XCTAssertEqual(speed.downloadBytesPerSecond, 1024, accuracy: 0.001)
        XCTAssertEqual(speed.uploadBytesPerSecond, 512, accuracy: 0.001)
    }
}
