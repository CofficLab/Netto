import SwiftUI
import MagicCore
import MagicContainer
import MagicBackground

/**
 * App Store 主页面
 * 展示应用核心价值和主要功能
 */
struct AppStoreHero: View {
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Spacer()
                
                // 左侧：应用介绍
                VStack(alignment: .leading, spacing: 40) {
                    Spacer()
                    
                    // Logo 和标题
                    VStack(alignment: .leading, spacing: 24) {
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(AppConfig.appName)
                                .font(.system(size: 120, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("网络监控工具")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 主要功能
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            featureRow("实时监控", "监控所有应用的网络连接", "eye.fill", .blue)
                            featureRow("智能过滤", "自动识别并阻止可疑连接", "shield.checkered", .green)
                            featureRow("流量分析", "详细的网络使用统计报告", "chart.bar.fill", .orange)
                            featureRow("隐私保护", "本地处理，保护用户隐私", "lock.shield.fill", .purple)
                        }
                    }
                    
                    Spacer()
                }
                .frame(alignment: .leading)
                .padding(.horizontal, 60)
                .padding(.vertical, 80)
                .frame(width: geo.size.width*0.3)
                
                // 右侧：应用界面预览
                VStack(spacing: 0) {
                    
                            Spacer()
                                // 状态栏
                                HStack {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(.green)
                                            .frame(width: 8, height: 8)
                                        Text("监控中")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("12 个活跃连接")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.green.opacity(0.1))
                                
                                // 连接列表
                                VStack(spacing: 8) {
                                    connectionRow("Safari", "允许", .green, "https://www.apple.com")
                                    connectionRow("Chrome", "监控中", .blue, "https://www.google.com")
                                    connectionRow("Xcode", "允许", .green, "https://developer.apple.com")
                                    connectionRow("可疑应用", "已阻止", .red, "suspicious-site.com")
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                
                                Spacer()
                            
                        
                }.frame(width: geo.size.width*0.3)
                
                Spacer()
            }
            .inMagicBackgroundCoral()
        }
    }
    
    private func featureRow(_ title: String, _ description: String, _ iconName: String, _ color: Color) -> some View {
        HStack(spacing: 32) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(color)
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.system(size: 32))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 30))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private func connectionRow(_ app: String, _ status: String, _ color: Color, _ url: String) -> some View {
        HStack(spacing: 12) {
            // 应用图标
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay(
                    Text(String(app.prefix(1)))
                        .font(.headline)
                        .foregroundColor(color)
                )
            
            // 应用信息
            VStack(alignment: .leading, spacing: 4) {
                Text(app)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(url)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 状态
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview
#Preview("App Store Hero") {
    AppStoreHero()
        .inMagicContainer(.macBook13, scale: 0.5)
}
