import SwiftUI

/**
 * 工作原理示意图视图
 * 展示应用程序与系统扩展的通信机制和整体架构
 */
struct WorkingPrincipleDiagramView: View {
    @State private var showAnimation = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("工作原理示意图")
                .font(.title2)
                .fontWeight(.bold)
            
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
                .shadow(radius: 8)
        )
    }
    
    private var systemSettingsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)
                .scaleEffect(showAnimation ? 1.1 : 1.0)
            
            Text("系统设置")
                .font(.headline)
                .fontWeight(.semibold)
            
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
                Text("IPC 通信")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("数据交换")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .opacity(showAnimation ? 1.0 : 0.5)
        }
    }
    
    private var appInterfaceView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "menubar.rectangle")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                
                Text("菜单栏")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .scaleEffect(showAnimation ? 1.05 : 1.0)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .frame(width: 100, height: 60)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        
                        Text("应用列表")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.gray.opacity(0.4))
                                    .frame(width: 20, height: 2)
                            }
                        }
                        .opacity(showAnimation ? 1.0 : 0.5)
                    }
                )
                .scaleEffect(showAnimation ? 1.05 : 1.0)
                .shadow(color: showAnimation ? .blue.opacity(0.3) : .clear, radius: 6)
            
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
