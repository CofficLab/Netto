import MagicCore
import OSLog
import SwiftUI

struct AppList: View, SuperLog {
    @EnvironmentObject private var ui: UIProvider
    @EnvironmentObject private var repo: AppSettingRepo
    @EnvironmentObject private var eventRepo: EventRepo
    @EnvironmentObject private var firewall: FirewallService
    
    /// 应用列表
    @State private var allApps: [SmartApp] = []
    @State private var deniedIds: [String] = []
    
    var filtedApps: [SmartApp] {
        switch ui.displayType {
        case .All:
            allApps
        case .Allowed:
            allApps.filter({
                self.deniedIds.contains($0.id) == false
            })
        case .Rejected:
            allApps.filter({
                self.deniedIds.contains($0.id)
            })
        }
    }

    nonisolated static let emoji = "🖥️"

    /// 构建应用列表视图
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array((filtedApps.isNotEmpty ? filtedApps : SmartApp.samples).enumerated()), id: \.element.id) { index, app in
                        AppLine(app: app)
                        if index < (allApps.isNotEmpty ? allApps : SmartApp.samples).count - 1 {
                            Divider()
                        }
                    }
                }
            }

            if firewall.status.isNotRunning() || filtedApps.isEmpty || ui.shouldShowUpgradeGuide {
                GuideView()
            }
        }
        .onAppear {
            Task {
                await loadData()
            }
        }
    }
}

// MARK: - Action
extension AppList {
    private func loadData() async {
        // 提取环境对象引用以避免数据竞争
        let repo = self.repo
        let eventRepo = self.eventRepo
        
        // 获取“产生过事件的应用ID”
        let eventAppIds = await withCheckedContinuation { continuation in
            eventRepo.getAllAppIdsAsync { appIds in
                continuation.resume(returning: appIds)
            }
        }

        // 获取“被禁止的应用ID”
        let deniedIds: [String] = await Task { @MainActor in
            (try? await repo.getDeniedApps()) ?? []
        }.value

        // 合并并去重
        let mergedIds: [String] = Array(Set(eventAppIds).union(deniedIds))

        let apps = mergedIds.map({ SmartApp.fromId($0) })
        
        let baseApps = apps.sorted(by: { $0.name < $1.name })
            .filter { ui.showSystemApps || !$0.isSystemApp }
            .filter { $0.hasId }
        
        let displayType = self.ui.displayType

        await MainActor.run {
            self.allApps = apps
            self.deniedIds = deniedIds
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
