import MagicCore
import ProviderViewEnvironment
import MagicUI
import OSLog
import ProviderShell
import ProviderFirewallEvents
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
    private let perPage: Int = 20

    // MARK: - Environment

    /// 事件存储契约（替代旧 EventRepo；分页语义一致，0-based）。
    @Environment(\.eventsProvider) private var queryRepo: FirewallEventsProviding?

    /// Shell（Toast 出口）。
    @EnvironmentObject private var shell: ShellCenter

    // MARK: - State

    @State private var events: [FirewallEventSnapshot] = []
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
                        shell.post(ToastMessage(description: "已导出到下载目录"))
                    }
                }, label: {
                    HStack(spacing: 6) {
                        Image(systemName: .iconDownload)
                        Text("导出近期日志")
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

    private func setEvents(events: [FirewallEventSnapshot]) {
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
        // 契约缺失时保持空列表（明确 unavailable，不做强制解包）
        guard let queryRepo else {
            setEvents(events: [])
            setTotalEventCount(totalEventCount: 0)
            setLoading(false)
            return
        }
        // 先在主线程标记加载状态
        setLoading(true)

        // 捕获当前查询参数
        let queryAppId = appId
        let queryPage = currentPage
        let queryPerPage = perPage
        let status: FirewallEventDecision? = statusFilter == .all ? nil : (statusFilter == .allowed ? .allowed : .rejected)
        let direction: FirewallTrafficDirection? = directionFilter == .all ? nil : (directionFilter == .inbound ? .inbound : .outbound)

        Task {
            do {
                let page = try await queryRepo.fetchPage(FirewallEventQuery(
                    appIdentifier: queryAppId,
                    status: status,
                    direction: direction,
                    page: queryPage,
                    pageSize: queryPerPage
                ))
                self.setTotalEventCount(totalEventCount: page.totalCount)
                self.setEvents(events: page.events)
                self.setLoading(false)
            } catch {
                self.setEvents(events: [])
                self.setLoading(false)
            }
        }
    }
}

// MARK: - Export

extension EventDetailView {
    /// 导出所有日志到下载目录（CSV）
    private func exportAllLogs() async {
        guard let queryRepo else { return }
        do {
            let status: FirewallEventDecision? = statusFilter == .all ? nil : (statusFilter == .allowed ? .allowed : .rejected)
            let direction: FirewallTrafficDirection? = directionFilter == .all ? nil : (directionFilter == .inbound ? .inbound : .outbound)

            // 限制最多导出 1000 条记录，优先导出最近的
            let maxExportCount = 1000
            let pageSize = 200
            var all: [FirewallEventSnapshot] = []
            var page = 0

            while all.count < maxExportCount {
                let result = try await queryRepo.fetchPage(FirewallEventQuery(
                    appIdentifier: appId,
                    status: status,
                    direction: direction,
                    page: page,
                    pageSize: pageSize
                ))

                if result.events.isEmpty { break }

                // 如果加上这一页会超过限制，只取需要的部分
                let remaining = maxExportCount - all.count
                let itemsToAdd = Array(result.events.prefix(remaining))
                all.append(contentsOf: itemsToAdd)

                if itemsToAdd.count < result.events.count { break }
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
        .dashboardPreviewRoot()
        .frame(width: 600, height: 1000)
}
