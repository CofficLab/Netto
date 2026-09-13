import Foundation
import KernelCore
import ProviderShell
import ProviderSettingView
import ProviderStore
import Testing
@testable import PluginStore

/// StoreConfig 产品映射测试（不触碰 StoreKit）。
struct StoreConfigTests {
    @Test func productTierMapping() {
        // 已知产品 ID → 等级映射（与 StoreConfig.productTier 一致）。
        #expect(StoreConfig.tier(for: "com.coffic.netto.monthly") == .pro)
        #expect(StoreConfig.tier(for: "com.coffic.netto.annual") == .pro)
        // 未知 ID 回退 none。
        #expect(StoreConfig.tier(for: "com.example.unknown") == .none)
    }

    @Test func allProductIdsUniqueAndNonEmpty() {
        let ids = StoreConfig.allProductIds
        #expect(!ids.isEmpty)
        #expect(Set(ids).count == ids.count)
    }
}

/// StoreState UserDefaults 持久化测试（键名与旧实现一致：store.purchase）。
///
/// 串行套件：这些测试共享同一 UserDefaults 键，Swift Testing 默认并行执行
/// 会导致读写交错，故必须串行且互斥。
@Suite(.serialized)
@MainActor
struct StoreStateTests {
    @Test func persistenceRoundTripAndClear() {
        // 先清理，保证可重复。
        StoreState.clear()
        let none = StoreState.cachedPurchaseInfo()
        #expect(none.tier == .none)

        StoreState.update(entitlement: PurchaseInfo(tier: .pro, expiresAt: Date(timeIntervalSinceNow: 3600)))
        let loaded = StoreState.cachedPurchaseInfo()
        #expect(loaded.tier == .pro)
        #expect(loaded.expiresAt != nil)

        StoreState.clear()
        #expect(StoreState.cachedPurchaseInfo().tier == .none)
    }

    @Test func entitlementMapsFromStoreState() {
        let plugin = PluginStore()
        StoreState.clear()
        #expect(plugin.entitlement.tier == .none)
        StoreState.update(entitlement: PurchaseInfo(tier: .ultimate, expiresAt: Date(timeIntervalSinceNow: 7200)))
        #expect(plugin.entitlement.tier == .ultimate)
        #expect(plugin.entitlement.isProOrHigher)
        StoreState.clear()
    }

    @Test func observeEntitlementEmitsOnUpdate() async {
        let plugin = PluginStore()
        StoreState.clear()
        let stream = plugin.observeEntitlement()
        // 让出主线程，确保观察者任务完成订阅后再触发更新（避免通知先于订阅发出）。
        await Task.yield()

        // 触发一次更新，应收到快照。
        StoreState.update(entitlement: PurchaseInfo(tier: .pro, expiresAt: Date(timeIntervalSinceNow: 3600)))

        // 收集直到收到 .pro（当前快照或变更通知都算；容忍订阅竞态）。
        let first = await firstPro(of: stream, timeoutSeconds: 3)
        #expect(first?.tier == .pro)
        StoreState.clear()
    }

    /// 带超时地从流中取首个 pro 级快照（最多消费 8 个元素，避免悬挂与跨隔离发送问题）。
    private func firstPro(of stream: AsyncStream<StoreEntitlementSnapshot>, timeoutSeconds: Double) async -> StoreEntitlementSnapshot? {
        await withTaskGroup(of: StoreEntitlementSnapshot?.self) { group in
            group.addTask {
                var iterator = stream.makeAsyncIterator()
                var count = 0
                while let snapshot = await iterator.next(), count < 8 {
                    count += 1
                    if snapshot.tier >= .pro { return snapshot }
                }
                return nil
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(timeoutSeconds))
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}

/// PluginStore 插件装配测试（真实 Kernel + 真 Provider，不触碰 StoreKit 沙盒）。
@MainActor
struct PluginStorePluginTests {
    @Test func registersProviderAndSettingsEntry() async throws {
        let kernel = KernelCoreContainer()
        // 先注册 SettingViewProviding（DefaultSettingViewProviding）与
        // ShellCenter，再启动 PluginStore（设置视图契约缺失时优雅降级）。
        let settingsView = DefaultSettingViewProviding()
        try kernel.registerProvider(settingsView, for: SettingViewProviding.self)
        try kernel.start(plugins: [MockShellPlugin(), PluginStore()])

        // Provider 已注册（owner=store）。
        let store = kernel.resolveProvider(StoreProviding.self)
        #expect(store != nil)
        #expect(store is PluginStore)

        // 商店入口已注入设置视图（替代旧主窗口 StoreBtn / store-window）。
        let entries = settingsView.entries
        #expect(entries.contains { $0.id == "store" } == true)
        #expect(entries.first(where: { $0.id == "store" })?.title == "商店")

        // 停止后：Provider 撤回、设置入口移除。
        try await kernel.stopAsync()
        #expect(kernel.resolveProvider(StoreProviding.self) == nil)
        #expect(settingsView.entries.contains { $0.id == "store" } != true)
    }

}


/// 注册 ShellCenter（SettingsProviding）的最小 Mock 插件。
@MainActor
private final class MockShellPlugin: SuperPlugin {
    let id = "mock-shell"
    var order: Int { 1 }
    var dependencies: [String] { [] }
    let metadata = PluginMetadata(name: "MockShell", version: "1.0", policy: .required)
    private let shell = ShellCenter()

    func onBoot(kernel: KernelCoreContainer) throws {
        try kernel.registerProvider(shell, for: SettingsProviding.self, owner: id)
        try kernel.registerProvider(shell, for: ShellToolbarProviding.self, owner: id)
        try kernel.registerProvider(shell, for: WindowProviding.self, owner: id)
    }
}
