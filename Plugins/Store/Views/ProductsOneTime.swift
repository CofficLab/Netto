import SwiftUI

struct ProductsOfOneTime: View {
    @EnvironmentObject private var store: StoreProvider

    var body: some View {
        productList(items: store.cars)
    }

    @ViewBuilder
    private func productList(items: [StoreProductDTO]) -> some View {
        if items.isEmpty {
            Text("暂无一次性购买商品").foregroundStyle(.secondary)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(items, id: \.id) { p in
                        ProductCell(product: p, purchasingEnabled: true, showStatus: false)
                        Divider()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Buy") {
    PurchaseView()
        .inRootView()
        .frame(height: 800)
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(width: 700)
        .frame(height: 800)
}


