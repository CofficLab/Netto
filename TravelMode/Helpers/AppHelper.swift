import AppKit
import Foundation
import OSLog
import SwiftUI

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
        //print("getApp for \(id)")
        var workId = id

        if workId.hasPrefix(".") {
            workId = String(workId.dropFirst())
        }

        let apps = getRunningAppList()

        for app in apps {
            let bundleIdentifier = app.bundleIdentifier
            
            
            guard let bundleIdentifier = bundleIdentifier else {
                continue
            }
            
            if
                bundleIdentifier == workId ||
                bundleIdentifier == id ||
                id.hasSuffix(bundleIdentifier) {
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
