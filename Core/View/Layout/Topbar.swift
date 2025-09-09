import MagicCore
import SwiftUI
import MagicBackground

struct Topbar: View {
    @EnvironmentObject var p: PluginProvider

    var body: some View {
        HStack {
            // 左侧按钮
            p.getLeftButtons()
            
            Spacer()
            
            // 中心按钮
            p.getCenterButtons()
            
            Spacer()
            
            // 右侧按钮
            p.getRightButtons()
            
            // 设置按钮（始终在右侧）
            BtnSettings()
        }
        .frame(height: 30)
        .background(MagicBackground.colorTeal.opacity(0.2))
    }
}

#Preview {
    RootView {
        ContentView()
    }
    .frame(height: 800)
}
