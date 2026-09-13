import MagicCore
import PluginShell
import SwiftUI
import MagicBackground

/// 顶部工具栏 —— 通过 `ShellToolbarProviding` 聚合稳定 ID/位置/排序的贡献。
///
/// 阶段 6 迁移后不再读取 `PluginProvider`；贡献由 App Host 插件在
/// 启动期注册进 ShellCenter，本视图只按位置渲染。
struct TopBar: View {
    @EnvironmentObject var shell: ShellCenter

    var body: some View {
        HStack(spacing: 0) {
            // 左侧贡献
            HStack(spacing: 8) {
                ForEach(shell.leftContributions) { contribution in
                    contribution.makeView()
                }
            }

            Spacer()

            // 中间贡献
            HStack(spacing: 8) {
                ForEach(shell.centerContributions) { contribution in
                    contribution.makeView()
                }
            }

            Spacer()

            // 右侧贡献
            HStack(spacing: 8) {
                ForEach(shell.rightContributions) { contribution in
                    contribution.makeView()
                }
            }

            // 设置按钮（始终在右侧）
            BtnSettings()
        }
        .frame(height: 36)
        .background(MagicBackground.colorTeal.opacity(0.2))
    }
}

#Preview {
    DashboardPreviewHost {
        ContentView()
    }
    .frame(height: 800)
}
