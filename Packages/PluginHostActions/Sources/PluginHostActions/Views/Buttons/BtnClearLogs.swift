import SwiftUI
import OSLog
import MagicCore
import MagicUI
import ProviderShell
import ProviderFirewallEvents
import ProviderViewEnvironment

/// 清空所有日志（DEBUG 设置入口）
/// 阶段 6 迁移：经 `FirewallEventsProviding` 契约删除（替代 EventRepo.shared），
/// 结果经 Shell Toast 呈现（替代 MagicMessageProvider.shared）。
struct BtnClearLogs: View {
    @Environment(\.eventsProvider) private var events: FirewallEventsProviding?
    @EnvironmentObject private var shell: ShellCenter

    var body: some View {
        MagicButton.simple(action: {
            guard let events else { return }
            Task {
                do {
                    let deleted = try await events.deleteAll()
                    os_log("🧹 已清空日志: 删除 \(deleted) 条记录")
                    shell.post(ToastMessage(description: "已删除 \(deleted) 条记录"))
                } catch {
                    os_log("❌ 清空日志失败: \(error.localizedDescription)")
                    shell.postError(error.localizedDescription)
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

// MARK: - Preview

#Preview("App - Large") {
    BtnClearLogs()
        .environmentObject(ShellCenter())
        .frame(width: 260, height: 100)
}

#Preview("App - Small") {
    BtnClearLogs()
        .environmentObject(ShellCenter())
        .frame(width: 260, height: 100)
}
