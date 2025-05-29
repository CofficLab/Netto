import Foundation
import SwiftUI

struct SystemApps {
    
    /// 创建系统应用图标的通用函数
    /// - Parameters:
    ///   - iconName: 图标名称（SF Symbol名称或自定义图片名称）
    ///   - gradientColors: 渐变色数组，第一个为起始色，第二个为结束色
    ///   - isSystemIcon: 是否为SF Symbol图标（默认为true）
    /// - Returns: 配置好的图标视图
    private static func createSystemIcon(
        iconName: String,
        gradientColors: [Color],
        isSystemIcon: Bool = true
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            if isSystemIcon {
                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(6)
                    .foregroundColor(.white)
            } else {
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(6)
            }
        }
        .frame(width: 34, height: 34)
        .clipped()
    }
    static let dns = SmartApp(
        id: ".com.apple.mDNSResponder",
        name: "DNS服务",
        icon: createSystemIcon(
            iconName: "DNS",
            gradientColors: [Color.blue.opacity(0.6), Color.cyan],
            isSystemIcon: false
        ),
        isSystemApp: true
    )

    static let ampDeviceDiscovery = SmartApp(
        id: ".com.apple.AMPDeviceDiscoveryAgent",
        name: "设备发现代理",
        icon: createSystemIcon(
            iconName: "bonjour",
            gradientColors: [Color.orange.opacity(0.8), Color.orange]
        ),
        isSystemApp: true
    )

    static let aiAgent = SmartApp(
        id: ".ai-agent",
        name: "AI 代理",
        icon: createSystemIcon(
            iconName: "brain.head.profile",
            gradientColors: [Color.purple.opacity(0.8), Color.purple]
        ),
        isSystemApp: true
    )

    static let geod = SmartApp(
        id: ".com.apple.geod",
        name: "地理位置服务",
        icon: createSystemIcon(
            iconName: "location",
            gradientColors: [Color.red.opacity(0.8), Color.red]
        ),
        isSystemApp: true
    )

    static let airPlayHelper = SmartApp(
        id: ".com.apple.AirPlayXPCHelper",
        name: "AirPlay 助手",
        icon: createSystemIcon(
            iconName: "airplayvideo.circle",
            gradientColors: [Color.blue.opacity(0.8), Color.blue]
        ),
        isSystemApp: true
    )

    static let gitRemoteHttp = SmartApp(
        id: ".com.apple.git-remote-http",
        name: "Git 远程助手",
        icon: createSystemIcon(
            iconName: "network",
            gradientColors: [Color.green.opacity(0.8), Color.green]
        ),
        isSystemApp: true
    )

    static let usbmuxd = SmartApp(
        id: ".com.apple.usbmuxd",
        name: "USB多路复用守护进程",
        icon: createSystemIcon(
            iconName: "cable.connector",
            gradientColors: [Color.gray.opacity(0.8), Color.gray]
        ),
        isSystemApp: true
    )

    static let cloudd = SmartApp(
        id: ".com.apple.cloudd",
        name: "iCloud守护进程",
        icon: createSystemIcon(
            iconName: "icloud",
            gradientColors: [Color.cyan.opacity(0.8), Color.blue]
        ),
        isSystemApp: true
    )

    static let shortcuts = SmartApp(
        id: ".com.apple.shortcuts",
        name: "快捷指令",
        icon: createSystemIcon(
            iconName: "bolt.circle",
            gradientColors: [Color.yellow.opacity(0.8), Color.orange]
        ),
        isSystemApp: true
    )

    static let bird = SmartApp(
        id: ".com.apple.bird",
        name: "系统鸟类服务",
        icon: createSystemIcon(
            iconName: "bird",
            gradientColors: [Color.mint.opacity(0.8), Color.teal]
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
        default:
            return nil
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    })
    .frame(width: 700)
    .frame(height: 800)
}
