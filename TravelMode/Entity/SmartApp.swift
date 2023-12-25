import Foundation
import SwiftUI
import AppKit

struct SmartApp: Identifiable {
    var id: String
    var name: String
    var icon: NSImage? = nil
    var events: [FirewallEvent] = []
    var image: some View {
        ZStack {
            if let i = icon {
                Image(nsImage: i).resizable()
            } else {
                Image("dot_yellow").scaleEffect(0.7)
            }
        }
    }
    var nameView: some View {
        Text(name)
    }
    
    func appendEvent(_ e: FirewallEvent) -> Self {
        var cloned = self
        cloned.events.append(e)
        
        return cloned
    }
    
    static func fromId(_ id: String) -> Self {
        if let runningApp = AppHelper.getApp(id) {
            return SmartApp(
                id: runningApp.bundleIdentifier ?? "",
                name: runningApp.localizedName ?? "",
                icon: runningApp.icon ?? NSImage()
            )
        }
        
        if dnsApp.id == id {
            return dnsApp
        }
        
        return SmartApp(id: id, name: "未知")
    }
    
    static func fromRunningApp(_ app: NSRunningApplication) -> Self {
        return SmartApp(
            id: app.bundleIdentifier ?? "-",
            name: app.localizedName ?? "-",
            icon: app.icon
        )
    }
    
    // MARK: 软件列表
    
    static let appList: [SmartApp] = AppHelper.getRunningAppList().map({
        return Self.fromRunningApp($0)
    })
    
    // MARK: 系统软件
    
    static let dnsApp = Self(id: ".com.apple.mDNSResponder", name: "DNS服务")
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
