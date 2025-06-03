import SwiftUI
import SwiftData
import MagicCore
import NetworkExtension
import Combine

/// 数据库防火墙事件展示视图
/// 用于展示数据库中存储的所有防火墙事件记录
struct DBEventView: View {
    // 使用ModelContext替代直接Query
    @Environment(\.modelContext) private var modelContext
    
    // 存储加载的事件数据
    @State private var events: [FirewallEventModel] = []
    @State private var totalCount: Int = 0
    
    // 分页控制状态
    @State private var currentPage = 0
    @State private var itemsPerPage = 20
    @State private var isLoading = false
    
    // 刷新控制
    @State private var refreshTrigger = false
    @State private var refreshTimer: AnyCancellable?
    
    // 计算总页数
    private var totalPages: Int {
        return max(1, (totalCount + itemsPerPage - 1) / itemsPerPage)
    }
    
    /// 加载当前页的事件数据
    private func loadEvents() {
        guard !isLoading else { return }
        
        isLoading = true
        
        // 计算分页参数
        let startIndex = currentPage * itemsPerPage
        
        // 创建查询描述符，按时间倒序排列
        var descriptor = FetchDescriptor<FirewallEventModel>(sortBy: [SortDescriptor(\.time, order: .reverse)])
        
        // 设置分页限制
        descriptor.fetchLimit = itemsPerPage
        descriptor.fetchOffset = startIndex
        
        do {
            // 获取总数
            let countDescriptor = FetchDescriptor<FirewallEventModel>()
            totalCount = try modelContext.fetchCount(countDescriptor)
            
            // 获取当前页数据
            events = try modelContext.fetch(descriptor)
            
            // 检查页码边界
            checkPageBounds()
        } catch {
            print("加载事件数据失败: \(error)")
            events = []
        }
        
        isLoading = false
    }
    
    /// 检查并修正页码边界
    private func checkPageBounds() {
        let maxPage = max(0, totalPages - 1)
        if currentPage > maxPage {
            currentPage = maxPage
        }
    }
    
    /// 设置刷新定时器
    private func setupRefreshTimer() {
        // 取消现有定时器
        refreshTimer?.cancel()
        
        // 创建新定时器，每5秒刷新一次数据
        refreshTimer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                loadEvents()
            }
    }
    
    var body: some View {
        VStack {
            // 标题和统计信息
            HStack {
                Text("防火墙事件记录")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("共 \(totalCount) 条记录")
                    .foregroundStyle(.secondary)
                
                Button("刷新") {
                    loadEvents()
                }
                
                Button("打开数据库文件夹") {
                    try? URL.database.openFolder()
                }
            }
            .padding()
            
            // 事件表格
            Table(events) {
                // 时间列
                TableColumn("时间", value: \.timeFormatted)
                    .width(min: 120, ideal: 150)
                
                // 地址列
                TableColumn("地址") { event in
                    Text(event.address)
                        .font(.system(.body, design: .monospaced))
                }
                .width(min: 120, ideal: 200)
                
                // 端口列
                TableColumn("端口") { event in
                    Text(event.port)
                        .font(.system(.body, design: .monospaced))
                }
                .width(min: 60, ideal: 80)
                
                // 应用程序列
                TableColumn("应用程序") { event in
                    Text(event.sourceAppIdentifier.isEmpty ? "未知" : event.sourceAppIdentifier)
                        .foregroundStyle(event.sourceAppIdentifier.isEmpty ? .secondary : .primary)
                }
                .width(min: 100, ideal: 150)
                
                // 状态列
                TableColumn("状态") { event in
                    HStack {
                        Circle()
                            .fill(event.isAllowed ? .green : .red)
                            .frame(width: 8, height: 8)
                        
                        Text(event.statusDescription)
                            .foregroundStyle(event.isAllowed ? .green : .red)
                    }
                }
                .width(min: 60, ideal: 80)
                
                // 方向列
                TableColumn("方向") { event in
                    HStack {
                        Image(systemName: event.direction == .inbound ? "arrow.down.circle" : "arrow.up.circle")
                            .foregroundStyle(event.direction == .inbound ? .blue : .orange)
                        
                        Text(event.direction == .inbound ? "入站" : "出站")
                            .foregroundStyle(event.direction == .inbound ? .blue : .orange)
                    }
                }
                .width(min: 60, ideal: 80)
                
                // 描述列
                TableColumn("描述") { event in
                    Text(event.description)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .width(min: 100, ideal: 150)
            }
            .overlay {
                if isLoading {
                    ProgressView("加载中...")
                }
            }
            
            // 分页控制
            HStack {
                // 每页显示数量选择器
                HStack(spacing: 4) {
                    Text("每页显示:")
                        .foregroundStyle(.secondary)
                    
                    Picker("", selection: $itemsPerPage) {
                        Text("10").tag(10)
                        Text("20").tag(20)
                        Text("50").tag(50)
                        Text("100").tag(100)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 70)
                    .onChange(of: itemsPerPage) { _, _ in
                        currentPage = 0 // 重置到第一页
                        loadEvents()
                    }
                }
                
                Spacer()
                
                // 页码控制
                HStack(spacing: 8) {
                    Button(action: {
                        currentPage = 0
                        loadEvents()
                    }) {
                        Image(systemName: "backward.end.fill")
                    }
                    .disabled(currentPage == 0 || isLoading)
                    
                    Button(action: {
                        currentPage = max(0, currentPage - 1)
                        loadEvents()
                    }) {
                        Image(systemName: "chevron.backward")
                    }
                    .disabled(currentPage == 0 || isLoading)
                    
                    Text("\(currentPage + 1) / \(totalPages)")
                        .frame(minWidth: 60)
                    
                    Button(action: {
                        currentPage = min(totalPages - 1, currentPage + 1)
                        loadEvents()
                    }) {
                        Image(systemName: "chevron.forward")
                    }
                    .disabled(currentPage >= totalPages - 1 || isLoading)
                    
                    Button(action: {
                        currentPage = totalPages - 1
                        loadEvents()
                    }) {
                        Image(systemName: "forward.end.fill")
                    }
                    .disabled(currentPage >= totalPages - 1 || isLoading)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationTitle("防火墙事件")
        .onAppear {
            // 视图出现时加载数据
            loadEvents()
            // 设置刷新定时器
            setupRefreshTimer()
        }
        .onDisappear {
            // 视图消失时取消定时器
            refreshTimer?.cancel()
        }
    }
}

#Preview("防火墙事件视图") {
    RootView {
        DBEventView()
    }
    .frame(width: 600, height: 700)
}

#Preview("App") {
    RootView {
        ContentView()
    }
    .frame(width: 500)
    .frame(height: 800)
}

#Preview("DBSettingView") {
    RootView {
        DBSettingView()
    }
    .frame(width: 600, height: 800)
}
