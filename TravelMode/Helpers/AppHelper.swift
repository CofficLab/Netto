import Foundation
import AppKit
import SwiftUI
import OSLog

struct AppHelper {
    struct AppWrapper: Identifiable {
        var id: String = UUID().uuidString
        var app: NSRunningApplication
        
        var appName: String {
            app.localizedName ?? ""
        }
        var appId: String {
            app.bundleIdentifier ?? ""
        }
        var appIcon: NSImage {
            app.icon ?? NSImage()
        }
    }
    
    static func getRunningAppList() -> [NSRunningApplication] {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        return runningApps
    }
    
    static func getApp(_ id: String) -> AppWrapper? {
        var workId = id
        
        if workId.hasPrefix(".") {
            workId = String(workId.dropFirst())
        }
        
        let apps = getRunningAppList()
        
        for app in apps {
            if app.bundleIdentifier == workId || app.bundleIdentifier == id {
                return AppWrapper(app: app)
            }
        }
        
        return nil
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700)
}

