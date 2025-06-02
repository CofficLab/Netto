import SwiftUI
import SwiftData
import MagicCore
import NetworkExtension

/// 数据库防火墙事件展示视图
/// 用于展示数据库中存储的所有防火墙事件记录
struct DBEventView: View {
    @Query(sort: \FirewallEventModel.time, order: .reverse)
    var events: [FirewallEventModel]
    
    var body: some View {
        VStack {
            // 标题和统计信息
            HStack {
                Text("防火墙事件记录")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("共 \(events.count) 条记录")
                    .foregroundStyle(.secondary)
                
                Button("打开数据库文件夹") {
                    try? URL.database.openFolder()
                }
            }
            .padding(.horizontal)
            
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
        }
        .navigationTitle("防火墙事件")
    }
}

#Preview("防火墙事件视图") {
    RootView {
        DBEventView()
    }
    .frame(width: 600, height: 600)
}

#Preview("App") {
    RootView {
        ContentView()
    }
    .frame(width: 500)
}
