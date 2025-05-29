import Foundation
import SwiftUI

struct SystemApps {
    static let dns = SmartApp(
        id: ".com.apple.mDNSResponder",
        name: "DNS服务",
        icon: ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.cyan]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            Image("DNS")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(6)
        },
        isSystemApp: true
    )

    static let ampDeviceDiscovery = SmartApp(
        id: ".com.apple.AMPDeviceDiscoveryAgent",
        name: "设备发现代理",
        icon: ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            Image(systemName: "bonjour")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(6)
                .foregroundColor(.white)
        },
        isSystemApp: true)

    static let aiAgent = SmartApp(
        id: ".ai-agent",
        name: "AI 代理",
        icon: ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.purple]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            Image(systemName: "brain.head.profile")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(6)
                .foregroundColor(.white)
        },
        isSystemApp: true
    )

    static let geod = SmartApp(
        id: ".com.apple.geod",
        name: "地理位置服务",
        icon: ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            Image(systemName: "location")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(6)
                .foregroundColor(.white)
        },
        isSystemApp: true)

    static let airPlayHelper = SmartApp(
        id: ".com.apple.AirPlayXPCHelper",
        name: "AirPlay 助手",
        icon: ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            Image(systemName: "airplay")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(6)
                .foregroundColor(.white)
        },
        isSystemApp: true)

    static let gitRemoteHttp = SmartApp(
        id: ".com.apple.git-remote-http",
        name: "Git 远程助手",
        icon: ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            Image(systemName: "network")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(6)
                .foregroundColor(.white)
        },
        isSystemApp: true)

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
