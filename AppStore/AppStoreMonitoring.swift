import SwiftUI
import MagicCore

/**
 * App Store 监控功能页面
 * 展示实时网络监控功能
 */
struct AppStoreMonitoring: View {
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题区域
            VStack(spacing: 24) {
                HStack {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("实时网络监控")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("监控所有应用的网络活动，让隐藏的连接变得可见")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.top, 60)
            }
            
            // 主要内容区域
            HStack(spacing: 40) {
                // 左侧：功能说明
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("核心功能")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            featureRow("实时监控所有网络连接", icon: "network", color: .blue)
                            featureRow("显示应用网络状态", icon: "apps.iphone", color: .green)
                            featureRow("检测异常网络活动", icon: "exclamationmark.triangle", color: .orange)
                            featureRow("提供详细连接信息", icon: "info.circle", color: .purple)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("监控数据")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            dataCard("活跃连接", "12", "个", .blue)
                            dataCard("监控应用", "24", "个", .green)
                            dataCard("今日流量", "2.4", "GB", .orange)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 右侧：模拟界面
                VStack(spacing: 0) {
                    Text("实时监控界面")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .frame(width: 400, height: 500)
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
                                    
                                    Text("12 个连接")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.gray.opacity(0.1))
                                
                                // 连接列表
                                ScrollView {
                                    VStack(spacing: 8) {
                                        connectionRow("Safari", "允许", .green, "https://www.apple.com")
                                        connectionRow("Chrome", "监控中", .blue, "https://www.google.com")
                                        connectionRow("Xcode", "允许", .green, "https://developer.apple.com")
                                        connectionRow("Terminal", "监控中", .blue, "ssh://server.com")
                                        connectionRow("可疑应用", "已阻止", .red, "suspicious-site.com")
                                        connectionRow("Mail", "允许", .green, "imap://mail.apple.com")
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                }
                            }
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 40)
            
            Spacer()
        }
        .frame(width: 1600, height: 1000)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.03), Color.purple.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private func featureRow(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
    
    private func dataCard(_ title: String, _ value: String, _ unit: String, _ color: Color) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
    
    private func connectionRow(_ app: String, _ status: String, _ color: Color, _ url: String) -> some View {
        HStack(spacing: 12) {
            // 应用图标
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 32, height: 32)
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
#Preview("App Store Monitoring") {
    AppStoreMonitoring()
        .inMagicContainer()
}
