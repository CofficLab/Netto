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
    
    nonisolated static let emoji = "📋"

    /// 应用ID
    let appId: String

    /// 当前页码（从0开始）
    @State private var currentPage: Int = 0

    /// 状态筛选选项
    @State private var statusFilter: StatusFilter = .all

    /// 方向筛选选项
    @State private var directionFilter: DirectionFilter = .all

    /// 事件列表
    @State private var events: [FirewallEvent] = []

    /// 事件总数
    @State private var totalEventCount: Int = 0

    /// 每页显示的事件数量
    private let eventsPerPage: Int = 20
    
    private var firewallEventService: EventService {
        service.firewallEventService
    }

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

            // 事件数量
            HStack {
                Spacer()
                Text("共 \(totalEventCount) 条事件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)

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
                            loadEvents()
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
        .onAppear(perform: onAppear)
        .onChange(of: statusFilter) { _, _ in
            currentPage = 0 // 重置到第一页
            loadEvents()
        }
        .onChange(of: directionFilter) { _, _ in
            currentPage = 0 // 重置到第一页
            loadEvents()
        }
    }
}

// MARK: - 事件加载和分页方法

extension EventDetailView {
    /// 获取总页数
    private func getTotalPages() -> Int {
        return max(1, Int(ceil(Double(totalEventCount) / Double(eventsPerPage))))
    }

    /// 加载事件数据
    private func loadEvents() {
        do {
            // 获取状态筛选条件
            let statusFilterValue: FirewallEvent.Status? = statusFilter == .all ? nil :
                (statusFilter == .allowed ? .allowed : .rejected)

            // 获取方向筛选条件
            let directionFilterValue: NETrafficDirection? = directionFilter == .all ? nil :
                (directionFilter == .inbound ? .inbound : .outbound)

            // 获取事件总数
            totalEventCount = try firewallEventService.getEventCountByAppId(
                appId,
                statusFilter: statusFilterValue,
                directionFilter: directionFilterValue
            )

            // 获取分页数据
            events = try firewallEventService.getEventsByAppIdPaginated(
                appId,
                page: currentPage,
                pageSize: eventsPerPage,
                statusFilter: statusFilterValue,
                directionFilter: directionFilterValue
            )

            os_log("\(self.t)🍑 (\(appId)) 加载了 \(events.count) 个事件，总数: \(totalEventCount)")
        } catch {
            os_log(.error, "加载事件数据失败: \(error)")
            events = []
            totalEventCount = 0
        }
    }
}

// MARK: - Events

extension EventDetailView {
    /// 视图出现时加载数据
    private func onAppear() {
        loadEvents()
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}

#Preview("事件详情视图") {
    EventDetailView(appId: "59GAB85EFG.com.apple.dt.Xcode")
        .frame(width: 600, height: 600)
}
