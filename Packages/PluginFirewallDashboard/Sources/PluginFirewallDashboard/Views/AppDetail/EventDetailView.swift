import LumiUI
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

    @State private var model = EventDetailModel()
    @State private var currentPage: Int = 0
    @State private var statusFilter: StatusFilter = .all
    @State private var directionFilter: DirectionFilter = .all
    @State private var loadTask: Task<Void, Never>?

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

                EventTableView(events: model.events, isLoading: model.isLoading)

                if getTotalPages() > 1 {
                    PaginationView(
                        currentPage: $currentPage,
                        totalPages: getTotalPages(),
                        totalCount: model.totalCount,
                        pageSize: perPage,
                        isLoading: model.isLoading,
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
        .onDisappear {
            loadTask?.cancel()
        }
        .onChange(of: statusFilter) {
            resetPageAndReload()
        }
        .onChange(of: directionFilter) {
            resetPageAndReload()
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
                    await exportRecentLogs()
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

    // MARK: - Filter Mapping

    private var statusDecision: FirewallEventDecision? {
        switch statusFilter {
        case .all: return nil
        case .allowed: return .allowed
        case .rejected: return .rejected
        }
    }

    private var directionValue: FirewallTrafficDirection? {
        switch directionFilter {
        case .all: return nil
        case .inbound: return .inbound
        case .outbound: return .outbound
        }
    }
}

// MARK: - Action

extension EventDetailView {
    private func getTotalPages() -> Int {
        return max(1, Int(ceil(Double(model.totalCount) / Double(perPage))))
    }

    /// 筛选变化时回到第一页；若本来就在第一页则直接加载。
    ///
    /// 非零页时只改 `currentPage`，由它的 onChange 触发唯一一次加载，
    /// 避免「筛选 + 页码复位」重复发请求。
    private func resetPageAndReload() {
        if currentPage == 0 {
            updateDataSource()
        } else {
            currentPage = 0
        }
    }

    private func updateDataSource() {
        loadTask?.cancel()

        let query = FirewallEventQuery(
            appIdentifier: appId,
            status: statusDecision,
            direction: directionValue,
            page: currentPage,
            pageSize: perPage
        )
        // 令牌同步领取，保证后发起的请求总是最后生效。
        let token = model.beginRequest()
        let provider = queryRepo

        loadTask = Task {
            await model.load(query, token: token, from: provider)
        }
    }
}

// MARK: - Export

extension EventDetailView {
    /// 导出近期日志到下载目录（CSV）；仅在写入成功后提示。
    private func exportRecentLogs() async {
        let directory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        do {
            _ = try await EventCSVExport.export(
                provider: queryRepo,
                appId: appId,
                status: statusDecision,
                direction: directionValue,
                directory: directory
            )
            shell.post(ToastMessage(description: "已导出到下载目录"))
        } catch {
            shell.postError(error.localizedDescription)
        }
    }
}

// MARK: - Preview

#Preview("App") {
    ContentView()
        .dashboardPreviewRoot()
        .frame(width: 600, height: 1000)
}
