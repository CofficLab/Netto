import Combine
import MagicCore
import NetworkExtension
import SwiftData
import SwiftUI

/// 数据库防火墙事件展示视图
/// 用于展示数据库中存储的所有防火墙事件记录
struct DBEventView: View {
    @EnvironmentObject private var repo: EventRepo

    // 存储加载的事件数据
    @State private var events: [FirewallEventDTO] = []
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

        isLoading = true

        // 捕获需要的值，避免在 Task 中捕获 self
        let currentFilterAppId = filterAppId
        let currentPage = currentPage
        let currentItemsPerPage = itemsPerPage
        let repo = self.repo

        Task {
            do {
                // 使用筛选条件获取事件总数
                let newTotalCount: Int
                if !currentFilterAppId.isEmpty {
                    newTotalCount = try await repo.getEventCountByAppId(currentFilterAppId)
                } else {
                    // 获取所有事件总数
                    newTotalCount = try await repo.getEventCount()
                }

                // 使用筛选条件获取分页数据
                let newEvents: [FirewallEventDTO]
                if !currentFilterAppId.isEmpty {
                    // 使用应用ID筛选
                    newEvents = try await repo.fetchByAppIdPaginated(
                        currentFilterAppId,
                        page: currentPage,
                        pageSize: currentItemsPerPage
                    )
                } else {
                    // 获取所有事件（分页）
                    newEvents = try await repo.fetchAllPaginated(
                        page: currentPage,
                        pageSize: currentItemsPerPage
                    )
                }

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

    /// 清除筛选条件
    private func clearFilter() {
        filterAppId = ""
        currentPage = 0
        loadEvents()
    }

    var body: some View {
        VStack {
            // 第一行工具栏：标题和基本操作
            HStack {
                Text("防火墙事件记录")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Text("共 \(totalCount) 条记录")
                    .foregroundStyle(.secondary)

                Button("刷新") {
                    loadEvents()
                }

                Button("打开数据库文件夹") {
                    try? URL.database.openFolder()
                }
            }
            .padding()

            // 第二行工具栏：筛选控制
            HStack {
                Text("应用ID筛选:")
                    .foregroundStyle(.secondary)

                TextField("输入应用ID", text: $filterAppId)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)

                Button("应用筛选") {
                    currentPage = 0 // 重置到第一页
                    loadEvents()
                }
                .buttonStyle(.borderedProminent)
                .disabled(filterAppId.isEmpty)

                if !filterAppId.isEmpty {
                    Button("清除筛选") {
                        clearFilter()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Text("提示: 应用ID通常是应用的Bundle ID，例如 com.apple.Safari")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // 事件表格
            Table(events) {
                // 时间列
                TableColumn("时间", value: \.timeFormatted)
                    .width(min: 120, ideal: 150)

                // 地址列
                TableColumn("地址") { event in
                    Text(event.address)
                        .font(.system(.body, design: .monospaced))
                }
                .width(min: 120, ideal: 200)

                // 端口列
                TableColumn("端口") { event in
                    Text(event.port)
                        .font(.system(.body, design: .monospaced))
                }
                .width(min: 60, ideal: 80)

                // 应用程序列
                TableColumn("应用程序") { event in
                    Text(event.sourceAppIdentifier.isEmpty ? "未知" : event.sourceAppIdentifier)
                        .foregroundStyle(event.sourceAppIdentifier.isEmpty ? .secondary : .primary)
                }
                .width(min: 100, ideal: 150)

                // 状态列
                TableColumn("状态") { event in
                    HStack {
                        Circle()
                            .fill(event.isAllowed ? .green : .red)
                            .frame(width: 8, height: 8)

                        Text(event.statusDescription)
                            .foregroundStyle(event.isAllowed ? .green : .red)
                    }
                }
                .width(min: 60, ideal: 80)

                // 方向列
                TableColumn("方向") { event in
                    HStack {
                        Image(systemName: event.direction == .inbound ? "arrow.down.circle" : "arrow.up.circle")
                            .foregroundStyle(event.direction == .inbound ? .blue : .orange)

                        Text(event.direction == .inbound ? "入站" : "出站")
                            .foregroundStyle(event.direction == .inbound ? .blue : .orange)
                    }
                }
                .width(min: 60, ideal: 80)

                // 描述列
                TableColumn("描述") { event in
                    Text(event.description)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .width(min: 100, ideal: 150)
            }
            .overlay {
                if isLoading {
                    ProgressView("加载中...")
                }
            }

            // 分页控制
            HStack {
                // 每页显示数量选择器
                HStack(spacing: 4) {
                    Text("每页显示:")
                        .foregroundStyle(.secondary)

                    Picker("", selection: $itemsPerPage) {
                        Text("10").tag(10)
                        Text("20").tag(20)
                        Text("50").tag(50)
                        Text("100").tag(100)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 70)
                    .onChange(of: itemsPerPage) { _, _ in
                        currentPage = 0 // 重置到第一页
                        loadEvents()
                    }
                }

                Spacer()

                // 页码控制
                HStack(spacing: 8) {
                    Button(action: {
                        currentPage = 0
                        loadEvents()
                    }) {
                        Image(systemName: "backward.end.fill")
                    }
                    .disabled(currentPage == 0 || isLoading)

                    Button(action: {
                        currentPage = max(0, currentPage - 1)
                        loadEvents()
                    }) {
                        Image(systemName: "chevron.backward")
                    }
                    .disabled(currentPage == 0 || isLoading)

                    Text("\(currentPage + 1) / \(totalPages)")
                        .frame(minWidth: 60)

                    Button(action: {
                        currentPage = min(totalPages - 1, currentPage + 1)
                        loadEvents()
                    }) {
                        Image(systemName: "chevron.forward")
                    }
                    .disabled(currentPage >= totalPages - 1 || isLoading)

                    Button(action: {
                        currentPage = totalPages - 1
                        loadEvents()
                    }) {
                        Image(systemName: "forward.end.fill")
                    }
                    .disabled(currentPage >= totalPages - 1 || isLoading)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationTitle("防火墙事件")
        .onAppear {
            // 视图出现时加载数据
            loadEvents()
        }
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
            loadEvents()
        }
    }
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(height: 600)
        .frame(width: 800)
}

#Preview {
    DBEventView()
        .inRootView()
        .frame(height: 600)
        .frame(width: 800)
}
