import SwiftUI
import StoreKit
import OSLog

struct OneTimeView: View {
    @EnvironmentObject var store: StoreProvider
    
    private var products: [Product] {
        store.nonRenewables
    }
    
    var body: some View {
        Section("一次性订阅") {
            ForEach(products) { product in
                ProductCell(product: product, purchasingEnabled: store.purchasedSubscriptions.isEmpty)
            }
        }
    }
}

// MARK: - Preview

#Preview("Buy") {
    BuySetting()
        .inRootView()
        .frame(height: 800)
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(width: 700)
        .frame(height: 800)
}
