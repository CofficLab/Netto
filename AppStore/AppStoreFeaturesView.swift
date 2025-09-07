import SwiftUI
import MagicCore

/**
 * App Store 功能特性展示页面
 * 详细展示应用的各种功能特性
 */
struct AppStoreFeaturesView: View {
    @State private var selectedCategory = 0
    @State private var showDetailView = false
    @State private var selectedFeature: FeatureItem? = nil
    
    private let categories = ["核心功能", "监控能力", "安全特性", "用户体验"]
    
    private let features: [FeatureItem] = [
        // 核心功能
        FeatureItem(
            category: 0,
            title: "实时网络监控",
            description: "实时监控所有应用的网络连接状态，让您随时了解数据流向",
            icon: "network",
            color: .blue,
            details: [
                "监控所有应用的网络请求",
                "实时显示连接状态",
                "支持 TCP/UDP 协议监控",
                "自动识别应用类型"
            ]
        ),
        FeatureItem(
            category: 0,
            title: "智能过滤控制",
            description: "智能识别可疑网络活动，自动或手动控制网络访问权限",
            icon: "shield.checkered",
            color: .green,
            details: [
                "智能识别可疑连接",
                "一键允许/拒绝访问",
                "支持批量操作",
                "自定义过滤规则"
            ]
        ),
        FeatureItem(
            category: 0,
            title: "流量统计分析",
            description: "提供详细的网络流量统计，帮助您了解数据使用情况",
            icon: "chart.bar.fill",
            color: .orange,
            details: [
                "实时流量统计",
                "历史数据分析",
                "按应用分类统计",
                "导出详细报告"
            ]
        ),
        
        // 监控能力
        FeatureItem(
            category: 1,
            title: "全应用覆盖",
            description: "监控系统上所有应用的网络活动，无遗漏",
            icon: "apps.iphone",
            color: .purple,
            details: [
                "监控所有已安装应用",
                "支持系统应用监控",
                "自动发现新应用",
                "实时更新应用列表"
            ]
        ),
        FeatureItem(
            category: 1,
            title: "深度流量分析",
            description: "深入分析网络数据包，提供详细的连接信息",
            icon: "magnifyingglass",
            color: .cyan,
            details: [
                "分析数据包内容",
                "识别连接协议",
                "检测异常流量",
                "提供详细日志"
            ]
        ),
        FeatureItem(
            category: 1,
            title: "实时状态显示",
            description: "在菜单栏实时显示网络状态，一目了然",
            icon: "menubar.rectangle",
            color: .red,
            details: [
                "菜单栏状态指示",
                "实时连接数量",
                "快速访问控制",
                "状态变化提醒"
            ]
        ),
        
        // 安全特性
        FeatureItem(
            category: 2,
            title: "隐私保护",
            description: "保护您的隐私，防止敏感数据泄露",
            icon: "lock.shield.fill",
            color: .green,
            details: [
                "加密存储敏感数据",
                "本地处理所有信息",
                "不上传用户数据",
                "符合隐私保护标准"
            ]
        ),
        FeatureItem(
            category: 2,
            title: "恶意软件检测",
            description: "智能识别并阻止恶意软件的网络活动",
            icon: "exclamationmark.triangle.fill",
            color: .red,
            details: [
                "智能威胁识别",
                "自动阻止恶意连接",
                "实时安全提醒",
                "安全事件记录"
            ]
        ),
        FeatureItem(
            category: 2,
            title: "安全审计",
            description: "提供完整的安全审计日志，便于安全分析",
            icon: "doc.text.magnifyingglass",
            color: .indigo,
            details: [
                "完整操作日志",
                "安全事件记录",
                "审计报告生成",
                "合规性检查"
            ]
        ),
        
        // 用户体验
        FeatureItem(
            category: 3,
            title: "直观界面设计",
            description: "简洁直观的用户界面，轻松上手使用",
            icon: "rectangle.3.group.fill",
            color: .blue,
            details: [
                "现代化界面设计",
                "直观的操作流程",
                "清晰的视觉反馈",
                "响应式布局"
            ]
        ),
        FeatureItem(
            category: 3,
            title: "快速响应",
            description: "极速响应的操作体验，不卡顿不延迟",
            icon: "bolt.fill",
            color: .yellow,
            details: [
                "毫秒级响应速度",
                "流畅的动画效果",
                "优化的性能表现",
                "低资源占用"
            ]
        ),
        FeatureItem(
            category: 3,
            title: "个性化设置",
            description: "丰富的个性化设置选项，满足不同用户需求",
            icon: "gearshape.fill",
            color: .gray,
            details: [
                "自定义界面主题",
                "个性化通知设置",
                "灵活的控制选项",
                "用户偏好保存"
            ]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题
            headerSection
            
            // 分类选择器
            categorySelector
            
            // 功能列表
            featuresList
            
            // 底部操作
            bottomActions
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $showDetailView) {
            if let feature = selectedFeature {
                FeatureDetailView(feature: feature)
            }
        }
    }
}

