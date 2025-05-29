import Foundation
import SwiftUI

extension SmartApp {
    /// 获取系统应用
    /// - Parameter id: 应用ID
    /// - Returns: 应用
    static func getSystemApp(_ id: String) -> SmartApp? {
        return allSystemApps.first { $0.id == id }
    }
    
    static let allSystemApps: [SmartApp] = [
        // DNS服务
        SmartApp(
            id: ".com.apple.mDNSResponder",
            name: "DNS服务",
            icon: IconHelper.createSystemIcon(
                iconName: "network",
                gradientColors: [Color.blue.opacity(0.6), Color.cyan],
                isSystemIcon: false
            ),
            isSystemApp: true
        ),
        
        // 设备发现代理
        SmartApp(
            id: ".com.apple.AMPDeviceDiscoveryAgent",
            name: "设备发现代理",
            icon: IconHelper.createSystemIcon(
                iconName: "bonjour",
                gradientColors: [Color.orange.opacity(0.8), Color.orange]
            ),
            isSystemApp: true
        ),
        
        // AI 代理
        SmartApp(
            id: ".ai-agent",
            name: "AI 代理",
            icon: IconHelper.createSystemIcon(
                iconName: "brain.head.profile",
                gradientColors: [Color.purple.opacity(0.8), Color.purple]
            ),
            isSystemApp: true
        ),
        
        // 地理位置服务
        SmartApp(
            id: ".com.apple.geod",
            name: "地理位置服务",
            icon: IconHelper.createSystemIcon(
                iconName: "location",
                gradientColors: [Color.red.opacity(0.8), Color.red]
            ),
            isSystemApp: true
        ),
        
        // AirPlay 助手
        SmartApp(
            id: ".com.apple.AirPlayXPCHelper",
            name: "AirPlay 助手",
            icon: IconHelper.createSystemIcon(
                iconName: "airplayvideo.circle",
                gradientColors: [Color.blue.opacity(0.8), Color.blue]
            ),
            isSystemApp: true
        ),
        
        // Git 远程助手
        SmartApp(
            id: ".com.apple.git-remote-http",
            name: "Git 远程助手",
            icon: IconHelper.createSystemIcon(
                iconName: "network",
                gradientColors: [Color.green.opacity(0.8), Color.green]
            ),
            isSystemApp: true
        ),
        
        // USB多路复用守护进程
        SmartApp(
            id: ".com.apple.usbmuxd",
            name: "USB多路复用守护进程",
            icon: IconHelper.createSystemIcon(
                iconName: "cable.connector",
                gradientColors: [Color.gray.opacity(0.8), Color.gray]
            ),
            isSystemApp: true
        ),
        
        // iCloud守护进程
        SmartApp(
            id: ".com.apple.cloudd",
            name: "iCloud守护进程",
            icon: IconHelper.createSystemIcon(
                iconName: "icloud",
                gradientColors: [Color.cyan.opacity(0.8), Color.blue]
            ),
            isSystemApp: true
        ),
        
        // 快捷指令
        SmartApp(
            id: ".com.apple.shortcuts",
            name: "快捷指令",
            icon: IconHelper.createSystemIcon(
                iconName: "bolt.circle",
                gradientColors: [Color.yellow.opacity(0.8), Color.orange]
            ),
            isSystemApp: true
        ),
        
        // 系统鸟类服务
        SmartApp(
            id: ".com.apple.bird",
            name: "系统鸟类服务",
            icon: IconHelper.createSystemIcon(
                iconName: "bird",
                gradientColors: [Color.mint.opacity(0.8), Color.teal]
            ),
            isSystemApp: true
        ),
        
        // 帮助守护进程
        SmartApp(
            id: ".com.apple.helpd",
            name: "帮助守护进程",
            icon: IconHelper.createSystemIcon(
                iconName: "questionmark.circle",
                gradientColors: [Color.indigo.opacity(0.8), Color.purple]
            ),
            isSystemApp: true
        ),
        
        // Git远程HTTP
        SmartApp(
            id: ".git-remote-http",
            name: "Git远程HTTP",
            icon: IconHelper.createSystemIcon(
                iconName: "arrow.up.arrow.down.circle",
                gradientColors: [Color.brown.opacity(0.8), Color.orange]
            ),
            isSystemApp: true
        ),
        
        // SSH服务
        SmartApp(
            id: ".com.apple.ssh",
            name: "SSH服务",
            icon: IconHelper.createSystemIcon(
                iconName: "terminal",
                gradientColors: [Color.black.opacity(0.8), Color.gray]
            ),
            isSystemApp: true
        ),
        
        // 时间守护进程
        SmartApp(
            id: ".com.apple.timed",
            name: "时间守护进程",
            icon: IconHelper.createSystemIcon(
                iconName: "clock",
                gradientColors: [Color.pink.opacity(0.8), Color.red]
            ),
            isSystemApp: true
        ),
        
        // NetBIOS守护进程
        SmartApp(
            id: ".com.apple.netbiosd",
            name: "NetBIOS守护进程",
            icon: IconHelper.createSystemIcon(
                iconName: "network.badge.shield.half.filled",
                gradientColors: [Color.yellow.opacity(0.8), Color.green]
            ),
            isSystemApp: true
        ),
        
        // CKG服务器
        SmartApp(
            id: ".ckg_server",
            name: "CKG服务器",
            icon: IconHelper.createSystemIcon(
                iconName: "server.rack",
                gradientColors: [Color.cyan.opacity(0.8), Color.blue]
            ),
            isSystemApp: true
        ),
        
        // Apple账户守护进程
        SmartApp(
            id: ".com.apple.appleaccountd",
            name: "Apple账户守护进程",
            icon: IconHelper.createSystemIcon(
                iconName: "person.circle",
                gradientColors: [Color.mint.opacity(0.8), Color.green]
            ),
            isSystemApp: true
        ),
        
        // Node.js进程
        SmartApp(
            id: ".node",
            name: "Node.js进程",
            icon: IconHelper.createSystemIcon(
                iconName: "circle.hexagongrid",
                gradientColors: [Color.green.opacity(0.8), Color.mint]
            ),
            isSystemApp: true
        )
    ]
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
