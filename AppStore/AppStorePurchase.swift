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
        AppStoreDesktop {
            PurchaseView()
                .background(.background)
                .frame(height: 500)
                .frame(width: 500)
        }
    }
}

// MARK: - Preview

#Preview("App Store PurchaseView") {
    AppStorePurchaseView()
        .inMagicContainer(CGSizeMake(1280, 800), scale:1)
}
