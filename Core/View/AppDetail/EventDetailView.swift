import MagicCore
import NetworkExtension
import OSLog
import SwiftData
import SwiftUI

/**
 * 事件详情视图
 *
 * 展示应用的网络事件详情，包括事件列表、筛选工具栏和分页控制
 * 使用 @Query 自动获取和更新数据，支持筛选和分页
 */
struct EventDetailView: View, SuperLog {
    nonisolated static let emoji = "📋"

    // MARK: - Dependencies & Configuration

    let appId: String
    private let eventsPerPage: Int = 20

    // MARK: - Environment

    @EnvironmentObject private var dataProvider: DataProvider

    // MARK: - State

    @State private var events: [FirewallEventModel] = []
    @State private var totalEventCount: Int = 0
    @State private var currentPage: Int = 0
    @State private var statusFilter: StatusFilter = .all
    @State private var directionFilter: DirectionFilter = .all

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("事件详情")
                .font(.title2)
                .fontWeight(.semibold)

            // Filter Toolbar
            HStack(spacing: 8) {
                Picker("状态", selection: $statusFilter) {
                    ForEach(StatusFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 180)

                Spacer()

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

            // Event Count
            HStack {
                Text("共 \(totalEventCount) 条事件")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)

            // Data Table
            ZStack {
                Table(events, columns: { // Use the new state variable 'events'
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

                if events.isEmpty {
                    EmptyStateView(
                        iconName: "doc.text.magnifyingglass",
                        title: "暂无事件数据"
                    )
                }
            }

            // Pagination
            if getTotalPages() > 1 {
                PaginationView(
                    currentPage: $currentPage,
                    totalPages: getTotalPages(),
                    isLoading: false,
                    onPreviousPage: {},
                    onNextPage: {}
                )
            }
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            updateDataSource()
        }
        .onChange(of: statusFilter) {
            currentPage = 0
            updateDataSource()
        }
        .onChange(of: directionFilter) {
            currentPage = 0
            updateDataSource()
        }
        .onChange(of: currentPage) {
            updateDataSource()
        }
    }
}

// MARK: - Action

extension EventDetailView {
    private func getTotalPages() -> Int {
        return max(1, Int(ceil(Double(totalEventCount) / Double(eventsPerPage))))
    }

    private func updateDataSource() {
        let eventRepo = dataProvider.eventRepo

        // Convert view-specific filters to data-layer filters
        let status: FirewallEvent.Status? = statusFilter == .all ? nil : (statusFilter == .allowed ? .allowed : .rejected)
        let direction: NETrafficDirection? = directionFilter == .all ? nil : (directionFilter == .inbound ? .inbound : .outbound)

        do {
            // Fetch count and data using the repository
            self.totalEventCount = try eventRepo.getEventCountByAppIdFiltered(appId, statusFilter: status, directionFilter: direction)
            self.events = try eventRepo.fetchByAppIdPaginated(appId, page: currentPage, pageSize: eventsPerPage, statusFilter: status, directionFilter: direction)
        } catch {
            self.events = []
            self.totalEventCount = 0
        }
    }
}

// MARK: - Preview

#Preview("App") {
    ContentView().inRootView()
        .frame(width: 600, height: 1000)
}
