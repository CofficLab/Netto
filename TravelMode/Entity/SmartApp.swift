import Foundation
import SwiftUI
import AppKit

struct SmartApp: Identifiable {
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    init(id: String, name: String, icon: NSImage? = nil) {
        self.id = id
        self.name = name
        if let i = icon {
            self.icon = Image(nsImage: i).resizable()
        }
    }
    
    init(id: String, name: String, icon: Image? = nil) {
        self.id = id
        self.name = name
        self.icon = nil
        if let i = icon {
            self.icon = i.resizable()
        }
    }
    
    var id: String
    var name: String
    var icon: Image? = nil
    var events: [FirewallEvent] = []
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
        
        return SmartApp(id: id, name: "未知", icon: Image("Unknown"))
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
    
    static let dnsApp = Self(id: ".com.apple.mDNSResponder", name: "DNS服务", icon: Image("DNS"))
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}
