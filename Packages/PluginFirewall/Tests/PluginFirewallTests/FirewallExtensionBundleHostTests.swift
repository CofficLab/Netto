import Foundation
import XCTest
@testable import PluginFirewall

/// 系统扩展 Bundle 定位的宿主目录分支测试。
///
/// ## 可达性说明
/// 生产装配里宿主固定为 `Bundle.main.bundleURL`（App bundle），系统扩展目录
/// `Contents/Library/SystemExtensions` 随 App 一起打包，单测进程（xctest runner）
/// 里不存在该目录，因此「扩展已存在」的分支原本不可达。
/// 生产实现已把宿主 bundle URL 抽为 `load(inHostBundleURL:)` 入参，
/// 本文件用临时目录构造假的 App bundle 覆盖该分支。
final class FirewallExtensionBundleHostTests: XCTestCase {

    /// 构造一个临时目录，返回其 URL。
    private func makeTempDirectory(named name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("NettoFirewallBundleTest-\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }
        return url
    }

    /// 在指定目录下写入一个带 Info.plist 的扩展 bundle 目录。
    @discardableResult
    private func makeExtensionBundle(in extensionsDirectory: URL, named name: String = "FakeExtension.bundle") throws -> URL {
        let bundleURL = extensionsDirectory.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        let info: [String: Any] = [
            "CFBundleIdentifier": "com.coffic.test.extension",
            "CFBundleName": "FakeExtension",
            "CFBundlePackageType": "XPC!",
            "CFBundleVersion": "1.0",
            "CFBundleShortVersionString": "1.0",
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: bundleURL.appendingPathComponent("Info.plist"))
        return bundleURL
    }

    func testLoadReturnsNilWhenHostIsNotAppAndDirectoryMissing() throws {
        let host = try makeTempDirectory(named: "NotAnApp")

        let bundle = FirewallExtensionBundle.load(inHostBundleURL: host)

        XCTAssertNil(bundle, "非 App 宿主且没有系统扩展目录时应降级返回 nil")
    }

    func testLoadReturnsNilWhenHostIsNotAppAndDirectoryIsEmpty() throws {
        let host = try makeTempDirectory(named: "NotAnAppEmpty")
        let extensionsDirectory = host
            .appendingPathComponent("Contents/Library/SystemExtensions", isDirectory: true)
        try FileManager.default.createDirectory(at: extensionsDirectory, withIntermediateDirectories: true)

        let bundle = FirewallExtensionBundle.load(inHostBundleURL: host)

        XCTAssertNil(bundle, "非 App 宿主且扩展目录为空时应降级返回 nil")
    }

    func testLoadFindsExtensionBundleInsideAppHost() throws {
        let host = try makeTempDirectory(named: "FakeApp")
        let extensionsDirectory = host
            .appendingPathComponent("Contents/Library/SystemExtensions", isDirectory: true)
        try FileManager.default.createDirectory(at: extensionsDirectory, withIntermediateDirectories: true)
        let expected = try makeExtensionBundle(in: extensionsDirectory)

        let bundle = FirewallExtensionBundle.load(inHostBundleURL: host)

        XCTAssertNotNil(bundle, "App 宿主下应定位到系统扩展 bundle")
        XCTAssertEqual(bundle?.bundleIdentifier, "com.coffic.test.extension")
        XCTAssertEqual(bundle?.bundleURL.standardizedFileURL, expected.standardizedFileURL)
    }

    func testLoadSkipsHiddenEntriesWhenPickingExtension() throws {
        let host = try makeTempDirectory(named: "FakeAppHidden")
        let extensionsDirectory = host
            .appendingPathComponent("Contents/Library/SystemExtensions", isDirectory: true)
        try FileManager.default.createDirectory(at: extensionsDirectory, withIntermediateDirectories: true)
        // 隐藏目录被 .skipsHiddenFiles 过滤，不应被当成扩展。
        try FileManager.default.createDirectory(
            at: extensionsDirectory.appendingPathComponent(".hidden", isDirectory: true),
            withIntermediateDirectories: true
        )
        let expected = try makeExtensionBundle(in: extensionsDirectory)

        let bundle = FirewallExtensionBundle.load(inHostBundleURL: host)

        XCTAssertEqual(bundle?.bundleURL.standardizedFileURL, expected.standardizedFileURL)
    }
}
