import SwiftUI

struct NonRenewableProductsView: View {
    @EnvironmentObject private var store: StoreProvider

    var body: some View {
        productList(items: store.nonRenewables)
    }

    @ViewBuilder
    private func productList(items: [StoreProductDTO]) -> some View {
        if items.isEmpty {
            Text("暂无非续订商品").foregroundStyle(.secondary)
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


