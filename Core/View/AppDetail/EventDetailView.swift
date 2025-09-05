import MagicCore
import NetworkExtension
import OSLog
import SwiftUI
import SwiftData

/**
 * 事件详情视图
 *
 * 展示应用的网络事件详情，包括事件列表、筛选工具栏和分页控制
 * 使用 @Query 自动获取和更新数据，支持筛选和分页
 */
struct EventDetailView: View, SuperLog {
    nonisolated static let emoji = "📋"

    /// 应用ID
    let appId: String

    @State private var currentPage: Int = 0
    @State private var statusFilter: StatusFilter = .all
    @State private var directionFilter: DirectionFilter = .all

    private let eventsPerPage: Int = 20
    
    /// 使用 @Query 获取事件数据，支持动态筛选
    @Query var allEvents: [FirewallEventModel]
    
    init(appId: String) {
        self.appId = appId
        let predicate = #Predicate<FirewallEventModel> {
            $0.sourceAppIdentifier == appId
        }
        _allEvents = Query(filter: predicate, sort: \.time, order: .reverse)
    }
    
    /// 根据当前筛选条件过滤的事件
    private var filteredEvents: [FirewallEventModel] {
        allEvents.filter { event in
            // 状态筛选
            if statusFilter != .all {
                let statusValue = statusFilter == .allowed ? 0 : 1
                guard event.statusRawValue == statusValue else { return false }
            }
            
            // 方向筛选
            if directionFilter != .all {
                let directionValue = directionFilter == .inbound ? NETrafficDirection.inbound.rawValue : NETrafficDirection.outbound.rawValue
                guard event.directionRawValue == directionValue else { return false }
            }
            
            return true
        }
    }
    
    /// 分页后的事件数据
    private var paginatedEvents: [FirewallEventModel] {
        let startIndex = currentPage * eventsPerPage
        let endIndex = min(startIndex + eventsPerPage, filteredEvents.count)
        guard startIndex < filteredEvents.count else { return [] }
        return Array(filteredEvents[startIndex..<endIndex])
    }
    
    /// 总事件数量
    private var totalEventCount: Int {
        filteredEvents.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("事件详情")
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

            // 事件数量显示
            HStack {
                Text("共 \(totalEventCount) 条事件")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)

            ZStack {
                Table(paginatedEvents, columns: {
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

                // 空状态
                if paginatedEvents.isEmpty {
                    EmptyStateView(
                        iconName: "doc.text.magnifyingglass",
                        title: "暂无事件数据"
                    )
                }
            }

            // 分页控制
            if getTotalPages() > 1 {
                PaginationView(
                    currentPage: $currentPage,
                    totalPages: getTotalPages(),
                    isLoading: false,
                    onPreviousPage: {
                        // 分页变化会自动触发UI更新
                    },
                    onNextPage: {
                        // 分页变化会自动触发UI更新
                    }
                )
            }
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onChange(of: statusFilter) { _, _ in
            currentPage = 0 // 重置到第一页
        }
        .onChange(of: directionFilter) { _, _ in
            currentPage = 0 // 重置到第一页
        }
    }
}

// MARK: - Action

extension EventDetailView {
    /// 获取总页数
    private func getTotalPages() -> Int {
        return max(1, Int(ceil(Double(totalEventCount) / Double(eventsPerPage))))
    }
}


// MARK: - Preview


#Preview("App") {
    ContentView().inRootView()
    .frame(width: 600, height: 1000)
}
