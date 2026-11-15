import Foundation
import LumiUI
import ProviderSettingView
import ProviderToolbar
import SwiftUI

/// 主窗口工具栏右侧的设置按钮（对齐 Lumi / Wakey）。
///
/// 共享包只提供工具栏协议与渲染，按钮归属宿主，因此在装配期由 Factory
/// 直接贡献一个 `ToolbarItem`：点击发出标准的「打开设置」通知，由常驻的
/// `SettingsWindowRouter` 打开设置窗口 —— 插件与视图层都不持有窗口动作。
@MainActor
enum NettoToolbarSettings {
    /// 设置按钮的工具栏项。
    ///
    /// `title` 会被工具栏渲染成悬停提示。
    static func makeItem() -> ProviderToolbar.ToolbarItem {
        ProviderToolbar.ToolbarItem(
            id: "settings",
            title: "设置",
            placement: .trailing,
            category: .global,
            order: 300
        ) {
            AppIconButton(systemImage: "gearshape") {
                NotificationCenter.default.post(
                    name: SettingViewNavigation.openSettingsNotification,
                    object: nil
                )
            }
            .accessibilityLabel("设置")
            .accessibilityIdentifier("netto.toolbar.settings")
        }
    }
}
