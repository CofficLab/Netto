import CloudKit
import OSLog
import SwiftData
import SwiftUI
import WebKit

@MainActor
struct AppConfig {
    static private let fileManager = FileManager.default
    nonisolated static let dbFileName = "db.sqlite"
    nonisolated static let label = "com.yueyi.TravelMode"
    nonisolated static let appName = "TravelMode"
    
    // Window IDs
    static let welcomeWindowId = "welcome"
    
    nonisolated static var documentsURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
    }
    
    static var databaseFolder: URL {
        AppConfig.databaseURL.deletingLastPathComponent()
    }
    
    nonisolated static var databaseURL: URL {
        getDatabaseURL()
    }
    
    nonisolated private static func getDatabaseURL() -> URL {
        let fileName = dbFileName
        #if DEBUG
            let dirName = "debug"
        #else
            let dirName = "production"
        #endif
        
        var isDir: ObjCBool = true
        let dbDir = documentsURL
            .appendingPathComponent(dirName, isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: dbDir.path, isDirectory: &isDir) {
            do {
                try FileManager.default.createDirectory(atPath: dbDir.path, withIntermediateDirectories: true)
            } catch (let error) {
                fatalError("新建数据库文件夹发生错误：\(error.localizedDescription)")
            }
        }
        
        return dbDir.appendingPathComponent(fileName)
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }.frame(width: 700)
}
