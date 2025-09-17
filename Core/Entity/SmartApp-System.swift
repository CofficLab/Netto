import Foundation
import SwiftUI

extension SmartApp {
    /// 获取系统应用
    /// - Parameter id: 应用ID
    /// - Returns: 应用
    static func getSystemApp(_ id: String) -> SmartApp? {
        // 遍历系统应用，如果找到则返回
        for app in allSystemApps {
            if app.id == id {
                return app
            }
        }
        
        // 如果没找到与定义的系统应用，但ID以.开头，表示是系统应用，返回未知的系统应用
        if id.hasPrefix(".") {
            return SmartApp(
                id: id,
                name: "未知系统应用",
                isSystemApp: true,
                hidden: true
            )
        }
        
        return nil
    }

    
    static let allSystemApps: [SmartApp] = [
        // DNS服务
        SmartApp(
            id: ".com.apple.mDNSResponder",
            name: "DNS服务",
            isSystemApp: true,
            hidden: true
        ),
        
        // 设备发现代理
        SmartApp(
            id: ".com.apple.AMPDeviceDiscoveryAgent",
            name: "设备发现代理",
            isSystemApp: true,
            hidden: true
        ),
        
        // AI 代理
        SmartApp(
            id: ".ai-agent",
            name: "AI 代理",
            isSystemApp: true,
            hidden: true
        ),
        
        // 地理位置服务
        SmartApp(
            id: ".com.apple.geod",
            name: "地理位置服务",
            isSystemApp: true,
            hidden: true
        ),
        
        // AirPlay 助手
        SmartApp(
            id: ".com.apple.AirPlayXPCHelper",
            name: "AirPlay 助手",
            isSystemApp: true,
            hidden: true
        ),
        
        // Git 远程助手
        SmartApp(
            id: ".com.apple.git-remote-http",
            name: "Git 远程助手",
            isSystemApp: true,
            hidden: true
        ),
        
        // USB多路复用守护进程
        SmartApp(
            id: ".com.apple.usbmuxd",
            name: "USB多路复用守护进程",
            isSystemApp: true,
            hidden: true
        ),
        
        // iCloud守护进程
        SmartApp(
            id: ".com.apple.cloudd",
            name: "iCloud守护进程",
            isSystemApp: true,
            hidden: false
        ),
        
        // 快捷指令
        SmartApp(
            id: ".com.apple.shortcuts",
            name: "快捷指令",
            isSystemApp: true,
            hidden: true
        ),
        
        // iCloud 数据同步和文件系统管理
        SmartApp(
            id: ".com.apple.bird",
            name: "iCloud 数据同步和文件系统管理",
            isSystemApp: true,
            hidden: false
        ),
        
        // 帮助守护进程
        SmartApp(
            id: ".com.apple.helpd",
            name: "帮助守护进程",
            isSystemApp: true,
            hidden: true
        ),
        
        // Git远程HTTP
        SmartApp(
            id: ".git-remote-http",
            name: "Git远程HTTP",
            isSystemApp: true,
            hidden: true
        ),
        
        // SSH服务
        SmartApp(
            id: ".com.apple.ssh",
            name: "SSH服务",
            isSystemApp: true,
            hidden: true
        ),
        
        // 时间守护进程
        SmartApp(
            id: ".com.apple.timed",
            name: "时间守护进程",
            isSystemApp: true,
            hidden: true
        ),
        
        // NetBIOS守护进程
        SmartApp(
            id: ".com.apple.netbiosd",
            name: "NetBIOS守护进程",
            isSystemApp: true,
            hidden: true
        ),
        
        // CKG服务器
        SmartApp(
            id: ".ckg_server",
            name: "CKG服务器",
            isSystemApp: true,
            hidden: true
        ),
        
        // Apple账户守护进程
        SmartApp(
            id: ".com.apple.appleaccountd",
            name: "Apple账户守护进程",
            isSystemApp: true,
            hidden: true
        ),
        
        // Node.js进程
        SmartApp(
            id: ".node",
            name: "Node.js进程",
            isSystemApp: true,
            hidden: true
        ),
        
        // 控制中心
        SmartApp(
            id: ".com.apple.controlcenter",
            name: "控制中心",
            isSystemApp: true,
            hidden: true
        ),
        
        // 备忘录
        SmartApp(
            id: ".com.apple.Notes",
            name: "备忘录",
            isSystemApp: true,
            hidden: false
        ),
        
        // 远程配对守护进程
        SmartApp(
            id: ".com.apple.CoreDevice.remotepairingd",
            name: "远程配对守护进程",
            isSystemApp: true,
            hidden: true
        ),
        
        // AppKit XPC 打开和保存面板服务
        SmartApp(
            id: ".com.apple.appkit.xpc.openAndSavePanelService",
            name: "AppKit XPC 打开和保存面板服务",
            isSystemApp: true,
            hidden: true
        ),
        
        // 系统策略守护进程
        SmartApp(
            id: ".com.apple.syspolicyd",
            name: "系统策略守护进程",
            isSystemApp: true,
            hidden: true
        ),
        
        // Apple推送服务守护进程
        SmartApp(
            id: ".com.apple.apsd",
            name: "Apple推送服务守护进程",
            isSystemApp: true,
            hidden: true
        ),
        
        // 配置守护进程
        SmartApp(
            id: ".com.apple.configd",
            name: "配置守护进程",
            isSystemApp: true,
            hidden: true
        ),
        
        // App Store
        SmartApp(
            id: ".com.apple.AppStore",
            name: "App Store",
            isSystemApp: true,
            hidden: false
        ),
        
        // 屏幕使用时间小组件
        SmartApp(
            id: ".com.apple.ScreenTimeWidgetApplication.ScreenTimeWidgetExtension",
            name: "屏幕使用时间（小组件）",
            isSystemApp: true,
            hidden: true
        )
    ]
}


