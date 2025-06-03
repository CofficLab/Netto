import SwiftUI
import MagicCore
import OSLog

/**
 * 事件详情视图
 * 
 * 展示应用的网络事件详情，包括事件列表、筛选工具栏和分页控制
 */
struct EventDetailView: View, SuperLog {
    nonisolated static let emoji = "📋"
    
    /// 从数据库加载的事件列表
    @Binding var events: [FirewallEvent]
    
    /// 当前页码（从0开始）
    @Binding var currentPage: Int
    
    /// 状态筛选选项
    @Binding var statusFilter: StatusFilter
    
    /// 方向筛选选项
    @Binding var directionFilter: DirectionFilter
    
    /// 每页显示的事件数量
    private let eventsPerPage: Int = 20
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("事件详情 (Event Details)")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 筛选工具栏
            HStack(spacing: 8) {
                // 状态筛选
                Picker("状态", selection: $statusFilter) {
                    ForEach(StatusFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 180)
                
                Spacer()
                
                // 方向筛选
                Picker("方向", selection: $directionFilter) {
                    ForEach(DirectionFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 180)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor).opacity(0.7))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 0)
            .padding(.bottom, 8)
            
            // 筛选后的事件数量
            HStack {
                Spacer()
                Text("共 \(getFilteredEvents().count) 条事件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            
            Table(getCurrentPageEvents(), columns: {
                TableColumn("Time", value: \.timeFormatted).width(150)
                TableColumn("Address", value: \.address)
                TableColumn("Port", value: \.port).width(60)
                TableColumn("Direction") { event in
                    Text(event.direction == .inbound ? "入" : "出")
                        .foregroundStyle(event.isAllowed ? .green : .red)
                }.width(60)
                TableColumn("Status") { event in
                    Text(event.status == .allowed ? "允许" : "拒绝")
                        .foregroundStyle(event.isAllowed ? .green : .red)
                }.width(60)
            })
            .frame(minHeight: 200)
            .frame(maxHeight: 300)
            
            // 分页控制
            if getTotalPages() > 1 {
                HStack {
                    Button(action: {
                        if currentPage > 0 {
                            currentPage -= 1
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(currentPage > 0 ? .primary : .secondary)
                    }
                    .disabled(currentPage <= 0)
                    
                    Spacer()
                    
                    Text("第 \(currentPage + 1) 页，共 \(getTotalPages()) 页")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        if currentPage < getTotalPages() - 1 {
                            currentPage += 1
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(currentPage < getTotalPages() - 1 ? .primary : .secondary)
                    }
                    .disabled(currentPage >= getTotalPages() - 1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.controlBackgroundColor).opacity(0.6))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal, 0)
                .padding(.bottom, 8)
            }
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - 事件筛选和分页方法
    
    /// 根据筛选条件获取事件列表
    private func getFilteredEvents() -> [FirewallEvent] {
        var filteredEvents = events
        
        // 应用状态筛选
        if statusFilter != .all {
            filteredEvents = filteredEvents.filter { event in
                switch statusFilter {
                case .allowed:
                    return event.status == .allowed
                case .rejected:
                    return event.status == .rejected
                case .all:
                    return true
                }
            }
        }
        
        // 应用方向筛选
        if directionFilter != .all {
            filteredEvents = filteredEvents.filter { event in
                switch directionFilter {
                case .inbound:
                    return event.direction == .inbound
                case .outbound:
                    return event.direction == .outbound
                case .all:
                    return true
                }
            }
        }
        
        return filteredEvents
    }
    
    /// 获取当前页的事件数据
    private func getCurrentPageEvents() -> [FirewallEvent] {
        let filteredEvents = getFilteredEvents()
        let reversedEvents = Array(filteredEvents.reversed())
        let startIndex = currentPage * eventsPerPage
        let endIndex = min(startIndex + eventsPerPage, reversedEvents.count)
        
        if startIndex >= reversedEvents.count {
            return []
        }
        
        return Array(reversedEvents[startIndex..<endIndex])
    }
    
    /// 获取总页数
    private func getTotalPages() -> Int {
        return max(1, Int(ceil(Double(getFilteredEvents().count) / Double(eventsPerPage))))
    }
}


#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}

#Preview("事件详情视图") {
    EventDetailView(
        events: .constant([
            FirewallEvent(
                address: "example.com",
                port: "443",
                sourceAppIdentifier: "com.example.app",
                status: .allowed,
                direction: .outbound
            ),
            FirewallEvent(
                address: "test.com",
                port: "80",
                sourceAppIdentifier: "com.example.app",
                status: .rejected,
                direction: .inbound
            )
        ]),
        currentPage: .constant(0),
        statusFilter: .constant(.all),
        directionFilter: .constant(.all)
    )
    .frame(width: 600, height: 600)
}
