import FinderSync
import SwiftUI

struct DebugCommands: Commands {
    var body: some Commands {
        SidebarCommands()

        CommandMenu("调试") {
            Button("打开数据文件夹") {
                let folderPath = DBConfig.databaseURL.deletingLastPathComponent()

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
