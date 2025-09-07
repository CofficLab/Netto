import SwiftUI
import MagicCore
import MagicContainer

/**
 * App Store 主页面
 * 展示应用核心价值和主要功能
 */
struct AppStoreHero: View {
    var body: some View {
        HStack(spacing: 0) {
            // 左侧：应用介绍
            VStack(alignment: .leading, spacing: 40) {
                // Logo 和标题
                VStack(alignment: .leading, spacing: 24) {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .background(
                            Circle()
                                .fill(.regularMaterial)
                                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                        )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppConfig.appName)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("网络监控与安全工具")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 核心价值主张
                VStack(alignment: .leading, spacing: 20) {
                    Text("掌控您的网络世界")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("实时监控所有应用的网络活动，智能过滤可疑连接，全面保护您的隐私安全")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                
                // 主要功能
                VStack(alignment: .leading, spacing: 16) {
                    Text("核心功能")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        featureRow("实时监控", "监控所有应用的网络连接", "eye.fill", .blue)
                        featureRow("智能过滤", "自动识别并阻止可疑连接", "shield.checkered", .green)
                        featureRow("流量分析", "详细的网络使用统计报告", "chart.bar.fill", .orange)
                        featureRow("隐私保护", "本地处理，保护用户隐私", "lock.shield.fill", .purple)
                    }
                }
                
                Spacer()
                
                // 下载按钮
                Button(action: {}) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title2)
                        Text("免费下载")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 60)
            .padding(.vertical, 80)
            
            // 右侧：应用界面预览
            VStack(spacing: 0) {
                Text("应用界面预览")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .frame(width: 600, height: 400)
                    .overlay(
                        VStack(spacing: 0) {
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
                        }
                    )
                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 60)
            .padding(.vertical, 80)
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private func featureRow(_ title: String, _ description: String, _ iconName: String, _ color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
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
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Preview
#Preview("App Store Hero") {
    AppStoreHero()
        .inMagicContainer(.macBook13_20Percent)
}
