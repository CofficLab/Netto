import SwiftUI
import SwiftData
import MagicCore
import NetworkExtension

/// 数据库防火墙事件展示视图
/// 用于展示数据库中存储的所有防火墙事件记录
struct DBEventView: View {
    @Query(sort: \FirewallEventModel.time, order: .reverse)
    var events: [FirewallEventModel]
    
    // 分页控制状态
    @State private var currentPage = 0
    @State private var itemsPerPage = 20
    @State private var shouldCheckPageBounds = false
    
    // 计算总页数
    private var totalPages: Int {
        let total = events.count
        return max(1, (total + itemsPerPage - 1) / itemsPerPage)
    }
    
    // 获取当前页的事件数据
    private var currentPageEvents: [FirewallEventModel] {
        // 安全检查，避免索引越界
        guard !events.isEmpty else { return [] }
        
        // 计算有效的当前页码
        let validCurrentPage = min(currentPage, max(0, totalPages - 1))
        let startIndex = validCurrentPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, events.count)
        
        // 如果索引有效，返回当前页数据
        if startIndex < events.count {
            return Array(events[startIndex..<endIndex])
        }
        
        return []
    }
    
    /// 检查并修正页码边界
    private func checkPageBounds() {
        let maxPage = max(0, totalPages - 1)
        if currentPage > maxPage {
            currentPage = maxPage
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
                
                Text("共 \(events.count) 条记录")
                    .foregroundStyle(.secondary)
                
                Button("打开数据库文件夹") {
                    try? URL.database.openFolder()
                }
            }
            .padding(.horizontal)
            
            // 事件表格
            Table(currentPageEvents) {
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
                        // 当每页显示数量变化时，检查页码边界
                        checkPageBounds()
                    }
                }
                
                Spacer()
                
                // 页码控制
                HStack(spacing: 8) {
                    Button(action: {
                        currentPage = 0
                    }) {
                        Image(systemName: "backward.end.fill")
                    }
                    .disabled(currentPage == 0)
                    
                    Button(action: {
                        currentPage = max(0, currentPage - 1)
                    }) {
                        Image(systemName: "chevron.backward")
                    }
                    .disabled(currentPage == 0)
                    
                    Text("\(currentPage + 1) / \(totalPages)")
                        .frame(minWidth: 60)
                    
                    Button(action: {
                        currentPage = min(totalPages - 1, currentPage + 1)
                    }) {
                        Image(systemName: "chevron.forward")
                    }
                    .disabled(currentPage >= totalPages - 1)
                    
                    Button(action: {
                        currentPage = totalPages - 1
                    }) {
                        Image(systemName: "forward.end.fill")
                    }
                    .disabled(currentPage >= totalPages - 1)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationTitle("防火墙事件")
        .onAppear {
            // 视图出现时检查页码边界
            checkPageBounds()
        }
        .onChange(of: events.count) { _, _ in
            // 当事件数量变化时检查页码边界
            checkPageBounds()
        }
    }
}

#Preview("防火墙事件视图") {
    RootView {
        DBEventView()
    }
    .frame(width: 600, height: 600)
}

#Preview("App") {
    RootView {
        ContentView()
    }
    .frame(width: 500)
}

#Preview("DBSettingView") {
    RootView {
        DBSettingView()
    }
    .frame(width: 600, height: 800)
}
