import LumiUI
import SwiftUI

// MARK: - 商品列表

/// 商品列表：负责「加载 / 错误 / 空 / 有内容」四种呈现状态。
///
/// 刷新失败时保留旧商品，只在顶部叠加错误横幅——清空列表会让用户
/// 误以为商品下架了。
struct StoreProductListView: View {
    @LumiTheme private var theme

    let state: StoreProductListState
    let groups: [SubscriptionGroupDTO]
    let loadError: Error?
    let purchaseError: Error?
    let isPurchased: (String) -> Bool
    let purchasingProductID: String?
    let onPurchase: (String) -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.md) {
            if let loadError, state == .content {
                AppStatusBanner(
                    kind: .warning,
                    title: "Refresh Failed",
                    message: loadError.localizedDescription
                )
            }

            // 购买错误走独立横幅：标题是「购买失败」，不能复用「刷新失败」——
            // 那会让用户以为商品下架了。
            if let purchaseError {
                AppStatusBanner(
                    kind: .error,
                    title: "Purchase Failed",
                    message: purchaseError.localizedDescription
                )
            }

            switch state {
            case .loading:
                loadingState
            case .error:
                errorState
            case .empty:
                emptyState
            case .content:
                contentState
            }
        }
    }

    // MARK: - Subviews

    private var loadingState: some View {
        VStack(spacing: AppUI.Spacing.sm) {
            ProgressView()
                .controlSize(.small)

            Text("Loading subscription options…")
                .font(AppUI.Typography.footnote)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppUI.Spacing.xl)
    }

    private var errorState: some View {
        VStack(spacing: AppUI.Spacing.sm) {
            AppStatusBanner(
                kind: .error,
                title: "Unable to Load Subscription Options",
                message: loadError?.localizedDescription ?? String(localized: "Check your network connection and try again.")
            )

            AppButton("Retry", systemImage: "arrow.clockwise", style: .secondary, fillsWidth: true) {
                onRetry()
            }
        }
        .padding(.vertical, AppUI.Spacing.sm)
    }

    private var emptyState: some View {
        VStack(spacing: AppUI.Spacing.sm) {
            Image(systemName: "cart.circle")
                .font(.system(size: 44))
                .foregroundStyle(theme.textTertiary)
                .accessibilityHidden(true)

            Text("No subscription options available")
                .font(AppUI.Typography.bodyEmphasized)
                .foregroundStyle(theme.textSecondary)

            Text("Subscription options appear here once they are available on the App Store.")
                .font(AppUI.Typography.footnote)
                .foregroundStyle(theme.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppUI.Spacing.xl)
    }

    private var contentState: some View {
        VStack(alignment: .leading, spacing: AppUI.Spacing.md) {
            ForEach(groups, id: \.id) { group in
                StoreProductGroupSection(
                    group: group,
                    isPurchased: isPurchased,
                    purchasingProductID: purchasingProductID,
                    onPurchase: onPurchase
                )
            }
        }
    }
}
