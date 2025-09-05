import MagicCore
import NetworkExtension
import OSLog
import SwiftUI

/**
 * 事件详情视图
 *
 * 展示应用的网络事件详情，包括事件列表、筛选工具栏和分页控制
 * 直接通过appId获取事件数据，支持分页加载和筛选
 */
struct EventDetailView: View, SuperLog {
    @EnvironmentObject private var service: ServiceProvider
    @EnvironmentObject private var repo: EventRepo
    
    nonisolated static let emoji = "📋"

    /// 应用ID
    let appId: String

    @State private var currentPage: Int = 0
    @State private var statusFilter: StatusFilter = .all
    @State private var directionFilter: DirectionFilter = .all
    @State private var events: [FirewallEvent] = []
    @State private var totalEventCount: Int = 0
    @State private var isLoading: Bool = false
    @State private var isInitialLoad: Bool = true
    @State private var loadError: String? = nil
    
    private let eventsPerPage: Int = 20
    private var firewallEventService: EventService {
        service.firewallEventService
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
                .disabled(isLoading)

                Spacer()

                // 方向筛选
                Picker("方向", selection: $directionFilter) {
                    ForEach(DirectionFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 180)
                .disabled(isLoading)
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

            // 事件数量和加载状态
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("加载中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let error = loadError {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text("加载失败: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                        Button(action: {
                            Task {
                                await loadEventsAsync()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .help("重试")
                    }
                } else {
                    Text("共 \(totalEventCount) 条事件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)

            ZStack {
                Table(events, columns: {
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
                .opacity(isLoading && isInitialLoad ? 0.3 : 1.0)

                // 初始加载时的骨架屏
                if isLoading && isInitialLoad {
                    VStack(spacing: 8) {
                        ForEach(0..<5, id: \.self) { _ in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 150, height: 16)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 120, height: 16)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 16)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 16)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 16)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // 空状态
                if !isLoading && !isInitialLoad && events.isEmpty && loadError == nil {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("暂无事件数据")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // 分页控制
            if getTotalPages() > 1 {
                HStack {
                    Button(action: {
                        if currentPage > 0 {
                            currentPage -= 1
                            loadEvents()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor((currentPage > 0 && !isLoading) ? .primary : .secondary)
                    }
                    .disabled(currentPage <= 0 || isLoading)

                    Spacer()

                    Text("第 \(currentPage + 1) 页，共 \(getTotalPages()) 页")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(action: {
                        if currentPage < getTotalPages() - 1 {
                            currentPage += 1
                            loadEvents()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor((currentPage < getTotalPages() - 1 && !isLoading) ? .primary : .secondary)
                    }
                    .disabled(currentPage >= getTotalPages() - 1 || isLoading)
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
        .onAppear(perform: onAppear)
        .onChange(of: statusFilter) { _, _ in
            currentPage = 0 // 重置到第一页
            Task {
                await loadEventsAsync()
            }
        }
        .onChange(of: directionFilter) { _, _ in
            currentPage = 0 // 重置到第一页
            Task {
                await loadEventsAsync()
            }
        }
    }
}

// MARK: - Action

extension EventDetailView {
    /// 获取总页数
    private func getTotalPages() -> Int {
        return max(1, Int(ceil(Double(totalEventCount) / Double(eventsPerPage))))
    }

    /// 异步加载事件数据
    private func loadEventsAsync() async {
        // 设置加载状态
        await MainActor.run {
            isLoading = true
            loadError = nil
        }

        do {
            // 获取状态筛选条件
            let statusFilterValue: FirewallEvent.Status? = statusFilter == .all ? nil :
                (statusFilter == .allowed ? .allowed : .rejected)

            // 获取方向筛选条件
            let directionFilterValue: NETrafficDirection? = directionFilter == .all ? nil :
                (directionFilter == .inbound ? .inbound : .outbound)

            // 使用Task在后台执行数据加载，避免阻塞主线程
            let (count, eventList) = try await Task {
                // 获取事件总数
                let count = try firewallEventService.getEventCountByAppId(
                    appId,
                    statusFilter: statusFilterValue,
                    directionFilter: directionFilterValue
                )

                // 获取分页数据
                let events = try firewallEventService.getEventsByAppIdPaginated(
                    appId,
                    page: currentPage,
                    pageSize: eventsPerPage,
                    statusFilter: statusFilterValue,
                    directionFilter: directionFilterValue
                )

                return (count, events)
            }.value

            // 更新UI状态
            await MainActor.run {
                totalEventCount = count
                events = eventList
                isInitialLoad = false
                os_log("\(self.t)🍑 (\(appId)) 异步加载了 \(eventList.count) 个事件，总数: \(count)")
            }
        } catch {
            await MainActor.run {
                os_log(.error, "异步加载事件数据失败: \(error)")
                loadError = error.localizedDescription
                events = []
                totalEventCount = 0
                isInitialLoad = false
            }
        }

        // 结束加载状态
        await MainActor.run {
            isLoading = false
        }
    }

    /// 同步加载事件数据（向后兼容，用于分页按钮）
    private func loadEvents() {
        Task {
            await loadEventsAsync()
        }
    }
}

// MARK: - Events

extension EventDetailView {
    private func onAppear() {
        Task.detached(priority: .background) {
            os_log("\(self.t)🍑 (\(appId)) 视图出现时加载数据")
            await loadEventsAsync()
        }
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}

#Preview("事件详情视图") {
    RootView {
        EventDetailView(appId: "59GAB85EFG.com.apple.dt.Xcode")
    }
    .frame(width: 600, height: 600)
}
