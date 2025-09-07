import SwiftUI
import MagicCore

/**
 * App Store 过滤功能页面
 * 展示智能网络过滤功能
 */
struct AppStoreFiltering: View {
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题区域
            VStack(spacing: 24) {
                HStack {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("智能网络过滤")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("智能识别并控制可疑网络连接，保护您的设备安全")
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
                        Text("过滤功能")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            featureRow("智能威胁检测", icon: "brain.head.profile", color: .red)
                            featureRow("自动阻止恶意连接", icon: "hand.raised.fill", color: .orange)
                            featureRow("自定义过滤规则", icon: "gearshape.fill", color: .blue)
                            featureRow("白名单管理", icon: "checkmark.shield", color: .green)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("安全统计")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            dataCard("威胁拦截", "156", "次", .red)
                            dataCard("安全连接", "2,847", "个", .green)
                            dataCard("过滤规则", "12", "条", .blue)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 右侧：模拟界面
                VStack(spacing: 0) {
                    Text("过滤控制界面")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .frame(width: 400, height: 500)
                        .overlay(
                            VStack(spacing: 0) {
                                // 过滤状态
                                HStack {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(.green)
                                            .frame(width: 8, height: 8)
                                        Text("过滤已启用")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("12 条规则")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.green.opacity(0.1))
                                
                                // 过滤规则列表
                                ScrollView {
                                    VStack(spacing: 8) {
                                        filterRuleRow("恶意软件检测", "已启用", .red, "自动阻止已知恶意域名")
                                        filterRuleRow("广告拦截", "已启用", .orange, "阻止广告和跟踪脚本")
                                        filterRuleRow("钓鱼网站", "已启用", .red, "检测并阻止钓鱼网站")
                                        filterRuleRow("安全连接", "已启用", .green, "允许HTTPS安全连接")
                                        filterRuleRow("自定义规则", "已启用", .blue, "用户自定义过滤规则")
                                        filterRuleRow("白名单", "已启用", .green, "信任的应用和域名")
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
                colors: [Color.green.opacity(0.03), Color.blue.opacity(0.02)],
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
    
    private func filterRuleRow(_ title: String, _ status: String, _ color: Color, _ description: String) -> some View {
        HStack(spacing: 12) {
            // 规则图标
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "shield.fill")
                        .font(.system(size: 16))
                        .foregroundColor(color)
                )
            
            // 规则信息
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
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
#Preview("App Store Filtering") {
    AppStoreFiltering()
        .inMagicContainer()
}
