import ProviderAppSettings
import ProviderShell
import ProviderStore

/// 禁止联网的完整流程：限额判定、写入规则、结果反馈。
///
/// 从视图层抽出，使「达到免费版限制时必须给出可见反馈」这条规则可以在
/// 不驱动 SwiftUI 按钮的情况下被回归测试覆盖。
@MainActor
struct DenyOperation {
    /// 操作结果。
    enum Outcome: Equatable {
        /// 规则已写入。
        case denied
        /// 达到免费版限制，需要升级。
        case upgradeRequired(String)
        /// 写入失败。
        case failed(String)
    }

    let repo: AppSettingsProviding
    let entitlement: StoreEntitlementSnapshot
    let ui: UIProvider
    let shell: ShellCenter
    let appId: String
    /// 规则写入成功后通知列表重新加载。
    var onRuleChange: (() -> Void)?

    func run() async throws -> Outcome {
        let isProOrHigher = entitlement.isProOrHigher
        let deniedCount = isProOrHigher ? 0 : try await repo.deniedAppsCount()

        if case .upgradeRequired(let message) = FreeTierDenyGuard.decide(
            isProOrHigher: isProOrHigher,
            deniedCount: deniedCount
        ) {
            // 升级引导必须覆盖在当前视图之上，否则提示不可见。
            ui.presentUpgradeLimit()
            shell.postError(message)
            return .upgradeRequired(message)
        }

        do {
            try await repo.setDeny(appId)
        } catch {
            shell.postError(error.localizedDescription)
            return .failed(error.localizedDescription)
        }

        onRuleChange?()
        shell.post(ToastMessage(description: "已禁止"))
        return .denied
    }
}
