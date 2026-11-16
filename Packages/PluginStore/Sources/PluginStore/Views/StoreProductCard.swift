import LumiUI
import SwiftUI

// MARK: - 商品卡片

/// 商品卡片：单个订阅档位的价格、周期与购买入口。
///
/// 已购商品不隐藏，而是保留在原位并标记「已购买」——隐藏会让用户以为
/// 订阅丢了，转而去做恢复购买。
struct StoreProductCard: View {
    @LumiTheme private var theme

    let product: ProductDTO
    let isPurchased: Bool
    let isPurchasing: Bool
    let onPurchase: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: AppUI.Spacing.md) {
            details

            Spacer(minLength: AppUI.Spacing.sm)

            purchaseButton
        }
        .padding(AppUI.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                .fill(theme.appListRowBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    // MARK: - Subviews

    private var details: some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.xs) {
            HStack(spacing: AppUI.Spacing.xs) {
                Text(product.displayName)
                    .font(AppUI.Typography.bodyEmphasized)
                    .foregroundStyle(theme.textPrimary)

                if isPurchased {
                    purchasedBadge
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(product.displayPrice)
                    .font(AppUI.Typography.title3)
                    .foregroundStyle(theme.primary)

                if let period = periodLabel {
                    Text(period)
                        .font(AppUI.Typography.caption1)
                        .foregroundStyle(theme.textSecondary)
                }
            }

            if let offer = product.subscription?.introductoryOffer {
                trialLabel(offer)
            }
        }
    }

    private var purchasedBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10))
                .accessibilityHidden(true)

            Text("已购买")
                .font(AppUI.Typography.caption2)
        }
        .foregroundStyle(theme.success)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule(style: .continuous)
                .fill(theme.success.opacity(0.14))
        )
    }

    private func trialLabel(_ offer: IntroductoryOfferDTO) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "gift.fill")
                .font(.system(size: 10))
                .accessibilityHidden(true)

            Text(offer.paymentMode == "FreeTrial" ? "含免费试用" : "首期优惠 \(offer.displayPrice)")
                .font(AppUI.Typography.caption1)
        }
        .foregroundStyle(theme.primary)
    }

    @ViewBuilder
    private var purchaseButton: some View {
        if isPurchasing {
            ProgressView()
                .controlSize(.small)
                .frame(width: 72, height: 22)
        } else if isPurchased {
            Text("已订阅")
                .font(AppUI.Typography.bodyEmphasized)
                .foregroundStyle(theme.success)
                .frame(minWidth: 72)
        } else {
            AppButton("订阅", systemImage: "crown.fill", style: .primary, size: .small) {
                onPurchase()
            }
        }
    }

    private var borderColor: Color {
        isPurchased ? theme.success.opacity(0.35) : theme.appSubtleBorder
    }

    /// 订阅周期文案（「每月」「每 3 个月」）。
    private var periodLabel: String? {
        guard let period = product.subscription?.subscriptionPeriod else { return nil }

        let unit: String
        switch period.unit {
        case "day": unit = "天"
        case "week": unit = "周"
        case "month": unit = "月"
        case "year": unit = "年"
        default: return nil
        }

        return period.value > 1 ? "每 \(period.value) \(unit)" : "每\(unit)"
    }
}

// MARK: - 订阅组区块

/// 订阅组区块：组内档位并排列出。
struct StoreProductGroupSection: View {
    @LumiTheme private var theme

    let group: SubscriptionGroupDTO
    let isPurchased: (String) -> Bool
    let purchasingProductID: String?
    let onPurchase: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.sm) {
            HStack(spacing: AppUI.Spacing.xs) {
                Text(group.displayName)
                    .font(AppUI.Typography.callout)
                    .foregroundStyle(theme.textPrimary)

                Text(String(group.subscriptions.count))
                    .font(AppUI.Typography.caption2)
                    .foregroundStyle(theme.textTertiary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(
                        Capsule(style: .continuous)
                            .fill(theme.textSecondary.opacity(0.12))
                    )
            }

            VStack(spacing: AppUI.Spacing.sm) {
                ForEach(group.subscriptions) { product in
                    StoreProductCard(
                        product: product,
                        isPurchased: isPurchased(product.id),
                        isPurchasing: purchasingProductID == product.id,
                        onPurchase: { onPurchase(product.id) }
                    )
                }
            }
        }
    }
}

private extension SubscriptionGroupDTO {
    /// 组名：StoreKit 未给出显示名时回退为「订阅」，避免中文界面冒出组 ID。
    var displayName: String {
        name.isEmpty || name == id ? "订阅" : name
    }
}
