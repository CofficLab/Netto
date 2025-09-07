import SwiftUI
import MagicCore

/**
 * App Store 应用截图展示页面
 * 展示应用的实际界面截图和使用场景
 */
struct AppStoreScreenshotsView: View {
    @State private var selectedScreenshot = 0
    @State private var showFullScreen = false
    @State private var currentCategory = 0
    
    private let categories = ["主界面", "监控视图", "设置页面", "统计报告"]
    
    private let screenshots: [ScreenshotItem] = [
        // 主界面
        ScreenshotItem(
            category: 0,
            title: "主控制面板",
            description: "简洁直观的主界面，实时显示网络状态",
            imageName: "main_interface",
            features: ["实时状态显示", "快速操作按钮", "应用列表", "状态指示器"]
        ),
        ScreenshotItem(
            category: 0,
            title: "菜单栏视图",
            description: "在菜单栏中快速访问和控制",
            imageName: "menubar_view",
            features: ["状态指示", "快速切换", "通知提醒", "一键控制"]
        ),
        
        // 监控视图
        ScreenshotItem(
            category: 1,
            title: "实时监控",
            description: "实时监控所有应用的网络活动",
            imageName: "realtime_monitor",
            features: ["实时连接列表", "流量统计", "状态过滤", "详细信息"]
        ),
        ScreenshotItem(
            category: 1,
            title: "连接详情",
            description: "查看每个连接的详细信息",
            imageName: "connection_details",
            features: ["连接信息", "数据统计", "历史记录", "操作选项"]
        ),
        ScreenshotItem(
            category: 1,
            title: "应用管理",
            description: "管理应用的网络访问权限",
            imageName: "app_management",
            features: ["应用列表", "权限设置", "批量操作", "规则管理"]
        ),
        
        // 设置页面
        ScreenshotItem(
            category: 2,
            title: "通用设置",
            description: "个性化配置应用行为",
            imageName: "general_settings",
            features: ["启动设置", "通知配置", "界面主题", "语言选择"]
        ),
        ScreenshotItem(
            category: 2,
            title: "安全设置",
            description: "配置安全策略和过滤规则",
            imageName: "security_settings",
            features: ["安全策略", "过滤规则", "威胁检测", "审计日志"]
        ),
        ScreenshotItem(
            category: 2,
            title: "高级选项",
            description: "高级用户的高级配置选项",
            imageName: "advanced_settings",
            features: ["高级过滤", "自定义规则", "API 配置", "调试选项"]
        ),
        
        // 统计报告
        ScreenshotItem(
            category: 3,
            title: "流量统计",
            description: "详细的网络流量使用统计",
            imageName: "traffic_stats",
            features: ["流量图表", "应用排行", "时间分析", "趋势预测"]
        ),
        ScreenshotItem(
            category: 3,
            title: "安全报告",
            description: "安全事件和威胁分析报告",
            imageName: "security_report",
            features: ["威胁统计", "事件时间线", "风险评估", "建议措施"]
        ),
        ScreenshotItem(
            category: 3,
            title: "导出报告",
            description: "导出详细的分析报告",
            imageName: "export_report",
            features: ["多格式导出", "自定义报告", "定时生成", "邮件发送"]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题
            headerSection
            
            // 分类选择器
            categorySelector
            
            // 截图展示区域
            screenshotsDisplay
            
            // 底部信息
            bottomInfo
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.03), Color.purple.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $showFullScreen) {
            FullScreenScreenshotView(
                screenshots: filteredScreenshots,
                selectedIndex: $selectedScreenshot
            )
        }
    }
}

