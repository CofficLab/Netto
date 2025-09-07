import SwiftUI
import MagicCore

/**
 * App Store 隐私保护页面
 * 展示隐私保护和安全功能
 */
struct AppStorePrivacy: View {
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题区域
            VStack(spacing: 24) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("隐私保护")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("全面保护您的个人隐私，让网络使用更加安全")
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
                        Text("安全特性")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            featureRow("本地数据处理", icon: "house.fill", color: .green)
                            featureRow("加密存储", icon: "lock.fill", color: .blue)
                            featureRow("无数据上传", icon: "xmark.icloud", color: .orange)
                            featureRow("隐私合规", icon: "checkmark.shield", color: .purple)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("保护统计")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            dataCard("隐私事件", "0", "次", .green)
                            dataCard("数据泄露", "0", "次", .green)
                            dataCard("安全等级", "A+", "", .blue)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 右侧：模拟界面
                VStack(spacing: 0) {
                    Text("隐私保护界面")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .frame(width: 400, height: 500)
                        .overlay(
                            VStack(spacing: 0) {
                                // 安全状态
                                HStack {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(.green)
                                            .frame(width: 8, height: 8)
                                        Text("隐私保护已启用")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("A+ 安全等级")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.green.opacity(0.1))
                                
                                // 隐私设置列表
                                ScrollView {
                                    VStack(spacing: 8) {
                                        privacySettingRow("本地数据处理", "已启用", .green, "所有数据在本地处理")
                                        privacySettingRow("加密存储", "已启用", .blue, "敏感数据加密存储")
                                        privacySettingRow("无数据上传", "已启用", .orange, "不会上传任何数据")
                                        privacySettingRow("隐私模式", "已启用", .purple, "隐藏敏感信息")
                                        privacySettingRow("安全审计", "已启用", .red, "记录安全事件")
                                        privacySettingRow("合规检查", "已通过", .green, "符合隐私保护标准")
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
                colors: [Color.purple.opacity(0.03), Color.blue.opacity(0.02)],
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
            
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 80)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
    
    private func privacySettingRow(_ title: String, _ status: String, _ color: Color, _ description: String) -> some View {
        HStack(spacing: 12) {
            // 设置图标
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(color)
                )
            
            // 设置信息
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
#Preview("App Store Privacy") {
    AppStorePrivacy()
        .inMagicContainer(containerHeight: 1000)
}
