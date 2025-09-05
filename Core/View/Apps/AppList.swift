import MagicCore
import OSLog
import SwiftUI

struct AppList: View, SuperLog {
    @EnvironmentObject private var ui: UIProvider
    @EnvironmentObject private var data: DataProvider
    @EnvironmentObject private var repo: AppSettingRepo
    
    /// 过滤后的应用列表
    @State private var filteredApps: [SmartApp] = []

    nonisolated static let emoji = "🖥️"

    /// 构建应用列表视图
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array((filteredApps.isNotEmpty ? filteredApps : data.samples).enumerated()), id: \.element.id) { index, app in
                        AppLine(app: app)
                        if index < (filteredApps.isNotEmpty ? filteredApps : data.samples).count - 1 {
                            Divider()
                        }
                    }
                }
            }

            if data.status.isNotRunning() || filteredApps.isEmpty {
                GuideView()
            }
        }
        .onAppear {
            Task {
                await loadFilteredApps()
            }
        }
        .onChange(of: ui.showSystemApps) { _, _ in
            Task {
                await loadFilteredApps()
            }
        }
        .onChange(of: ui.displayType) { _, _ in
            Task {
                await loadFilteredApps()
            }
        }
        .onChange(of: data.apps) { _, _ in
            Task {
                await loadFilteredApps()
            }
        }
    }
}

// MARK: - Action
extension AppList {
    /// 异步加载过滤后的应用列表
    private func loadFilteredApps() async {
        let baseApps = data.apps.sorted(by: { $0.name < $1.name })
            .filter { ui.showSystemApps || !$0.isSystemApp }
            .filter { $0.hasId }
        
        let displayType = self.ui.displayType
        
        // 提取 repo 引用以避免数据竞争
        let repo = self.repo
        
        var filtered: [SmartApp] = []
        
        for app in baseApps {
            let shouldInclude: Bool
            switch displayType {
            case .All:
                shouldInclude = true
            case .Allowed:
                shouldInclude = await Task { @MainActor in
                    await repo.shouldAllow(app.id)
                }.value
            case .Rejected:
                shouldInclude = !(await Task { @MainActor in
                    await repo.shouldAllow(app.id)
                }.value)
            }
            
            if shouldInclude {
                filtered.append(app)
            }
        }
        
        await MainActor.run {
            self.filteredApps = filtered
        }
    }
}

#Preview("APP") {
    ContentView().inRootView()
        .frame(height: 600)
}

#Preview("AppList") {
    AppList()
        .inRootView()
}
