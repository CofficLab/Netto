import OSLog
import ProviderShell
import SwiftUI

/// 内核内置的设置按钮
/// 通过 `SettingsProviding` 获取设置入口，不再查询旧 PluginRegistry。
///
/// ## 「设置…」入口
///
/// 省略号 popover 里除各插件贡献的快捷入口外，额外提供一个 **「设置…」**
/// 按钮，点击后打开**双栏设置窗口**（左侧入口列表 + 右侧详情视图）。
///
/// 路由方式：popover 视图拿不到宿主的 `openWindow`（那是 SwiftUI 视图层
/// 能力，且只能由启动即存在的场景捕获），因此这里走契约
/// `WindowRoutingProviding`：插件/UI 只声明「我要打开设置窗口」，由宿主
/// （`SettingsWindowRouter`）翻译成真正的窗口动作。
struct BtnSettings: View {
    @EnvironmentObject private var shell: ShellCenter
    @State private var hovered = false
    @State private var isPresented = false

    var body: some View {
        Button {
            self.isPresented.toggle()
        } label: {
            Image(systemName: "ellipsis")
                .frame(maxHeight: .infinity)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 0))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("设置")
        .accessibilityIdentifier("netto.settings.button")
        .frame(maxHeight: .infinity)
        .onHover(perform: { hovering in
            self.hovered = hovering
        })
        .popover(isPresented: $isPresented, content: {
            VStack(spacing: 8) {
                // 「设置…」：打开完整设置窗口（双栏）。
                BtnOpenSettingsWindow()
                    .environmentObject(shell)

                Divider()

                // 设置入口（按 order 升序，由 ShellCenter 聚合）
                ForEach(shell.entries) { entry in
                    entry.makeView()
                }
            }
            .padding()
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("netto.settings.menu")
        })
    }
}

/// 「设置…」按钮 —— 打开宿主设置窗口。
///
/// 通过 `WindowRoutingProviding` 契约请求打开，宿主负责真正地
/// `openWindow(id:)`；窗口已打开时宿主只前置，不重复创建。
struct BtnOpenSettingsWindow: View {
    @EnvironmentObject private var shell: ShellCenter

    var body: some View {
        Button {
            shell.openSettings()
        } label: {
            Label {
                Text("设置…")
            } icon: {
                Image(systemName: "gearshape")
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("netto.settings.open")
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
