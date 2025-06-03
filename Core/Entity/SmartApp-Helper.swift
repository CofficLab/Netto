import AppKit
import Foundation
import MagicCore
import OSLog
import SwiftUI

extension SmartApp: SuperLog {
    /// 获取当前系统中所有正在运行的应用程序列表
    ///
    /// - Returns: 包含所有正在运行的应用程序的数组
    static func getRunningAppList() -> [NSRunningApplication] {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications

        return runningApps
    }

    /// 根据标识符查找正在运行的应用程序
    ///
    /// - Parameter
    //      - id: 要查找的应用程序标识符
    //      - verbose: 是否输出详细日志
    /// - Returns: 找到的应用程序实例，如果未找到则返回nil
    static func getApp(_ id: String, verbose: Bool = false) -> NSRunningApplication? {
        let apps = getRunningAppList()

        for app in apps {
            guard let bundleIdentifier = app.bundleIdentifier else {
                continue
            }

            // 完全匹配情况
            if bundleIdentifier == id {
                return app
            }

            // 收集可能接近的匹配
            if id.contains(bundleIdentifier) {
                return app
            }
        }

        if verbose {
            os_log(.debug, "\(self.t)⚠️ 未找到应用程序: \(id)")
        }

        return nil
    }
    
    /// 判断应用是否为代理软件
    ///
    /// 通过检查应用的bundle identifier和名称来识别常见的代理软件
    /// - Parameter app: 要检查的应用程序实例
    /// - Returns: 如果是代理软件返回true，否则返回false
    static func isProxyApp(_ app: NSRunningApplication) -> Bool {
        guard let bundleId = app.bundleIdentifier else {
            return false
        }
        
        // 常见代理软件的bundle identifier列表
        let proxyAppIdentifiers = [
            // VPN 客户端
            "com.expressvpn.ExpressVPN",
            "com.nordvpn.osx",
            "com.surfshark.vpnclient.macos",
            "com.cyberghostvpn.mac",
            "com.privateinternetaccess.vpn",
            "com.tunnelbear.mac.TunnelBear",
            "com.protonvpn.mac",
            "com.windscribe.desktop",
            "com.hotspotshield.vpn.mac",
            
            // Shadowsocks 客户端
            "com.qiuyuzhou.ShadowsocksX-NG",
            "com.shadowsocks.ShadowsocksX-NG",
            "clowwindy.ShadowsocksX",
            "com.github.shadowsocks.ShadowsocksX-NG",
            
            // V2Ray 客户端
            "com.v2ray.V2RayU",
            "com.yanue.V2rayU",
            "com.v2rayx.V2RayX",
            "net.qiuyuzhou.V2RayX",
            
            // Clash 客户端
            "com.west2online.ClashX",
            "com.dreamacro.clash.for.windows",
            "com.clash.for.windows",
            "com.github.yichengchen.clashX",
            
            // Surge
            "com.nssurge.surge-mac",
            "com.nssurge.surge.mac",
            
            // Proxyman
            "com.proxyman.NSProxy",
            
            // Charles
            "com.xk72.Charles",
            
            // Wireshark
            "org.wireshark.Wireshark",
            
            // Proxifier
            "com.proxifier.macos",
            
            // Tor Browser
            "org.torproject.torbrowser",
            
            // Lantern
            "org.getlantern.lantern",
            
            // Psiphon
            "ca.psiphon.Psiphon",
            
            // Tunnelblick
            "net.tunnelblick.tunnelblick",
            
            // OpenVPN Connect
            "net.openvpn.connect.app",
            
            // Viscosity
            "com.viscosityvpn.Viscosity"
        ]
        
        // 检查完全匹配
        if proxyAppIdentifiers.contains(bundleId) {
            return true
        }
        
        // 检查部分匹配的关键词
        let proxyKeywords = [
            "vpn", "proxy", "shadowsocks", "v2ray", "clash", 
            "surge", "trojan", "ssr", "vmess", "vless",
            "wireguard", "openvpn", "tunnel", "tor"
        ]
        
        let lowercaseBundleId = bundleId.lowercased()
        let appName = (app.localizedName ?? "").lowercased()
        
        for keyword in proxyKeywords {
            if lowercaseBundleId.contains(keyword) || appName.contains(keyword) {
                return true
            }
        }
        
        return false
    }
    
    /// 判断应用是否为代理软件（通过应用ID）
    ///
    /// - Parameter appId: 应用程序的bundle identifier
    /// - Returns: 如果是代理软件返回true，否则返回false
    static func isProxyApp(withId appId: String) -> Bool {
        guard let app = getApp(appId) else {
            // 如果找不到运行中的应用，仍然可以通过ID进行基本判断
            let proxyKeywords = [
                "vpn", "proxy", "shadowsocks", "v2ray", "clash", 
                "surge", "trojan", "ssr", "vmess", "vless",
                "wireguard", "openvpn", "tunnel", "tor"
            ]
            
            let lowercaseId = appId.lowercased()
            for keyword in proxyKeywords {
                if lowercaseId.contains(keyword) {
                    return true
                }
            }
            return false
        }
        
        return isProxyApp(app)
    }
}

// MARK: - Preview

/// 用于展示运行中应用列表的预览视图
struct RunningAppsPreview: View {
    @State private var runningApps: [NSRunningApplication] = []

    var body: some View {
        VStack {
            Text("当前运行的应用程序")
                .font(.headline)
                .padding()

            List(runningApps, id: \.bundleIdentifier) { app in
                HStack {
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: "questionmark.app")
                            .resizable()
                            .frame(width: 32, height: 32)
                    }

                    VStack(alignment: .leading) {
                        Text(app.localizedName ?? "未知应用")
                            .font(.headline)

                        if let bundleId = app.bundleIdentifier {
                            Text(bundleId)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let bundleURL = app.bundleURL {
                            Text(bundleURL.absoluteString)
                                .font(.caption)
                                .foregroundColor(.orange.opacity(0.8))
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(width: 400, height: 600)
        .onAppear {
            runningApps = SmartApp.getRunningAppList()
        }
    }
}

#Preview {
    RunningAppsPreview()
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 600)
}
