import SwiftUI
import MagicCore

/**
 * App Store 交互式演示页面
 * 提供交互式的功能演示和体验
 */
struct AppStoreDemoView: View {
    @State private var currentStep = 0
    @State private var isPlaying = false
    @State private var showAnimation = false
    @State private var selectedDemo: DemoType = .monitoring
    
    private let demoSteps: [DemoStep] = [
        DemoStep(
            title: "启动监控",
            description: "点击开始按钮启动网络监控",
            action: "点击开始监控",
            icon: "play.circle.fill",
            color: .green
        ),
        DemoStep(
            title: "查看连接",
            description: "实时查看所有应用的网络连接",
            action: "浏览连接列表",
            icon: "list.bullet",
            color: .blue
        ),
        DemoStep(
            title: "控制访问",
            description: "允许或拒绝特定应用的网络访问",
            action: "管理应用权限",
            icon: "hand.raised.fill",
            color: .orange
        ),
        DemoStep(
            title: "查看统计",
            description: "查看详细的网络使用统计",
            action: "分析流量数据",
            icon: "chart.bar.fill",
            color: .purple
        )
    ]
    
    private let demoTypes: [DemoType] = [
        .monitoring,
        .filtering,
        .statistics,
        .settings
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题
            headerSection
            
            // 演示类型选择
            demoTypeSelector
            
            // 主要内容区域
            ScrollView {
                VStack(spacing: 40) {
                    // 交互式演示区域
                    interactiveDemoSection
                    
                    // 功能演示步骤
                    demoStepsSection
                    
                    // 实时数据展示
                    realTimeDataSection
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
extension AppStoreDemoView {
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("交互式演示")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("通过交互式演示体验 \(AppConfig.appName) 的强大功能")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
}

// MARK: - Demo Type Selector
extension AppStoreDemoView {
    private var demoTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(demoTypes, id: \.self) { demoType in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedDemo = demoType
                            currentStep = 0
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: demoType.icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedDemo == demoType ? .white : demoType.color)
                            
                            Text(demoType.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedDemo == demoType ? .white : .primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedDemo == demoType ? 
                                      LinearGradient(colors: [demoType.color, demoType.color.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                                      LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedDemo == demoType ? Color.clear : demoType.color.opacity(0.3), lineWidth: 1)
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

// MARK: - Interactive Demo Section
extension AppStoreDemoView {
    private var interactiveDemoSection: some View {
        VStack(spacing: 24) {
            Text("实时演示")
                .font(.title2)
                .fontWeight(.bold)
            
            // 模拟应用界面
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .frame(height: 400)
                .overlay(
                    VStack(spacing: 20) {
                        // 状态栏
                        HStack {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(isPlaying ? .green : .red)
                                    .frame(width: 8, height: 8)
                                Text(isPlaying ? "监控中" : "已停止")
                                    .font(.headline)
                                    .foregroundColor(isPlaying ? .green : .red)
                            }
                            
                            Spacer()
                            
                            Button(action: toggleMonitoring) {
                                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(isPlaying ? .red : .green)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // 模拟数据列表
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(0..<6, id: \.self) { index in
                                    demoAppRow(index: index)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                    }
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
    }
    
    private func demoAppRow(index: Int) -> some View {
        let apps = ["Safari", "Chrome", "Xcode", "Terminal", "Finder", "Mail"]
        let statuses: [ConnectionStatus] = [.allowed, .blocked, .monitoring, .allowed, .monitoring, .blocked]
        
        let app = apps[index]
        let status = statuses[index]
        
        return HStack(spacing: 12) {
            // 应用图标
            Circle()
                .fill(status.color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(app.prefix(1)))
                        .font(.headline)
                        .foregroundColor(status.color)
                )
            
            // 应用信息
            VStack(alignment: .leading, spacing: 4) {
                Text(app)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("网络连接中")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 状态指示器
            HStack(spacing: 8) {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                
                Text(status.title)
                    .font(.caption)
                    .foregroundColor(status.color)
            }
            
            // 操作按钮
            Button(action: {
                // 模拟切换状态
            }) {
                Image(systemName: status == .allowed ? "hand.raised.fill" : "checkmark.circle.fill")
                    .foregroundColor(status == .allowed ? .orange : .green)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
        )
        .opacity(showAnimation ? 1 : 0)
        .offset(x: showAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.1), value: showAnimation)
    }
}

// MARK: - Demo Steps Section
extension AppStoreDemoView {
    private var demoStepsSection: some View {
        VStack(spacing: 24) {
            Text("操作步骤")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                ForEach(0..<demoSteps.count, id: \.self) { index in
                    demoStepCard(demoSteps[index], index: index)
                }
            }
        }
    }
    
    private func demoStepCard(_ step: DemoStep, index: Int) -> some View {
        HStack(spacing: 16) {
            // 步骤编号
            Text("\(index + 1)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(step.color)
                )
            
            // 步骤信息
            VStack(alignment: .leading, spacing: 8) {
                Text(step.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(step.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text(step.action)
                    .font(.caption)
                    .foregroundColor(step.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(step.color.opacity(0.1))
                    )
            }
            
            Spacer()
            
            // 图标
            Image(systemName: step.icon)
                .font(.title2)
                .foregroundColor(step.color)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .opacity(showAnimation ? 1 : 0)
        .offset(y: showAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.2), value: showAnimation)
    }
}

// MARK: - Real Time Data Section
extension AppStoreDemoView {
    private var realTimeDataSection: some View {
        VStack(spacing: 24) {
            Text("实时数据")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                dataCard(
                    title: "活跃连接",
                    value: "12",
                    unit: "个",
                    color: .blue,
                    icon: "network"
                )
                
                dataCard(
                    title: "今日流量",
                    value: "2.4",
                    unit: "GB",
                    color: .green,
                    icon: "arrow.up.arrow.down"
                )
                
                dataCard(
                    title: "阻止连接",
                    value: "8",
                    unit: "次",
                    color: .red,
                    icon: "hand.raised.fill"
                )
                
                dataCard(
                    title: "监控应用",
                    value: "24",
                    unit: "个",
                    color: .orange,
                    icon: "apps.iphone"
                )
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
    }
    
    private func dataCard(title: String, value: String, unit: String, color: Color, icon: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
        )
    }
}

// MARK: - Action
extension AppStoreDemoView {
    private func toggleMonitoring() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPlaying.toggle()
        }
    }
}

// MARK: - Animation
extension AppStoreDemoView {
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            showAnimation = true
        }
    }
}

// MARK: - Data Models
struct DemoStep {
    let title: String
    let description: String
    let action: String
    let icon: String
    let color: Color
}

enum DemoType: CaseIterable {
    case monitoring
    case filtering
    case statistics
    case settings
    
    var title: String {
        switch self {
        case .monitoring: return "监控"
        case .filtering: return "过滤"
        case .statistics: return "统计"
        case .settings: return "设置"
        }
    }
    
    var icon: String {
        switch self {
        case .monitoring: return "eye.fill"
        case .filtering: return "shield.checkered"
        case .statistics: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .monitoring: return .blue
        case .filtering: return .green
        case .statistics: return .orange
        case .settings: return .purple
        }
    }
}

enum ConnectionStatus {
    case allowed
    case blocked
    case monitoring
    
    var title: String {
        switch self {
        case .allowed: return "允许"
        case .blocked: return "阻止"
        case .monitoring: return "监控"
        }
    }
    
    var color: Color {
        switch self {
        case .allowed: return .green
        case .blocked: return .red
        case .monitoring: return .blue
        }
    }
}

// MARK: - Preview
#Preview("Demo - Large") {
    AppStoreDemoView()
        .frame(width: 1200, height: 1000)
}

#Preview("Demo - Small") {
    AppStoreDemoView()
        .frame(width: 800, height: 600)
}
