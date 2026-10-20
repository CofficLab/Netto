import Foundation
import Testing
@testable import PluginFirewallDashboard

/// 代理软件识别测试。
///
/// `isProxyApp(withId:)` 在应用未运行时退化为纯字符串关键词匹配，
/// 这条路径是确定性的，可稳定断言；运行中路径依赖 `NSWorkspace`，不做断言。
@Suite("代理软件识别")
struct SmartAppProxyTests {

    // MARK: - 关键词命中（未运行应用的退化路径）

    @Test("命中关键词的 id 被判为代理")
    func detectsProxyKeywords() {
        // 只列「关键词表」覆盖的 id：精确匹配表（如 Wireshark、Charles）只在
        // 应用处于运行中时才生效，依赖 NSWorkspace，会让断言随开发机环境漂移。
        for id in [
            "com.expressvpn.ExpressVPN",
            "com.nordvpn.osx",
            "com.qiuyuzhou.ShadowsocksX-NG",
            "com.west2online.ClashX",
            "com.nssurge.surge-mac",
            "net.openvpn.connect.app",
            "org.torproject.torbrowser",
            "com.proxyman.NSProxy",
        ] {
            #expect(SmartApp.isProxyApp(withId: id), "\(id) 应识别为代理软件")
        }
    }

    @Test("关键词匹配大小写不敏感")
    func keywordMatchIsCaseInsensitive() {
        #expect(SmartApp.isProxyApp(withId: "COM.NORDVPN.OSX"))
        #expect(SmartApp.isProxyApp(withId: "MyCompany-VPN-Client"))
    }

    @Test("常规应用不被误判为代理")
    func ignoresRegularApps() {
        for id in [
            "com.apple.Safari",
            "com.apple.finder",
            "com.microsoft.Excel",
            "com.apple.Terminal",
            "com.coffic.netto",
        ] {
            #expect(!SmartApp.isProxyApp(withId: id), "\(id) 不应被识别为代理软件")
        }
    }

    @Test("空 id 不被判为代理")
    func emptyIdIsNotProxy() {
        #expect(!SmartApp.isProxyApp(withId: ""))
    }
}
