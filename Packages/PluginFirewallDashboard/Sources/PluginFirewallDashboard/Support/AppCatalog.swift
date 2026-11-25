import AppKit
import Observation
import SwiftUI

/// 应用解析能力：列表模型只依赖这一层，测试可注入替身。
@MainActor
protocol AppResolving: AnyObject {
    func app(for id: String) -> SmartApp
    func icon(for id: String) -> NSImage?
    /// 应用集合变化（启动/退出）；订阅时立即推送一次当前版本。
    func observeChanges() -> AsyncStream<Void>
}

private struct AppCatalogEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppCatalog? = nil
}

extension EnvironmentValues {
    /// 由界面根视图注入的应用目录；缺失时图标回退默认图标。
    var appCatalog: AppCatalog? {
        get { self[AppCatalogEnvironmentKey.self] }
        set { self[AppCatalogEnvironmentKey.self] = newValue }
    }
}

/// 运行中应用与图标的进程级缓存。
///
/// `NSWorkspace.runningApplications` 扫描与 `NSRunningApplication.icon` 获取
/// 都在主线程执行；应用列表每次重绘都重新解析，会把「悬停」这类交互拖成
/// 秒级卡顿。这里只在启动/退出通知驱动下重建字典，视图侧退化为 O(1) 查表。
@MainActor
@Observable
final class AppCatalog: AppResolving {
    /// 目录版本号；应用启动/退出后递增。
    private(set) var revision = 0

    private var knownSystemApps: [String: SmartApp]
    private var runningByID: [String: NSRunningApplication] = [:]
    private var appsByID: [String: SmartApp] = [:]
    private var iconsByID: [String: NSImage] = [:]
    private var missingIconIDs: Set<String> = []
    private var changeContinuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    init(systemApps: [SmartApp] = SmartApp.allSystemApps) {
        self.knownSystemApps = Dictionary(
            systemApps.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        rebuildRunningApplications()

        let center = NSWorkspace.shared.notificationCenter
        for name in [
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
        ] {
            center.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.invalidateRunningApplications()
                }
            }
        }
    }

    // MARK: - 查询

    /// 解析应用信息；同一 id 只解析一次，应用启停时整体失效。
    func app(for id: String) -> SmartApp {
        if let cached = appsByID[id] { return cached }

        let app: SmartApp
        if let running = runningApplication(for: id) {
            app = SmartApp(
                id: id,
                name: running.localizedName ?? "",
                isProxy: SmartApp.isProxyApp(running),
                bundleURL: running.bundleURL
            )
        } else if let system = knownSystemApps[id] ?? SmartApp.getSystemApp(id) {
            app = system
        } else {
            app = SmartApp.unknownApp(id)
        }
        appsByID[id] = app
        return app
    }

    /// 运行中应用的图标；无图标或未运行返回 nil（由调用方回退默认图标）。
    func icon(for id: String) -> NSImage? {
        if let icon = iconsByID[id] { return icon }
        if missingIconIDs.contains(id) { return nil }
        guard let running = runningApplication(for: id), let icon = running.icon else {
            missingIconIDs.insert(id)
            return nil
        }
        iconsByID[id] = icon
        return icon
    }

    /// 应用集合变化（启动/退出）通知；订阅时立即推送一次当前版本。
    func observeChanges() -> AsyncStream<Void> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            changeContinuations[id] = continuation
            continuation.yield()
            continuation.onTermination = { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.changeContinuations[id] = nil
                }
            }
        }
    }

    // MARK: - 失效

    private func invalidateRunningApplications() {
        rebuildRunningApplications()
        appsByID.removeAll(keepingCapacity: true)
        iconsByID.removeAll(keepingCapacity: true)
        missingIconIDs.removeAll(keepingCapacity: true)
        revision += 1
        changeContinuations.values.forEach { $0.yield() }
    }

    private func rebuildRunningApplications() {
        var next: [String: NSRunningApplication] = [:]
        for app in NSWorkspace.shared.runningApplications {
            guard let bundleID = app.bundleIdentifier, next[bundleID] == nil else { continue }
            next[bundleID] = app
        }
        runningByID = next
    }

    /// 精确保留旧 `SmartApp.getApp(_:)` 语义：先全等匹配，再允许
    /// 事件里的扩展 id（如 `com.foo.helper`）命中其主进程。
    private func runningApplication(for id: String) -> NSRunningApplication? {
        if let exact = runningByID[id] { return exact }
        for (bundleID, app) in runningByID where id.contains(bundleID) {
            return app
        }
        return nil
    }
}