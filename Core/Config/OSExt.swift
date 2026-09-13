import PluginFirewallDashboard
import Foundation
import SwiftUI

extension AppConfig {
    static var osVersion: Int {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion
    }
}

#Preview("APP") {
    RootView(environment: .preview()) {
        ContentView()
    }.frame(width: 700)
}
