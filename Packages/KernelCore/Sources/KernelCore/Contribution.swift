import Foundation
import Synchronization

/// 贡献 Token —— 插件向 Kernel 登记的可撤销资源句柄。
///
/// 插件在 `onBoot` 中用 `kernel.registerContribution(_:owner:)` 登记任意需要
/// 在停止/禁用/失败时撤回的资源（observer、Task、定时器、共享 Provider 贡献）。
/// Kernel 在 `cancelContributions(ownedBy:)` 中按登记顺序**逆序**调用 `revoke()`，
/// 保证撤回顺序可预测。
///
/// 线程/actor：`revoke()` 可在任意线程调用（内部 Mutex 保证幂等），
/// 但 Kernel 只会在 MainActor 生命周期路径中调用它。
public final class ContributionToken: Sendable {
    private struct State {
        var revoked = false
    }

    /// Token 稳定 ID（插件内唯一即可，Kernel 仅用于诊断）。
    public let id: String

    /// 幂等互斥状态。
    private let state = Mutex<State>(State())

    /// 实际撤回动作；只会在首次 `revoke()` 时执行一次。
    private let revokeAction: @Sendable () -> Void

    /// 创建贡献 Token。
    ///
    /// - Parameters:
    ///   - id: Token 稳定 ID（诊断用）。
    ///   - revokeAction: 撤回动作，被调用后不得抛错（失败应记录日志）。
    public init(id: String, revokeAction: @escaping @Sendable () -> Void) {
        self.id = id
        self.revokeAction = revokeAction
    }

    /// 执行撤回（幂等；重复调用只生效一次）。
    public func revoke() {
        let shouldRun = state.withLock { state -> Bool in
            guard !state.revoked else { return false }
            state.revoked = true
            return true
        }
        if shouldRun {
            revokeAction()
        }
    }

    /// 是否已撤回（诊断用）。
    public var isRevoked: Bool {
        state.withLock { $0.revoked }
    }
}
