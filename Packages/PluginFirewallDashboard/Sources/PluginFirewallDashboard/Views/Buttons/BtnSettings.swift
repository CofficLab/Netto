import MagicAlert
import MagicCore
import OSLog
import PluginShell
import SwiftUI

/// 内核内置的设置按钮
/// 通过 `SettingsProviding` 获取设置入口，不再查询旧 PluginRegistry。
struct BtnSettings: View, SuperLog, SuperThread {
    @EnvironmentObject private var shell: ShellCenter
    @State private var hovered = false
    @State private var isPresented = false

    var body: some View {
        HStack {
            Image(systemName: "ellipsis")
        }
        .frame(maxHeight: .infinity)
        .onHover(perform: { hovering in
            self.hovered = hovering
        })
        .onTapGesture {
            self.isPresented.toggle()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .popover(isPresented: $isPresented, content: {
            VStack(spacing: 8) {
                // 设置入口（按 order 升序，由 ShellCenter 聚合）
                ForEach(shell.entries) { entry in
                    entry.makeView()
                }
            }
            .padding()
        })
    }
}

// MARK: - Preview

#Preview("Settings Button") {
    DashboardPreviewHost {
        VStack {
            Text("设置按钮测试")
            HStack {
                BtnSettings()
            }
        }
        .padding()
    }
    .frame(width: 500, height: 300)
}

#Preview("App") {
    ContentView()
        .dashboardPreviewRoot()
        .frame(width: 500, height: 300)
}
