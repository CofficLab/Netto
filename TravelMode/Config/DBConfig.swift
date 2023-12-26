import CloudKit
import OSLog
import SwiftData
import SwiftUI
import WebKit

struct DBConfig {
    static var dbFileName = "db.sqlite"
    static var label = "com.yueyi.TravelMode"
    
    static var documentsURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
    }
    
    static var databaseFolder: URL {
        DBConfig.databaseURL.deletingLastPathComponent()
    }
    
    static var databaseURL: URL {
        getDatabaseURL()
    }
    
    private static func getDatabaseURL() -> URL {
        let fileName = dbFileName
        let databaseFolder = databaseFolder
            .appendingPathComponent("production", isDirectory: true)
            .appendingPathComponent(fileName)
        let databaseFolderDebug = databaseFolder
            .appendingPathComponent("debug", isDirectory: true)
            .appendingPathComponent(fileName)

        #if DEBUG
            return databaseFolderDebug
        #else
            return databaseFolder
        #endif
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
