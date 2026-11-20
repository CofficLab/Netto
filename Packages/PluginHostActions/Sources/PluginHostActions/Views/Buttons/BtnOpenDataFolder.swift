import AppKit
import LumiUI
import SwiftUI

struct BtnOpenDataFolder: View {
    /// 数据根目录（由 `HostDataFolderPlugin` 从 `StorageProviding` 注入）。
    let directory: URL?

    var body: some View {
        AppButton("打开数据目录", systemImage: "gearshape", style: .primary, fillsWidth: true, action: {
            guard let directory else { return }
            NSWorkspace.shared.open(directory)
        })
        .frame(width: 150)
        .frame(height: 50)
    }
}

#Preview {
    BtnOpenDataFolder(directory: nil)
}
