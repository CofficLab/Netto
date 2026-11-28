import PluginBrandLogo
import SwiftUI

/**
 * 菜单栏示意图视图
 * 绘制macOS菜单栏并突出显示本应用实际使用的菜单栏图标，用于引导用户了解应用访问入口
 */
struct MenuBarDiagramView: View {
    var body: some View {
        VStack(spacing: 16) {
            // 菜单栏示意图
            ZStack {
                // 菜单栏背景
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(height: 32)

                HStack(spacing: 12) {
                    Spacer()

                    // 突出显示的应用图标（与菜单栏实际渲染一致：statusBar 场景模板图）
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(Color.green, lineWidth: 2)
                                    .scaleEffect(1.2)
                                    .opacity(0.8)
                            )

                        BrandLogoMark(scene: .statusBar)
                            .frame(width: 16, height: 16)
                    }
                    .padding(.horizontal, 4)

                    // 其他菜单栏图标（灰色）
                    HStack(spacing: 8) {
                        Image(systemName: "wifi")
                            .foregroundColor(.gray.opacity(0.6))
                        Image(systemName: "battery.100")
                            .foregroundColor(.gray.opacity(0.6))
                        Image(systemName: "clock")
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .font(.system(size: 14))

                    Spacer().frame(width: 12)
                }
            }
            .frame(width: 280)

            // 指示箭头和文字
            VStack(spacing: 8) {
                Image(systemName: "arrow.up")
                    .foregroundColor(.green)
                    .font(.system(size: 20, weight: .bold))
                    .offset(x: 10) // 指向网络图标位置

                Text("Click here to open the app")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
                    .offset(x: 10)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    MenuBarDiagramView()
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
}
