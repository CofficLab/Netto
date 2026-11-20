import Foundation

/// 一次「禁止联网」操作的判定结果。
enum FreeTierDenyDecision: Equatable {
    /// 允许执行。
    case allowed
    /// 被免费版限制拦截，附带面向用户的提示文案。
    case upgradeRequired(String)
}

/// 免费版的禁止数量限制。
///
/// 非 Pro 用户最多禁止 5 个应用；达到上限后必须给出可见反馈
/// （升级引导 + 错误提示），否则操作会静默失败。
enum FreeTierDenyGuard {
    /// 免费版允许禁止的应用数量上限。
    static let deniedLimit = 5

    /// 判定一次「禁止联网」是否被免费版限制拦截。
    static func decide(isProOrHigher: Bool, deniedCount: Int) -> FreeTierDenyDecision {
        if isProOrHigher || deniedCount < deniedLimit {
            return .allowed
        }
        return .upgradeRequired("已达到免费版限制，请升级到 Pro")
    }
}
