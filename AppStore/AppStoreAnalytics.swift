import SwiftUI
import MagicCore

/**
 * App Store 分析功能页面
 * 展示流量统计和分析功能
 */
struct AppStoreAnalytics: View {
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题区域
            VStack(spacing: 24) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("流量统计分析")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("详细的网络使用统计，帮您了解数据流向")
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
                        Text("分析功能")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            featureRow("实时流量统计", icon: "chart.line.uptrend.xyaxis", color: .blue)
                            featureRow("应用使用排行", icon: "list.number", color: .green)
                            featureRow("历史数据分析", icon: "clock.fill", color: .orange)
                            featureRow("趋势预测", icon: "chart.xyaxis.line", color: .purple)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("今日统计")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            dataCard("总流量", "2.4", "GB", .blue)
                            dataCard("上传", "856", "MB", .green)
                            dataCard("下载", "1.5", "GB", .orange)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 右侧：模拟界面
                VStack(spacing: 0) {
                    Text("流量分析界面")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .frame(width: 400, height: 500)
                        .overlay(
                            VStack(spacing: 0) {
                                // 统计概览
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("今日流量")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("2.4 GB")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("较昨日")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("+12%")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.blue.opacity(0.1))
                                
                                // 应用排行
                                ScrollView {
                                    VStack(spacing: 8) {
                                        appUsageRow("Safari", "1.2 GB", "50%", .blue)
                                        appUsageRow("Chrome", "680 MB", "28%", .green)
                                        appUsageRow("Xcode", "320 MB", "13%", .orange)
                                        appUsageRow("Mail", "180 MB", "7%", .purple)
                                        appUsageRow("其他", "120 MB", "5%", .gray)
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
                colors: [Color.orange.opacity(0.03), Color.blue.opacity(0.02)],
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
    
    private func appUsageRow(_ app: String, _ usage: String, _ percentage: String, _ color: Color) -> some View {
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
                
                Text(usage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 使用百分比
            VStack(alignment: .trailing, spacing: 4) {
                Text(percentage)
                    .font(.headline)
                    .foregroundColor(color)
                
                // 进度条
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 4)
                    .overlay(
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color)
                                .frame(width: 60 * (Double(percentage.replacingOccurrences(of: "%", with: "")) ?? 0) / 100)
                            
                            Spacer()
                        }
                    )
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
#Preview("App Store Analytics") {
    AppStoreAnalytics()
        .inMagicContainer()
}
