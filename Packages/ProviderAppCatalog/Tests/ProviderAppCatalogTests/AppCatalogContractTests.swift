import Foundation
import XCTest
@testable import ProviderAppCatalog

/// 契约值类型测试。
final class AppCatalogContractTests: XCTestCase {

    func testEntryValueSemantics() throws {
        let icon = Data([0x89, 0x50, 0x4E, 0x47])
        let entry = AppCatalogEntry(identifier: "com.example", displayName: "Example", iconData: icon, isSystemApp: false)
        XCTAssertEqual(entry, AppCatalogEntry(identifier: "com.example", displayName: "Example", iconData: icon, isSystemApp: false))
        XCTAssertNotEqual(entry, AppCatalogEntry(identifier: "com.example", displayName: "Other", iconData: icon, isSystemApp: false))
        XCTAssertEqual(entry.id, "com.example")
        XCTAssertEqual(entry.iconData, icon)
    }

    func testBatchPreservesInputOrderContract() async {
        // 契约要求：entries(for:) 保留输入顺序；未知应用由实现返回 fallback，
        // 调用方不做强制解包（缺失即返回空数组以外的 fallback 条目）。
        let catalog = MockCatalog()
        let results = await catalog.entries(for: ["a", "b", "c"])
        XCTAssertEqual(results.map(\.identifier), ["a", "b", "c"])
        XCTAssertEqual(results.count, 3)
    }
}

/// 契约测试用 Mock（验证协议在无 App target 时可独立实现与构建）。
@MainActor
private final class MockCatalog: AppCatalogProviding {
    func entry(for identifier: String) async -> AppCatalogEntry {
        AppCatalogEntry(identifier: identifier, displayName: "App \(identifier)", iconData: nil, isSystemApp: false)
    }

    func entries(for identifiers: [String]) async -> [AppCatalogEntry] {
        var result: [AppCatalogEntry] = []
        for identifier in identifiers {
            result.append(await entry(for: identifier))
        }
        return result
    }

    func iconData(for identifier: String) async -> Data? { nil }
}
