import SwiftUI

struct AppDetail: View {
    @EnvironmentObject var data: DataProvider
    
    @Binding var popoverHovering: Bool

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
                    // 应用图标
                    if let icon = app.icon {
                        icon
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 48, height: 48)
                            .overlay {
                                Image(systemName: "app")
                                    .foregroundColor(.gray)
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("ID: \(app.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
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
                        
                        Text("\(app.events.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    if !app.events.isEmpty {
                        Text("最近事件: \(app.events.last?.description ?? "无")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(12)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 子应用程序列表
             if !app.children.isEmpty {
                 Text("子应用程序 (Child Applications)")
                     .font(.headline)
                     .padding(.bottom, 4)

                ForEach(app.children) { childApp in
                    AppInfo(
                        app: childApp,
                        iconSize: 24,
                        nameFont: .subheadline,
                        idFont: .caption2,
                        countFont: .caption2,
                        isCompact: true,
                        copyMessageDuration: 1.5,
                        copyMessageText: "App ID 已复制"
                    )
                }
            }
        }
        .padding(12)
        .onHover { hovering in
            popoverHovering = hovering
        }
    }
}

#Preview("APP") {
    RootView {
        ContentView()
    }
    .frame(height: 600)
}
