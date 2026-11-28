import LumiUI
import SwiftUI

// MARK: - 商店设置页

/// 商店设置页：订阅状态、版本对比、商品列表与恢复购买入口。
///
/// 与「通用」「外观」等设置页使用同一套 LumiUI 组件
/// （`AppSettingsContentScaffold` + `AppSettingSection` + `AppSettingRow`），
/// 侧栏、分组卡片与留白节奏与其他设置页一致。
public struct StoreSettingsView: View {
    /// 用 `@ObservedObject` 订阅 ViewModel：商品加载完成改的是对象内的
    /// `@Published` 属性，只用 `@State` 存引用不会触发重绘。
    @ObservedObject private var viewModel: StoreViewModel

    public init(viewModel: StoreViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        StoreSettingsContent(viewModel: viewModel)
            .task {
                await viewModel.loadProducts()
            }
    }
}

// MARK: - 内容

private struct StoreSettingsContent: View {
    @LumiTheme private var theme

    @ObservedObject var viewModel: StoreViewModel

    @State private var isShowingRestore = false

    var body: some View {
        AppSettingsContentScaffold(maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: AppUI.Spacing.lg) {
                subscriptionSection
                purchaseSection
                restoreSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(isPresented: $isShowingRestore) {
            StoreRestoreView(
                state: viewModel.restoreState,
                error: viewModel.restoreError,
                onRestore: {
                    Task { await viewModel.restore() }
                },
                onReset: {
                    viewModel.resetRestoreState()
                }
            )
        }
    }

    // MARK: - Sections

    /// 订阅信息：当前版本、订阅状态、到期时间。
    private var subscriptionSection: some View {
        AppSettingSection(title: String(localized: "Subscription Info")) {
            VStack(spacing: 0) {
                AppSettingRow(
                    title: String(localized: "Current Plan"),
                    description: String(localized: "The plan you are using"),
                    icon: "star.fill"
                ) {
                    Text(viewModel.tierDisplayName)
                        .font(AppUI.Typography.footnote)
                        .foregroundStyle(theme.textSecondary)
                }

                divider

                AppSettingRow(
                    title: String(localized: "Subscription Status"),
                    description: viewModel.isPro
                        ? String(localized: "Your subscription is active. Thank you for your support.")
                        : String(localized: "You are using the free plan"),
                    icon: "info.circle"
                ) {
                    statusBadge
                }

                if let expiresAt = viewModel.expiresAt {
                    divider

                    AppSettingRow(
                        title: String(localized: "Expiration Date"),
                        description: String(localized: "When your subscription ends"),
                        icon: "calendar"
                    ) {
                        Text(expiresAt.formatted(date: .abbreviated, time: .omitted))
                            .font(AppUI.Typography.footnote)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }
        }
    }

    /// 应用内购买：版本对比 + 商品列表 + 法律链接。
    private var purchaseSection: some View {
        AppSettingSection(title: String(localized: "In-App Purchases")) {
            VStack(alignment: .leading, spacing: AppUI.Spacing.md) {
                StoreVersionComparisonView()

                StoreProductListView(
                    state: viewModel.listState,
                    groups: viewModel.subscriptionGroups,
                    loadError: viewModel.loadError,
                    purchaseError: viewModel.purchaseError,
                    isPurchased: { viewModel.isPurchased($0) },
                    purchasingProductID: viewModel.purchasingProductID,
                    onPurchase: { productID in
                        Task { await viewModel.purchase(productID) }
                    },
                    onRetry: {
                        Task { await viewModel.loadProducts() }
                    }
                )

                StoreLegalLinksView()
            }
            .padding(.vertical, AppUI.Spacing.xs)
        }
    }

    /// 恢复购买入口。
    private var restoreSection: some View {
        AppSettingSection {
            AppSettingRow(
                title: String(localized: "Restore Purchases"),
                description: String(localized: "Recover purchases made on other devices"),
                icon: "arrow.clockwise"
            ) {
                AppButton(
                    "Restore",
                    systemImage: "arrow.clockwise",
                    style: .secondary,
                    size: .small
                ) {
                    isShowingRestore = true
                }
            }
        }
    }

    // MARK: - Helpers

    private var divider: some View {
        Divider()
            .padding(.vertical, AppUI.Spacing.xs)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if viewModel.isPro {
            Text("Active")
                .font(AppUI.Typography.footnote)
                .foregroundStyle(theme.success)
        } else {
            Text("Free")
                .font(AppUI.Typography.footnote)
                .foregroundStyle(theme.textSecondary)
        }
    }
}
