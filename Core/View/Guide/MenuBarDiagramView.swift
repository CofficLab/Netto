import SwiftUI

/**
 * 菜单栏示意图视图
 * 绘制macOS菜单栏并突出显示网络图标，用于引导用户了解应用访问入口
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
                    
                    // 突出显示的网络图标
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
                        
                        Image(systemName: "network")
                            .foregroundColor(.green)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.horizontal, 4)
                    
                    Spacer().frame(width: 12)
                }
            }
            .frame(width: 280)
            
            // 指示箭头和文字
            VStack(spacing: 8) {
                Image(systemName: "arrow.up")
                    .foregroundColor(.green)
                    .font(.system(size: 20, weight: .bold))
                    .offset(x: 60) // 指向网络图标位置
                
                Text("点击这里访问应用")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
                    .offset(x: 60)
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