import Foundation
import KernelCore
import ProviderSettingView
import ProviderStore
import Testing
@testable import PluginStore

/// 依赖 `UserDefaults.standard["store.purchase"]` 的用例。
///
/// 这些用例与 `PluginStoreTests.swift` 中的 `StoreStateTests` 共享同一 UserDefaults
/// 键，必须与之一同串行执行，因此嵌套在该 `.serialized` 套件内部
/// （Swift Testing 的 `.serialized` 特性会连同嵌套套件一起串行）。
extension StoreStateTests {

    /// `StoreState` / `StoreService` 缓存读写的边界用例。
    @Suite("缓存读取")
    @MainActor
    struct StoreStateCacheTests {

        /// `StoreState.Keys.purchase` 是模块内私有，但键名是稳定契约（与旧实现一致）。
        private static let purchaseKey = "store.purchase"

        /// 清理共享键的辅助函数（Swift Testing 无 `@AfterEach`，需手工调用）。
        private func resetSharedState() {
            UserDefaults.standard.removeObject(forKey: Self.purchaseKey)
        }

        @Test("无缓存数据时 cachedPurchaseInfo 回退为 none")
        func cachedPurchaseInfoFallsBackToNone() {
            resetSharedState()
            let cached = StoreState.cachedPurchaseInfo()
            #expect(cached.tier == .none)
            #expect(cached.expiresAt == nil)
        }

        @Test("缓存数据损坏时回退为 none")
        func cachedPurchaseInfoFallsBackOnCorruptedData() {
            UserDefaults.standard.set(Data("not-json".utf8), forKey: Self.purchaseKey)
            let cached = StoreState.cachedPurchaseInfo()
            #expect(cached.tier == .none)
            #expect(cached.expiresAt == nil)
            resetSharedState()
        }

        @Test("校准：无权益时写入 none 权益")
        func calibrateWithoutEntitlementsWritesNone() async {
            resetSharedState()
            await StoreState.calibrateFromCurrentEntitlements()
            let cached = StoreState.cachedPurchaseInfo()
            #expect(cached.tier == .none)
            #expect(cached.expiresAt == nil)
        }

        @Test("StoreService 缓存读取入口与 StoreState 一致")
        func storeServiceCacheAccessors() {
            resetSharedState()
            StoreState.update(entitlement: PurchaseInfo(tier: .ultimate, expiresAt: Date(timeIntervalSinceNow: 7200)))

            #expect(StoreService.cachedPurchaseInfo().tier == .ultimate)
            #expect(StoreService.tierCached() == .ultimate)
            let expiresAt = StoreService.expiresAtCached()
            #expect(expiresAt != nil)

            StoreState.clear()
            #expect(StoreService.tierCached() == .none)
            #expect(StoreService.expiresAtCached() == nil)
        }
    }

    /// `PluginStore` 对外命令（loadProducts / purchase / restore）的用例。
    @Suite("PluginStore 命令")
    @MainActor
    struct PluginStoreCommandTests {

        @Test("loadProducts 在单测进程内抛错（无有效 App Store 会话）")
        func loadProductsThrows() async {
            let plugin = PluginStore()
            await #expect(throws: (any Error).self) {
                _ = try await plugin.loadProducts()
            }
        }

        @Test("purchase 在单测进程内抛错（取不到商品）")
        func purchaseThrows() async {
            let plugin = PluginStore()
            await #expect(throws: (any Error).self) {
                try await plugin.purchase("com.coffic.netto.monthly")
            }
        }

        @Test("restore 触发权益校准并落盘为 none")
        func restoreCalibratesEntitlement() async throws {
            let plugin = PluginStore()
            UserDefaults.standard.removeObject(forKey: "store.purchase")

            try await plugin.restore()

            #expect(plugin.entitlement.tier == .none)
            #expect(StoreState.cachedPurchaseInfo().tier == .none)
        }
    }

    /// 商店设置入口（含视图工厂）可用性的用例。
    @Suite("商店设置入口")
    @MainActor
    struct StoreSettingsEntryTests {

        @Test("设置入口的详情视图工厂可被构造")
        func storeEntryBuildsDetailView() async throws {
            let kernel = KernelCoreContainer()
            let settingsView = DefaultSettingViewProviding()
            try kernel.registerProvider(SettingViewProviding.self, settingsView)
            try kernel.start(plugins: [PluginStore()])

            let entry = settingsView.entries.first { $0.id == "store" }
            #expect(entry != nil)
            #expect(entry?.title == "商店")

            // 触发入口的视图工厂（StoreWindowContent.windowView()）。
            let detailView = entry?.makeDetailView()
            #expect(detailView != nil)

            try await kernel.stopAsync()
        }
    }
}
