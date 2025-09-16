import MagicCore
import NetworkExtension
import OSLog
import SwiftUI
import MagicAlert

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
    private let perPage: Int = 20

    // MARK: - Environment

    @EnvironmentObject private var queryRepo: EventRepo

    // MARK: - State

    @State private var events: [FirewallEventDTO] = []
    @State private var totalEventCount: Int = 0
    @State private var currentPage: Int = 0
    @State private var statusFilter: StatusFilter = .all
    @State private var directionFilter: DirectionFilter = .all
    @State private var isLoading: Bool = false

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

                Button(action: {
                    Task {
                        await exportAllLogs()
                        MagicMessageProvider.shared.success("已导出到下载目录")
                    }
                }, label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tray.and.arrow.down")
                        Text("导出全部日志")
                    }
                })
                .buttonStyle(.borderedProminent)
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

            // Data Table
            EventTableView(events: events, isLoading: $isLoading)

            // Pagination
            if getTotalPages() > 1 {
                PaginationView(
                    currentPage: $currentPage,
                    totalPages: getTotalPages(),
                    totalCount: totalEventCount,
                    pageSize: perPage,
                    isLoading: isLoading,
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

// MARK: - Setter

extension EventDetailView {
    @MainActor
    private func setLoading(_ loading: Bool) {
        self.isLoading = loading
    }

    private func setEvents(events: [FirewallEventDTO]) {
        self.events = events
    }

    private func setTotalEventCount(totalEventCount: Int) {
        self.totalEventCount = totalEventCount
    }
}

// MARK: - Action

extension EventDetailView {
    private func getTotalPages() -> Int {
        return max(1, Int(ceil(Double(totalEventCount) / Double(perPage))))
    }

    private func updateDataSource() {
        // 先在主线程标记加载状态
        setLoading(true)

        // 捕获当前查询参数
        let queryAppId = appId
        let queryPage = currentPage
        let queryPerPage = perPage
        let status: FirewallEvent.Status? = statusFilter == .all ? nil : (statusFilter == .allowed ? .allowed : .rejected)
        let direction: NETrafficDirection? = directionFilter == .all ? nil : (directionFilter == .inbound ? .inbound : .outbound)

        // 查询仓库的后台API
        queryRepo.loadAsync(
            appId: queryAppId,
            page: queryPage,
            pageSize: queryPerPage,
            status: status,
            direction: direction
        ) { totalCount, events in
            self.setTotalEventCount(totalEventCount: totalCount)
            self.setEvents(events: events)
            self.setLoading(false)
        }
    }
}

// MARK: - Export

extension EventDetailView {
    /// 导出所有日志到下载目录（CSV）
    private func exportAllLogs() async {
        do {
            let status: FirewallEvent.Status? = statusFilter == .all ? nil : (statusFilter == .allowed ? .allowed : .rejected)
            let direction: NETrafficDirection? = directionFilter == .all ? nil : (directionFilter == .inbound ? .inbound : .outbound)

            var page = 0
            let size = 200
            var all: [FirewallEventDTO] = []

            while true {
                let result = await withCheckedContinuation { continuation in
                    queryRepo.loadAsync(appId: appId, page: page, pageSize: size, status: status, direction: direction) { total, items in
                        continuation.resume(returning: (total, items))
                    }
                }
                all.append(contentsOf: result.1)
                if all.count >= result.0 || result.1.isEmpty { break }
                page += 1
            }

            let header = "id,time,address,port,appId,status,direction\n"
            let rows = all.map { e in
                let cols: [String] = [
                    e.id,
                    e.time.ISO8601Format(),
                    e.address,
                    e.port,
                    e.sourceAppIdentifier,
                    (e.status == .allowed ? "allowed" : "rejected"),
                    (e.direction == .inbound ? "inbound" : "outbound"),
                ]
                return cols.map { $0.replacingOccurrences(of: ",", with: " ") }.joined(separator: ",")
            }.joined(separator: "\n")
            let csv = header + rows + "\n"

            if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                let filename = "logs-\(appId)-\(Int(Date().timeIntervalSince1970)).csv"
                let url = downloads.appendingPathComponent(filename)
                try csv.data(using: .utf8)?.write(to: url)
                os_log("导出成功: \(url.path)")
            }
        } catch {
            os_log("导出失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview("App") {
    ContentView()
        .inRootView()
        .frame(width: 600, height: 1000)
}
