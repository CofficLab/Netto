import SwiftUI
import MagicCore

/**
 * App Store 主要宣传页面
 * 展示应用的核心价值主张和主要功能
 */
struct AppStoreHeroView: View {
    @State private var showAnimation = false
    @State private var currentFeatureIndex = 0
    
    private let features = [
        ("shield.checkered", "实时网络监控", "监控所有应用的网络连接，实时了解数据流向"),
        ("eye.fill", "透明化网络活动", "让隐藏的网络活动变得可见，保护您的隐私"),
        ("lock.shield.fill", "智能过滤控制", "智能识别并控制可疑的网络连接"),
        ("chart.line.uptrend.xyaxis", "详细流量分析", "提供详细的网络流量统计和分析报告")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            topNavigationBar
            
            // 主要内容区域
            ScrollView {
                VStack(spacing: 60) {
                    // 英雄区域
                    heroSection
                    
                    // 功能特性轮播
                    featuresCarousel
                    
                    // 核心价值主张
                    valuePropositionSection
                    
                    // 下载按钮区域
                    downloadSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            startAnimations()
        }
    }
}

// MARK: - Top Navigation
extension AppStoreHeroView {
    private var topNavigationBar: some View {
        HStack {
            // Logo 和标题
            HStack(spacing: 12) {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                
                Text(AppConfig.appName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // 导航按钮
            HStack(spacing: 20) {
                Button("功能特性") {
                    // 滚动到功能区域
                }
                .foregroundColor(.primary)
                
                Button("截图预览") {
                    // 滚动到截图区域
                }
                .foregroundColor(.primary)
                
                Button("立即下载") {
                    // 跳转到下载
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial)
    }
}

// MARK: - Hero Section
extension AppStoreHeroView {
    private var heroSection: some View {
        VStack(spacing: 32) {
            // 主标题和描述
            VStack(spacing: 20) {
                Text("掌控您的网络世界")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(showAnimation ? 1 : 0)
                    .offset(y: showAnimation ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: showAnimation)
                
                Text("实时监控、智能过滤、透明化网络活动\n让您完全掌控 Mac 上的网络连接")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(showAnimation ? 1 : 0)
                    .offset(y: showAnimation ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: showAnimation)
            }
            
            // 应用图标和预览
            HStack(spacing: 40) {
                // 应用图标
                VStack(spacing: 16) {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.regularMaterial)
                                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                        )
                        .scaleEffect(showAnimation ? 1 : 0.8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.6), value: showAnimation)
                    
                    VStack(spacing: 8) {
                        Text(AppConfig.appName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("网络监控工具")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 功能预览图
                VStack(spacing: 16) {
                    Text("实时监控界面")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .frame(width: 300, height: 200)
                        .overlay(
                            VStack(spacing: 12) {
                                HStack {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 8, height: 8)
                                    Text("Safari - 允许")
                                        .font(.caption)
                                    Spacer()
                                }
                                
                                HStack {
                                    Circle()
                                        .fill(.orange)
                                        .frame(width: 8, height: 8)
                                    Text("Chrome - 监控中")
                                        .font(.caption)
                                    Spacer()
                                }
                                
                                HStack {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 8, height: 8)
                                    Text("可疑应用 - 已阻止")
                                        .font(.caption)
                                    Spacer()
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .opacity(showAnimation ? 1 : 0)
                        .offset(x: showAnimation ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.8), value: showAnimation)
                }
            }
        }
        .padding(.top, 40)
    }
}

// MARK: - Features Carousel
extension AppStoreHeroView {
    private var featuresCarousel: some View {
        VStack(spacing: 24) {
            Text("核心功能")
                .font(.title2)
                .fontWeight(.bold)
            
            TabView(selection: $currentFeatureIndex) {
                ForEach(0..<features.count, id: \.self) { index in
                    featureCard(features[index])
                        .tag(index)
                }
            }
            .frame(height: 200)
        }
    }
    
    private func featureCard(_ feature: (String, String, String)) -> some View {
        HStack(spacing: 24) {
            // 图标
            Image(systemName: feature.0)
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(.regularMaterial)
                        .shadow(color: .blue.opacity(0.2), radius: 10)
                )
            
            // 内容
            VStack(alignment: .leading, spacing: 12) {
                Text(feature.1)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(feature.2)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Value Proposition
extension AppStoreHeroView {
    private var valuePropositionSection: some View {
        VStack(spacing: 32) {
            Text("为什么选择 \(AppConfig.appName)？")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                valueCard(
                    icon: "shield.fill",
                    title: "隐私保护",
                    description: "实时监控网络活动，保护您的隐私安全",
                    color: .green
                )
                
                valueCard(
                    icon: "speedometer",
                    title: "性能优化",
                    description: "智能识别并阻止不必要的网络连接",
                    color: .blue
                )
                
                valueCard(
                    icon: "chart.bar.fill",
                    title: "数据分析",
                    description: "详细的网络流量统计和分析报告",
                    color: .orange
                )
                
                valueCard(
                    icon: "gearshape.fill",
                    title: "简单易用",
                    description: "直观的界面设计，轻松上手使用",
                    color: .purple
                )
            }
        }
    }
    
    private func valueCard(icon: String, title: String, description: String, color: Color) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Download Section
extension AppStoreHeroView {
    private var downloadSection: some View {
        VStack(spacing: 24) {
            Text("立即开始使用")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("免费下载，立即体验强大的网络监控功能")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
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
extension AppStoreHeroView {
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            showAnimation = true
        }
        
        // 自动轮播功能
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentFeatureIndex = (currentFeatureIndex + 1) % features.count
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("App Store Hero - Large") {
    AppStoreHeroView()
        .frame(width: 1200, height: 1000)
}

#Preview("App Store Hero - Small") {
    AppStoreHeroView()
        .frame(width: 800, height: 600)
}
