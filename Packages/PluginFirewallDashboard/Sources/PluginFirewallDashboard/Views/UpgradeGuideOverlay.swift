import ProviderFirewall
import SwiftUI

/// 升级引导的覆盖层。
///
/// 达到免费版限制时，引导必须覆盖在当前子视图（应用详情）之上，
/// 否则提示不可见，操作会静默失败。
struct UpgradeGuideOverlay: View {
    /// 宿主订阅防火墙状态后传入的最新状态。
    let state: FirewallState?

    @EnvironmentObject private var ui: UIProvider

    var body: some View {
        if ui.showsUpgradeOverlay {
            GuideView(state: state, showsBackdrop: false)
                .padding(.vertical, 8)
        }
    }
}
