import SwiftUI
import OSLog
import MagicCore
import MagicUI
import MagicAlert

private struct BtnClearLogs: View {
    var body: some View {
        MagicButton.simple(action: {
            Task {
                do {
                    let deleted = try await EventRepo.shared.deleteAll()
                    os_log("🧹 已清空日志: 删除 \(deleted) 条记录")
                    MagicMessageProvider.shared.success("已删除 \(deleted) 条记录")
                } catch {
                    os_log("❌ 清空日志失败: \(error.localizedDescription)")
                }
            }
        })
        .magicIcon(.iconTrash)
        .magicTitle("清空所有日志")
        .magicSize(.auto)
        .frame(width: 180)
        .frame(height: 44)
    }
}

actor ClearLogsButtonPlugin: SuperPlugin {
    nonisolated let label: String = "ClearLogsButton"

    @MainActor
    func addToolBarButtons() -> [(id: String, view: AnyView)] { [] }

    @MainActor
    func addSettingsButtons() -> [(id: String, view: AnyView)] {
        #if DEBUG
        [ (id: "clear-logs", view: AnyView(BtnClearLogs())) ]
        #else
        []
        #endif
    }
}

@objc(ClearLogsButtonRegistrant)
class ClearLogsButtonRegistrant: NSObject, PluginRegistrant {
    static func register() {
        Task { await PluginRegistry.shared.register(id: "ClearLogsButton", order: 35) { ClearLogsButtonPlugin() } }
    }
}

// MARK: - Preview

#Preview("App - Large") {
    ContentView()
        .inRootView()
        .frame(width: 600, height: 1000)
}

#Preview("App - Small") {
    ContentView()
        .inRootView()
        .frame(width: 600, height: 600)
}
