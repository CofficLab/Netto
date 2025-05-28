import CloudKit
import OSLog
import SwiftData
import SwiftUI
import WebKit

struct AppConfig {
    static private var fileManager = FileManager.default
    static var dbFileName = "db.sqlite"
    static var label = "com.yueyi.TravelMode"
    static var appName = "TravelMode"
    
    // Window IDs
    static let welcomeWindowId = "welcome"
    
    static var documentsURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
    }
    
    static var databaseFolder: URL {
        AppConfig.databaseURL.deletingLastPathComponent()
    }
    
    static var databaseURL: URL {
        getDatabaseURL()
    }
    
    private static func getDatabaseURL() -> URL {
        let fileName = dbFileName
        #if DEBUG
            let dirName = "debug"
        #else
            let dirName = "production"
        #endif
        
        var isDir: ObjCBool = true
        let dbDir = documentsURL            .appendingPathComponent(dirName, isDirectory: true)
        
        if !fileManager.fileExists(atPath: dbDir.path, isDirectory: &isDir) {
            do {
                try fileManager.createDirectory(atPath: dbDir.path, withIntermediateDirectories: true)
            } catch (let error) {
                fatalError("新建数据库文件夹发生错误：\(error.localizedDescription)")
            }
        }
        
        return dbDir.appendingPathComponent(fileName)
    }

    static var container: ModelContainer = {
        let schema = Schema([
            AppSetting.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: databaseURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            return container
        } catch {
            fatalError("无法创建 primaryContainer: \n\(error)")
        }
    }()
}

#Preview("APP") {
    RootView {
        ContentView()
    }.frame(width: 700)
}