extension SmartApp {
    /// 系统应用图标映射表
    /// - Parameter id: 系统应用ID
    /// - Returns: 对应的图标视图
    static func getSystemAppIcon(_ id: String) -> AnyView? {
        switch id {
         case ".com.apple.mDNSResponder":
             return AnyView(IconHelper.createSystemIcon(
                 iconName: "network",
                 gradientColors: [Color.blue.opacity(0.6), Color.cyan]
             ))
        case ".com.apple.AMPDeviceDiscoveryAgent":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "bonjour",
                gradientColors: [Color.orange.opacity(0.8), Color.orange]
            ))
        case ".ai-agent":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "brain.head.profile",
                gradientColors: [Color.purple.opacity(0.8), Color.purple]
            ))
        case ".com.apple.geod":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "location",
                gradientColors: [Color.red.opacity(0.8), Color.red]
            ))
        case ".com.apple.AirPlayXPCHelper":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "airplayvideo.circle",
                gradientColors: [Color.blue.opacity(0.8), Color.blue]
            ))
        case ".com.apple.git-remote-http":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "network",
                gradientColors: [Color.green.opacity(0.8), Color.green]
            ))
        case ".com.apple.usbmuxd":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "cable.connector",
                gradientColors: [Color.gray.opacity(0.8), Color.gray]
            ))
        case ".com.apple.cloudd":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "icloud",
                gradientColors: [Color.cyan.opacity(0.8), Color.blue]
            ))
        case ".com.apple.shortcuts":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "bolt.circle",
                gradientColors: [Color.yellow.opacity(0.8), Color.orange]
            ))
        case ".com.apple.bird":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "bird",
                gradientColors: [Color.mint.opacity(0.8), Color.teal]
            ))
        case ".com.apple.helpd":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "questionmark.circle",
                gradientColors: [Color.indigo.opacity(0.8), Color.purple]
            ))
        case ".git-remote-http":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "arrow.up.arrow.down.circle",
                gradientColors: [Color.brown.opacity(0.8), Color.orange]
            ))
        case ".com.apple.ssh":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "terminal",
                gradientColors: [Color.black.opacity(0.8), Color.gray]
            ))
        case ".com.apple.timed":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "clock",
                gradientColors: [Color.pink.opacity(0.8), Color.red]
            ))
        case ".com.apple.netbiosd":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "network.badge.shield.half.filled",
                gradientColors: [Color.yellow.opacity(0.8), Color.green]
            ))
        case ".ckg_server":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "server.rack",
                gradientColors: [Color.cyan.opacity(0.8), Color.blue]
            ))
        case ".com.apple.appleaccountd":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "person.circle",
                gradientColors: [Color.mint.opacity(0.8), Color.green]
            ))
        case ".node":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "circle.hexagongrid",
                gradientColors: [Color.green.opacity(0.8), Color.mint]
            ))
        case ".com.apple.controlcenter":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "switch.2",
                gradientColors: [Color.blue.opacity(0.8), Color.indigo]
            ))
        case ".com.apple.Notes":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "note.text",
                gradientColors: [Color.yellow.opacity(0.8), Color.orange]
            ))
        case ".com.apple.CoreDevice.remotepairingd":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "antenna.radiowaves.left.and.right",
                gradientColors: [Color.teal.opacity(0.8), Color.cyan]
            ))
        case ".com.apple.appkit.xpc.openAndSavePanelService":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "folder.badge.plus",
                gradientColors: [Color.blue.opacity(0.8), Color.indigo]
            ))
        case ".com.apple.syspolicyd":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "shield.checkered",
                gradientColors: [Color.red.opacity(0.8), Color.orange]
            ))
        case ".com.apple.apsd":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "bell.badge",
                gradientColors: [Color.green.opacity(0.8), Color.mint]
            ))
        case ".com.apple.configd":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "gearshape.2",
                gradientColors: [Color.gray.opacity(0.8), Color.secondary]
            ))
        case ".com.apple.AppStore":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "bag",
                gradientColors: [Color.blue.opacity(0.8), Color.cyan]
            ))
        case ".com.apple.ScreenTimeWidgetApplication.ScreenTimeWidgetExtension":
            return AnyView(IconHelper.createSystemIcon(
                iconName: "hourglass",
                gradientColors: [Color.purple.opacity(0.8), Color.indigo]
            ))
        default:
            // 未知系统应用的默认图标
            if id.hasPrefix(".") {
                return AnyView(IconHelper.createSystemIcon(
                    iconName: "questionmark.circle",
                    gradientColors: [Color.indigo.opacity(0.8), Color.purple]
                ))
            }
            return nil
        }
    }
}

/// 系统应用网格视图，用于展示所有系统应用及其图标
struct SystemAppGridView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                ForEach(SmartApp.allSystemApps) { app in
                    VStack {
                        if let iconView = SmartApp.getSystemAppIcon(app.id) {
                            iconView
                                .frame(width: 60, height: 60)
                        } else {
                            SmartApp.getDefaultIcon()
                                .frame(width: 60, height: 60)
                        }
                        
                        Text(app.name)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding()
        }
        .background(Color(.windowBackgroundColor))
        .navigationTitle("系统应用列表")
    }
}

#Preview("ContentView") {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}

#Preview("系统应用列表") {
    RootView {
        SystemAppGridView()
    }
    .frame(width: 600, height: 800)
}
