import Foundation
import XCTest
@testable import ProviderAppSettings

/// 契约值类型测试：Snapshot 值语义、变更通知。
final class AppSettingsContractTests: XCTestCase {

    func testSnapshotEquatableAndIdentifiable() {
        let a = AppSettingSnapshot(appId: "com.example", allowed: false)
        let b = AppSettingSnapshot(appId: "com.example", allowed: false)
        let c = AppSettingSnapshot(appId: "com.example", allowed: true)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        XCTAssertEqual(a.id, "com.example")
    }

    func testChangeValues() {
        XCTAssertEqual(AppSettingsChange.didAllow(appId: "x"), .didAllow(appId: "x"))
        XCTAssertNotEqual(AppSettingsChange.didAllow(appId: "x"), .didDeny(appId: "x"))
    }
}
