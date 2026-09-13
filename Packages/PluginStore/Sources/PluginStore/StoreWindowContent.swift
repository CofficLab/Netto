import SwiftUI

/// Store 插件窗口内容构建器（阶段 7 迁入 PluginStore 包）。
/// 窗口内容由 PluginStore 插件以 `WindowContentContribution` 贡献到 ShellCenter。
@MainActor
public enum StoreWindowContent {
    /// 构建商店窗口内容视图。
    public static func windowView() -> AnyView {
        AnyView(
            StoreRootView {
                PurchaseView(showCloseButton: false)
            }
        )
    }
}
