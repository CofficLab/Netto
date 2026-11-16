import Foundation
import NettoIPCContracts
import NetworkExtension
import SystemExtensions
import XCTest
@testable import PluginFirewall

/// 构造测试用的假系统扩展 Bundle（带 Info.plist）。
///
/// 生产环境由 `FirewallExtensionBundle.load()` 从 App bundle 里定位扩展；
/// 单测进程没有 App bundle，这里手工造一个最小 bundle 覆盖
/// 「扩展存在」时的分支。
enum FakeExtensionBundleFactory {

    struct Descriptor {
        var bundleIdentifier: String
        var version: String
        var shortVersion: String
        var machServiceName: String?
        /// 是否写入 CFBundleVersion（缺失时 `currentExtensionVersion` 应为 nil）。
        var includesVersion: Bool = true
        var includesShortVersion: Bool = true
    }

    static func make(_ descriptor: Descriptor) -> Bundle? {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FakeExtension-\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            return nil
        }

        var info: [String: Any] = [
            "CFBundleIdentifier": descriptor.bundleIdentifier,
            "CFBundleName": "FakeExtension",
            "CFBundlePackageType": "XPC!",
        ]
        if descriptor.includesVersion {
            info["CFBundleVersion"] = descriptor.version
        }
        if descriptor.includesShortVersion {
            info["CFBundleShortVersionString"] = descriptor.shortVersion
        }
        if let machServiceName = descriptor.machServiceName {
            info["NetworkExtension"] = ["NEMachServiceName": machServiceName]
        }

        guard let data = try? PropertyListSerialization.data(
            fromPropertyList: info,
            format: .xml,
            options: 0
        ) else {
            return nil
        }
        let plistURL = directory.appendingPathComponent("Info.plist")
        guard (try? data.write(to: plistURL)) != nil else {
            return nil
        }
        return Bundle(url: directory)
    }
}

/// `SystemFirewallAdapter` 在「扩展存在」时的版本信息分支。
@MainActor
final class SystemFirewallAdapterBundleTests: XCTestCase {

    func testCurrentExtensionVersionReadsBundleInfo() {
        let bundle = FakeExtensionBundleFactory.make(.init(
            bundleIdentifier: "com.coffic.test.extension",
            version: "2.3",
            shortVersion: "2.3.1",
            machServiceName: nil
        ))
        guard let bundle else {
            return XCTFail("无法构造测试用扩展 bundle")
        }

        let adapter = SystemFirewallAdapter(extensionBundle: bundle)
        let version = adapter.currentExtensionVersion

        XCTAssertEqual(version?.version, "2.3")
        XCTAssertEqual(version?.shortVersion, "2.3.1")
        XCTAssertEqual(version?.identifier, "com.coffic.test.extension")
    }

    func testCurrentExtensionVersionIsNilWhenBundleLacksVersion() {
        let bundle = FakeExtensionBundleFactory.make(.init(
            bundleIdentifier: "com.coffic.test.extension",
            version: "",
            shortVersion: "",
            machServiceName: nil,
            includesVersion: false,
            includesShortVersion: false
        ))
        guard let bundle else {
            return XCTFail("无法构造测试用扩展 bundle")
        }

        let adapter = SystemFirewallAdapter(extensionBundle: bundle)

        XCTAssertNil(adapter.currentExtensionVersion)
    }
}

/// 过滤器配置观察者对系统通知的响应。
@MainActor
final class FilterConfigurationObserverTests: XCTestCase {

    func testObserverHandlerReceivesCurrentFilterEnabledState() async {
        let adapter = SystemFirewallAdapter(extensionBundle: nil)
        let box = FilterEnabledBox()
        let received = expectation(description: "observerHandler")

        adapter.addFilterConfigurationObserver { enabled in
            box.value = enabled
            received.fulfill()
        }

        NotificationCenter.default.post(name: .NEFilterConfigurationDidChange, object: nil)

        await fulfillment(of: [received], timeout: 5)
        // 单测进程里没有启用过滤器，读取到的是系统的真实当前值。
        XCTAssertEqual(box.value, NEFilterManager.shared().isEnabled)
    }
}

/// 跨闭包传递观察结果的可变盒子。
@MainActor
final class FilterEnabledBox {
    var value: Bool?
}

/// NSXPC 适配器在「扩展存在」时的注册路径。
@MainActor
final class NSXPCAdapterWithBundleTests: XCTestCase {

    func testRegisterWithFakeBundleFailsGracefully() async {
        let bundle = FakeExtensionBundleFactory.make(.init(
            bundleIdentifier: "com.coffic.test.extension",
            version: "1.0",
            shortVersion: "1.0",
            machServiceName: "com.coffic.test.mockservice"
        ))
        guard let bundle else {
            return XCTFail("无法构造测试用扩展 bundle")
        }

        let adapter = NSXPCFirewallIPCAdapter(extensionBundle: bundle)
        // exportedAppCommunication 是弱引用，必须由测试持有强引用。
        let communication = StubAppCommunication()
        adapter.exportedAppCommunication = communication
        defer { _ = communication }

        // 测试用的 Mach service 并不存在，注册必然失败；
        // 这里验证的是「失败被收敛为 false，而不是崩溃或挂起」。
        let registered = await adapter.register()

        XCTAssertFalse(registered)

        // 失败后连接已清理，重复注销是安全的。
        adapter.unregister()
    }
}

/// 系统扩展请求提交路径。
@MainActor
final class SystemExtensionRequestSubmissionTests: XCTestCase {

    func testSubmitRequestWithFakeBundleDoesNotCrash() {
        let bundle = FakeExtensionBundleFactory.make(.init(
            bundleIdentifier: "com.coffic.test.extension",
            version: "1.0",
            shortVersion: "1.0",
            machServiceName: nil
        ))
        guard let bundle else {
            return XCTFail("无法构造测试用扩展 bundle")
        }

        let adapter = SystemFirewallAdapter(extensionBundle: bundle)

        // 扩展标识并不存在，提交后由系统异步回调失败；
        // 这里验证的是「请求能构造并提交，且不会让进程崩溃」。
        adapter.submitSystemExtensionRequest(.properties)
        adapter.submitSystemExtensionRequest(.activate)
    }
}
