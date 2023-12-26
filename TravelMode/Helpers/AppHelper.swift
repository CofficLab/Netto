import AppKit
import Foundation
import OSLog
import SwiftUI

struct AppHelper {
    static func getRunningAppList() -> [NSRunningApplication] {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications

        return runningApps
    }

    static func getApp(_ id: String) -> NSRunningApplication? {
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
                id.contains(bundleIdentifier) ||
                id.hasSuffix(bundleIdentifier) {
                return app
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
