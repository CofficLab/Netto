import FinderSync
import SwiftUI

struct DebugCommands: Commands {
    var body: some Commands {
        SidebarCommands()

        CommandMenu("Debug") {
            Button("Open Data Folder") {
                let folderPath = AppConfig.databaseURL.deletingLastPathComponent()

                NSWorkspace.shared.open(folderPath)
            }
            .keyboardShortcut("f", modifiers: [.shift, .option])
        }
    }
}

#Preview("APP") {
    RootView(content: {
        ContentView()
    }).frame(width: 700, height: 600)
}
