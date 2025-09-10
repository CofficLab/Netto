import SwiftUI
import StoreKit
import MagicCore
import MagicAlert

struct DebugView: View, SuperLog {
    @EnvironmentObject var m: MagicMessageProvider
    @State private var isLoading: Bool = false
    @State private var productGroups: StoreProductGroupsDTO?
    @State private var purchasedCars: [StoreProductDTO] = []
    @State private var purchasedSubscriptions: [StoreProductDTO] = []
    @State private var purchasedNonRenewables: [StoreProductDTO] = []
    @State private var subscriptionStatuses: [StoreSubscriptionStatusDTO] = []
    @State private var highestSubscriptionProduct: StoreProductDTO?
    @State private var highestSubscriptionStatus: StoreSubscriptionStatusDTO?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Button(action: loadProducts) {
                    Text(isLoading ? "加载中…" : "加载产品")
                }
                .disabled(isLoading)
                
                Button(action: updateSubscriptionStatus) {
                    Text(isLoading ? "加载中…" : "更新订阅状态")
                }
                .disabled(isLoading)

                Button(action: testFetchPurchased) {
                    Text(isLoading ? "加载中…" : "测试已购")
                }
                .disabled(isLoading)

                Button("清空") { clear() }

                Spacer()
            }
            
            Divider()

            Spacer()

            if let groups = productGroups {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        GroupBox {
                            productSection(groups: groups)
                        }

                        GroupBox {
                            purchasedSection()
                        }

                        GroupBox {
                            subscriptionStatusSection(subscriptions: groups.subscriptions)
                        }
                    }
                }
            } else {
                Text("尚未加载产品")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Action
extension DebugView {
    func loadProducts() {
        isLoading = true
        productGroups = nil

        Task {
            do {
                let dict = StoreService.loadProductIdToEmojiData()
                let groups = try await StoreService.requestProducts(productIds: dict.keys)
                setGroups(groups)
            } catch {
                self.m.error(error)
            }
            
            self.isLoading = false
        }
    }
    
    func updateSubscriptionStatus() {
        isLoading = true

        Task {
            do {
                let result = try await StoreService.inspectSubscriptionStatus(self.className)
                setSubscriptionInspectResult(result)
            } catch {
                self.m.error(error)
            }
            
            self.isLoading = false
            self.m.info("检查结束")
        }
    }

    func clear() {
        productGroups = nil
        purchasedCars.removeAll()
        purchasedSubscriptions.removeAll()
        purchasedNonRenewables.removeAll()
        subscriptionStatuses.removeAll()
        highestSubscriptionProduct = nil
        highestSubscriptionStatus = nil
    }

    func testFetchPurchased() {
        isLoading = true

        Task {
            do {
                // 若尚未加载产品，先拉取
                let groups: StoreProductGroupsDTO
                if let existing = productGroups {
                    groups = existing
                } else {
                    let dict = StoreService.loadProductIdToEmojiData()
                    groups = try await StoreService.requestProducts(productIds: dict.keys)
                    setGroups(groups)
                }

                let result = await StoreService.fetchPurchasedLists(
                    cars: groups.cars,
                    subscriptions: groups.subscriptions,
                    nonRenewables: groups.nonRenewables
                )

                setPurchased(result)
                self.m.info("已更新已购清单")
            } catch {
                self.m.error(error)
            }

            self.isLoading = false
        }
    }
}

// MARK: - Setter
extension DebugView {
    @MainActor
    func setGroups(_ newValue: StoreProductGroupsDTO) {
        productGroups = newValue
    }

    @MainActor
    func setPurchased(_ newValue: (
        cars: [StoreProductDTO],
        nonRenewables: [StoreProductDTO],
        subscriptions: [StoreProductDTO]
    )) {
        purchasedCars = newValue.cars
        purchasedNonRenewables = newValue.nonRenewables
        purchasedSubscriptions = newValue.subscriptions
    }

    @MainActor
    func setSubscriptionInspectResult(_ result: (
        subscriptions: [StoreProductDTO],
        statuses: [StoreSubscriptionStatusDTO],
        highestProduct: StoreProductDTO?,
        highestStatus: StoreSubscriptionStatusDTO?
    )) {
        subscriptionStatuses = result.statuses
        highestSubscriptionProduct = result.highestProduct
        highestSubscriptionStatus = result.highestStatus
    }
}

// MARK: - Private Helpers
extension DebugView {
    func groupSection(title: String, items: [StoreProductDTO]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(title) (\(items.count))")
                .font(.headline)
            if items.isEmpty {
                Text("空")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items, id: \.id) { p in
                    HStack {
                        Text(p.displayName)
                        Spacer()
                        Text(p.displayPrice)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Divider()
        }
    }

    @ViewBuilder
    func purchasedSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Purchased")
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text("Cars (\(purchasedCars.count))").font(.headline)
                if purchasedCars.isEmpty {
                    Text("空").foregroundStyle(.secondary)
                } else {
                    ForEach(purchasedCars, id: \.id) { p in
                        Text(p.displayName)
                    }
                }
                Divider()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Subscriptions (\(purchasedSubscriptions.count))").font(.headline)
                if purchasedSubscriptions.isEmpty {
                    Text("空").foregroundStyle(.secondary)
                } else {
                    ForEach(purchasedSubscriptions, id: \.id) { p in
                        Text(p.displayName)
                    }
                }
                Divider()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("NonRenewables (\(purchasedNonRenewables.count))").font(.headline)
                if purchasedNonRenewables.isEmpty {
                    Text("空").foregroundStyle(.secondary)
                } else {
                    ForEach(purchasedNonRenewables, id: \.id) { p in
                        Text(p.displayName)
                    }
                }
                Divider()
            }
        }
    }

    @ViewBuilder
    func productSection(groups: StoreProductGroupsDTO) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Products")
                .font(.title3)

            groupSection(title: "Cars", items: groups.cars)
            groupSection(title: "Subscriptions", items: groups.subscriptions)
            groupSection(title: "NonRenewables", items: groups.nonRenewables)
            groupSection(title: "Fuel", items: groups.fuel)
        }
    }

    @ViewBuilder
    func subscriptionStatusSection(subscriptions: [StoreProductDTO]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subscription Status")
                .font(.title3)

            if let highest = highestSubscriptionProduct {
                HStack {
                    Text("Highest Product:")
                    Spacer()
                    Text(highest.displayName)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Highest Product: 无").foregroundStyle(.secondary)
            }

            if let hs = highestSubscriptionStatus {
                HStack {
                    Text("Highest Status:")
                    Spacer()
                    Text("state=\(hs.state)")
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Highest Status: 无").foregroundStyle(.secondary)
            }

            Divider()

            Text("All Statuses (\(subscriptionStatuses.count))")
                .font(.headline)
            if subscriptionStatuses.isEmpty {
                Text("空").foregroundStyle(.secondary)
            } else {
                ForEach(Array(subscriptionStatuses.enumerated()), id: \.offset) { _, s in
                    HStack(alignment: .top) {
                        Text("state=")
                        Text("\(s.state)")
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let pid = s.currentProductID {
                            Text(pid).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Store Debug") {
    DebugView()
        .inRootView()
        .frame(width: 500, height: 800)
}
