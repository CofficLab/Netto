import SwiftUI
import MagicCore

/**
 * App Store 用户评价和推荐页面
 * 展示用户评价、推荐和成功案例
 */
struct AppStoreTestimonialsView: View {
    @State private var selectedTestimonial = 0
    @State private var showAnimation = false
    @State private var currentCategory = 0
    
    private let categories = ["全部评价", "5星好评", "专业用户", "企业用户"]
    
    private let testimonials: [TestimonialItem] = [
        TestimonialItem(
            category: 0,
            rating: 5,
            title: "非常实用的网络监控工具",
            content: "使用 \(AppConfig.appName) 已经半年了，它帮我发现了许多隐藏的网络活动。界面简洁，功能强大，是我用过最好的网络监控工具。",
            author: "张工程师",
            role: "软件开发者",
            avatar: "person.circle.fill",
            verified: true,
            date: "2024-01-15"
        ),
        TestimonialItem(
            category: 0,
            rating: 5,
            title: "企业网络安全的得力助手",
            content: "作为IT管理员，我需要监控公司网络使用情况。\(AppConfig.appName) 提供了详细的网络活动报告，帮助我们及时发现安全威胁。",
            author: "李经理",
            role: "IT管理员",
            avatar: "person.circle.fill",
            verified: true,
            date: "2024-01-10"
        ),
        TestimonialItem(
            category: 1,
            rating: 5,
            title: "简单易用，功能强大",
            content: "作为一个普通用户，我担心个人隐私泄露。这个应用让我能够清楚地看到哪些应用在访问网络，给了我很大的安全感。",
            author: "王女士",
            role: "普通用户",
            avatar: "person.circle.fill",
            verified: false,
            date: "2024-01-08"
        ),
        TestimonialItem(
            category: 1,
            rating: 5,
            title: "开发调试的好帮手",
            content: "在开发过程中，我需要监控应用的网络请求。\(AppConfig.appName) 提供了详细的连接信息，大大提高了我的开发效率。",
            author: "陈开发者",
            role: "iOS开发者",
            avatar: "person.circle.fill",
            verified: true,
            date: "2024-01-05"
        ),
        TestimonialItem(
            category: 2,
            rating: 5,
            title: "专业级网络分析工具",
            content: "作为网络安全专家，我对工具的要求很高。\(AppConfig.appName) 不仅提供了基础的监控功能，还有深度的流量分析，完全满足我的专业需求。",
            author: "刘专家",
            role: "网络安全专家",
            avatar: "person.circle.fill",
            verified: true,
            date: "2024-01-03"
        ),
        TestimonialItem(
            category: 2,
            rating: 5,
            title: "系统管理员的首选",
            content: "管理多台Mac设备时，需要统一的网络监控方案。\(AppConfig.appName) 的集中管理功能让我的工作变得轻松很多。",
            author: "赵管理员",
            role: "系统管理员",
            avatar: "person.circle.fill",
            verified: true,
            date: "2024-01-01"
        ),
        TestimonialItem(
            category: 3,
            rating: 5,
            title: "企业级安全解决方案",
            content: "我们公司使用 \(AppConfig.appName) 来监控员工网络活动，有效防止了数据泄露。审计报告功能特别有用，满足了合规要求。",
            author: "孙总监",
            role: "信息安全总监",
            avatar: "person.circle.fill",
            verified: true,
            date: "2023-12-28"
        ),
        TestimonialItem(
            category: 3,
            rating: 5,
            title: "提升团队工作效率",
            content: "团队使用 \(AppConfig.appName) 后，网络问题排查效率提升了50%。实时监控功能让我们能够快速定位问题。",
            author: "周主管",
            role: "技术主管",
            avatar: "person.circle.fill",
            verified: true,
            date: "2023-12-25"
        )
    ]
    
    private let stats: [StatItem] = [
        StatItem(title: "用户评分", value: "4.9", unit: "分", color: .orange),
        StatItem(title: "总评价数", value: "1,234", unit: "条", color: .blue),
        StatItem(title: "5星好评率", value: "96%", unit: "", color: .green),
        StatItem(title: "推荐率", value: "98%", unit: "", color: .purple)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题
            headerSection
            
            // 统计数据
            statsSection
            
            // 分类选择器
            categorySelector
            
            // 评价列表
            testimonialsList
            
            // 底部操作
            bottomActions
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.03), Color.purple.opacity(0.02)],
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
extension AppStoreTestimonialsView {
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("用户评价")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("听听用户对 \(AppConfig.appName) 的真实评价和推荐")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
}

