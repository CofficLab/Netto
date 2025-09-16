import SwiftUI

/// Store 插件的窗口内容
@MainActor
public struct StoreWindowContent: PluginWindowContent {
    public let windowTitle = "Store - TravelMode"
    
    @ViewBuilder
    public func windowView() -> AnyView {
        AnyView(
            StoreRootView {
                PurchaseView(showCloseButton: true)
            }
        )
    }
}