// MARK: - Header Section
extension AppStoreFeaturesView {
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("强大功能特性")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("探索 \(AppConfig.appName) 的丰富功能，让网络监控变得简单高效")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
}

// MARK: - Category Selector
extension AppStoreFeaturesView {
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<categories.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedCategory = index
                        }
                    }) {
                        Text(categories[index])
                            .font(.headline)
                            .foregroundColor(selectedCategory == index ? .white : .primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedCategory == index ? 
                                          LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                                          LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(selectedCategory == index ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Features List
extension AppStoreFeaturesView {
    private var featuresList: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 20) {
                ForEach(filteredFeatures, id: \.id) { feature in
                    FeatureCard(feature: feature) {
                        selectedFeature = feature
                        showDetailView = true
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var filteredFeatures: [FeatureItem] {
        features.filter { $0.category == selectedCategory }
    }
}

// MARK: - Bottom Actions
extension AppStoreFeaturesView {
    private var bottomActions: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                Button("查看所有功能") {
                    // 滚动到顶部或显示所有功能
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Spacer()
                
                Button("立即体验") {
                    // 跳转到下载或试用
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(.regularMaterial)
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let feature: FeatureItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // 图标和标题
                HStack(spacing: 12) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 24))
                        .foregroundColor(feature.color)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(feature.color.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                
                // 描述
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                // 查看更多指示器
                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature Detail View
struct FeatureDetailView: View {
    let feature: FeatureItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 头部信息
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            Image(systemName: feature.icon)
                                .font(.system(size: 48))
                                .foregroundColor(feature.color)
                                .frame(width: 80, height: 80)
                                .background(
                                    Circle()
                                        .fill(feature.color.opacity(0.1))
                                )
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(feature.title)
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text(feature.description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                    )
                    
                    // 详细功能列表
                    VStack(alignment: .leading, spacing: 16) {
                        Text("功能详情")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(feature.details, id: \.self) { detail in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(feature.color)
                                        .font(.system(size: 16))
                                        .frame(width: 20, alignment: .top)
                                    
                                    Text(detail)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                    )
                }
                .padding(20)
            }
            .navigationTitle("功能详情")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Data Models
struct FeatureItem: Identifiable {
    let id = UUID()
    let category: Int
    let title: String
    let description: String
    let icon: String
    let color: Color
    let details: [String]
}

// MARK: - Preview
#Preview("Features - Large") {
    AppStoreFeaturesView()
        .frame(width: 1200, height: 1000)
}

#Preview("Features - Small") {
    AppStoreFeaturesView()
        .frame(width: 800, height: 600)
}

#Preview("Feature Detail") {
    FeatureDetailView(feature: FeatureItem(
        category: 0,
        title: "实时网络监控",
        description: "实时监控所有应用的网络连接状态，让您随时了解数据流向",
        icon: "network",
        color: .blue,
        details: [
            "监控所有应用的网络请求",
            "实时显示连接状态",
            "支持 TCP/UDP 协议监控",
            "自动识别应用类型"
        ]
    ))
    .frame(width: 600, height: 500)
}
