import SwiftUI

struct AppDetail: View {
    @EnvironmentObject var data: DataProvider
    
    @Binding var popoverHovering: Bool
    
    /// 复制状态，用于显示复制成功的动画提示
    @State private var isCopied = false
    
    /// 从数据库加载的事件列表
    @State private var events: [FirewallEvent] = []
    
    /// 防火墙事件服务
    private let firewallEventService = FirewallEventService()

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
                    
                    VStack {
                        Label("系统应用 (System App)", systemImage: app.isSystemApp ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(app.isSystemApp ? .green : .secondary)
                            .font(.caption)
                    }
                }
                
                Divider()
                
                // 事件统计信息
                VStack(alignment: .leading, spacing: 6) {
                    Text("网络事件 (Network Events)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Label("事件总数 (Total Events)", systemImage: "network")
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(events.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    if !events.isEmpty {
                        Text("最近事件: \(events.last?.description ?? "无")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(12)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 事件详细列表
            if !events.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("事件详情 (Event Details)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                    
                    Table(events.reversed(), columns: {
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
        .onAppear {
            loadEvents()
        }
    }
    
    /// 从数据库加载指定应用的事件数据
    private func loadEvents() {
        do {
            let allEvents = try firewallEventService.getEventsByAppId(app.id)
            events = allEvents
        } catch {
            print("加载事件数据失败: \(error)")
            events = []
        }
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
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}