// MARK: - Header Section
extension AppStoreScreenshotsView {
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("应用界面预览")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("通过实际截图了解 \(AppConfig.appName) 的界面设计和功能布局")
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
extension AppStoreScreenshotsView {
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<categories.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentCategory = index
                            selectedScreenshot = 0
                        }
                    }) {
                        Text(categories[index])
                            .font(.headline)
                            .foregroundColor(currentCategory == index ? .white : .primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(currentCategory == index ? 
                                          LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                                          LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(currentCategory == index ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
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

// MARK: - Screenshots Display
extension AppStoreScreenshotsView {
    private var screenshotsDisplay: some View {
        VStack(spacing: 24) {
            // 主要截图展示
            mainScreenshotView
            
            // 缩略图列表
            thumbnailListView
        }
        .padding(.horizontal, 20)
    }
    
    private var mainScreenshotView: some View {
        VStack(spacing: 16) {
            if !filteredScreenshots.isEmpty {
                let screenshot = filteredScreenshots[selectedScreenshot]
                
                // 截图标题
                VStack(spacing: 8) {
                    Text(screenshot.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(screenshot.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 截图展示
                Button(action: {
                    showFullScreen = true
                }) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .frame(height: 400)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundColor(.blue)
                                
                                Text("点击查看大图")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Text("\(screenshot.imageName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
                
                // 功能特性标签
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(screenshot.features, id: \.self) { feature in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.regularMaterial)
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var thumbnailListView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<filteredScreenshots.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedScreenshot = index
                        }
                    }) {
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.regularMaterial)
                                .frame(width: 120, height: 80)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.system(size: 24))
                                            .foregroundColor(selectedScreenshot == index ? .blue : .gray)
                                        
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .foregroundColor(selectedScreenshot == index ? .blue : .gray)
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedScreenshot == index ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            
                            Text(filteredScreenshots[index].title)
                                .font(.caption)
                                .foregroundColor(selectedScreenshot == index ? .blue : .primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var filteredScreenshots: [ScreenshotItem] {
        screenshots.filter { $0.category == currentCategory }
    }
}

// MARK: - Bottom Info
extension AppStoreScreenshotsView {
    private var bottomInfo: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal, 20)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("更多截图")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("在 App Store 中查看更多应用截图和视频演示")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("查看全部") {
                    showFullScreen = true
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

// MARK: - Full Screen Screenshot View
struct FullScreenScreenshotView: View {
    let screenshots: [ScreenshotItem]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    
    init(screenshots: [ScreenshotItem], selectedIndex: Binding<Int>) {
        self.screenshots = screenshots
        self._selectedIndex = selectedIndex
        self._currentIndex = State(initialValue: selectedIndex.wrappedValue)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部控制栏
                HStack {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) / \(screenshots.count)")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.5))
                
                // 截图展示区域
                TabView(selection: $currentIndex) {
                    ForEach(0..<screenshots.count, id: \.self) { index in
                        VStack(spacing: 20) {
                            // 截图
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.regularMaterial)
                                .frame(maxWidth: 800, maxHeight: 500)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.system(size: 64))
                                            .foregroundColor(.white)
                                        
                                        Text(screenshots[index].title)
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .fontWeight(.semibold)
                                    }
                                )
                                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            // 截图信息
                            VStack(spacing: 12) {
                                Text(screenshots[index].title)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(screenshots[index].description)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                        .tag(index)
                    }
                }
                .onChange(of: currentIndex) { newValue in
                    selectedIndex = newValue
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Data Models
struct ScreenshotItem: Identifiable {
    let id = UUID()
    let category: Int
    let title: String
    let description: String
    let imageName: String
    let features: [String]
}

// MARK: - Preview
#Preview("Screenshots - Large") {
    AppStoreScreenshotsView()
        .frame(width: 1200, height: 1000)
}

#Preview("Screenshots - Small") {
    AppStoreScreenshotsView()
        .frame(width: 800, height: 600)
}

#Preview("Full Screen") {
    FullScreenScreenshotView(
        screenshots: [
            ScreenshotItem(
                category: 0,
                title: "主控制面板",
                description: "简洁直观的主界面，实时显示网络状态",
                imageName: "main_interface",
                features: ["实时状态显示", "快速操作按钮", "应用列表", "状态指示器"]
            )
        ],
        selectedIndex: .constant(0)
    )
}
