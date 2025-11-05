import MagicCore
import OSLog
import SwiftUI

/**
 * 应用列表视图
 * 
 * 显示和管理应用列表，支持根据显示类型过滤应用。
 * 当防火墙未运行或需要升级时显示引导视图。
 * 当列表为空时显示优雅的空视图。
 */
struct AppList: View, SuperLog {
    /// UI状态提供者
    @EnvironmentObject private var ui: UIProvider
    
    /// 应用设置仓库
    @EnvironmentObject private var repo: AppSettingRepo
    
    /// 事件仓库
    @EnvironmentObject private var eventRepo: EventRepo
    
    /// 防火墙服务
    @EnvironmentObject private var firewall: FirewallService
    
    /// 应用列表
    @State private var allApps: [SmartApp] = []
    
    /// 被拒绝的应用ID列表
    @State private var deniedIds: [String] = []
    
    /// 过滤后的应用列表
    /// 
    /// 根据显示类型（全部/允许/拒绝）和隐藏状态进行过滤。
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

    /// 日志表情符号
    nonisolated static let emoji = "🖥️"

    /// 构建应用列表视图
    var body: some View {
        ZStack {
            if filtedApps.isEmpty && !shouldShowGuide {
                // 显示空视图：当列表为空且不需要显示引导视图时
                AppListEmptyView(displayType: ui.displayType)
            } else {
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
            }

            if shouldShowGuide {
                GuideView()
            }
        }
        .onAppear(perform: handleOnAppear)
    }
    
    /// 是否需要显示引导视图
    /// 
    /// 当防火墙未运行或需要升级时显示引导视图。
    private var shouldShowGuide: Bool {
        firewall.status.isNotRunning() || ui.shouldShowUpgradeGuide
    }
}

// MARK: - Setter
extension AppList {
    /// 更新应用列表状态
    /// 
    /// 在主线程上更新应用列表和被拒绝的应用ID列表。
    /// 
    /// - Parameters:
    ///   - apps: 应用列表
    ///   - deniedIds: 被拒绝的应用ID列表
    @MainActor
    private func setApps(_ apps: [SmartApp], deniedIds: [String]) {
        self.allApps = apps
        self.deniedIds = deniedIds
    }
}

// MARK: - Event Handler
extension AppList {
    /// 处理视图出现事件
    /// 
    /// 当视图出现时，异步加载应用列表数据。
    private func handleOnAppear() {
        Task {
            await loadData()
        }
    }
    
    /// 加载应用列表数据
    /// 
    /// 从事件仓库获取产生过事件的应用ID，从应用设置仓库获取被拒绝的应用ID，
    /// 合并去重后创建应用实例并排序更新状态。
    private func loadData() async {
        // 提取环境对象引用以避免数据竞争
        let repo = self.repo
        let eventRepo = self.eventRepo
        
        // 获取"自会话开始以来产生过事件的应用ID"
        let since = eventRepo.sessionStartDate
        let eventAppIds = await withCheckedContinuation { continuation in
            eventRepo.getAppIdsSinceAsync(since) { appIds in
                continuation.resume(returning: appIds)
            }
        }

        // 获取"被禁止的应用ID"
        let deniedIds: [String] = await Task { @MainActor in
            (try? await repo.getDeniedApps()) ?? []
        }.value

        // 合并并去重：将事件应用ID和被拒绝应用ID合并
        let mergedIds: [String] = Array(Set(eventAppIds).union(deniedIds))

        let apps = mergedIds.map({ SmartApp.fromId($0) })
        
        // 过滤系统应用：仅保留非系统应用或未隐藏的系统应用
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
        
        setApps(baseApps, deniedIds: deniedIds)
    }
}

// MARK: - Preview
#Preview("App") {
    ContentView()
        .inRootView()
        .frame(width: 600, height: 600)
}

#Preview("AppList") {
    AppList()
        .inRootView()
        .frame(width: 600, height: 800)
}
