import OSLog
import StoreKit
import SwiftUI

struct MySubscription: View {

    @State private var error: Error? = nil
    @State private var refreshing: Bool = false
    @State private var description: String = ""
    @State private var status: RenewalState.RawValue?
    @State private var product: ProductDTO?

    private var statusDescription: String {
        guard let status = status else {
            return String(localized: "No Status")
        }

        switch status {
        case RenewalState.subscribed.rawValue:
            return String(localized: "Subscribed")
        case RenewalState.expired.rawValue:
            return String(localized: "Expired")
        case RenewalState.revoked.rawValue:
            return String(localized: "Revoked")
        case RenewalState.inGracePeriod.rawValue:
            return String(localized: "In Billing Grace Period")
        case RenewalState.inBillingRetryPeriod.rawValue:
            return String(localized: "In Billing Retry Period. The App Store will charge automatically.")
        default:
            return String(localized: "Unknown Status")
        }
    }

    private var productDescription: String {
        guard let product = product else {
            return String(localized: "No Subscription Product")
        }

        return product.displayName
    }

    var body: some View {
        GroupBox {
            VStack {
                header
                if status != nil {
                    Divider()
                    Spacer()
                    Text(statusDescription)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(productDescription)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .task {
            await refresh("🐛 初始化我的订阅")
        }
    }

    private var header: some View {
        ZStack {
            if status != nil {
                Text("Subscribed").font(.title3)
            } else {
                Text("No Active Subscription").font(.title3)
            }

            HStack {
                Spacer()
                ZStack {
                    if refreshing {
                        ProgressView().scaleEffect(0.4)
                    } else {
                        refreshButton
                    }
                }.frame(width: 30, height: 10)
            }
        }
    }

    // MARK: 刷新按钮

    private var refreshButton: some View {
        Button(action: {
            Task {
                await refresh("🐛 点击了我的订阅中的刷新按钮")
            }
        }, label: {
            Label(
                title: { Text("Refresh") },
                icon: { Image(systemName: "arrow.clockwise") }
            ).labelStyle(.iconOnly)
        }).disabled(refreshing).buttonStyle(.plain)
    }

    private func refresh(_ reason: String) async {
        refreshing = true

        do {
            let result = try await StoreService.inspectSubscriptionStatus(reason)
            self.status = result.highestStatus?.state
            self.product = result.highestProduct
        } catch {
            self.error = error
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            refreshing = false
        })
    }
}

// MARK: - Preview




