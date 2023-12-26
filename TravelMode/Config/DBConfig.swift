import CloudKit
import OSLog
import SwiftData
import SwiftUI
import WebKit

struct DBConfig {
    static var dbFileName = "db_private.sqlite"

    static var label = "com.yueyi.kuaiyizhi"

    static var documentsURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
    }
    
    static var appURL: URL {
        documentsURL.appendingPathComponent("Kuaiyizhi", isDirectory: true)
    }

    var databaseFolder: URL {
        DBConfig.databaseURL.deletingLastPathComponent()
    }

    static var databaseURL: URL {
        getDatabaseURL()
    }

    private static func getDatabaseURL() -> URL {
        let fileName = dbFileName
        let databaseFolder = appURL
            .appendingPathComponent("production", isDirectory: true)
            .appendingPathComponent(fileName)
        let databaseFolderDebug = appURL
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
