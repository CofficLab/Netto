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
        let base: [SmartApp] = {
            switch ui.displayType {
            case .All:
                return allApps
            case .Allowed:
                return allApps.filter({ self.deniedIds.contains($0.id) == false })
            case .Rejected:
                return allApps.filter({ self.deniedIds.contains($0.id) })
            }
        }()

        return base.filter { $0.hidden == false }
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
        
        // 获取“自会话开始以来产生过事件的应用ID”
        let since = eventRepo.sessionStartDate
        let eventAppIds = await withCheckedContinuation { continuation in
            eventRepo.getAppIdsSinceAsync(since) { appIds in
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
        
        let baseApps = apps
            .filter { !$0.isSystemApp || ($0.isSystemApp && $0.hidden == false) }
            .filter { $0.hasId }
            .sorted { app1, app2 in
                let isApp1Denied = deniedIds.contains(app1.id)
                let isApp2Denied = deniedIds.contains(app2.id)
                
                // 被禁止的应用优先显示
                if isApp1Denied && !isApp2Denied {
                    return true
                } else if !isApp1Denied && isApp2Denied {
                    return false
                } else {
                    // 同类型内按名称排序
                    return app1.name < app2.name
                }
            }
        
        await MainActor.run {
            self.allApps = baseApps
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
