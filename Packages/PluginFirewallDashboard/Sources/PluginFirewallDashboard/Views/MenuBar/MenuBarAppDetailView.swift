import LumiUI
import ProviderAppSettings
import ProviderFirewallEvents
import ProviderShell
import ProviderViewEnvironment
import SwiftUI

/// 菜单栏弹窗内的应用详情：规则开关 + 筛选 + 紧凑事件列表 + CSV 导出。
///
/// 复用旧主窗口事件详情的查询/导出逻辑（`EventDetailModel` / `EventCSVExport`），
/// 只把表格换成 360pt 宽可用的行式列表，避免在弹窗里横向滚动表格。
struct MenuBarAppDetailView: View {
    @EnvironmentObject private var shell: ShellCenter
    @Environment(\.eventsProvider) private var queryRepo
    @Environment(\.settingsProvider) private var settingsRepo
    @LumiTheme private var theme

    let app: SmartApp
    let onBack: () -> Void
    /// 规则变更后回调（列表需要重新加载以反映最新状态）。
    var onRuleChange: (() -> Void)?

    @State private var model = EventDetailModel()
    @State private var currentPage = 0
    @State private var statusFilter: StatusFilter = .all
    @State private var directionFilter: DirectionFilter = .all
    @State private var shouldAllow = true
    @State private var loadTask: Task<Void, Never>?

    private let perPage = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            eventFilters
            Divider()
            eventsSection
            footer
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(height: 360, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("netto.app.detail")
        .onAppear(perform: handleAppear)
        .onDisappear { loadTask?.cancel() }
        .onChange(of: statusFilter) { resetPageAndReload() }
        .onChange(of: directionFilter) { resetPageAndReload() }
        .onChange(of: currentPage) { reload() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                AppButton(systemImage: "chevron.left", style: .ghost, size: .small, action: onBack)
                    .accessibilityLabel("返回应用列表")
                    .accessibilityIdentifier("netto.app.detail.back")

                Text(app.name)
                    .font(.appBodyEmphasized)
                    .lineLimit(1)

                Spacer(minLength: 4)

                AppAction(shouldAllow: $shouldAllow, appId: app.id, onRuleChange: onRuleChange)
                    .accessibilityIdentifier("netto.app.detail.rule")
            }

            HStack(spacing: 8) {
                app.getIcon()
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 1) {
                    Text(app.id)
                        .font(.appCaption)
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text(shouldAllow ? "允许联网" : "已阻止联网")
                        .font(.appMicro)
                        .foregroundStyle(shouldAllow ? theme.textSecondary : theme.error)
                }

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Filters

    private var eventFilters: some View {
        HStack(spacing: 6) {
            AppSegmentedControl(
                StatusFilter.allCases.map(\.rawValue),
                selection: statusSelection,
                maxWidth: 150,
                accessibilityIdentifiers: StatusFilter.allCases.map { "netto.events.status.\($0.rawValue)" }
            )
            .accessibilityIdentifier("netto.events.status-filter")

            AppSegmentedControl(
                DirectionFilter.allCases.map(\.rawValue),
                selection: directionSelection,
                maxWidth: 96,
                accessibilityIdentifiers: DirectionFilter.allCases.map { "netto.events.direction.\($0.rawValue)" }
            )
            .accessibilityIdentifier("netto.events.direction-filter")

            Spacer(minLength: 0)

            AppButton(systemImage: "square.and.arrow.down", style: .ghost, size: .small) {
                Task { await exportRecentLogs() }
            }
            .help("导出近期日志")
            .accessibilityLabel("导出近期日志")
            .accessibilityIdentifier("netto.events.export")
        }
    }

    // MARK: - Events

    private var eventsSection: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                if model.isLoading && model.events.isEmpty {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                } else if model.events.isEmpty {
                    Text("暂无事件数据")
                        .font(.appCaption)
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                } else {
                    ForEach(model.events, id: \.id) { event in
                        eventRow(event)
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("netto.events.detail")
    }

    private func eventRow(_ event: FirewallEventSnapshot) -> some View {
        HStack(spacing: 6) {
            Image(systemName: event.status == .allowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(event.isAllowed ? Color.green : theme.error)

            Text(event.timeFormatted)
                .font(.appMicro)
                .foregroundStyle(theme.textSecondary)

            Text(event.address)
                .font(.appCaption)
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 4)

            Text("\(event.port)")
                .font(.appMicro)
                .foregroundStyle(theme.textTertiary)

            Image(systemName: event.direction == .inbound ? "arrow.down" : "arrow.up")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(theme.textTertiary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            AppButton(systemImage: "chevron.left", style: .ghost, size: .small) {
                guard currentPage > 0 else { return }
                currentPage -= 1
            }
            .disabled(currentPage <= 0 || model.isLoading)
            .accessibilityLabel("上一页")
            .accessibilityIdentifier("netto.events.prev")

            Spacer(minLength: 0)

            Text("第 \(currentPage + 1)/\(totalPages) 页 · 共 \(model.totalCount) 条")
                .font(.appMicro)
                .foregroundStyle(theme.textSecondary)

            Spacer(minLength: 0)

            AppButton(systemImage: "chevron.right", style: .ghost, size: .small) {
                guard currentPage < totalPages - 1 else { return }
                currentPage += 1
            }
            .disabled(currentPage >= totalPages - 1 || model.isLoading)
            .accessibilityLabel("下一页")
            .accessibilityIdentifier("netto.events.next")
        }
    }

    // MARK: - Loading

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

    private var totalPages: Int {
        max(1, Int(ceil(Double(model.totalCount) / Double(perPage))))
    }

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

    private func handleAppear() {
        Task {
            shouldAllow = await settingsRepo?.shouldAllow(app.id) ?? true
        }
        reload()
    }

    private func resetPageAndReload() {
        if currentPage == 0 {
            reload()
        } else {
            currentPage = 0
        }
    }

    private func reload() {
        loadTask?.cancel()

        let query = FirewallEventQuery(
            appIdentifier: app.id,
            status: statusDecision,
            direction: directionValue,
            page: currentPage,
            pageSize: perPage
        )
        let token = model.beginRequest()
        let provider = queryRepo

        loadTask = Task {
            await model.load(query, token: token, from: provider)
        }
    }

    private func exportRecentLogs() async {
        let directory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        do {
            _ = try await EventCSVExport.export(
                provider: queryRepo,
                appId: app.id,
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