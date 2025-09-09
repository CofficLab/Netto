import SwiftUI
import StoreKit

struct DebugView: View {
    @State private var isLoading: Bool = false
    @State private var error: Error?
    @State private var productGroups: StoreProductGroupsDTO?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Button(action: loadProducts) {
                    Text(isLoading ? "加载中…" : "加载产品")
                }
                .disabled(isLoading)

                Button("清空") { clear() }

                Spacer()

                // 简单展示计算失效时间（无状态函数演示）
                Text("失效时间演示: \(format(date: StoreService.computeExpirationDate(from: nil)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = self.error {
                error.makeView()
            }

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
        error = nil
        isLoading = true
        productGroups = nil

        Task {
            do {
                let dict = StoreService.loadProductIdToEmojiData()
                let groups = try await StoreService.requestProductGroupsDTO(productIds: dict.keys)
                setGroups(groups)
            } catch {
                setError(error)
            }
        }
    }

    func clear() {
        productGroups = nil
        error = nil
    }
}

// MARK: - Setter
extension DebugView {
    @MainActor
    func setGroups(_ newValue: StoreProductGroupsDTO) {
        productGroups = newValue
        isLoading = false
    }

    @MainActor
    func setError(_ error: Error) {
        self.error = error
        isLoading = false
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

    func format(date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.string(from: date)
    }
}

// MARK: - Preview
#Preview("Store Debug - Large") {
    DebugView()
        .inRootView()
        .frame(width: 700, height: 900)
}

#Preview("Store Debug - Small") {
    DebugView()
        .inRootView()
        .frame(width: 600, height: 600)
}

