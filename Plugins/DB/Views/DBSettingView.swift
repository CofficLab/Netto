import SwiftUI
import MagicCore
import ProviderAppSettings

/// 数据库设置视图（DEBUG）
/// 阶段 6 迁移：经 `AppSettingsProviding` 契约读取规则（替代视图内 @Query）。
struct DBSettingView: View {
    @Environment(\.settingsProvider) private var envSettings: AppSettingsProviding?

    /// 注入的设置契约（设置入口由插件在 onBoot 解析传入；nil 时回退环境）。
    private let injectedSettings: AppSettingsProviding?

    /// 设置契约来源：注入优先，其次环境。
    private var settings: AppSettingsProviding? { injectedSettings ?? envSettings }

    init(settings: AppSettingsProviding? = nil) {
        self.injectedSettings = settings
    }

    /// 规则快照（契约 DTO）
    @State private var items: [AppSettingSnapshot] = []

    /// 筛选状态
    @State private var filterStatus: StatusFilter = .all

    /// 搜索文本
    @State private var searchText = ""

    /// 根据筛选条件过滤后的应用设置列表
    private var filteredItems: [AppSettingSnapshot] {
        var filtered = items

        // 根据状态筛选
        switch filterStatus {
        case .allowed:
            filtered = filtered.filter { $0.allowed }
        case .rejected:
            filtered = filtered.filter { !$0.allowed }
        case .all:
            break
        }

        // 根据搜索文本筛选
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.appId.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    /// 加载全部规则（契约路径）
    private func load() async {
        guard let settings else { return }
        items = (try? await settings.fetchAll()) ?? []
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            toolbarView
            
            // 表格
            Table(filteredItems, columns: {
                TableColumn("ID", value: \.appId)
                TableColumn("Allowed") {
                    if $0.allowed {
                        Text("Yes").foregroundStyle(.green)
                    } else {
                        Text("No").foregroundStyle(.red)
                    }
                }
                TableColumn("Action") { i in
                    AppAction(shouldAllow: .constant(true), appId: i.appId)
                }
            })
        }
        .task {
            await load()
        }
    }
    
    /// 工具栏视图
    private var toolbarView: some View {
        HStack(spacing: 12) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                TextField("搜索应用ID", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 14))
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .frame(maxWidth: 200)
            
            Spacer()
            
            // 状态筛选器
            HStack(spacing: 4) {
                Text("状态:")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Picker("筛选状态", selection: $filterStatus) {
                    ForEach(StatusFilter.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 180)
            }
            
            Button("Finder中显示") {
                try? URL.database.openFolder()
            }
            
            Spacer()
            
            // 统计信息
            HStack(spacing: 8) {
                Text("总计: \(items.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("显示: \(filteredItems.count)")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separatorColor))
                .opacity(0.5),
            alignment: .bottom
        )
    }
}

#Preview("APP") {
    RootView(environment: .preview()) {
        ContentView()
    }
    .frame(width: 500)
    .frame(height: 600)
}

#Preview("DBSetting") {
    RootView(environment: .preview()) {
        DBSettingView()
    }
    .frame(width: 600, height: 800)
}

#Preview("防火墙事件视图") {
    RootView(environment: .preview()) {
        DBEventView()
    }
    .frame(width: 600, height: 800)
}
