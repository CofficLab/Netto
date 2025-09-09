import MagicAlert
import MagicCore
import OSLog
import SwiftUI

/// 内核内置的设置按钮
/// 从插件系统获取设置按钮内部的按钮
struct BtnSettings: View, SuperLog, SuperThread {
    @EnvironmentObject private var p: PluginProvider
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
                // 从插件系统获取设置按钮内部的按钮
                p.getSettingsButtons()
            }
            .padding()
        })
    }
}

// MARK: - Preview

#Preview("Settings Button") {
    RootView {
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
        .inRootView()
        .frame(width: 500, height: 300)
}
