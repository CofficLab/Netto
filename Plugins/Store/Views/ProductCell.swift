import MagicCore

import OSLog
import StoreKit
import SwiftUI

struct ProductCell: View, SuperLog {
    @State var isPurchased: Bool = false
    @State var errorTitle = ""
    @State var isShowingError: Bool = false
    @State var purchasing = false
    @State var btnHovered: Bool = false
    @State var status: Product.SubscriptionInfo.Status?
    @State var current: Product?

    let product: ProductDTO
    let purchasingEnabled: Bool
    let showStatus: Bool

    var isCurrent: Bool {
        if let current = current {
            return current.id == product.id
        }

        return false
    }

    nonisolated static let emoji = "🖥️"

    init(product: ProductDTO, purchasingEnabled: Bool = true, showStatus: Bool = false) {
        self.product = product
        self.purchasingEnabled = purchasingEnabled
        self.showStatus = showStatus
    }

    var body: some View {
        HStack {
            if purchasingEnabled {
                productDetail
                Spacer()
                buyButton
            } else {
                productDetail
            }
        }
        .alert(isPresented: $isShowingError, content: {
            Alert(title: Text(errorTitle), message: nil, dismissButton: .default(Text("好")))
        })
    }

    // MARK: 中间的产品介绍

    @ViewBuilder
    var productDetail: some View {
        if product.kind == .autoRenewable {
            VStack(alignment: .leading) {
                Text(product.displayName)
                    .bold()
                Text(product.id)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if isCurrent {
                    Text("正在使用")
                        .font(.footnote)
                        .foregroundStyle(.green)
                }
                if isPurchased {
                    Text("已购买")
                        .font(.footnote)
                        .foregroundStyle(.green)
                }
            }
        } else {
            VStack(alignment: .leading) {
                Text(product.description)
                    .frame(alignment: .leading)
                Text(product.id)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: 购买按钮的提示词

    func subscribeButton(_ subscription: SubscriptionInfoDTO) -> some View {
        let unit: String
        let plural = 1 < subscription.subscriptionPeriod.value
        switch subscription.subscriptionPeriod.unit {
        case "day":
            unit = plural ? "\(subscription.subscriptionPeriod.value) 天" : "天"
        case "week":
            unit = plural ? "\(subscription.subscriptionPeriod.value) 周" : "周"
        case "month":
            unit = plural ? "\(subscription.subscriptionPeriod.value) 月" : "月"
        case "year":
            unit = plural ? "\(subscription.subscriptionPeriod.value) 年" : "年"
        default:
            unit = "period"
        }

        return Text(product.displayPrice + "/" + unit)
            .foregroundColor(.white)
            .bold()
    }

    // MARK: 购买按钮

    var buyButton: some View {
        Button(action: {
            buy()
        }) {
            if purchasing {
                Text("支付中...")
                    .bold()
                    .foregroundColor(.white)
            } else {
                if let subscription = product.subscription {
                    subscribeButton(subscription)
                } else {
                    Text(product.displayPrice)
                        .foregroundColor(.white)
                        .bold()
                }
            }
        }
        .buttonStyle(BuyButtonStyle(isPurchased: isPurchased, hovered: btnHovered))
        .disabled(purchasing)
        .onHover(perform: { hovering in
            self.btnHovered = hovering
        })
        .onAppear(perform: onAppear)
    }

    // MARK: 去购买

    func buy() {
        purchasing = true
        Task {
            do {
                os_log("\(self.t)🏬 点击了购买按钮")

                let result = try await StoreService.purchase(product)
                if result != nil {
                    withAnimation {
                        os_log("\(self.t)🏬 购买回调，更新购买状态为 true")
                        isPurchased = true
                    }
                } else {
                    os_log("\(self.t)购买回调，结果为空，表示取消了")
                }
            } catch StoreError.failedVerification {
                errorTitle = "App Store 验证失败"
                isShowingError = true
            } catch {
                errorTitle = error.localizedDescription
                isShowingError = true
            }

            purchasing = false
        }
    }
}

// MARK: Event Handler

extension ProductCell {
    func onAppear() {
        let verbose = false
        Task {
            // 检查购买状态
            let groups = try? await StoreService.fetchAllProducts()
            let purchasedLists = await StoreService.fetchPurchasedLists(
                cars: groups?.cars ?? [],
                subscriptions: groups?.subscriptions ?? [],
                nonRenewables: groups?.nonRenewables ?? []
            )

            switch product.kind {
            case .nonRenewable:
                isPurchased = purchasedLists.nonRenewables.contains { $0.id == product.id }
            case .nonConsumable:
                isPurchased = purchasedLists.cars.contains { $0.id == product.id }
            case .autoRenewable:
                isPurchased = purchasedLists.subscriptions.contains { $0.id == product.id }
            default:
                isPurchased = false
            }

            if verbose {
                os_log("\(self.t)OnAppear 检查购买状态 -> \(product.displayName) -> \(isPurchased)")
            }
        }
    }
}

// MARK: - Preview

#Preview("Buy") {
    PurchaseView(showCloseButton: false)
        .inRootView()
        .frame(height: 800)
}

#Preview("APP") {
    ContentView()
        .inRootView()
        .frame(width: 700)
        .frame(height: 800)
}
