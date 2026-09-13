import MagicCore
import MagicUI
import ProviderPersistence
import SwiftUI

struct BtnOpenDataFolder: View {
    var body: some View {
        MagicButton.simple(action: {
            let folder = PersistenceConfig.databaseFolder
            NSWorkspace.shared.open(folder)
        })
        .magicIcon(.iconSettings)
        .magicTitle("打开数据目录")
        .magicSize(.auto)
        .frame(width: 150)
        .frame(height: 50)
    }
}

#Preview {
    BtnOpenDataFolder()
}
