import MagicBackground
import MagicContainer
import MagicCore
import MagicUI
import SwiftUI

/**
 * App Store - 购买页面，用于创建订阅时的审核
 */
struct AppStorePurchaseView: View {
    var body: some View {
        AppStoreHeroContainer(
            title: AppConfig.appName,
            subtitleTop: "实时监控，简单可靠。",
            subtitleBottom: "看得见的网络安全，清晰而从容。"
        ) {
            PurchaseView()
        }
    }
}

// MARK: - Preview

#Preview("App Store PurchaseView") {
    AppStorePurchaseView()
        .inMagicContainer(CGSizeMake(2560, 1600), scale: 0.3)
}
