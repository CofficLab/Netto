import Foundation
import SwiftUI

struct SystemApps {
    static let dns = SmartApp(
        id: ".com.apple.mDNSResponder",
        name: "DNS服务",
        icon: IconHelper.createSystemIcon(
            iconName: "DNS",
            gradientColors: [Color.blue.opacity(0.6), Color.cyan],
            isSystemIcon: false
        ),
        isSystemApp: true
    )

    static let ampDeviceDiscovery = SmartApp(
        id: ".com.apple.AMPDeviceDiscoveryAgent",
        name: "设备发现代理",
        icon: IconHelper.createSystemIcon(
            iconName: "bonjour",
            gradientColors: [Color.orange.opacity(0.8), Color.orange]
        ),
        isSystemApp: true
    )

    static let aiAgent = SmartApp(
        id: ".ai-agent",
        name: "AI 代理",
        icon: IconHelper.createSystemIcon(
            iconName: "brain.head.profile",
            gradientColors: [Color.purple.opacity(0.8), Color.purple]
        ),
        isSystemApp: true
    )

    static let geod = SmartApp(
        id: ".com.apple.geod",
        name: "地理位置服务",
        icon: IconHelper.createSystemIcon(
            iconName: "location",
            gradientColors: [Color.red.opacity(0.8), Color.red]
        ),
        isSystemApp: true
    )

    static let airPlayHelper = SmartApp(
        id: ".com.apple.AirPlayXPCHelper",
        name: "AirPlay 助手",
        icon: IconHelper.createSystemIcon(
            iconName: "airplayvideo.circle",
            gradientColors: [Color.blue.opacity(0.8), Color.blue]
        ),
        isSystemApp: true
    )

    static let gitRemoteHttp = SmartApp(
        id: ".com.apple.git-remote-http",
        name: "Git 远程助手",
        icon: IconHelper.createSystemIcon(
            iconName: "network",
            gradientColors: [Color.green.opacity(0.8), Color.green]
        ),
        isSystemApp: true
    )

    static let usbmuxd = SmartApp(
        id: ".com.apple.usbmuxd",
        name: "USB多路复用守护进程",
        icon: IconHelper.createSystemIcon(
            iconName: "cable.connector",
            gradientColors: [Color.gray.opacity(0.8), Color.gray]
        ),
        isSystemApp: true
    )

    static let cloudd = SmartApp(
        id: ".com.apple.cloudd",
        name: "iCloud守护进程",
        icon: IconHelper.createSystemIcon(
            iconName: "icloud",
            gradientColors: [Color.cyan.opacity(0.8), Color.blue]
        ),
        isSystemApp: true
    )

    static let shortcuts = SmartApp(
        id: ".com.apple.shortcuts",
        name: "快捷指令",
        icon: IconHelper.createSystemIcon(
            iconName: "bolt.circle",
            gradientColors: [Color.yellow.opacity(0.8), Color.orange]
        ),
        isSystemApp: true
    )

    static let bird = SmartApp(
        id: ".com.apple.bird",
        name: "系统鸟类服务",
        icon: IconHelper.createSystemIcon(
            iconName: "bird",
            gradientColors: [Color.mint.opacity(0.8), Color.teal]
        ),
        isSystemApp: true
    )

    static let helpd = SmartApp(
        id: ".com.apple.helpd",
        name: "帮助守护进程",
        icon: IconHelper.createSystemIcon(
            iconName: "questionmark.circle",
            gradientColors: [Color.indigo.opacity(0.8), Color.purple]
        ),
        isSystemApp: true
    )

    static let gitRemoteHttpAlt = SmartApp(
        id: ".git-remote-http",
        name: "Git远程HTTP",
        icon: IconHelper.createSystemIcon(
            iconName: "arrow.up.arrow.down.circle",
            gradientColors: [Color.brown.opacity(0.8), Color.orange]
        ),
        isSystemApp: true
    )

    static let ssh = SmartApp(
        id: ".com.apple.ssh",
        name: "SSH服务",
        icon: IconHelper.createSystemIcon(
            iconName: "terminal",
            gradientColors: [Color.black.opacity(0.8), Color.gray]
        ),
        isSystemApp: true
    )

    static let timed = SmartApp(
        id: ".com.apple.timed",
        name: "时间守护进程",
        icon: IconHelper.createSystemIcon(
            iconName: "clock",
            gradientColors: [Color.pink.opacity(0.8), Color.red]
        ),
        isSystemApp: true
    )

    static let netbiosd = SmartApp(
        id: ".com.apple.netbiosd",
        name: "NetBIOS守护进程",
        icon: IconHelper.createSystemIcon(
            iconName: "network.badge.shield.half.filled",
            gradientColors: [Color.yellow.opacity(0.8), Color.green]
        ),
        isSystemApp: true
    )

    static let ckgServer = SmartApp(
        id: ".ckg_server",
        name: "CKG服务器",
        icon: IconHelper.createSystemIcon(
            iconName: "server.rack",
            gradientColors: [Color.cyan.opacity(0.8), Color.blue]
        ),
        isSystemApp: true
    )

    static let appleAccountd = SmartApp(
        id: ".com.apple.appleaccountd",
        name: "Apple账户守护进程",
        icon: IconHelper.createSystemIcon(
            iconName: "person.circle",
            gradientColors: [Color.mint.opacity(0.8), Color.green]
        ),
        isSystemApp: true
    )

    static let node = SmartApp(
        id: ".node",
        name: "Node.js进程",
        icon: IconHelper.createSystemIcon(
            iconName: "circle.hexagongrid",
            gradientColors: [Color.green.opacity(0.8), Color.mint]
        ),
        isSystemApp: true
    )

    /// 获取系统应用
    /// - Parameter id: 应用ID
    /// - Returns: 应用
    static func getSystemApp(_ id: String) -> SmartApp? {
        switch id {
        case dns.id:
            return dns
        case ampDeviceDiscovery.id:
            return ampDeviceDiscovery
        case aiAgent.id:
            return aiAgent
        case geod.id:
            return geod
        case airPlayHelper.id:
            return airPlayHelper
        case gitRemoteHttp.id:
            return gitRemoteHttp
        case usbmuxd.id:
            return usbmuxd
        case cloudd.id:
            return cloudd
        case shortcuts.id:
            return shortcuts
        case bird.id:
            return bird
        case helpd.id:
            return helpd
        case gitRemoteHttpAlt.id:
            return gitRemoteHttpAlt
        case ssh.id:
            return ssh
        case timed.id:
            return timed
        case netbiosd.id:
            return netbiosd
        case ckgServer.id:
            return ckgServer
        case appleAccountd.id:
            return appleAccountd
        case node.id:
            return node
        default:
            return nil
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
