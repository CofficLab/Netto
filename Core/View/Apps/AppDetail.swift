import SwiftUI
import MagicCore
import OSLog

struct AppDetail: View, SuperLog {
    nonisolated static let emoji = "🖥️"
    
    @EnvironmentObject var data: DataProvider
    
    @Binding var popoverHovering: Bool
    
    /// 复制状态，用于显示复制成功的动画提示
    @State private var isCopied = false
    
    /// 从数据库加载的事件列表
    @State private var events: [FirewallEvent] = []
    
    /// 当前页码（从0开始）
    @State private var currentPage: Int = 0
    
    /// 是否显示代理解释视图
    @State private var showProxyExplanation = false
    
    /// 每页显示的事件数量
    private let eventsPerPage: Int = 20
    
    /// 防火墙事件服务
    private let firewallEventService = FirewallEventService()
    
    /// 状态筛选选项
    @State private var statusFilter: StatusFilter = .all
    
    /// 方向筛选选项
    @State private var directionFilter: DirectionFilter = .all

    var app: SmartApp

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 应用信息展示区域
            VStack(alignment: .leading, spacing: 8) {
                Text("应用详情 (Application Details)")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // 应用基本信息
                HStack(spacing: 12) {
                    app.getIcon()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // App ID 和复制按钮
                        HStack(spacing: 6) {
                            Text("ID: \(app.id)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                            
                            Button(action: {
                                copyAppID()
                            }) {
                                Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                    .foregroundColor(isCopied ? .green : .secondary)
                                    .font(.caption)
                                    .scaleEffect(isCopied ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCopied)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help(isCopied ? "已复制!" : "复制 App ID")
                        }
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // 应用属性信息
                VStack(alignment: .leading, spacing: 6) {
                    Text("属性信息 (Properties)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(spacing: 4) {
                        // 根据应用类型显示相应的标签
                        if app.isSystemApp {
                            // 系统应用标签
                            HStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                        .frame(width: 12, alignment: .center)
                                    
                                    Text("系统应用 (System App)")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                                
                                Spacer(minLength: 0)
                            }
                        } else if SmartApp.isProxyApp(withId: app.id) {
                            // 代理应用标签
                            HStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "shield.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                        .frame(width: 12, alignment: .center)
                                    
                                    Text("代理应用 (Proxy App)")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                }
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showProxyExplanation.toggle()
                                    }
                                }) {
                                    Image(systemName: showProxyExplanation ? "chevron.up.circle.fill" : "info.circle")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .help(showProxyExplanation ? "收起代理应用说明" : "了解代理应用对网络监控的影响")

                                Spacer(minLength: 0)
                            }
                        }
                    }
                    
                    // Bundle URL 信息
                    if let bundleURL = app.bundleURL {
                        HStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder")
                                    .foregroundColor(.purple)
                                    .font(.caption)
                                    .frame(width: 12, alignment: .center)
                                
                                Text("Bundle路径 (Bundle Path)")
                                    .foregroundColor(.purple)
                                    .font(.caption)
                            }
                            
                            Spacer(minLength: 0)
                        }
                        
                        // Bundle URL 路径显示
                        HStack(spacing: 6) {
                            Text(bundleURL.path)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                                .lineLimit(2)
                                .truncationMode(.middle)
                            
                            Button(action: {
                                bundleURL.openInFinder()
                            }) {
                                Image(systemName: "doc.viewfinder")
                                    .foregroundColor(.secondary)
                                    .font(.caption2)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("在 Finder 中显示")
                            
                            Spacer(minLength: 0)
                        }
                        .padding(.leading, 16)
                    }
                }
                
                // 代理应用解释视图（折叠/展开）
                if showProxyExplanation {
                    ProxyExplanationView()
                        .frame(height: 380)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.controlBackgroundColor).opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .padding(12)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 事件详细列表
            if !events.isEmpty {
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
                    .padding(.bottom, 4)
                    
                    // 筛选后的事件数量
                    HStack {
                        Spacer()
                        Text("共 \(getFilteredEvents().count) 条事件")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    
                    Table(getCurrentPageEvents(), columns: {
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
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(currentPage < getTotalPages() - 1 ? .primary : .secondary)
                            }
                            .disabled(currentPage >= getTotalPages() - 1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                }
                .padding(12)
                .background(Color(.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // 注意：子应用程序现在在主列表中通过折叠方式展示
        }
        .padding(12)
        .onHover { hovering in
            popoverHovering = hovering
        }
        .onAppear(perform: onAppear)
        .onChange(of: statusFilter) { _, _ in
            currentPage = 0 // 重置到第一页
        }
        .onChange(of: directionFilter) { _, _ in
            currentPage = 0 // 重置到第一页
        }
    }
}

// MARK: - Event

extension AppDetail {
    func onAppear() {
        loadEvents()
    }
}

// MARK: - Action

extension AppDetail {
    /// 从数据库加载指定应用的事件数据
    private func loadEvents() {
        do {
            let allEvents = try firewallEventService.getEventsByAppId(app.id)
            events = allEvents
            currentPage = 0 // 重置到第一页
            os_log("\(self.t)加载了 \(allEvents.count) 个事件")
        } catch {
            print("加载事件数据失败: \(error)")
            events = []
            currentPage = 0
        }
    }
    
    /// 根据筛选条件获取事件列表
    private func getFilteredEvents() -> [FirewallEvent] {
        var filteredEvents = events
        
        // 应用状态筛选
        if statusFilter != .all {
            filteredEvents = filteredEvents.filter { event in
                switch statusFilter {
                case .allowed:
                    return event.status == .allowed
                case .rejected:
                    return event.status == .rejected
                case .all:
                    return true
                }
            }
        }
        
        // 应用方向筛选
        if directionFilter != .all {
            filteredEvents = filteredEvents.filter { event in
                switch directionFilter {
                case .inbound:
                    return event.direction == .inbound
                case .outbound:
                    return event.direction == .outbound
                case .all:
                    return true
                }
            }
        }
        
        return filteredEvents
    }
    
    /// 获取当前页的事件数据
    private func getCurrentPageEvents() -> [FirewallEvent] {
        let filteredEvents = getFilteredEvents()
        let reversedEvents = Array(filteredEvents.reversed())
        let startIndex = currentPage * eventsPerPage
        let endIndex = min(startIndex + eventsPerPage, reversedEvents.count)
        
        if startIndex >= reversedEvents.count {
            return []
        }
        
        return Array(reversedEvents[startIndex..<endIndex])
    }
    
    /// 获取总页数
    private func getTotalPages() -> Int {
        return max(1, Int(ceil(Double(getFilteredEvents().count) / Double(eventsPerPage))))
    }
    
    /// 复制App ID到剪贴板的方法
    private func copyAppID() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(app.id, forType: .string)
        
        // 显示复制成功的动画
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isCopied = true
        }
        
        // 2秒后重置状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isCopied = false
            }
        }
    }
    
    /// 复制Bundle路径到剪贴板的方法
    /// - Parameter path: 要复制的Bundle路径字符串
    private func copyBundlePath(_ path: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(path, forType: .string)
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}

#Preview("防火墙事件视图") {
    RootView {
        DBEventView()
    }
    .frame(width: 600, height: 600)
}

#Preview("APP配置") {
    RootView {
        DBSettingView()
    }
    .frame(width: 600, height: 800)
}
