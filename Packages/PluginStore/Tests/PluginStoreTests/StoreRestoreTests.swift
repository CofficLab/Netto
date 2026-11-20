import Foundation
import StoreKit
import Testing
@testable import PluginStore

/// 恢复购买：必须真正触发 App Store 同步，否则重装/换机后永远「没有购买记录」。
@MainActor
@Suite("恢复购买")
struct StoreRestoreTests {

    @Test("恢复会先同步商店端凭据再校准本地权益")
    func restoreSyncsThenCalibrates() async throws {
        var order: [String] = []
        let outcome = try await StoreRestoreRunner.run(dependencies: StoreRestoreDependencies(
            sync: { order.append("sync") },
            calibrate: { order.append("calibrate") }
        ))

        #expect(outcome == .synced)
        #expect(order == ["sync", "calibrate"])
    }

    @Test("用户取消 App Store 登录不算失败")
    func userCancellationIsNotFailure() async throws {
        var calibrated = false
        let outcome = try await StoreRestoreRunner.run(dependencies: StoreRestoreDependencies(
            sync: { throw StoreKitError.userCancelled },
            calibrate: { calibrated = true }
        ))

        #expect(outcome == .userCancelled)
        #expect(calibrated)
    }

    @Test("同步失败时抛出原始错误且不校准")
    func syncFailurePropagates() async throws {
        struct SyncFailure: Error {}
        var calibrated = false

        await #expect(throws: SyncFailure.self) {
            _ = try await StoreRestoreRunner.run(dependencies: StoreRestoreDependencies(
                sync: { throw SyncFailure() },
                calibrate: { calibrated = true }
            ))
        }
        #expect(calibrated == false)
    }

    @Test("商店服务层的恢复入口确实触发同步")
    func storeServiceRestoreTriggersSync() async throws {
        let original = StoreService.appStoreSync
        defer { StoreService.appStoreSync = original }

        var synced = false
        StoreService.appStoreSync = { synced = true }

        _ = try? await StoreService.restorePurchases()

        #expect(synced)
    }
}
