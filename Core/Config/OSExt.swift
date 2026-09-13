import Foundation

extension AppConfig {
    static var osVersion: Int {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion
    }
}
