import LumiUI
import ProviderPersistence
import SwiftUI

struct BtnOpenDataFolder: View {
    var body: some View {
        AppButton("打开数据目录", systemImage: "gearshape", style: .primary, fillsWidth: true, action: {
            let folder = PersistenceConfig.databaseFolder
            NSWorkspace.shared.open(folder)
        })
        .frame(width: 150)
        .frame(height: 50)
    }
}

#Preview {
    BtnOpenDataFolder()
}
