import SwiftUI
import MagicCore

/**
 * App Store 用户收益和价值主张页面
 * 展示使用应用带来的具体收益和价值
 */
struct AppStoreBenefitsView: View {
    @State private var selectedBenefit = 0
    @State private var showAnimation = false
    @State private var currentMetric = 0
    
    private let benefits: [BenefitItem] = [
        BenefitItem(
            title: "隐私安全保护",
            subtitle: "全面保护您的个人隐私",
            description: "实时监控网络活动，防止敏感数据泄露，让您安心使用网络",
            icon: "shield.fill",
            color: .green,
            metrics: [
                ("威胁拦截", "99.9%", "恶意连接拦截率"),
                ("隐私保护", "100%", "本地数据处理"),
                ("安全检测", "24/7", "全天候监控")
            ],
            features: [
                "实时监控所有网络连接",
                "智能识别可疑活动",
                "自动阻止恶意软件",
                "保护个人隐私数据"
            ]
        ),
        BenefitItem(
            title: "网络性能优化",
            subtitle: "提升网络使用效率",
            description: "智能管理网络连接，优化带宽使用，提升整体网络性能",
            icon: "speedometer",
            color: .blue,
            metrics: [
                ("带宽节省", "30%", "平均带宽优化"),
                ("连接优化", "50%", "减少无效连接"),
                ("响应速度", "2x", "网络响应提升")
            ],
            features: [
                "智能带宽管理",
                "优化网络连接",
                "减少无效流量",
                "提升响应速度"
            ]
        ),
        BenefitItem(
            title: "透明化监控",
            subtitle: "让网络活动变得可见",
            description: "将隐藏的网络活动变得透明可见，让您完全掌控网络使用情况",
            icon: "eye.fill",
            color: .orange,
            metrics: [
                ("监控覆盖", "100%", "应用监控覆盖率"),
                ("实时更新", "1秒", "状态更新频率"),
                ("数据准确", "99.9%", "监控数据准确性")
            ],
            features: [
                "全应用网络监控",
                "实时状态显示",
                "详细流量分析",
                "历史数据追踪"
            ]
        ),
        BenefitItem(
            title: "简单易用",
            subtitle: "零学习成本上手",
            description: "直观的界面设计，简单的操作流程，让任何人都能轻松使用",
            icon: "hand.point.up.fill",
            color: .purple,
            metrics: [
                ("学习时间", "< 5分钟", "上手使用时间"),
                ("操作步骤", "1-2步", "常用操作步骤"),
                ("用户满意度", "98%", "用户好评率")
            ],
            features: [
                "直观的界面设计",
                "一键式操作",
                "智能默认设置",
                "详细的使用指导"
            ]
        )
    ]
    
