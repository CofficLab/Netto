import Combine
import AppKit
import LumiUI
import ProviderFirewallEvents
import ProviderViewEnvironment
import SwiftUI

/// 数据库防火墙事件展示视图
/// 用于展示数据库中存储的所有防火墙事件记录
/// 阶段 6 迁移：数据经 `FirewallEventsProviding` 契约读取（替代旧 EventRepo env）。
struct DBEventView: View {
    @LumiTheme private var theme

    @Environment(\.eventsProvider) private var envRepo: FirewallEventsProviding?

    /// 注入的事件契约（设置入口由插件在 onBoot 解析传入；nil 时回退环境）。
    private let injectedRepo: FirewallEventsProviding?

    /// 事件契约来源：注入优先，其次环境。
    private var repo: FirewallEventsProviding? { injectedRepo ?? envRepo }

    /// 是否设置导航标题（`.navigationTitle`）。
    ///
    /// 默认 **false**：本视图作为「数据库」设置入口的详情内容嵌入设置窗口，
    /// 而 SwiftUI 会把内容里的 `navigationTitle` 提升为**宿主窗口标题**，
    /// 导致设置窗口标题被改写成「防火墙事件」。仅在独立窗口/预览场景需要
    /// 标题时才开启。
    private let showsNavigationTitle: Bool

    /// 事件库所在目录（由插件从 `StorageProviding` 注入；nil 时按钮不可用）。
    private let eventsDirectory: URL?

    init(events: FirewallEventsProviding? = nil, eventsDirectory: URL? = nil, showsNavigationTitle: Bool = false) {
        self.injectedRepo = events
        self.eventsDirectory = eventsDirectory
        self.showsNavigationTitle = showsNavigationTitle
    }

    // 存储加载的事件数据
    @State private var events: [FirewallEventSnapshot] = []
    @State private var totalCount: Int = 0

    // 分页控制状态
    @State private var currentPage = 0
    @State private var itemsPerPage = 20
    @State private var isLoading = false

    // 筛选控制
    @State private var filterAppId: String = ""
    @State private var showFilterOptions = false

    // 刷新控制
    @State private var refreshTrigger = false

    // 计算总页数
    private var totalPages: Int {
        return max(1, (totalCount + itemsPerPage - 1) / itemsPerPage)
    }

    /// 加载当前页的事件数据
    private func loadEvents() {
        guard !isLoading else { return }
        guard let repo else { return }

        isLoading = true

        // 捕获需要的值，避免在 Task 中捕获 self
        let currentFilterAppId = filterAppId
        let currentPage = currentPage
        let currentItemsPerPage = itemsPerPage

        Task {
            do {
                // 使用筛选条件获取事件总数
                let newTotalCount: Int
                if !currentFilterAppId.isEmpty {
                    newTotalCount = try await repo.count(FirewallEventCountQuery(appIdentifier: currentFilterAppId))
                } else {
                    // 获取所有事件总数
                    newTotalCount = try await repo.totalCount()
                }

                // 使用筛选条件获取分页数据（契约统一分页；筛选条件为空传 nil）
                let newEvents = try await repo.fetchPage(FirewallEventQuery(
                    appIdentifier: currentFilterAppId.isEmpty ? nil : currentFilterAppId,
                    page: currentPage,
                    pageSize: currentItemsPerPage
                )).events

                await MainActor.run {
                    self.totalCount = newTotalCount
                    self.events = newEvents
                    self.isLoading = false

                    // 检查页码边界
                    self.checkPageBounds()
                }
            } catch {
                print("加载事件数据失败: \(error)")
                await MainActor.run {
                    self.events = []
                    self.isLoading = false
                }
            }
        }
    }

    /// 检查并修正页码边界
    private func checkPageBounds() {
        let maxPage = max(0, totalPages - 1)
        if currentPage > maxPage {
            currentPage = maxPage
        }
    }

    /// 每页数量的索引绑定（供 `AppSegmentedControl` 使用）
    private var pageSizeSelection: Binding<Int> {
        let options = [10, 20, 50, 100]
        return Binding(
            get: { options.firstIndex(of: itemsPerPage) ?? 1 },
            set: { index in
                guard options.indices.contains(index) else { return }
                itemsPerPage = options[index]
                currentPage = 0
                loadEvents()
            }
        )
    }

    /// 应用当前筛选条件
    private func applyFilter() {
        currentPage = 0
        loadEvents()
    }

    /// 清除筛选条件
    private func clearFilter() {
        filterAppId = ""
        currentPage = 0
        loadEvents()
    }

