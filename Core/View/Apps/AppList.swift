import MagicCore
import OSLog
import SwiftUI

struct AppList: View, SuperLog {
    @EnvironmentObject private var ui: UIProvider
    @EnvironmentObject private var repo: AppSettingRepo
    @EnvironmentObject private var eventRepo: EventRepo
    @EnvironmentObject private var firewall: FirewallService
    
    /// 过滤后的应用列表
    @State private var filteredApps: [SmartApp] = []

    nonisolated static let emoji = "🖥️"

    /// 构建应用列表视图
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array((filteredApps.isNotEmpty ? filteredApps : SmartApp.samples).enumerated()), id: \.element.id) { index, app in
                        AppLine(app: app)
                        if index < (filteredApps.isNotEmpty ? filteredApps : SmartApp.samples).count - 1 {
                            Divider()
                        }
                    }
                }
            }

            if firewall.status.isNotRunning() || filteredApps.isEmpty {
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
    }
}

// MARK: - Action
extension AppList {
    /// 异步加载过滤后的应用列表
    private func loadFilteredApps() async {
        // 提取环境对象引用以避免数据竞争
        let repo = self.repo
        let eventRepo = self.eventRepo
        
        // 使用异步回调方式获取应用ID列表，避免数据竞争
        let appIds = await withCheckedContinuation { continuation in
            eventRepo.getAllAppIdsAsync { appIds in
                continuation.resume(returning: appIds)
            }
        }
        
        let apps = appIds.map({SmartApp.fromId($0)})
        
        let baseApps = apps.sorted(by: { $0.name < $1.name })
            .filter { ui.showSystemApps || !$0.isSystemApp }
            .filter { $0.hasId }
        
        let displayType = self.ui.displayType
        
        // 将应用拆分为“被禁止(denied)”与“允许(allowed)”两组
        var denied: [SmartApp] = []
        var allowed: [SmartApp] = []

        for app in baseApps {
            let isAllowed = await Task { @MainActor in
                await repo.shouldAllow(app.id)
            }.value
            if isAllowed {
                allowed.append(app)
            } else {
                denied.append(app)
            }
        }

        // 按显示类型拼装；仅在 All 模式下，将“被禁止”的应用置顶并包含
        let finalList: [SmartApp]
        switch displayType {
        case .All:
            finalList = denied + allowed
        case .Allowed:
            finalList = allowed
        case .Rejected:
            finalList = denied
        }

        await MainActor.run {
            self.filteredApps = finalList
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