// MARK: - Stats Section
extension AppStoreTestimonialsView {
    private var statsSection: some View {
        HStack(spacing: 20) {
            ForEach(stats, id: \.title) { stat in
                VStack(spacing: 8) {
                    Text(stat.value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(stat.color)
                    
                    Text(stat.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if !stat.unit.isEmpty {
                        Text(stat.unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(stat.color.opacity(0.05))
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Category Selector
extension AppStoreTestimonialsView {
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<categories.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentCategory = index
                            selectedTestimonial = 0
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

// MARK: - Testimonials List
extension AppStoreTestimonialsView {
    private var testimonialsList: some View {
        VStack(spacing: 20) {
            if !filteredTestimonials.isEmpty {
                // 主要评价展示
                TabView(selection: $selectedTestimonial) {
                    ForEach(0..<filteredTestimonials.count, id: \.self) { index in
                        testimonialCard(filteredTestimonials[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 300)
                
                // 缩略图列表
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<filteredTestimonials.count, id: \.self) { index in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedTestimonial = index
                                }
                            }) {
                                VStack(spacing: 8) {
                                    // 评分星星
                                    HStack(spacing: 2) {
                                        ForEach(0..<5, id: \.self) { star in
                                            Image(systemName: star < filteredTestimonials[index].rating ? "star.fill" : "star")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    
                                    // 评价标题
                                    Text(filteredTestimonials[index].title)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedTestimonial == index ? .blue : .primary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                    
                                    // 作者
                                    Text(filteredTestimonials[index].author)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .frame(width: 120, height: 80)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedTestimonial == index ? 
                                              Color.blue.opacity(0.1) : .regularMaterial)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedTestimonial == index ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private var filteredTestimonials: [TestimonialItem] {
        switch currentCategory {
        case 0: return testimonials
        case 1: return testimonials.filter { $0.rating == 5 }
        case 2: return testimonials.filter { $0.verified }
        case 3: return testimonials.filter { $0.role.contains("管理员") || $0.role.contains("总监") || $0.role.contains("主管") }
        default: return testimonials
        }
    }
    
    private func testimonialCard(_ testimonial: TestimonialItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 头部信息
            HStack(spacing: 12) {
                // 头像
                Image(systemName: testimonial.avatar)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(.blue.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(testimonial.author)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if testimonial.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    
                    Text(testimonial.role)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { star in
                            Image(systemName: star < testimonial.rating ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        Text(testimonial.date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // 评价内容
            VStack(alignment: .leading, spacing: 8) {
                Text(testimonial.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(testimonial.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Bottom Actions
extension AppStoreTestimonialsView {
    private var bottomActions: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                Text("加入我们的用户社区")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("立即下载 \(AppConfig.appName)，体验强大的网络监控功能")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Button("免费下载") {
                        // 下载逻辑
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("查看所有评价") {
                        // 查看更多评价
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(.regularMaterial)
    }
}

// MARK: - Animation
extension AppStoreTestimonialsView {
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            showAnimation = true
        }
        
        // 自动轮播评价
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.5)) {
                    if !filteredTestimonials.isEmpty {
                        selectedTestimonial = (selectedTestimonial + 1) % filteredTestimonials.count
                    }
                }
            }
        }
    }
}

// MARK: - Data Models
struct TestimonialItem: Identifiable {
    let id = UUID()
    let category: Int
    let rating: Int
    let title: String
    let content: String
    let author: String
    let role: String
    let avatar: String
    let verified: Bool
    let date: String
}

struct StatItem {
    let title: String
    let value: String
    let unit: String
    let color: Color
}

// MARK: - Preview
#Preview("Testimonials - Large") {
    AppStoreTestimonialsView()
        .frame(width: 1200, height: 1000)
}

#Preview("Testimonials - Small") {
    AppStoreTestimonialsView()
        .frame(width: 800, height: 600)
}
