import SwiftUI

/**
 * 工作原理示意图视图
 * 展示应用程序与系统扩展的通信机制和整体架构
 */
struct WorkingPrincipleDiagramView: View {
    @State private var showAnimation = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 40) {
                systemSettingsView
                communicationView
                appInterfaceView
            }
            .frame(maxWidth: 500)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 1.5)) {
                    showAnimation = true
                }
            }
        }
    }
    
    private var systemSettingsView: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.2))
                .frame(width: 100, height: 50)
                .overlay(
                    VStack(spacing: 2) {
                        Image(systemName: "puzzlepiece.extension.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                        Text("系统扩展")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                )
                .scaleEffect(showAnimation ? 1.05 : 1.0)
                .shadow(color: showAnimation ? .orange.opacity(0.3) : .clear, radius: 6)
            
            Text("网络过滤扩展")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var communicationView: some View {
        VStack(spacing: 15) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)
                    .opacity(showAnimation ? 1.0 : 0.3)
                    .scaleEffect(showAnimation ? 1.2 : 1.0)
                
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.green)
                    .opacity(showAnimation ? 1.0 : 0.3)
                    .scaleEffect(showAnimation ? 1.2 : 1.0)
            }
            
            VStack(spacing: 4) {
                Text("数据交换")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .opacity(showAnimation ? 1.0 : 0.5)
        }
    }
    
    /**
     * 应用界面视图 - 展示菜单栏和应用列表界面
     * 参考真实的macOS菜单栏设计，突出显示网络图标
     */
    private var appInterfaceView: some View {
        VStack(spacing: 12) {
            ZStack {
                // 菜单栏背景
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.1))
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .frame( height: 24)

                HStack(spacing: 6) {
                    Spacer()

                    // 突出显示的网络图标
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.green, lineWidth: 1.5)
                                    .scaleEffect(showAnimation ? 1.3 : 1.1)
                                    .opacity(showAnimation ? 0.8 : 0.6)
                            )

                        Image(systemName: "network")
                            .foregroundColor(.green)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .scaleEffect(showAnimation ? 1.1 : 1.0)

                    // 其他菜单栏图标（灰色）
                    HStack(spacing: 4) {
                        Image(systemName: "wifi")
                            .foregroundColor(.gray.opacity(0.6))
                        Image(systemName: "battery.100")
                            .foregroundColor(.gray.opacity(0.6))
                        Image(systemName: "clock")
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .font(.system(size: 10))

                    Spacer().frame(width: 6)
                }
            }
            
            // 应用列表界面
            VStack(spacing: 0) {
                // 应用列表标题
                HStack {
                    Text("应用列表")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                
                // 模拟应用行
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { index in
                        HStack(spacing: 6) {
                            // 应用图标
                            Circle()
                                .fill(index == 0 ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                                .frame(width: 8, height: 8)
                            
                            // 应用名称
                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 40, height: 3)
                            
                            Spacer()
                            
                            // 状态指示
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 12, height: 2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            index == 1 ? Color.red.opacity(0.05) : Color.clear
                        )
                        
                        if index < 2 {
                            Divider()
                                .opacity(0.3)
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.05))
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .frame(width: 120)
            .scaleEffect(showAnimation ? 1.05 : 1.0)
            .shadow(color: showAnimation ? .blue.opacity(0.3) : .clear, radius: 6)
            .opacity(showAnimation ? 1.0 : 0.8)
            
            Text("用户界面")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    WorkingPrincipleDiagramView()
        .frame(width: 600, height: 500)
}
