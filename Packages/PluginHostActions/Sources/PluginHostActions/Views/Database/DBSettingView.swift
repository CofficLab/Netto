import AppKit
import LumiUI
import SwiftUI
import ProviderAppSettings
import ProviderViewEnvironment
import OSLog

/// 数据库设置视图（DEBUG）
/// 阶段 6 迁移：经 `AppSettingsProviding` 契约读取规则（替代视图内 @Query）。
struct DBSettingView: View {
    @LumiTheme private var theme

    @Environment(\.settingsProvider) private var envSettings: AppSettingsProviding?

    /// 注入的设置契约（设置入口由插件在 onBoot 解析传入；nil 时回退环境）。
    private let injectedSettings: AppSettingsProviding?

    /// 设置契约来源：注入优先，其次环境。
    private var settings: AppSettingsProviding? { injectedSettings ?? envSettings }

    /// 设置库所在目录（由插件从 `StorageProviding` 注入；nil 时按钮不可用）。
    private let settingsDirectory: URL?

    init(settings: AppSettingsProviding? = nil, settingsDirectory: URL? = nil) {
        self.injectedSettings = settings
        self.settingsDirectory = settingsDirectory
    }

    /// 规则快照（契约 DTO）
    @State private var items: [AppSettingSnapshot] = []

    /// 筛选状态
    @State private var filterStatus: DBFilterStatus = .all

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

    /// 状态筛选的索引绑定（供 `AppSegmentedControl` 使用）
    private var filterSelection: Binding<Int> {
        Binding(
            get: { DBFilterStatus.allCases.firstIndex(of: filterStatus) ?? 0 },
            set: { index in
                guard DBFilterStatus.allCases.indices.contains(index) else { return }
                filterStatus = DBFilterStatus.allCases[index]
            }
        )
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
                        Text("Yes").foregroundStyle(theme.success)
                    } else {
                        Text("No").foregroundStyle(theme.error)
                    }
                }
                TableColumn("Action") { item in
                    Button {
                        Task {
                            guard let settings else { return }
                            do {
                                if item.allowed {
                                    try await settings.setDeny(item.appId)
                                } else {
                                    try await settings.setAllow(item.appId)
                                }
                                await load()
                            } catch {
                                os_log(.error, "数据库规则更新失败: %{public}@", error.localizedDescription)
                            }
                        }
                    } label: {
                        Image(systemName: item.allowed ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(item.allowed ? theme.error : theme.success)
                    }
                    .buttonStyle(.plain)
                    .help(item.allowed ? "禁止此应用" : "允许此应用")
                }
            })
        }
        .task {
            await load()
        }
    }
    
    /// 工具栏视图
    private var toolbarView: some View {
        HStack(spacing: AppUI.Spacing.md) {
            AppSearchBar(text: $searchText, placeholder: "搜索应用ID")
                .frame(maxWidth: 220)

            Spacer()

            AppSegmentedControl(
                DBFilterStatus.allCases.map(\.rawValue),
                selection: filterSelection,
                maxWidth: 200
            )

            AppButton("Finder中显示", systemImage: "folder", style: .secondary, size: .small) {
                guard let settingsDirectory else { return }
                NSWorkspace.shared.open(settingsDirectory)
            }

            // 统计信息
            HStack(spacing: 6) {
                Text("总计: \(items.count)")
                    .font(.appCaption)
                    .foregroundStyle(theme.textSecondary)

                Text("显示: \(filteredItems.count)")
                    .font(.appMicroEmphasized)
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.primary.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, AppUI.Spacing.md)
        .padding(.vertical, AppUI.Spacing.sm)
        .background(theme.background)
        .overlay(alignment: .bottom) {
            AppSettingsDivider()
        }
    }
}

private enum DBFilterStatus: String, CaseIterable {
    case all = "全部"
    case allowed = "允许"
    case rejected = "阻止"
}

#Preview("APP") {
    DBSettingView().frame(width: 600, height: 700)
}

#Preview("DBSetting") {
    DBSettingView().frame(width: 600, height: 700)
}

#Preview("防火墙事件视图") {
    DBEventView().frame(width: 600, height: 700)
}
