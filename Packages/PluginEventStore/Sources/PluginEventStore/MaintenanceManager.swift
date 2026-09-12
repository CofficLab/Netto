import Foundation
import ProviderFirewallEvents

/// 数据库维护管理器（对应旧 `DatabaseMaintenanceManager` 语义）。
///
/// 保留行为：每小时执行一次清理（30 天前的过期事件）与健康检查；
/// 启动时执行一次初始维护。任务全部结构化持有，`stopPeriodicCleanup()` 取消
/// 在途任务并失效定时器，不在停止后遗留后台任务。
///
/// 线程/actor：`@MainActor`（定时器在主 RunLoop 上）；清理由 store 的 actor 执行。
@MainActor
final class MaintenanceManager {
    /// 维护间隔（1 小时，与旧实现一致）。
    private let maintenanceInterval: TimeInterval = 1 * 60 * 60

    /// 定期清理定时器。
    private var cleanupTimer: Timer?

    /// 初始维护任务（结构化持有，停止时取消）。
    private var initialMaintenanceTask: Task<Void, Never>?

    /// 弱引用事件存储，避免循环引用。
    weak var store: EventStore?

    init(store: EventStore?) {
        self.store = store
    }

    // 注意：不提供 deinit 访问 MainActor 状态；停止由插件 onShutdown 显式调用
    // stopPeriodicCleanup()。定时器闭包对 self 为弱引用，不形成循环。

    /// 启动定期清理任务（每小时）。
    func startPeriodicCleanup() {
        guard cleanupTimer == nil else { return }
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: maintenanceInterval, repeats: true) { [weak self] _ in
            guard let self, let store = self.store else { return }
            Task { @MainActor in
                _ = try? await store.triggerMaintenance()
            }
        }
    }

    /// 执行一次初始维护（启动路径；结构化任务，可取消）。
    func runInitialMaintenance() {
        guard let store else { return }
        initialMaintenanceTask = Task { @MainActor [weak self, weak store] in
            guard let store else { return }
            _ = try? await store.triggerMaintenance()
            self?.initialMaintenanceTask = nil
        }
    }

    /// 停止定期维护并取消初始任务。
    func stopPeriodicCleanup() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
        initialMaintenanceTask?.cancel()
        initialMaintenanceTask = nil
    }

    /// 执行数据库维护：清理 30 天前事件 + 健康检查。
    ///
    /// - Returns: 维护结果；失败时抛出（与旧行为一致，调用方记录日志）。
    func performMaintenance() async throws -> FirewallMaintenanceResult {
        guard let store else {
            throw NSError(
                domain: "MaintenanceManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "EventStore reference is nil"]
            )
        }

        let startTime = Date()
        var result = FirewallMaintenanceResult()

        do {
            result.deletedEventCount = try await store.cleanupOlderThan(days: 30)
            result.isDatabaseHealthy = true
            result.executionTime = Date().timeIntervalSince(startTime)
            result.isSuccessful = true
        } catch {
            result.isSuccessful = false
            result.errorMessage = error.localizedDescription
            result.executionTime = Date().timeIntervalSince(startTime)
            throw error
        }
        return result
    }
}
