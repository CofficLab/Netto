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
                // 试用期信息
                if let introOffer = product.subscription?.introductoryOffer {
                    Text(formatIntroductoryOffer(introOffer))
                        .font(.caption)
                }
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

    @ViewBuilder
    func subscribeButton(_ subscription: SubscriptionInfoDTO) -> some View {
        VStack(spacing: 2) {
            // 主要价格信息
            Text(product.displayPrice + "/" + formatPeriodUnit(subscription.subscriptionPeriod))
                .foregroundColor(.white)
                .bold()
        }
    }
    
    // MARK: 格式化周期单位
    
    private func formatPeriodUnit(_ period: StoreSubscriptionPeriodDTO) -> String {
        let plural = 1 < period.value
        switch period.unit {
        case "day":
            return plural ? "\(period.value) 天" : "天"
        case "week":
            return plural ? "\(period.value) 周" : "周"
        case "month":
            return plural ? "\(period.value) 月" : "月"
        case "year":
            return plural ? "\(period.value) 年" : "年"
        default:
            return "period"
        }
    }
    
    // MARK: 格式化试用期信息
    
    private func formatIntroductoryOffer(_ offer: IntroductoryOfferDTO) -> String {
        let periodText: String
        let plural = offer.subscriptionPeriod.value > 1
        
        switch offer.subscriptionPeriod.unit {
        case "day":
            periodText = plural ? "\(offer.subscriptionPeriod.value) 天" : "天"
        case "week":
            periodText = plural ? "\(offer.subscriptionPeriod.value) 周" : "周"
        case "month":
            periodText = plural ? "\(offer.subscriptionPeriod.value) 月" : "月"
        case "year":
            periodText = plural ? "\(offer.subscriptionPeriod.value) 年" : "年"
        default:
            periodText = "period"
        }
        
        switch offer.paymentMode {
        case "FreeTrial":
            return "首\(periodText)免费"
        case "PayAsYouGo":
            return "首\(periodText)仅\(offer.displayPrice)"
        case "PayUpFront":
            return "首\(periodText)预付\(offer.displayPrice)"
        default:
            return "首\(periodText)优惠"
        }
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




