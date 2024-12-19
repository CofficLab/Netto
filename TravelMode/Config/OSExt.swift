import Foundation
import SwiftUI

extension AppConfig {
    static var osVersion: Int {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }.frame(width: 700)
}