    private let useCases: [UseCaseItem] = [
        UseCaseItem(
            title: "个人用户",
            description: "保护个人隐私，监控家庭网络使用",
            icon: "person.fill",
            color: .blue,
            scenarios: [
                "监控家庭成员的网络使用情况",
                "保护个人隐私和敏感数据",
                "优化家庭网络性能",
                "防止恶意软件入侵"
            ]
        ),
        UseCaseItem(
            title: "企业用户",
            description: "企业网络安全管理和员工监控",
            icon: "building.2.fill",
            color: .green,
            scenarios: [
                "监控员工网络活动",
                "防止数据泄露",
                "优化企业网络性能",
                "合规性审计支持"
            ]
        ),
        UseCaseItem(
            title: "开发者",
            description: "应用开发和调试的网络分析工具",
            icon: "hammer.fill",
            color: .orange,
            scenarios: [
                "调试应用网络连接",
                "分析网络性能问题",
                "监控API调用情况",
                "优化网络请求"
            ]
        ),
        UseCaseItem(
            title: "安全专家",
            description: "网络安全分析和威胁检测",
            icon: "lock.shield.fill",
            color: .red,
            scenarios: [
                "深度网络流量分析",
                "威胁检测和响应",
                "安全事件调查",
                "合规性检查"
            ]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题
            headerSection
            
            // 主要内容区域
            ScrollView {
                VStack(spacing: 60) {
                    // 核心收益展示
                    benefitsSection
                    
                    // 使用场景
                    useCasesSection
                    
                    // 数据统计
                    metricsSection
                    
                    // 价值主张
                    valuePropositionSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            startAnimations()
        }
    }
}

// MARK: - Header Section
extension AppStoreBenefitsView {
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("为什么选择 \(AppConfig.appName)？")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("了解使用 \(AppConfig.appName) 为您带来的具体收益和价值")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
}

// MARK: - Benefits Section
extension AppStoreBenefitsView {
    private var benefitsSection: some View {
        VStack(spacing: 32) {
            Text("核心收益")
                .font(.title2)
                .fontWeight(.bold)
            
            TabView(selection: $selectedBenefit) {
                ForEach(0..<benefits.count, id: \.self) { index in
                    benefitCard(benefits[index])
                        .tag(index)
                }
            }
            .frame(height: 500)
        }
    }
    
    private func benefitCard(_ benefit: BenefitItem) -> some View {
        VStack(spacing: 24) {
            // 头部信息
            VStack(spacing: 16) {
                Image(systemName: benefit.icon)
                    .font(.system(size: 48))
                    .foregroundColor(benefit.color)
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(benefit.color.opacity(0.1))
                    )
                
                VStack(spacing: 8) {
                    Text(benefit.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(benefit.subtitle)
                        .font(.headline)
                        .foregroundColor(benefit.color)
                    
                    Text(benefit.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            // 关键指标
            HStack(spacing: 20) {
                ForEach(0..<benefit.metrics.count, id: \.self) { index in
                    let metric = benefit.metrics[index]
                    VStack(spacing: 8) {
                        Text(metric.value)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(benefit.color)
                        
                        Text(metric.label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text(metric.description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.regularMaterial)
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Use Cases Section
extension AppStoreBenefitsView {
    private var useCasesSection: some View {
        VStack(spacing: 32) {
            Text("适用场景")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(useCases, id: \.id) { useCase in
                    useCaseCard(useCase)
                }
            }
        }
    }
    
    private func useCaseCard(_ useCase: UseCaseItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: useCase.icon)
                    .font(.system(size: 24))
                    .foregroundColor(useCase.color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(useCase.color.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(useCase.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(useCase.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(useCase.scenarios, id: \.self) { scenario in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(useCase.color)
                            .font(.system(size: 12))
                            .frame(width: 16, alignment: .top)
                        
                        Text(scenario)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Metrics Section
extension AppStoreBenefitsView {
    private var metricsSection: some View {
        VStack(spacing: 32) {
            Text("用户数据统计")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                metricCard(
                    title: "用户数量",
                    value: "10,000+",
                    description: "活跃用户",
                    color: .blue
                )
                
                metricCard(
                    title: "监控应用",
                    value: "50,000+",
                    description: "已监控应用",
                    color: .green
                )
                
                metricCard(
                    title: "威胁拦截",
                    value: "1,000,000+",
                    description: "拦截次数",
                    color: .red
                )
                
                metricCard(
                    title: "用户满意度",
                    value: "98%",
                    description: "好评率",
                    color: .orange
                )
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private func metricCard(title: String, value: String, description: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
        )
    }
}

// MARK: - Value Proposition Section
extension AppStoreBenefitsView {
    private var valuePropositionSection: some View {
        VStack(spacing: 24) {
            Text("立即体验 \(AppConfig.appName)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("加入数万用户的选择，开始享受安全、高效的网络监控体验")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                Button(action: {
                    // 下载逻辑
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("免费下载")
                    }
                    .font(.headline)
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
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Button("了解更多") {
                    // 了解更多逻辑
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
        )
    }
}

// MARK: - Animation
extension AppStoreBenefitsView {
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            showAnimation = true
        }
        
        // 自动轮播收益卡片
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.5)) {
                    selectedBenefit = (selectedBenefit + 1) % benefits.count
                }
            }
        }
    }
}

// MARK: - Data Models
struct BenefitItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
    let metrics: [(label: String, value: String, description: String)]
    let features: [String]
}

struct UseCaseItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let scenarios: [String]
}

// MARK: - Preview
#Preview("Benefits - Large") {
    AppStoreBenefitsView()
        .frame(width: 1200, height: 1000)
}

#Preview("Benefits - Small") {
    AppStoreBenefitsView()
        .frame(width: 800, height: 600)
}
