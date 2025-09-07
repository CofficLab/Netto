import SwiftUI
import MagicCore

/**
 * App Store 主视图
 * 整合所有宣传页面，提供统一的 App Store 展示体验
 */
struct AppStoreMainView: View {
    @State private var selectedTab = 0
    @State private var showWelcome = true
    
    private let tabs = [
        ("house.fill", "首页"),
        ("star.fill", "功能"),
        ("photo.fill", "截图"),
        ("heart.fill", "收益"),
        ("play.fill", "演示"),
        ("quote.bubble.fill", "评价")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            topNavigationBar
            
            // 主要内容区域
            TabView(selection: $selectedTab) {
                AppStoreHeroView()
                    .tag(0)
                
                AppStoreFeaturesView()
                    .tag(1)
                
                AppStoreScreenshotsView()
                    .tag(2)
                
                AppStoreBenefitsView()
                    .tag(3)
                
                AppStoreDemoView()
                    .tag(4)
                
                AppStoreTestimonialsView()
                    .tag(5)
            }
            
            // 底部标签栏
            bottomTabBar
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $showWelcome) {
            AppStoreWelcomeView()
        }
    }
}

// MARK: - Top Navigation Bar
extension AppStoreMainView {
    private var topNavigationBar: some View {
        HStack {
            // Logo 和标题
            HStack(spacing: 12) {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(AppConfig.appName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("App Store 预览")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 操作按钮
            HStack(spacing: 16) {
                Button("分享") {
                    // 分享逻辑
                }
                .foregroundColor(.primary)
                
                Button("收藏") {
                    // 收藏逻辑
                }
                .foregroundColor(.primary)
                
                Button("立即下载") {
                    // 下载逻辑
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial)
    }
}

// MARK: - Bottom Tab Bar
extension AppStoreMainView {
    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].0)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedTab == index ? .blue : .secondary)
                        
                        Text(tabs[index].1)
                            .font(.caption)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                            .foregroundColor(selectedTab == index ? .blue : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .background(.regularMaterial)
    }
}

// MARK: - Welcome View
struct AppStoreWelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAnimation = false
    
    var body: some View {
        VStack(spacing: 32) {
            // 欢迎内容
            VStack(spacing: 24) {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .scaleEffect(showAnimation ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showAnimation)
                
                VStack(spacing: 16) {
                    Text("欢迎来到 \(AppConfig.appName)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("探索强大的网络监控功能，\n让您的网络使用更加安全透明")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(showAnimation ? 1 : 0)
                        .offset(y: showAnimation ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.4), value: showAnimation)
                }
            }
            
            // 功能预览
            VStack(spacing: 16) {
                Text("主要功能")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    featurePreview("实时监控", icon: "eye.fill", color: .blue)
                    featurePreview("智能过滤", icon: "shield.checkered", color: .green)
                    featurePreview("流量分析", icon: "chart.bar.fill", color: .orange)
                    featurePreview("隐私保护", icon: "lock.shield.fill", color: .purple)
                }
            }
            .opacity(showAnimation ? 1 : 0)
            .offset(y: showAnimation ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.6), value: showAnimation)
            
            // 操作按钮
            VStack(spacing: 12) {
                Button("开始探索") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("稍后再说") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .opacity(showAnimation ? 1 : 0)
            .offset(y: showAnimation ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.8), value: showAnimation)
        }
        .padding(40)
        .frame(width: 500, height: 600)
        .background(.regularMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showAnimation = true
            }
        }
    }
    
    private func featurePreview(_ title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Preview
#Preview("App Store Main - Large") {
    AppStoreMainView()
        .frame(width: 1200, height: 1000)
}

#Preview("App Store Main - Small") {
    AppStoreMainView()
        .frame(width: 800, height: 600)
}

#Preview("Welcome") {
    AppStoreWelcomeView()
}
