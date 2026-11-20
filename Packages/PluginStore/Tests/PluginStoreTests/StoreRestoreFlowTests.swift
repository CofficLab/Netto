import Foundation
import Testing
@testable import PluginStore

/// 恢复购买的结果判定：由恢复后的账户状态决定，而不是恢复前后的差值。
@MainActor
@Suite("恢复结果判定")
struct StoreRestoreFlowTests {

    private func makeFlow(
        sync: @escaping () async throws -> Void = {},
        refreshPurchasedProducts: @escaping () async throws -> Void = {},
        accountState: StoreRestoreFlow.AccountState
    ) -> StoreRestoreFlow {
        StoreRestoreFlow(
            sync: sync,
            refreshEntitlement: {},
            refreshPurchasedProducts: refreshPurchasedProducts,
            accountState: { accountState },
            reloadProducts: {}
        )
    }

    @Test("权益本来就有效的用户恢复后报成功，而不是「没有购买记录」")
    func activeEntitlementReportsSuccess() async {
        let result = await makeFlow(accountState: .init(
            hasActiveEntitlement: true,
            hasPurchasedProducts: false
        )).run()

        #expect(isSuccess(result))
    }

    @Test("账户上存在已购商品时恢复报成功")
    func purchasedProductsReportSuccess() async {
        let result = await makeFlow(accountState: .init(
            hasActiveEntitlement: false,
            hasPurchasedProducts: true
        )).run()

        #expect(isSuccess(result))
    }

    @Test("账户上确实没有任何购买时才报「没有购买记录」")
    func noPurchaseReportsNothingFound() async {
        let result = await makeFlow(accountState: .init(
            hasActiveEntitlement: false,
            hasPurchasedProducts: false
        )).run()

        if case .nothingFound = result {
            return
        }
        Issue.record("无购买时应报 nothingFound，实际为 \(String(describing: result))")
    }

    @Test("已购集合刷新失败时上报失败，而不是「没有购买记录」")
    func refreshFailureReportsFailed() async {
        struct RefreshFailure: Error {}

        let result = await makeFlow(
            refreshPurchasedProducts: { throw RefreshFailure() },
            accountState: .init(hasActiveEntitlement: true, hasPurchasedProducts: true)
        ).run()

        guard case .failed(let error) = result else {
            Issue.record("刷新失败时应报 failed，实际为 \(String(describing: result))")
            return
        }
        #expect(error is RefreshFailure)
    }

    @Test("同步失败时上报失败")
    func syncFailureReportsFailed() async {
        struct SyncFailure: Error {}

        let result = await makeFlow(
            sync: { throw SyncFailure() },
            accountState: .init(hasActiveEntitlement: true, hasPurchasedProducts: true)
        ).run()

        guard case .failed(let error) = result else {
            Issue.record("同步失败时应报 failed，实际为 \(String(describing: result))")
            return
        }
        #expect(error is SyncFailure)
    }

    private func isSuccess(_ result: StoreRestoreFlow.Result) -> Bool {
        if case .success = result { return true }
        return false
    }
}