    var body: some View {
        VStack {
            // 第一行工具栏：标题和基本操作
            HStack(spacing: AppUI.Spacing.sm) {
                Text("Firewall Event Log")
                    .font(.appSectionTitle)
                    .foregroundStyle(theme.textPrimary)

                Spacer()

                Text("\(totalCount) records")
                    .font(.appCaption)
                    .foregroundStyle(theme.textSecondary)

                AppButton("Refresh", systemImage: "arrow.clockwise", style: .secondary, size: .small) {
                    loadEvents()
                }

                AppButton("Open Database Folder", systemImage: "folder", style: .secondary, size: .small) {
                    guard let eventsDirectory else { return }
                    NSWorkspace.shared.open(eventsDirectory)
                }
            }
            .padding(.horizontal, AppUI.Spacing.md)
            .padding(.vertical, AppUI.Spacing.sm)

            // 第二行工具栏：筛选控制
            HStack(spacing: AppUI.Spacing.sm) {
                AppSearchBar(text: $filterAppId, placeholder: "Enter an app ID", onSubmit: applyFilter)
                    .frame(width: 220)

                AppButton("Apply Filter", style: .primary, size: .small, action: applyFilter)
                    .disabled(filterAppId.isEmpty)

                if !filterAppId.isEmpty {
                    AppButton("Clear Filter", style: .secondary, size: .small, action: clearFilter)
                }

                Spacer()

                Text("Tip: an app ID is usually the bundle ID, for example com.apple.Safari")
                    .font(.appCaption)
                    .foregroundStyle(theme.textTertiary)
            }
            .padding(.horizontal, AppUI.Spacing.md)
            .padding(.bottom, AppUI.Spacing.sm)

            // 事件表格
            Table(events) {
                // 时间列
                TableColumn("Time", value: \.timeFormatted)
                    .width(min: 120, ideal: 150)

                // 地址列
                TableColumn("Address") { event in
                    Text(event.address)
                        .font(.system(.body, design: .monospaced))
                }
                .width(min: 120, ideal: 200)

                // 端口列
                TableColumn("Port") { event in
                    Text(event.port)
                        .font(.system(.body, design: .monospaced))
                }
                .width(min: 60, ideal: 80)

                // 应用程序列
                TableColumn("App") { event in
                    Text(event.sourceAppIdentifier.isEmpty ? String(localized: "Unknown") : event.sourceAppIdentifier)
                        .foregroundStyle(event.sourceAppIdentifier.isEmpty ? .secondary : .primary)
                }
                .width(min: 100, ideal: 150)

                // 状态列
                TableColumn("Status") { event in
                    HStack {
                        Circle()
                            .fill(event.isAllowed ? theme.success : theme.error)
                            .frame(width: 8, height: 8)

                        Text(event.statusDescription)
                            .foregroundStyle(event.isAllowed ? theme.success : theme.error)
                    }
                }
                .width(min: 60, ideal: 80)

                // 方向列
                TableColumn("Direction") { event in
                    HStack {
                        Image(systemName: event.direction == .inbound ? "arrow.down.circle" : "arrow.up.circle")
                            .foregroundStyle(event.direction == .inbound ? theme.info : theme.warning)

                        Text(event.direction == .inbound ? String(localized: "Inbound") : String(localized: "Outbound"))
                            .foregroundStyle(event.direction == .inbound ? theme.info : theme.warning)
                    }
                }
                .width(min: 60, ideal: 80)

                // 描述列
                TableColumn("Description") { event in
                    Text(event.description)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .width(min: 100, ideal: 150)
            }
            .overlay {
                if isLoading {
                    AppLoadingOverlay(message: "Loading…")
                }
            }

            // 分页控制
            HStack(spacing: AppUI.Spacing.md) {
                // 每页显示数量
                HStack(spacing: AppUI.Spacing.sm) {
                    Text("Rows per page")
                        .font(.appCaption)
                        .foregroundStyle(theme.textSecondary)

                    AppSegmentedControl(["10", "20", "50", "100"], selection: pageSizeSelection, maxWidth: 180)
                }

                Spacer()

                // 页码控制
                HStack(spacing: AppUI.Spacing.xs) {
                    AppButton(systemImage: "backward.end.fill") {
                        currentPage = 0
                        loadEvents()
                    }
                    .disabled(currentPage == 0 || isLoading)

                    AppButton(systemImage: "chevron.backward") {
                        currentPage = max(0, currentPage - 1)
                        loadEvents()
                    }
                    .disabled(currentPage == 0 || isLoading)

                    Text("\(currentPage + 1) / \(totalPages)")
                        .font(.appCaption)
                        .foregroundStyle(theme.textSecondary)
                        .frame(minWidth: 60)

                    AppButton(systemImage: "chevron.forward") {
                        currentPage = min(totalPages - 1, currentPage + 1)
                        loadEvents()
                    }
                    .disabled(currentPage >= totalPages - 1 || isLoading)

                    AppButton(systemImage: "forward.end.fill") {
                        currentPage = totalPages - 1
                        loadEvents()
                    }
                    .disabled(currentPage >= totalPages - 1 || isLoading)
                }
            }
            .padding(.horizontal, AppUI.Spacing.md)
            .padding(.bottom, AppUI.Spacing.sm)
        }
        // 导航标题仅在明确开启时设置：SwiftUI 会把内容里的
        // `navigationTitle` 提升为宿主窗口标题，嵌入设置窗口时会改写
        // 「设置」窗口标题，因此默认不设置。
        .modifier(OptInNavigationTitle(isEnabled: showsNavigationTitle, title: String(localized: "Firewall Events")))
        .onAppear {
            // 视图出现时加载数据
            loadEvents()
        }
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            loadEvents()
        }
    }
}

/// 按开关应用 `navigationTitle` 的视图修饰器。
private struct OptInNavigationTitle: ViewModifier {
    let isEnabled: Bool
    let title: String

    func body(content: Content) -> some View {
        if isEnabled {
            content.navigationTitle(title)
        } else {
            content
        }
    }
}

/// 仅用于 DEBUG 数据库表格的事件显示字段，避免宿主插件依赖 Dashboard 插件。
private extension FirewallEventSnapshot {
    var isAllowed: Bool { status == .allowed }

    var timeFormatted: String { time.fullDateTime }

    var description: String { "\(address):\(port)" }

    var statusDescription: String {
        switch status {
        case .allowed: String(localized: "Allowed")
        case .rejected: String(localized: "Blocked")
        }
    }
}

#Preview("APP") {
    DBEventView().frame(width: 800, height: 600)
}

#Preview {
    DBEventView().frame(width: 800, height: 600)
}
