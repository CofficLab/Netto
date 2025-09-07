import SwiftUI
import MagicCore

/**
 * App Store 简洁易用页面
 * 展示简单易用特性
 */
struct AppStoreSimple: View {
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题区域
            VStack(spacing: 24) {
                HStack {
                    Image(systemName: "hand.point.up.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("简单易用")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("直观的界面设计，零学习成本，轻松上手使用")
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
                        Text("易用特性")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            featureRow("一键启动监控", icon: "play.circle.fill", color: .green)
                            featureRow("直观的界面设计", icon: "rectangle.3.group.fill", color: .blue)
                            featureRow("智能默认设置", icon: "gearshape.fill", color: .orange)
                            featureRow("详细使用指导", icon: "questionmark.circle.fill", color: .purple)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("用户反馈")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            dataCard("学习时间", "< 5分钟", "", .green)
                            dataCard("操作步骤", "1-2步", "", .blue)
                            dataCard("满意度", "98%", "", .orange)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 右侧：模拟界面
                VStack(spacing: 0) {
                    Text("简洁界面")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .frame(width: 400, height: 500)
                        .overlay(
                            VStack(spacing: 0) {
                                // 应用状态
                                HStack {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(.blue)
                                            .frame(width: 8, height: 8)
                                        Text("\(AppConfig.appName)")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("就绪")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.blue.opacity(0.1))
                                
                                // 主要操作区域
                                VStack(spacing: 20) {
                                    // 大按钮
                                    Button(action: {}) {
                                        VStack(spacing: 12) {
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 48))
                                                .foregroundColor(.white)
                                            
                                            Text("开始监控")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 24)
                                        .background(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(16)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    // 快速设置
                                    VStack(spacing: 12) {
                                        Text("快速设置")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        HStack(spacing: 12) {
                                            quickSettingButton("自动启动", icon: "power", color: .green)
                                            quickSettingButton("通知提醒", icon: "bell", color: .orange)
                                            quickSettingButton("隐私模式", icon: "eye.slash", color: .purple)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
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
                colors: [Color.blue.opacity(0.03), Color.green.opacity(0.02)],
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
    
    private func quickSettingButton(_ title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Preview
#Preview("App Store Simple") {
    AppStoreSimple()
        .inMagicContainer(containerHeight: 1000)
}
