import SwiftUI
import StoreKit
import MagicCore
import MagicAlert

struct DebugView: View, SuperLog {
    @EnvironmentObject var m: MagicMessageProvider
    @State private var isLoading: Bool = false
    @State private var productGroups: StoreProductGroupsDTO?

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

                Button("清空") { clear() }

                Spacer()
            }
            
            Divider()

            Spacer()

            if let groups = productGroups {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        groupSection(title: "Cars", items: groups.cars)
                        groupSection(title: "Subscriptions", items: groups.subscriptions)
                        groupSection(title: "NonRenewables", items: groups.nonRenewables)
                        groupSection(title: "Fuel", items: groups.fuel)
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
                try await StoreService.updateSubscriptionStatus(self.className)
            } catch {
                self.m.error(error)
            }
            
            self.isLoading = false
            self.m.info("检查结束")
        }
    }

    func clear() {
        productGroups = nil
    }
}

// MARK: - Setter
extension DebugView {
    @MainActor
    func setGroups(_ newValue: StoreProductGroupsDTO) {
        productGroups = newValue
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
}

// MARK: - Preview

#Preview("Store Debug") {
    DebugView()
        .inRootView()
        .frame(width: 500, height: 700)
}
