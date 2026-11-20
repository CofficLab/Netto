import Foundation
import StoreKit

/// 恢复购买的结果。
enum StoreRestoreOutcome: Equatable {
    /// 已与 App Store 同步并完成权益校准。
    case synced
    /// 用户取消了 App Store 登录：不是失败，但也没有新凭据。
    case userCancelled
}

/// 恢复购买依赖的外部动作（可替换，便于回归测试）。
@MainActor
struct StoreRestoreDependencies {
    /// 与 App Store 同步凭据（`AppStore.sync()`）。
    var sync: () async throws -> Void
    /// 校准本地权益缓存。
    var calibrate: () async -> Void
}

/// 恢复购买的执行流程。
///
/// 关键点：必须真正调用 `AppStore.sync()`。`Transaction.currentEntitlements`
/// 只反映已经落到本机收据库的交易；重装、换机或换 Apple ID 之后这份缓存
/// 是空的，只做本地校准会读到同样的空数据，恢复按钮永远返回「没有购买记录」。
@MainActor
enum StoreRestoreRunner {

    /// 执行恢复：先同步商店端凭据，再校准本地权益。
    ///
    /// - Parameter dependencies: 同步与校准动作。
    /// - Returns: 恢复结果；用户取消登录时返回 `.userCancelled`。
    /// - Throws: 同步失败（非用户取消）时抛出原始错误。
    static func run(dependencies: StoreRestoreDependencies) async throws -> StoreRestoreOutcome {
        let outcome: StoreRestoreOutcome
        do {
            try await dependencies.sync()
            outcome = .synced
        } catch {
            guard isUserCancellation(error) else { throw error }
            outcome = .userCancelled
        }
        await dependencies.calibrate()
        return outcome
    }

    /// 用户取消 App Store 登录不算失败。
    static func isUserCancellation(_ error: Error) -> Bool {
        guard let storeKitError = error as? StoreKitError else { return false }
        if case .userCancelled = storeKitError { return true }
        return false
    }
}
