import LumiUI
import OSLog
import ProviderFirewallEvents
import ProviderShell
import ProviderViewEnvironment
import SwiftUI

/**
 * 事件详情视图
 *
 * 展示应用的网络事件详情，包括事件列表、筛选工具栏和分页控制
 * 使用 Provider 契约获取和更新数据，支持筛选和分页
 */
struct EventDetailView: View {
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

    @LumiTheme private var theme

    var body: some View {
        AppCard(
            style: .subtle,
            cornerRadius: DesignTokens.Radius.md,
            showShadow: false
        ) {
            VStack(alignment: .leading, spacing: AppUI.Spacing.sm) {
                Text("事件详情")
                    .font(.appSectionTitle)
                    .foregroundStyle(theme.textPrimary)

                filterBar

                EventTableView(events: events, isLoading: $isLoading)

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
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("netto.events.detail")
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

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: AppUI.Spacing.sm) {
            AppSegmentedControl(
                StatusFilter.allCases.map(\.rawValue),
                selection: statusSelection,
                maxWidth: 180,
                accessibilityIdentifiers: StatusFilter.allCases.map { "netto.events.status.\($0.rawValue)" }
            )
            .accessibilityIdentifier("netto.events.status-filter")

            Spacer(minLength: 0)

            AppSegmentedControl(
                DirectionFilter.allCases.map(\.rawValue),
                selection: directionSelection,
                maxWidth: 180,
                accessibilityIdentifiers: DirectionFilter.allCases.map { "netto.events.direction.\($0.rawValue)" }
            )
            .accessibilityIdentifier("netto.events.direction-filter")

            AppButton("导出近期日志", systemImage: "arrow.down.circle", style: .secondary, size: .small) {
                Task {
                    await exportAllLogs()
                    shell.post(ToastMessage(description: "已导出到下载目录"))
                }
            }
            .accessibilityIdentifier("netto.events.export")
        }
    }

    private var statusSelection: Binding<Int> {
        Binding(
            get: { StatusFilter.allCases.firstIndex(of: statusFilter) ?? 0 },
            set: { statusFilter = StatusFilter.allCases[$0] }
        )
    }

    private var directionSelection: Binding<Int> {
        Binding(
            get: { DirectionFilter.allCases.firstIndex(of: directionFilter) ?? 0 },
            set: { directionFilter = DirectionFilter.allCases[$0] }
        )
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
